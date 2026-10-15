class_name StrongholdHooks
## Plugs a castle into the shared lists (static): the crown nest and enemy gates/winch as
## Operative targets, gates/winch as unit enemies, walls/gates/winch of castles you hold as
## raider prey (only where raiders can stand next to them), the pump jam, and its marker.
## Every callable reads the castle's state dictionary live, so load_state keeps working.


static func attach(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	var world := s.world
	var enemy_owned := func(p: Dictionary, ring: String): return CastleStages.ring_owner(c, lay, ring) == "enemy" and p.hp > 0.0
	var ours_sealed := func(p: Dictionary, ring: String): return c.owner == "player" and not c.get("raid", {}).get("grace", false) and p.hp > 0.0 and StrongholdRules.sealed(c, lay, ring)
	world.add_target({ "node": v.crown, "radius": 1.9, "oy": 2.0, "chargeable": true,
		"charge_ok": func(): return CastleStages.crown_open(c, lay),  # no charge wasted on a warded crown
		"alive": func(): return c.state == "hostile", "on_hit": func(d, _p = null): s._hit_crown(c, d) })
	v["prey"] = []
	v["enemies"] = []
	var parts := []
	for i in lay.gates.size():
		parts.append(["gates", i, v.gates[i], 3.2, lay.gates[i].get("ring", "outer")])
	if v.has("winch"):
		parts.append(["winch", 0, v.winch, 1.2, "outer"])
	for i in lay.segments.size():  # walls raiders can stand next to: no moat, not raised; inner always
		var ring: String = lay.segments[i].get("ring", "outer")
		if ring == "inner" or (not lay.raised and not lay.moat):
			parts.append(["walls", i, v.segs[i], CastleShape.SEGMENT_MAX * 0.5 * Config.CELL * 0.6 + Config.CELL, ring])
	for p in parts:
		var part: String = p[0]
		var i: int = p[1]
		var rg: String = p[4]
		var state := func() -> Dictionary: return c.winch if part == "winch" else c[part][i]
		var hit := func(d, _pt = null): s._hit(c, lay, part, i, d)
		var reach := func(): return part != "gates" or rg == "inner" or not lay.raised or c.winch.hp <= 0.0  # raised gate: winch first
		var prey_row := { "node": p[2], "radius": p[3], "alive": func(): return ours_sealed.call(state.call(), rg) and reach.call(), "hit": hit }
		if part == "walls":
			prey_row["wall"] = true  # Brute / Behemoth wall_mult
		v.prey.append(prey_row)
		if part != "walls":
			var e := { "node": p[2], "oy": 0.5, "radius": p[3] * 0.6, "alive": func(): return enemy_owned.call(state.call(), rg), "hit": hit }
			v.enemies.append(e)
			world.add_target({ "node": p[2], "radius": e.radius, "oy": 0.5, "alive": e.alive, "on_hit": hit, "chargeable": true })
	_turrets(s, c, v)
	CastleSocketLook.markers(world, v, c)
	world.interactables.append({ "pos": v.pump.position, "radius": Config.PUMP_JAM_RANGE,
		"prompt": func(): return "[%s] Jam the spire pump (%ds)" % [Keybinds.short("use"), Config.PUMP_JAM_TIME] \
			if c.owner == "enemy" and c.pump.jam <= 0.0 else "",
		"use": func():
			c.pump.jam = Config.PUMP_JAM_TIME
			Sfx.play("click")
			Bus.say("Spire pump jammed: %s builds nothing from its moat for %ds." % [c.name, Config.PUMP_JAM_TIME], "good") })
	world.markers.append({ "pos": func() -> Vector3: return StrongholdHooks.stage_pos(s, c, lay, v), "label": func(): return label(c, lay),
		"color": StrongholdMeshes.PLAYER if c.owner == "player" else Color("ff6a8a"), "visible": func(): return true })


## Where the castle marker floats: the current stage's objective, not the crown nest.
## (The marker used to sit over the crown always, so players walked to the heart and shot
## it while the real objective — gate hall, bailey standard — was somewhere else.)
static func stage_pos(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> Vector3:
	var g := s.world.grid
	match CastleStages.current(c, lay):
		"gate":
			if lay.zones.has("gate"):
				var cells: Array = lay.zones["gate"].cells
				var mid: Vector2i = cells[cells.size() / 2]
				return g.cell_ground(mid.x, mid.y) + Vector3(0, 3, 0)
		"bailey":
			return g.cell_ground(lay.home.x, lay.home.y) + Vector3(0, 3, 0)
	return (v.crown as Node3D).position + Vector3(0, 5, 0)


## Turrets are raider prey, and each socket is an E prompt in first person (arm / upgrade).
static func _turrets(s: Strongholds, c: Dictionary, v: Dictionary) -> void:
	for i in c.sockets.size():
		var node: Node3D = v.turrets[i]
		var sock := func() -> Dictionary: return c.sockets[i]
		v.prey.append({ "node": node, "radius": 1.0, "weapon": true, "alive": func(): return c.owner == "player" and CastleTurrets.alive(sock.call()),
			"hit": func(d, _pt = null): CastleTurretFire.hit(c, sock.call(), d) })
		s.world.interactables.append({ "pos": node.position, "radius": 2.5,
			"prompt": func(): return CastleTurrets.use_label(c, i, s.stockpile.salvage) if c.owner == "player" and s.stockpile else "",
			"use": func():
				var t: String = sock.call().turret if sock.call().turret != "" else "repeater"
				var why := CastleTurrets.buy(c, i, t, s.stockpile)
				Sfx.play("good" if why == "" else "deny")
				if why != "":
					Bus.say(why, "warn") })


static func label(c: Dictionary, lay: Dictionary) -> String:
	match c.state:
		"hostile": return CastleStages.marker(c, lay)
		"capturing": return "%s: hold the %s %d%%" % [c.name, "keep hall" if lay.stages.size() > 1 else "spire top", roundi(c.capture.progress * 100.0)]
		"siege": return "%s UNDER SIEGE %ds" % [c.name, ceili(Config.RETAKE_TIME - c.capture.retake)]
	var yours := "%s (yours) +%.0f Æ/min" % [c.name, Config.CASTLE_AETHER_RATE * 60.0 * c.get("yield", 1.0)]
	var rd: Dictionary = c.get("raid", {})
	if rd.get("grace", false) and rd.get("kind", "") == "reprisal":
		yours += " | reprisal in %ds" % ceili(rd.warn)
	return yours


## Where raiders gather to break into a sealed ring of a castle you hold (outside its walls).
static func breach_cells(c: Dictionary, lay: Dictionary, ring := "outer") -> Array:
	var out := []
	var r: Rect2i = lay.inner_rect if ring == "inner" else lay.rect
	if ring == "inner" or (not lay.raised and not lay.moat):
		for seg in lay.segments:
			if seg.get("ring", "outer") != ring:
				continue
			for cell in seg.cells:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not r.has_point(cell + d):
						out.append(cell + d)
	for gt in lay.gates:
		if gt.get("ring", "outer") == ring:
			out.append_array(gt.outer)
	if ring == "outer" and c.winch.hp > 0.0 and lay.winch.x >= 0:
		for d in [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0)]:
			out.append(lay.winch + d)
	return out
