class_name StrongholdHooks
## Plugs a castle into the shared lists (static): the crown nest and enemy gates/winch as
## Operative targets, gates/winch as unit enemies, walls/gates/winch of castles you hold as
## raider prey (only where raiders can stand next to them), the pump jam, and its marker.
## Every callable reads the castle's state dictionary live, so load_state keeps working.


static func attach(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	var world := s.world
	var enemy_owned := func(p: Dictionary): return c.owner == "enemy" and p.hp > 0.0
	var ours_sealed := func(p: Dictionary): return c.owner == "player" and p.hp > 0.0 and StrongholdRules.sealed(c, lay)
	world.add_target({ "node": v.crown, "radius": 1.9, "oy": 2.0,
		"alive": func(): return c.state == "hostile", "on_hit": func(d, _p = null): s._hit_crown(c, d) })
	v["prey"] = []
	v["enemies"] = []
	var parts := []
	for i in lay.gates.size():
		parts.append(["gates", i, v.gates[i], 3.2])
	if v.has("winch"):
		parts.append(["winch", 0, v.winch, 1.2])
	if not lay.raised and not lay.moat:  # walls raiders can stand next to
		for i in lay.segments.size():
			parts.append(["walls", i, v.segs[i], CastleShape.SEGMENT_MAX * 0.5 * Config.CELL * 0.6 + Config.CELL])
	for p in parts:
		var part: String = p[0]
		var i: int = p[1]
		var state := func() -> Dictionary: return c.winch if part == "winch" else c[part][i]
		var hit := func(d, _pt = null): s._hit(c, lay, part, i, d)
		var reach := func(): return part != "gates" or not lay.raised or c.winch.hp <= 0.0  # raised gate: winch first
		v.prey.append({ "node": p[2], "radius": p[3], "alive": func(): return ours_sealed.call(state.call()) and reach.call(), "hit": hit })
		if part != "walls":
			var e := { "node": p[2], "oy": 0.5, "radius": p[3] * 0.6, "alive": func(): return enemy_owned.call(state.call()), "hit": hit }
			v.enemies.append(e)
			world.add_target({ "node": p[2], "radius": e.radius, "oy": 0.5, "alive": e.alive, "on_hit": hit })
	world.interactables.append({ "pos": v.pump.position, "radius": Config.PUMP_JAM_RANGE,
		"prompt": func(): return "[%s] Jam the spire pump (%ds)" % [Keybinds.short("use"), Config.PUMP_JAM_TIME] \
			if c.owner == "enemy" and c.pump.jam <= 0.0 else "",
		"use": func():
			c.pump.jam = Config.PUMP_JAM_TIME
			Sfx.play("click")
			Bus.say("Spire pump jammed: %s builds nothing from its moat for %ds." % [c.name, Config.PUMP_JAM_TIME], "good") })
	world.markers.append({ "pos": (v.crown as Node3D).position + Vector3(0, 5, 0), "label": func(): return label(c),
		"color": StrongholdMeshes.PLAYER if c.owner == "player" else Color("ff6a8a"), "visible": func(): return true })


static func label(c: Dictionary) -> String:
	match c.state:
		"hostile": return "%s: climb the spire, kill the crown nest" % c.name
		"capturing": return "%s: hold the spire top %d%%" % [c.name, roundi(c.capture.progress * 100.0)]
		"siege": return "%s UNDER SIEGE %ds" % [c.name, ceili(Config.RETAKE_TIME - c.capture.retake)]
	return "%s (yours) +%.0f Æ/min" % [c.name, Config.CASTLE_AETHER_RATE * 60.0]


## Where raiders gather to break into a sealed castle you hold.
static func breach_cells(c: Dictionary, lay: Dictionary) -> Array:
	var out := []
	var r: Rect2i = lay.rect
	if not lay.raised and not lay.moat:
		for seg in lay.segments:
			for cell in seg.cells:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not r.has_point(cell + d):
						out.append(cell + d)
	for gt in lay.gates:
		out.append_array(gt.outer)
	if c.winch.hp > 0.0 and lay.winch.x >= 0:
		for d in [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0)]:
			out.append(lay.winch + d)
	return out
