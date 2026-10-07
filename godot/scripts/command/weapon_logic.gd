class_name WeaponLogic
## Active behaviour for built, connected, landed weapons. Every shot spends ammo, and ammo
## only arrives as packets. Targets by def.targets: "creeper", "air" (spores + raiders),
## "raiders". Hold-fire (CW3 toggle) skips firing entirely.


static func update(s: Structure, dt: float, mgr) -> void:
	s.firing = maxf(0.0, s.firing - dt)
	if not s.def.has("fire_rate") or s.hold_fire:
		return
	s.cooldown -= dt
	if s.cooldown > 0.0 or s.ammo < s.per_shot():
		return
	var fired := false
	match s.type:
		"cannon", "thor":
			fired = _zap(s, mgr)
		"mortar", "bertha":
			fired = _lob(s, mgr)
		"beam":
			fired = _beam(s, mgr)
		"sniper":
			fired = _snipe(s, mgr)
	# Only reset the cooldown when a shot happened, so idle weapons react instantly.
	if fired:
		s.ammo -= s.per_shot()
		s.cooldown = fire_interval(s)
		s.firing = fire_interval(s) + 1.5


## Forge-adjusted stats.
static func fire_interval(s: Structure) -> float:
	return s.def.fire_rate / Upgrades.mult("fire_rate")


static func range_cells(s: Structure) -> float:
	return s.def.get("range", 0.0) * Upgrades.mult("range")


static func _muzzle(s: Structure) -> Vector3:
	return s.node.position + Vector3(0, s.def.link_y, 0)


static func _aim(s: Structure, target: Vector3) -> void:
	var tur := s.body.get_node_or_null("Turret") as Node3D
	if tur:
		var d := target - s.node.position
		tur.rotation.y = atan2(-d.z, d.x)


static func _zap(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var t = w.creeper.nearest_wet(s.x, s.z, range_cells(s))
	if t == null:
		return false
	w.creeper.remove(t.x, t.y, s.def.power)
	var a := _muzzle(s)
	var b := w.grid.cell_ground(t.x, t.y) + Vector3(0, w.creeper.depth_at(t.x, t.y), 0)
	_aim(s, b)
	var col := Color("7fe0ff") if s.type == "thor" else Color("fff27a")
	w.effects.beam(a, b, col, 0.07, 0.08)
	w.effects.burst(b, Color("fff6b0"), 0.6, 0.12)
	Sfx.play("blaster", s.pos)
	return true


static func _lob(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var t = w.creeper.deepest_wet(s.x, s.z, range_cells(s), w.grid.height_at(s.x, s.z), Config.LOB_RANGE_PER_LEVEL)
	if t == null:
		return false
	var a := _muzzle(s)
	var b := w.grid.cell_ground(t.x, t.y) + Vector3(0, w.creeper.depth_at(t.x, t.y), 0)
	_aim(s, b)
	var big := s.type == "bertha"
	var splash: float = s.def.splash
	var power: float = s.def.power
	w.effects.lob(a, b, { "color": Color("ffb347"), "time": 2.2 if big else 1.0, "arc": 30.0 if big else 10.0,
		"size": 0.8 if big else 0.45, "on_arrive": func():
			w.creeper.remove_radius(t.x, t.y, splash, power)
			w.effects.burst(b, Color("ffaa33"), splash * Config.CELL * 0.7, 0.45)
			Sfx.play("boom", b) })
	Sfx.play("mortar", s.pos)
	return true


## Beam: shoot down spore volleys first, then nest raiders.
static func _beam(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var a := _muzzle(s)
	var reach: float = range_cells(s) * Config.CELL
	for it in w.effects.lobs():
		if it.has("spore") and (it.pos as Vector3).distance_to(a) <= reach:
			it.spore_hp -= s.def.power
			w.effects.beam(a, it.pos, Color("ff5050"), 0.06, 0.07)
			_aim(s, it.pos)
			if it.spore_hp <= 0.0:
				it.dead = true
				w.effects.burst(it.pos, Color("88ff55"), 2.5, 0.4)
				Sfx.play("pop", it.pos)
			Sfx.play("beam", s.pos)
			return true
	return _snipe(s, mgr)


static func _snipe(s: Structure, mgr) -> bool:
	if mgr.hazards == null:
		return false
	var w: World = mgr.world
	var a := _muzzle(s)
	var reach: float = range_cells(s) * Config.CELL
	var best: Dictionary = {}
	var bd := reach
	for m in mgr.hazards.nests.raiders.list:
		var d := (m.node.position as Vector3).distance_to(a)
		if d < bd:
			bd = d
			best = m
	if best.is_empty():
		return false
	var p: Vector3 = best.node.position
	_aim(s, p)
	w.effects.beam(a, p, Color("ff5050") if s.type == "beam" else Color("e0f0ff"), 0.08, 0.05)
	best.enemy.hit.call(s.def.power)
	Sfx.play("rifle" if s.type == "sniper" else "beam", s.pos)
	return true
