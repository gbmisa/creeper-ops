class_name SmokeTerpRing
## A Terp ring seals a pool against raiders and creeper.


static func _ring(g, grid: Grid, paint: TerpPaint, terps: Array[Structure], pad: Vector2i) -> void:
	SmokeTerpJobs._settle(g, grid, paint, terps)
	var h0 := grid.height_at(pad.x, pad.y)
	var field: RaiderField = g.hazards.nests.raiders.field
	var probe := pad + Vector2i(0, 2)
	field.rebuild([pad])
	SmokeTest._check("terp: open pool is reachable", field.dist[grid.idx(probe.x, probe.y)] >= 0, str(field.dist[grid.idx(probe.x, probe.y)]))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx != 0 or dz != 0:
				SmokeTerpJobs._paint_cell(paint, g.command, pad + Vector2i(dx, dz), int(round(h0)) + 2)
	var t := 0.0
	while t < 55.0 and not _ring_done(grid, pad, h0):
		SmokeTerp._tick(g)
		t += 0.05
	SmokeTest._check("terp: ring reaches its target", _ring_done(grid, pad, h0), _ring_detail(grid, pad, terps))
	var wall := pad + Vector2i(0, 1)
	SmokeTest._check("terp: raiders cannot step onto the wall", not field.step_ok(probe.x, probe.y, wall.x, wall.y))
	field.rebuild([pad])
	var after := field.dist[grid.idx(probe.x, probe.y)]
	SmokeTest._check("terp: sealed pool has no raider route", after < 0, str(after))
	var sim := CreeperSim.new(grid)
	sim.set_depth(pad.x, pad.y, 1.0)
	for _n in 40:
		sim.update(Config.CREEPER_TICK)
	var held := sim.depth_at(wall.x, wall.y) < Config.MIN_DEPTH and sim.depth_at(probe.x, probe.y) < Config.MIN_DEPTH and sim.depth_at(pad.x, pad.y) > Config.MIN_DEPTH
	SmokeTest._check("terp: ring holds creeper", held, "pool %.3f wall %.3f" % [sim.depth_at(pad.x, pad.y), sim.depth_at(wall.x, wall.y)])
	field.invalidate()


static func _ring_done(grid: Grid, pad: Vector2i, h0: float) -> bool:
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var c := pad + Vector2i(dx, dz)
			if absf(grid.height_at(c.x, c.y) - (h0 + 2.0)) > 0.01 or grid.terp_target[grid.idx(c.x, c.y)] >= 0.0:
				return false
	return true


static func _ring_detail(grid: Grid, pad: Vector2i, terps: Array[Structure]) -> String:
	var bits := []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var c := pad + Vector2i(dx, dz)
			bits.append("%.0f/%.0f" % [grid.height_at(c.x, c.y), grid.terp_target[grid.idx(c.x, c.y)]])
	return " ".join(bits) + " " + SmokeTerpJobs._state(terps)


