class_name SmokeDeploy
## Stage 10b checks: drop cost, recall cooldown, respawn wait, second-death multiplier.


static func run(g) -> void:
	var grid: Grid = g.level.grid
	var origin := _line(grid, 20)
	SmokeTest._check("walkable recall line", origin.x >= 0, str(origin))
	if origin.x < 0:
		return
	var far := Vector2i(origin.x + 20, origin.y)
	var totem: Structure = g.structures.place("beacon", origin.x, origin.y, true)
	SmokeTest._check("totem label", totem.def.label == "Totem" and StructureDefs.MENU.Orbital.has("@drop"))
	g.economy.energy = 400.0
	var grew: bool = is_equal_approx(g.deploy.drop_cost(origin), Config.DROP_BASE) \
		and is_equal_approx(g.deploy.drop_cost(far), Config.DROP_BASE + floorf(20.0 / Config.DROP_PER_CELLS))
	SmokeTest._check("drop cost grows", grew, "near %.0f far %.0f" % [g.deploy.drop_cost(origin), g.deploy.drop_cost(far)])
	SmokeTest._check("drop cost capped", is_equal_approx(g.deploy.drop_cost_cells(10000.0), Config.DROP_MAX))
	var prev: Callable = g.deploy.drop_blocked
	g.deploy.drop_blocked = func(c): return c == far or prev.call(c)
	var blocked: Dictionary = g.deploy.can_drop(far)
	SmokeTest._check("shield blocks drop", not blocked.ok and "Shield" in str(blocked.reason), blocked.reason)
	g.deploy.drop_blocked = prev

	_recall(g, origin, far)
	_pod(g, far)
	_death(g, origin)


static func _line(grid: Grid, n: int) -> Vector2i:
	for z in range(1, grid.h):
		for x in range(0, grid.w - n):
			var ok := true
			var h := grid.height_at(x + n, z)
			for i in range(n - 1, -1, -1):
				var next := grid.height_at(x + i, z)
				if next - h > Config.CLIMB:
					ok = false
					break
				h = next
			if ok:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _recall(g, origin: Vector2i, far: Vector2i) -> void:
	g.fps.enter(g.surface, far, 0.0)
	var expect := Config.RECALL_COOLDOWN_MULT * (20.0 * Config.CELL) / Config.WALK
	var got: float = g.deploy.preview_recall()
	SmokeTest._check("recall 20 cells", absf(got - expect) < 0.05, "got %.3f want %.3f" % [got, expect])
	g.deploy.commit_recall()
	SmokeTest._check("recall sets cooldown", absf(g.teleport_cooldown - expect) < 0.05 and g.mode == "command")
	g.deploy.deploy_totem()
	SmokeTest._check("cooldown blocks totem", g.mode == "command")
	g.teleport_cooldown = 0.0
	g.deploy.deploy_totem()
	SmokeTest._check("totem deploy instant", g.mode == "surface")
	g.flow.to_command("")
	g.fps.enter(g.surface, origin, 0.0)
	g.fps.controller.pos.x += 2.5
	SmokeTest._check("recall within 3m", g.deploy.preview_recall() == 0.0)
	g.deploy.commit_recall()
	SmokeTest._check("totem recall no cooldown", g.teleport_cooldown == 0.0 and g.mode == "command")


static func _pod(g, far: Vector2i) -> void:
	g.economy.energy = 400.0
	var cost: float = g.deploy.drop_cost(far)
	g.deploy.start_drop(far)
	SmokeTest._check("drop paid", absf(g.economy.energy - (400.0 - cost)) < 0.01, "energy %.0f" % g.economy.energy)
	var t := 0.0
	while g.mode == "command" and t < Config.DROP_TIME + 1.0:
		g.deploy.update(0.05)
		t += 0.05
	SmokeTest._check("pod fall time", g.mode == "surface" and absf(t - Config.DROP_TIME) < 0.2, "t=%.2f" % t)
	g.flow.to_command("")


static func _death(g, origin: Vector2i) -> void:
	g.economy.energy = 500.0
	g.stockpile.salvage = 0.0
	g.deploy.carried_extractors = 2
	g.deploy.crafted_ammo = 4
	var seen := [-1]
	g.deploy.lose_crafted_ammo = func(): seen[0] = g.deploy.crafted_ammo
	g.fps.enter(g.surface, origin, 0.0)
	g.fps.since_hurt = 0.0
	g.fps.damage(Config.SUIT_MAX + 10.0)
	g.fps.update(0.05, g.input)
	var down: bool = g.deploy.down and g.mode == "command" and g.deploy.carried_extractors == 0 \
		and g.deploy.crafted_ammo == 0 and seen[0] == 4
	SmokeTest._check("death downs operative", down, "extractors %d ammo %d hook %d" % [g.deploy.carried_extractors, g.deploy.crafted_ammo, seen[0]])
	var left: float = g.deploy.respawn_left
	SmokeTest._sim(g, 1.0)
	SmokeTest._check("respawn waits without salvage", g.deploy.down and g.deploy.respawn_left >= left - 0.001 and "salvage" in g.deploy.status_text(), g.deploy.status_text())
	g.economy.energy = 500.0
	g.stockpile.salvage = g.deploy.bill_salvage
	var waited := 0.0
	while g.deploy.down and waited < Config.RESPAWN_TIME + 1.0:
		g.deploy.update(0.05)
		waited += 0.05
	var done: bool = not g.deploy.down and g.stockpile.salvage <= 0.001 and absf(waited - Config.RESPAWN_TIME) < 0.2
	SmokeTest._check("respawn completes", done, "waited %.2f salvage %.2f" % [waited, g.stockpile.salvage])
	g.economy.energy = 500.0
	g.fps.enter(g.surface, origin, 0.0)
	g.fps.since_hurt = 0.0
	g.fps.damage(Config.SUIT_MAX + 10.0)
	g.fps.update(0.05, g.input)
	SmokeTest._check("second death costs 1.5x", g.deploy.down \
		and is_equal_approx(g.deploy.bill_energy, Config.RESPAWN_ENERGY * Config.RESPAWN_GROWTH) \
		and is_equal_approx(g.deploy.bill_salvage, Config.RESPAWN_SALVAGE * Config.RESPAWN_GROWTH),
		"energy %.1f salvage %.1f" % [g.deploy.bill_energy, g.deploy.bill_salvage])
