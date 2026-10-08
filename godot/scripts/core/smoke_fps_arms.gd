class_name SmokeFpsArms
## Pulse Rifle vs the real Crossbow, and the Operative's arms (Stage 23 items 6-7).
## Called from SmokeTest.run.


static func run(g) -> void:
	_names_and_keys(g)
	_bolt(g)
	_reload(g)
	_hit(g)


static func _names_and_keys(g) -> void:
	var w: OperativeWeapons = g.fps.weapons
	w.current = "rifle"
	SmokeTest._check("rifle is called Pulse Rifle", Config.RIFLE.name == "Pulse Rifle" and w.label().contains("Pulse Rifle")
		and Keybinds.label("rifle") == "Pulse Rifle")
	var clash := ""
	var mine: Array = Keybinds.DEFAULTS["crossbow"][2]
	for id in Keybinds.DEFAULTS:
		if id == "crossbow":
			continue
		for k in Keybinds.DEFAULTS[id][2]:
			if mine.has(k):
				clash = id
	SmokeTest._check("crossbow action id has a free key", not mine.is_empty() and clash == "", "(clashes with '%s')" % clash)
	var arms := true
	for id in ["rifle", "crossbow", "sprayer", "rocket"]:
		arms = arms and w.models[id].get_node_or_null("arms") != null
	SmokeTest._check("every weapon model has arms; rifle has no string, crossbow has", arms
		and w.models["rifle"].get_node_or_null("string") == null and w.models["crossbow"].get_node_or_null("string") != null)


static func _bolt(g) -> void:
	var world: World = g.surface
	var cb := Crossbow.new()
	var start := world.grid.cell_ground(30, 30) + Vector3(0, 40, 0)
	cb.fire(world, start, Vector3.RIGHT)
	cb.update(0.1)
	var b: Dictionary = cb.bolts[0]
	var early: float = (b.pos as Vector3).x - start.x
	cb.update(0.5)
	var late: float = (b.pos as Vector3).x - start.x
	var drop := start.y - (b.pos as Vector3).y
	SmokeTest._check("crossbow bolt takes time and drops", early > 3.0 and early < Config.CROSSBOW.speed * 0.2 and late > early + 20.0 and drop > 1.0,
		"(%.1f m at 0.1 s, %.1f m at 0.6 s, drop %.2f m)" % [early, late, drop])
	for i in 200:
		cb.update(0.05)
	SmokeTest._check("crossbow bolt sticks then clears", cb.bolts.is_empty())


static func _reload(g) -> void:
	var world: World = g.surface
	var cb := Crossbow.new()
	var at := world.grid.cell_ground(30, 30) + Vector3(0, 40, 0)
	var first := cb.fire(world, at, Vector3.RIGHT)
	var blocked := not cb.fire(world, at, Vector3.RIGHT)
	cb.update(Config.CROSSBOW.reload * 0.5)
	var half := not cb.ready() and cb.reload_progress() > 0.3 and cb.reload_progress() < 0.7
	cb.update(Config.CROSSBOW.reload)
	SmokeTest._check("crossbow can't fire while reloading, reload completes", first and blocked and half and cb.ready() and cb.fire(world, at, Vector3.RIGHT))
	for i in 300:
		cb.update(0.05)


static func _hit(g) -> void:
	var world: World = g.surface
	var node := Node3D.new()
	world.add_child(node)
	var from := world.grid.cell_ground(30, 30) + Vector3(0, 30, 0)
	node.position = from + Vector3(25, 0.0, 0)
	var log := { "dmg": 0.0, "alive": true }
	var target := { "node": node, "oy": 0.0, "radius": 1.5, "alive": func(): return log.alive,
		"on_hit": func(d, _p): log.dmg += d; log.alive = false }
	world.targets.append(target)
	var cb := Crossbow.new()
	var killed := [false]
	cb.report = func(k): killed[0] = k
	cb.fire(world, from, Vector3.RIGHT)
	for i in 30:
		cb.update(0.05)
	world.targets.erase(target)
	node.queue_free()
	SmokeTest._check("crossbow bolt damages a target (4x a pulse) and reports the kill", is_equal_approx(log.dmg, Config.CROSSBOW.damage * OperativeUpgrades.mult("firepower"))
		and killed[0] and cb.bolts.is_empty(), "(%.1f dmg)" % log.dmg)
