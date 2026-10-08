class_name SmokeEngines
## Stage 9b P1: Salvage Engines exist, are solid, never buildable, and their sockets can be
## reached on foot (the top socket by the south stair). The hook prompt refuses without a relay.


static func run(g) -> void:
	var list: Array = g.engines.list
	var fresh := Levels.build(Levels.current())  # earlier checks dig and raise the live grid
	var grid: Grid = fresh.grid
	SmokeTest._check("engines: level 1 has 3-6 engines", list.size() >= 3 and list.size() <= 6, str(list.size()))
	var all_rows := true
	var solid := true
	var unbuildable := true
	var tall := true
	for e in list:
		var row: Dictionary = (fresh.engines as Array).filter(func(r): return r.id == e.id)[0]
		var k := EngineDefs.kind(row)
		for c in EngineDefs.body_cells(row):
			var i := grid.idx(c.x, c.y)
			tall = tall and is_equal_approx(grid.height[i], float(row.floor) + float(k.top))
			unbuildable = unbuildable and grid.blocked[i] == 1
		var c0: Vector2i = EngineDefs.body_cells(row)[0]
		var outside := Vector2i(c0.x, c0.y - 1)
		for f in [Grid.Faction.PLAYER, Grid.Faction.ENEMY]:
			solid = solid and not grid.step_ok(outside.x, outside.y, c0.x, c0.y, Config.CLIMB, 99.0, f) \
				or grid.height_at(outside.x, outside.y) >= grid.height_at(c0.x, c0.y) - Config.CLIMB
		all_rows = all_rows and e.sockets.size() == k.sockets.size()
	SmokeTest._check("engines: every kind builds its sockets", all_rows)
	SmokeTest._check("engines: bodies are raised blocks (stand_y sees them)", tall)
	SmokeTest._check("engines: bodies are never buildable", unbuildable)
	SmokeTest._check("engines: bodies block walkers", solid)
	var seen := _flood(grid, fresh.landing_hint)
	var cells_ok := true
	var why := ""
	for e in list:
		for s in e.sockets:
			if not seen.has(s.cell):
				cells_ok = false
				why = "%s %s" % [e.id, s.face]
	SmokeTest._check("engines: every socket's standing cell is reachable on foot", cells_ok, why)
	var top_ok := true
	for e in list:
		for s in e.sockets:
			if s.face == "top":
				var y: float = grid.stand_y(s.pos.x, s.pos.z, Grid.Faction.PLAYER)
				top_ok = top_ok and seen.has(s.cell) and y >= (float(e.row.floor) + 3.9) * Config.LEVEL_H
	SmokeTest._check("engines: top sockets sit on a walkable top reached by the stair", top_ok)
	_prompts(g)


static func _flood(grid: Grid, start: Vector2i) -> Dictionary:
	var seen := { start: true }
	var open := [start]
	while not open.is_empty():
		var a: Vector2i = open.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var b: Vector2i = a + d
			if grid.in_bounds(b.x, b.y) and not seen.has(b) \
					and grid.step_ok(a.x, a.y, b.x, b.y, Config.CLIMB, 99.0, Grid.Faction.PLAYER):
				seen[b] = true
				open.append(b)
	return seen


static func _prompts(g) -> void:
	var e: Dictionary = g.engines.list[0]
	var s: Dictionary = e.sockets[0]
	var far := g.engines.anchor_for(s) == null
	SmokeTest._check("engines: no network in reach by default", far)
	var text := EngineHook.prompt(g.engines, e, s)
	SmokeTest._check("engines: the prompt says to build a Relay within 8 cells", text.contains("No network in reach") and text.contains("Relay within 8"), text)
	SmokeTest._check("engines: hooking is refused without a relay", not g.engines.hook(e, s) and not bool(s.hooked))
	var its: Array = g.surface.interactables.filter(func(it): return it.has("hold") and is_equal_approx(float(it.hold), EngineDefs.HOOK_TIME))
	SmokeTest._check("engines: one hold-E interactable per socket", its.size() >= 8, str(its.size()))
