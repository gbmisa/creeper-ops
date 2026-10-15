class_name SmokePathPerf
## Pathfinding stays cheap: worst-case searches across a 160x160 grid and a 20-unit group order.
## Bounds are generous (headless CI noise); the old A* took ~175 ms per search here.


static func run(g) -> void:
	_single_search()
	_group_order(g)


static func _single_search() -> void:
	var grid := Grid.new(160, 160)
	var sim := CreeperSim.new(grid)
	var def: Dictionary = UnitDefs.DEFS.soldier
	var t0 := Time.get_ticks_usec()
	var open := Pathfind.find(grid, sim, Vector2i(2, 2), Vector2i(157, 157), def, Config.PATH_MAX_NODES, {})
	var open_ms := (Time.get_ticks_usec() - t0) / 1000.0
	SmokeTest._check("path perf: corner to corner finds a path", Pathfind.last_reached and not open.is_empty())
	SmokeTest._check("path perf: corner to corner is cheap", open_ms < 80.0, "(%.1f ms)" % open_ms)
	for z in 160:   # wall the goal in: the search must give up at the cap, not run away
		grid.height[z * 160 + 100] = 9.0
	t0 = Time.get_ticks_usec()
	Pathfind.find(grid, sim, Vector2i(2, 2), Vector2i(157, 157), def, Config.PATH_MAX_NODES, {})
	var cap_ms := (Time.get_ticks_usec() - t0) / 1000.0
	SmokeTest._check("path perf: unreachable goal stops at the cap", not Pathfind.last_reached and Pathfind.last_visited <= Config.PATH_MAX_NODES)
	SmokeTest._check("path perf: capped search is cheap", cap_ms < 150.0, "(%.1f ms, %d nodes)" % [cap_ms, Pathfind.last_visited])


static func _group_order(g) -> void:
	var units: UnitManager = g.units
	var grid: Grid = g.surface.grid
	var list: Array = []
	for i in 20:
		list.append(units.spawn("soldier", (40 + i % 5) * Config.CELL, (40 + i / 5) * Config.CELL))
	var dest := Vector2(grid.w - 20.0, grid.h - 20.0) * Config.CELL
	var worst := 0.0
	var t0 := Time.get_ticks_usec()
	units.order(list, dest)
	worst = (Time.get_ticks_usec() - t0) / 1000.0
	for i in 40:
		t0 = Time.get_ticks_usec()
		units.update(0.05, [])
		worst = maxf(worst, (Time.get_ticks_usec() - t0) / 1000.0)
	var waiting := list.filter(func(u): return u.wait).size()
	SmokeTest._check("path perf: 20-unit order is spread over updates", worst < 120.0, "(worst %.1f ms)" % worst)
	SmokeTest._check("path perf: every unit gets its route", waiting == 0 and units.paths.queue.is_empty(), "(%d waiting)" % waiting)
	for u in list:
		units.kill(u)
