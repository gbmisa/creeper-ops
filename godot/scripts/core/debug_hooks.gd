class_name DebugHooks
## Scene setups and the sim report for Debug.apply. Behaviour matches the old debug.gd helpers.


static func _armoury(g, spec: String) -> void:
	var open_menu := false
	var fire := false
	for raw in spec.split(",", false):
		var id := str(raw).strip_edges()
		if id == "open":
			open_menu = true
		elif id == "fire":
			fire = true
		elif OperativeUpgrades.DEFS.has(id):
			OperativeUpgrades.grant(id)
		elif OperativeUpgrades.DEFS.has("unlock_" + id):
			OperativeUpgrades.grant("unlock_" + id)
	var n: Structure = g.structures.command_node()
	if n == null:
		return
	if open_menu:
		g.fps.enter(g.surface, Vector2i(n.x + 2, n.z), PI)
		g.flow.set_mode("surface")
		ArmouryMenu.open(g.fps, g.stockpile)
	elif fire:
		g.fps.enter(g.surface, Vector2i(n.x + 3, n.z + 3), 0.5)
		g.fps.controller.pitch = -0.35
		g.flow.set_mode("surface")
		var pick: String = "plasma" if OperativeUpgrades.unlocked("plasma") else "railgun"
		g.fps.weapons.current = pick
		g.get_tree().create_timer(1.15).timeout.connect(func():
			g.fps.weapons.current = pick
			g.fps.weapons.advanced.showcase = true)


static func _drop(g, x: int, z: int, yaw: float) -> void:
	var b: Structure = g.structures.place("beacon", x, z, true)
	g.structures.selected_beacon = b
	g.deploy.deploy_totem()
	g.fps.controller.yaw = yaw


static func _castle(g, p: PackedStringArray) -> void:
	var c: Dictionary = g.castles.list[int(p[0])]
	var lay: Dictionary = g.castles.lays[c.id]
	var spot: String = p[1] if p.size() > 1 else "climb"
	var centre: Vector2i = lay.spire.centre
	var at: Vector2i = { "pad": lay.spire.pad[0] if not lay.spire.pad.is_empty() else lay.spire.entry,
		"top": centre + Vector2i(1, 1), "gate": lay.gates[0].outer.back() + (lay.gates[0].outer.back() - centre).sign() * 4,
		"climb": lay.climbs[0][0] + (lay.climbs[0][0] - centre).sign() * Vector2i(1, 0) if not lay.climbs.is_empty() else centre }[spot]
	_drop(g, g.level.landing_hint.x, g.level.landing_hint.y - 4, 0.0)
	var target: Vector2i = lay.climbs[0].back() if spot == "climb" and not lay.climbs.is_empty() else centre
	g.fps.controller.spawn(g.level.grid, at.x, at.y, atan2(-(target.x - at.x), -(target.y - at.y)))
	g.fps.controller.pitch = 0.25 if spot == "climb" else (0.4 if spot == "gate" else -0.1)


static func _fast_forward(g, seconds: float) -> void:
	var step := 0.05
	var t := 0.0
	var t0 := Time.get_ticks_msec()
	var probe := false
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--raidprobe"):
			probe = true
	var next_probe := 5.0
	var first_contact := -1.0
	var snipe3: Dictionary = g.get_meta("snipe3") if g.has_meta("snipe3") else {}
	while t < seconds and not g.over:
		g.update(step)
		t += step
		if not bool(snipe3.get("placed", true)) and t >= 180.0:
			for b in snipe3.snipers:
				g.structures.place(b[0], int(b[1]), int(b[2]), true)
			snipe3.placed = true
			print("[probe] snipers placed at t=", snappedf(t, 1))
		if probe and t >= next_probe:
			next_probe += 5.0
			print("[probe] ", JSON.stringify(_raid_probe(g, t)))
			if first_contact < 0.0:
				first_contact = _first_contact(g, t)
	var s: StructureManager = g.structures
	var weapons := s.list.filter(func(x): return x.def.has("fire_rate") and x.is_built())
	var node := s.command_node()
	print("[sim] report ", JSON.stringify({
		"time": roundi(g.time), "wall_ms": Time.get_ticks_msec() - t0,
		"energy": roundi(g.economy.energy), "max": g.economy.max_energy, "income": snappedf(g.economy.income, 0.01),
		"demand": snappedf(s.packets.demand_rate, 0.01), "unmet": snappedf(s.packets.unmet_rate, 0.01),
		"sent": snappedf(s.packets.sent_rate, 0.01), "wasted": snappedf(g.economy.wasted, 0.01),
		"field": g.economy.field_cells, "structures": s.list.size(), "mix": _mix(s.list),
		"connected": s.list.filter(func(x): return x.connected).size(),
		"unbuilt": s.list.filter(func(x): return not x.is_built()).map(func(x): return "%s:%d/%d%s" % [x.type, x.delivered, x.def.cost, "" if x.connected else "(off)"]),
		"weapons_dry": "%d/%d %s" % [weapons.filter(func(w): return w.ammo < w.per_shot()).size(), weapons.size(),
			weapons.filter(func(w): return w.ammo < w.per_shot()).map(func(w): return w.type)],
		"node_hp": roundi(node.hp) if node else 0,
		"units": " ".join(g.units.list.map(func(u): return "%s:%d hp/%d ammo/%s" % [u.type, u.hp, u.ammo, u.state])),
		"nests_alive": g.hazards.nests.alive_count(),
		"raiders": g.hazards.nests.raiders.list.map(func(r): return r.tier.name.left(2) + ("g" if r.guard else "")),
		"first_contact": first_contact,
		"raider_seen": g.hazards.nests.raiders.seen,
		"flyers": g.hazards.nests.flyers.stats,
		"raider_tier": RaiderDefs.newest(g.hazards.nests.pressure()).name,
		"aether": Upgrades.aether, "castles": g.castles.list.map(func(c): return "%s:%s" % [c.id, c.state]),
		"castle_raids": g.castle_raids.launched,
		"coverage": snappedf(g.surface.creeper.coverage(), 0.01),
		"objectives": g.hud.objectives.items.filter(func(o): return o.done).map(func(o): return o.id),
		"cave_coverage": snappedf(g.cave.creeper.coverage(), 0.01), "over": g.over,
		"salvage": roundi(g.stockpile.salvage), "salvage_earned": roundi(g.stockpile.earned_salvage), "salvage_left": roundi(g.engines.salvage_left()),
		"ore_mined": roundi(g.stockpile.earned_ore), "pressure": snappedf(g.hazards.nests.pressure(), 0.01),
		"sockets_hooked": g.engines.total_hooked(), "win_time": roundi(g.win_time), "objective_times": g.objective_times,
		"emitter_ring": g.hazards.emitters.filter(func(e): return e.alive).map(func(e): return _dry_ring(g, e)),
	}))
	if PlayMetrics.out_path != "":
		var m: PlayMetrics = g.metrics
		m.samples.append(m.sample())
		var p := m.write(MetricsSummary.build(m, "sim"))
		print("[sim] metrics written to ", p)


## "sniper:5 beam:2" counts, for the sim report.
static func _mix(list: Array) -> String:
	var n := {}
	for x in list:
		n[x.type] = int(n.get(x.type, 0)) + 1
	return " ".join(n.keys().map(func(k): return "%s:%d" % [k, n[k]]))


## "name: dry/total" cells within Nullifier range of an emitter (where one could be built).
static func _dry_ring(g, e: Dictionary) -> String:
	var cells: Array[Vector2i] = g.surface.grid.cells_in_radius(e.x, e.z, WeaponLogic.nullify_range())
	var dry: Array = cells.filter(func(c): return g.surface.creeper.depth_at(c.x, c.y) <= Config.MIN_DEPTH)
	return "%s: %d/%d dry" % [e.name, dry.size(), cells.size()]


## --raidprobe: raider pressure snapshot for playtest tuning.
static func _raid_probe(g, t: float) -> Dictionary:
	var node: Structure = g.structures.command_node()
	var np := Vector2(node.pos.x, node.pos.z) if node != null else Vector2.ZERO
	var total := 0
	var marching := 0
	var min_d := INF
	for r in g.hazards.nests.raiders.list:
		var rd: Dictionary = r
		total += 1
		if bool(rd.get("guard", false)):
			continue
		marching += 1
		var rp: Vector3 = (rd.node as Node3D).position
		min_d = minf(min_d, Vector2(rp.x - np.x, rp.z - np.y).length() / Config.CELL)
	var spawned := {}
	for n in g.hazards.nests.nests:
		var nd: Dictionary = n
		spawned[str(nd.name)] = int(nd.get("spawned", 0))
	return { "t": snappedf(t, 1), "raiders": total, "marching": marching,
		"min_dist_cells": snappedf(min_d, 1) if min_d < INF else -1.0, "spawned": spawned }


## Earliest probe tick with a marching (non-guard) raider within 30 cells of the Node, else -1.
static func _first_contact(g, t: float) -> float:
	var node: Structure = g.structures.command_node()
	if node == null:
		return -1.0
	var np := Vector2(node.pos.x, node.pos.z)
	for r in g.hazards.nests.raiders.list:
		var rd: Dictionary = r
		if bool(rd.get("guard", false)):
			continue
		var rp: Vector3 = (rd.node as Node3D).position
		if Vector2(rp.x - np.x, rp.z - np.y).length() / Config.CELL <= 30.0:
			return snappedf(t, 1)
	return -1.0


static func _screenshot_later(g, path: String) -> void:
	g.get_tree().create_timer(1.5).timeout.connect(func():
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png(path)
		print("[shot] saved ", path)
		g.get_tree().quit())
