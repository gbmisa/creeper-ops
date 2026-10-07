class_name SurfaceHazards
extends RefCounted
## Surface threats: emitters (one shielded by the Deep Core, with a visible power link),
## core-fed vents, the armored Spore Spire (Operative-only kill), Spore Nests and the Rift.
## Every objective gets an on-screen marker so the player always knows what to do and how.

var world: World
var structures: StructureManager
var core_alive := true
var time := 0.0
var rift: Dictionary
var emitters: Array[Dictionary] = []
var vents: Array[Dictionary] = []
var spire: Dictionary
var nests: SporeNests


func _init(w: World, level: Dictionary, sm: StructureManager) -> void:
	world = w
	structures = sm
	rift = _make_rift(level.rift)
	for e in level.emitters:
		emitters.append(_make_emitter(e))
	for v in level.vents:
		var node := HazardMeshes.vent()
		world.place_at(node, v.x, v.z)
		var src := world.creeper.add_source({ "x": v.x, "z": v.z, "amount": v.amount, "interval": v.interval })
		vents.append({ "node": node, "source": src })
	spire = _make_spire(level.spire)
	nests = SporeNests.new(w, level.nests)
	w.updaters.append(update)


func _marker(pos: Vector3, label: Variant, color: Color, vis: Callable, minor := false) -> void:
	world.markers.append({ "pos": pos, "label": label, "color": color, "visible": vis, "minor": minor })


func _make_emitter(e: Dictionary) -> Dictionary:
	var node := HazardMeshes.emitter()
	var pos := world.place_at(node, e.x, e.z)
	var em := e.duplicate()
	em.merge({ "node": node, "pos": pos, "alive": true, "shield": null, "link": null,
		"source": world.creeper.add_source({ "x": e.x, "z": e.z, "amount": e.amount, "interval": e.interval }) })
	em["shield_hint"] = e.get("shield_hint", "")
	if e.has("shielded_by"):
		em.shield = HazardMeshes.shield(3.4)
		em.shield.position.y = 1.6
		node.add_child(em.shield)
		em.link = HazardMeshes.link(rift.pos + Vector3(0, 1, 0), pos + Vector3(0, 2, 0))
		world.add_child(em.link)
	_marker(pos + Vector3(0, 4, 0), func(): return ("%s: SHIELDED (kill the Deep Core)" % e.name) if is_shielded(em) else ("%s: Nullify" % e.name),
		Color("d38cff") if e.has("shielded_by") else Color("7fb0ff"), func(): return em.alive)
	return em


func _make_spire(sp: Dictionary) -> Dictionary:
	var node := HazardMeshes.spire()
	var pos := world.place_at(node, sp.x, sp.z)
	var s := { "x": sp.x, "z": sp.z, "node": node, "pos": pos, "alive": true, "timer": 0.0,
		"interval": Config.SPIRE_INTERVAL, "fuse": -1.0 }
	world.interactables.append({ "pos": pos, "radius": 3.6,
		"prompt": func(): return "" if not s.alive else ("Charge armed. Get clear!" if s.fuse >= 0.0 else "[E] Plant demolition charge"),
		"use": func():
			if s.alive and s.fuse < 0.0:
				s.fuse = Config.CHARGE_FUSE
				Sfx.play("alarm")
				Bus.say("Charge planted on the Spore Spire. 3 seconds!", "warn") })
	_marker(pos + Vector3(0, 10, 0), "Spore Spire: Operative plants charge [E]", Color("ffc857"), func(): return s.alive)
	return s


func _make_rift(r: Dictionary) -> Dictionary:
	var node := HazardMeshes.rift()
	var pos := world.place_at(node, r.x, r.z)
	world.interactables.append({ "pos": pos, "radius": 2.8, "prompt": func(): return "[E] Descend into the Rift",
		"use": func(): Bus.enter_cave.emit() })
	_marker(pos + Vector3(0, 4, 0), func(): return "Rift: Operative descends [E]" if core_alive else "Rift (Core destroyed)",
		Color("b48cff"), func(): return true)
	return { "x": r.x, "z": r.z, "node": node, "pos": pos }


# ---- queries used by structures --------------------------------------------------
func emitter_near(x: int, z: int, r: float) -> Variant:
	for e in emitters:
		if e.alive and Vector2(e.x - x, e.z - z).length() <= r:
			return e
	return null


func is_shielded(e: Dictionary) -> bool:
	return e.has("shielded_by") and core_alive


func try_nullify(x: int, z: int) -> String:
	var e = emitter_near(x, z, Config.NULLIFY_RANGE)
	if e == null:
		return "none"
	if is_shielded(e):
		return "shielded"
	e.alive = false
	e.source.active = false
	world.effects.burst(e.pos + Vector3(0, 1.5, 0), Color("d38cff"), 8.0, 0.9)
	e.node.queue_free()
	Sfx.play("good")
	Bus.say("%s nullified!" % e.name, "good")
	Bus.objective_done.emit(e.id)
	return "destroyed"


func on_core_destroyed() -> void:
	core_alive = false
	for v in vents:
		v.source.active = false
		v.node.visible = false
	for e in emitters:
		if e.shield:
			e.shield.queue_free()
			e.shield = null
		if e.link:
			e.link.queue_free()
			e.link = null
	Bus.say("Vents have gone quiet. Emitter East's shield is DOWN. Build a Nullifier next to it!", "good")


# ---- per frame ---------------------------------------------------------------------
func update(dt: float) -> void:
	time += dt
	for e in emitters:
		if e.alive:
			(e.node.get_node("Orb") as Node3D).scale = Vector3.ONE * (1.0 + 0.15 * sin(time * 4.0 + e.x))
	for v in vents:
		(v.node.get_node("Ring") as Node3D).rotation.y += dt
	(rift.node.get_node("Marker") as Node3D).rotation.y += dt * 2.0
	nests.update(dt)
	_update_spire(dt)


func _update_spire(dt: float) -> void:
	if not spire.alive:
		return
	(spire.node.get_node("Sac") as Node3D).scale = Vector3.ONE * (0.8 + spire.timer / spire.interval * 0.7)
	if spire.fuse >= 0.0:
		spire.fuse -= dt
		if spire.fuse < 0.0:
			_destroy_spire()
		return
	spire.timer += dt
	if spire.timer < spire.interval:
		return
	spire.timer = 0.0
	spire.interval = maxf(Config.SPIRE_MIN_INTERVAL, spire.interval * Config.SPIRE_SPEEDUP)
	_fire_spore()


## Spore volley: a slow lob that Beams can shoot down before it lands.
func _fire_spore() -> void:
	var target := structures.nearest_to(spire.x, spire.z, func(s): return s.type != "beacon")
	if target == null:
		return
	var to := target.pos
	Bus.say("Spore volley incoming at your %s! (Beams can shoot it down)" % target.def.label, "warn")
	var it := world.effects.lob(spire.pos + Vector3(0, 7.5, 0), to, { "color": Color("88ff55"), "size": 0.9,
		"time": 4.0, "arc": 28.0, "on_arrive": func():
			world.creeper.add(target.x, target.z, Config.SPORE_AMOUNT)
			world.effects.burst(to, Color("88ff55"), 3.0 * Config.CELL, 0.6)
			Sfx.play("boom", to)
			if not target.dead:
				structures.damage(target, 15.0) })
	it["spore"] = true
	it["spore_hp"] = Config.SPORE_HP


func _destroy_spire() -> void:
	spire.alive = false
	world.effects.burst(spire.pos + Vector3(0, 4, 0), Color("ff8844"), 10.0, 1.2)
	spire.node.queue_free()
	Sfx.play("boom", spire.pos)
	Bus.say("Spore Spire destroyed. No more volleys.", "good")
	Bus.objective_done.emit("spire")
