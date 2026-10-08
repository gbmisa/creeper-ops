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
	while t < seconds and not g.over:
		g.update(step)
		t += step
	var s: StructureManager = g.structures
	var weapons := s.list.filter(func(x): return x.def.has("fire_rate") and x.is_built())
	var node := s.command_node()
	print("[sim] report ", JSON.stringify({
		"time": roundi(g.time), "wall_ms": Time.get_ticks_msec() - t0,
		"energy": roundi(g.economy.energy), "max": g.economy.max_energy, "income": snappedf(g.economy.income, 0.01),
		"demand": snappedf(s.packets.demand_rate, 0.01), "unmet": snappedf(s.packets.unmet_rate, 0.01),
		"sent": snappedf(s.packets.sent_rate, 0.01), "wasted": snappedf(g.economy.wasted, 0.01),
		"field": g.economy.field_cells, "structures": s.list.size(),
		"connected": s.list.filter(func(x): return x.connected).size(),
		"unbuilt": s.list.filter(func(x): return not x.is_built()).map(func(x): return "%s:%d/%d%s" % [x.type, x.delivered, x.def.cost, "" if x.connected else "(off)"]),
		"weapons_dry": "%d/%d %s" % [weapons.filter(func(w): return w.ammo < w.per_shot()).size(), weapons.size(),
			weapons.filter(func(w): return w.ammo < w.per_shot()).map(func(w): return w.type)],
		"node_hp": roundi(node.hp) if node else 0,
		"units": " ".join(g.units.list.map(func(u): return "%s:%d hp/%d ammo/%s" % [u.type, u.hp, u.ammo, u.state])),
		"nests_alive": g.hazards.nests.alive_count(),
		"raiders": g.hazards.nests.raiders.list.map(func(r): return r.tier.name.left(2) + ("g" if r.guard else "")),
		"raider_seen": g.hazards.nests.raiders.seen,
		"flyers": g.hazards.nests.flyers.stats,
		"raider_tier": RaiderDefs.newest(g.hazards.nests.pressure()).name,
		"aether": Upgrades.aether, "castles": g.castles.list.map(func(c): return "%s:%s" % [c.id, c.state]),
		"castle_raids": g.castle_raids.launched,
		"coverage": snappedf(g.surface.creeper.coverage(), 0.01),
		"objectives": g.hud.objectives.items.filter(func(o): return o.done).map(func(o): return o.id),
		"cave_coverage": snappedf(g.cave.creeper.coverage(), 0.01), "over": g.over,
		"emitter_ring": g.hazards.emitters.filter(func(e): return e.alive).map(func(e): return _dry_ring(g, e)),
	}))


## "name: dry/total" cells within Nullifier range of an emitter (where one could be built).
static func _dry_ring(g, e: Dictionary) -> String:
	var cells: Array[Vector2i] = g.surface.grid.cells_in_radius(e.x, e.z, WeaponLogic.nullify_range())
	var dry: Array = cells.filter(func(c): return g.surface.creeper.depth_at(c.x, c.y) <= Config.MIN_DEPTH)
	return "%s: %d/%d dry" % [e.name, dry.size(), cells.size()]


static func _screenshot_later(g, path: String) -> void:
	g.get_tree().create_timer(1.5).timeout.connect(func():
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png(path)
		print("[shot] saved ", path)
		g.get_tree().quit())
