class_name CaveHazards
extends RefCounted
## The Deep Core set piece: 3 Shield Pylons -> vulnerable Core -> kill. Also owns the flood
## source (its pressure cap rises over time), the exit pad, lights and the markers that tell
## the player exactly what to shoot.

const PYLON_HP := 8.0
const CORE_HP := 30.0

var world: World
var cave: Dictionary
var time := 0.0
var core: Dictionary
var pylons: Array[Dictionary] = []
var mites: CaveMites
var pad_pos: Vector3


func _init(w: World, c: Dictionary) -> void:
	world = w
	cave = c
	pad_pos = w.place_at(HazardMeshes.pad(), c.pad.x, c.pad.y)
	w.interactables.append({ "pos": pad_pos, "radius": 2.0, "prompt": func(): return "[E] Return to the surface",
		"use": func(): Bus.exit_cave.emit() })
	w.markers.append({ "pos": pad_pos + Vector3(0, 2.5, 0), "label": "Exit pad [E]", "color": Color("7fa0ff"),
		"visible": func(): return true, "minor": true })
	_light(pad_pos + Vector3(0, 3, 0), Color("6688ff"), 4.0, 22.0)
	_build_core()
	for p in c.pylons:
		pylons.append(_build_pylon(p))
	mites = CaveMites.new(w, core.pos)
	w.updaters.append(update)


func _light(p: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	world.add_child(l)
	return l


func _build_core() -> void:
	var node := HazardMeshes.core()
	var pos := world.place_at(node, cave.core.x, cave.core.y)
	var shield := HazardMeshes.shield(2.6)
	shield.position.y = 2.6
	node.add_child(shield)
	var src: Dictionary = cave.core_source
	# CW3 emitter: each burst tops the pit up to the current pressure (base_cap, rising).
	var source := world.creeper.add_source({ "x": cave.core.x, "z": cave.core.y, "amount": src.base_cap,
		"interval": src.interval })
	core = { "node": node, "pos": pos, "shield": shield, "source": source, "hp": CORE_HP, "alive": true,
		"light": _light(pos + Vector3(0, 4, 0), Color("ff3355"), 6.0, 45.0) }
	core["target"] = { "node": node, "oy": 2.6, "radius": 1.3, "alive": func(): return core.alive,
		"on_hit": func(dmg, p): _hit_core(dmg, p) }
	world.add_target(core.target)
	world.markers.append({ "pos": pos + Vector3(0, 5.5, 0), "color": Color("ff5577"), "visible": func(): return core.alive,
		"label": func(): return ("Deep Core: SHIELDED (%d pylons left)" % pylons_left()) if core.shield else "Deep Core: SHOOT IT" })


func _build_pylon(c: Vector2i) -> Dictionary:
	var node := HazardMeshes.pylon()
	var pos := world.place_at(node, c.x, c.y)
	var p := { "node": node, "pos": pos, "hp": PYLON_HP, "alive": true, "light": _light(pos + Vector3(0, 3.5, 0), Color("c070ff"), 3.0, 20.0) }
	world.markers.append({ "pos": pos + Vector3(0, 5, 0), "label": "Shield Pylon: SHOOT", "color": Color("d38cff"),
		"visible": func(): return p.alive })
	p["target"] = { "node": node, "oy": 3.0, "radius": 0.8, "alive": func(): return p.alive,
		"on_hit": func(dmg, _pt):
			p.hp -= dmg
			Sfx.play("hit")
			if p.hp <= 0.0:
				_destroy_pylon(p) }
	world.add_target(p.target)
	return p


func pylons_left() -> int:
	return pylons.filter(func(p): return p.alive).size()


func _destroy_pylon(p: Dictionary) -> void:
	if not p.alive:
		return
	p.alive = false
	world.effects.burst(p.pos + Vector3(0, 3, 0), Color("d38cff"), 3.0, 0.5)
	p.node.queue_free()
	p.light.queue_free()
	world.remove_target(p.target)
	Sfx.play("boom", p.pos)
	var left := pylons_left()
	if left > 0:
		Bus.say("Shield Pylon down. %d remaining." % left, "good")
	else:
		core.shield.queue_free()
		core.shield = null
		Sfx.play("good")
		Bus.say("Core shield collapsed! Shoot the Core!", "good")


func _hit_core(dmg: float, point: Vector3) -> void:
	if core.shield:
		world.effects.burst(point, Color("c070ff"), 0.6, 0.15)
		return
	core.hp -= dmg
	Sfx.play("hit")
	if core.hp <= 0.0 and core.alive:
		_destroy_core()


func _destroy_core() -> void:
	core.alive = false
	core.source.active = false
	world.effects.burst(core.pos + Vector3(0, 2.6, 0), Color("ff3355"), 10.0, 1.2)
	core.node.queue_free()
	world.remove_target(core.target)
	core.light.light_color = Color("334466")
	mites.enabled = false
	mites.kill_all()
	Sfx.play("good")
	Bus.say("DEEP CORE DESTROYED. Get back to the pad or recall (hold R).", "good")
	Bus.objective_done.emit("core")
	Bus.core_destroyed.emit()


## Debug/test hook: destroy everything in order.
func kill_all() -> void:
	for p in pylons:
		p.target.on_hit.call(99.0, p.pos)
	core.target.on_hit.call(99.0, core.pos)


func update(dt: float) -> void:
	time += dt
	if core.alive:
		var src: Dictionary = cave.core_source
		core.source.amount = src.base_cap + time * src.cap_growth  # flood pressure grows
		var heart := core.node.get_node("Heart") as Node3D
		heart.scale = Vector3.ONE * (1.0 + 0.08 * sin(time * (3.0 if core.shield else 8.0)))
		heart.rotation.y += dt * 0.6
	for p in pylons:
		if p.alive:
			(p.node.get_node("Crystal") as Node3D).rotation.y += dt * 2.0
	mites.update(dt, time)
