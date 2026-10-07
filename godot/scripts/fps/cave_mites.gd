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
		if timer >= Config.MITE_SPAWN and list.size() < Config.MITE_MAX:
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
		var step := dir.normalized() * Config.MITE_SPEED * dt
		step.y += sin(time * 5.0 + m.phase) * dt * 1.5
		node.position += step
