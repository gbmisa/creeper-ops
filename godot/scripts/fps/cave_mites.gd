class_name CaveMites
extends RefCounted
## Cave mites: small flying chasers spawned by the Deep Core. Shootable, pop on contact.
## They only spawn and hunt while the Operative is down here (`target` is set).

var world: World
var spawn_pos: Vector3
var list: Array[Dictionary] = []
var timer := 0.0
var enabled := true
var target: Node3D = null        # the Operative's body proxy
var on_player_hit := Callable()


func _init(w: World, at: Vector3) -> void:
	world = w
	spawn_pos = at


## Clear line between two points through the cave's rock (no terrain/roof in the way).
static func has_line(grid: Grid, a: Vector3, b: Vector3) -> bool:
	var d := b - a
	var len := d.length()
	return len < 0.01 or grid.raycast(a, d / len, len) == null


## One mite step toward `goal`: straight if clear, else the nearest clear sidestep
## (Config.MITE_STEER_ANGLES). Returns the new position, or null if rock blocks every way.
static func steer(grid: Grid, pos: Vector3, goal: Vector3, step_len: float) -> Variant:
	var dir := (goal - pos).normalized()
	for a in Config.MITE_STEER_ANGLES:
		var d := dir.rotated(Vector3.UP, a)
		if grid.raycast(pos, d, step_len + Config.MITE_CLEARANCE) == null:
			return pos + d * step_len
	return null


func _spawn() -> void:
	var node := HazardMeshes.mite(Color("99ff66"))
	node.position = spawn_pos + Vector3(randf_range(-1.5, 1.5), 1.5, randf_range(-1.5, 1.5))
	world.add_child(node)
	var m := { "node": node, "hp": 2.0, "alive": true, "phase": randf() * 6.0 }
	m["target"] = { "node": node, "oy": 0.0, "radius": 0.45, "alive": func(): return m.alive,
		"on_hit": func(dmg, _p):
			m.hp -= dmg
			if m.hp <= 0.0:
				_kill(m) }
	world.add_target(m.target)
	list.append(m)


func _kill(m: Dictionary) -> void:
	if not m.alive:
		return
	m.alive = false
	world.effects.burst(m.node.position, Color("99ff66"), 0.8, 0.25)
	m.node.queue_free()
	world.remove_target(m.target)
	list.erase(m)


func kill_all() -> void:
	for m in list.duplicate():
		_kill(m)


func update(dt: float, time: float) -> void:
	if target == null:
		return
	if enabled:
		timer += dt
		# The Core only fires with a line of fire to the Operative.
		if timer >= Config.MITE_SPAWN and list.size() < Config.MITE_MAX \
				and has_line(world.grid, spawn_pos + Vector3(0, 1.5, 0), target.position + Vector3(0, 1.0, 0)):
			timer = 0.0
			_spawn()
	var goal := target.position + Vector3(0, 1.0, 0)
	for m in list.duplicate():
		var node: Node3D = m.node
		var dir := goal - node.position
		if dir.length() < 0.8:
			if on_player_hit.is_valid():
				on_player_hit.call(Config.MITE_DAMAGE)
			_kill(m)
			continue
		m["age"] = float(m.get("age", 0.0)) + dt
		var next: Variant = steer(world.grid, node.position, goal, Config.MITE_SPEED * dt)
		if next == null or m.age > Config.MITE_LIFE:
			_kill(m)   # burst on the rock
			continue
		node.position = (next as Vector3) + Vector3(0, sin(time * 5.0 + m.phase) * dt * 1.5, 0)
