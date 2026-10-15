class_name DemoCharge
## Planted demolition charge. The Operative buys charges at the Armoury (carry cap
## DEMO_CHARGE_MAX), holds E on an enemy structure to stick one to it, and after
## DEMO_FUSE seconds it blasts everything in reach. A blast also destroys enemy mortars caught in it (they are sabotaged for free otherwise).
## The Deep Core target is skipped (cave_hazards marks it with deep_core). Charges tick
## from their World's updaters, so the fuse runs in command mode and after a recall.

static var list: Array[Dictionary] = []
static var _hooked: Array = []
static var _armed: Array = []  # target dicts with a charge stuck on (is_same, never value-compared)
static var _ball: SphereMesh


## Hold-E interactable that plants a charge on a structure at `pos`. `alive` says whether
## the structure still stands. Dry-handed it shows the buy hint instead.
static func interactable(world: World, pos: Vector3, radius: float, alive: Callable, key: Dictionary = {}) -> Dictionary:
	var st := { "armed": false }
	var it := {}
	it.merge({
		"pos": pos, "radius": radius, "hold": Config.DEMO_PLANT_HOLD,
		"prompt": func() -> String:
			if not alive.call():
				return ""
			if st.armed or _is_armed(key):
				return "Charge armed. Get clear!"
			if OperativeUpgrades.charges <= 0:
				return "Needs a demolition charge: buy one at the Armoury (Command Node)"
			return "[%s] Plant demolition charge" % Keybinds.short("use"),
		"ready": func() -> bool: return alive.call() and not st.armed and not _is_armed(key) and OperativeUpgrades.charges > 0,
		"progress": func(_f: float, _p: Vector3) -> void: pass,
		"use": func() -> void:
			if alive.call() and not st.armed and not _is_armed(key) and OperativeUpgrades.take_charge():
				st.armed = true
				if not key.is_empty():
					_armed.append(key)
				plant(world, (it.pos as Vector3) + Vector3.UP * 0.9, key),
	})
	return it


## Non-living, big enough, not a raider or flyer (those carry no max_hp). Mortars carry
## charge_kill and are handled by their own interactable.
static func chargeable(t: Dictionary) -> bool:
	if not t.alive.call() or t.get("deep_core", false) or t.get("living", false) or t.get("no_charge", false):
		return false
	if t.has("charge_ok") and not (t.charge_ok as Callable).call():
		return false
	return t.get("chargeable", false) or float(t.get("max_hp", 0.0)) >= Config.DEMO_MIN_HP


## Plant interactables for every chargeable target in the world; only offered while the
## Operative carries a charge, and listed so they beat a same-spot sabotage prompt.
static func candidates(world: World) -> Array:
	var out := []
	if OperativeUpgrades.charges <= 0:
		return out
	for t in world.targets:
		if t.has("charge_kill") or not chargeable(t):
			continue
		var node := t.node as Node3D
		var it := interactable(world, node.global_position, float(t.radius) + Config.DEMO_REACH, t.alive, t)
		it["prefer"] = true
		out.append(it)
	return out


static func _is_armed(key: Dictionary) -> bool:
	for k in _armed:
		if is_same(k, key):
			return true
	return false


static func plant(world: World, pos: Vector3, key: Dictionary = {}) -> Dictionary:
	if _ball == null:
		_ball = SphereMesh.new()
		_ball.radius = 0.16
		_ball.height = 0.32
	var mi := MeshInstance3D.new()
	mi.mesh = _ball
	mi.material_override = Effects.glow_mat(Color("ff8844"))
	mi.position = pos
	world.add_child(mi)
	var c := { "world": world, "pos": pos, "fuse": Config.DEMO_FUSE, "node": mi, "beep": Config.DEMO_FUSE, "key": key }
	list.append(c)
	_hook(world)
	Sfx.play("alarm", pos)
	Bus.say("Demolition charge planted. %d seconds, get clear!" % ceili(Config.DEMO_FUSE), "warn")
	return c


static func tick(world: World, dt: float) -> void:
	for i in range(list.size() - 1, -1, -1):
		var c: Dictionary = list[i]
		if c.world != world:
			continue
		c.fuse = float(c.fuse) - dt
		if float(c.fuse) <= 0.0:
			list.remove_at(i)
			_armed = _armed.filter(func(k): return not is_same(k, c.key))
			if is_instance_valid(c.node):
				(c.node as Node3D).queue_free()
			_explode(world, c.pos)
			continue
		(c.node as Node3D).visible = fmod(float(c.fuse), 0.4) > 0.15 or float(c.fuse) < 1.0
		if floorf(float(c.fuse)) < float(c.beep) - 0.5:
			c.beep = floorf(float(c.fuse)) + 1.0
			Sfx.play("lift", c.pos)


static func clear() -> void:
	for c in list:
		if is_instance_valid(c.node):
			(c.node as Node3D).queue_free()
	list.clear()
	_armed.clear()


static func _hook(world: World) -> void:
	_hooked = _hooked.filter(func(w): return is_instance_valid(w))
	if not _hooked.has(world):
		_hooked.append(world)
		world.updaters.append(func(dt: float) -> void: tick(world, dt))


static func _explode(w: World, pos: Vector3) -> void:
	var reach := Config.DEMO_RADIUS * Config.CELL
	for t in w.targets.duplicate():
		if not t.alive.call() or t.get("deep_core", false):
			continue
		var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
		if c.distance_to(pos) - float(t.radius) <= reach:
			if t.has("charge_kill"):
				(t.charge_kill as Callable).call()
			elif chargeable(t):
				t.on_hit.call(Config.DEMO_KILL_DAMAGE, pos)
			else:
				t.on_hit.call(Config.DEMO_DAMAGE, pos)
	w.effects.burst(pos, Color("ff8844"), reach, 0.45)
	Sfx.play("boom", pos)
