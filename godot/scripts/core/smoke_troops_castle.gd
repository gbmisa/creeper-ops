class_name SmokeTroopsCastle
## Troops into a taken castle: units ordered into a held castle's courtyard must path
## through the gate (and over the drawbridge) and arrive — not pile up at the walls,
## moat or gate. Also covers the bailey-taken (keep still hostile) case.

const SIM_DT := 0.05
const MAX_WALK := 120.0  # seconds of sim per march (generous; walks are short)


static func run(g) -> void:
	_held_castle(g)
	_bailey_taken(g)


## Full take: castle held -> order soldiers from outside the walls into the courtyard.
static func _held_castle(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var w: World = r.w
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var grid: Grid = w.grid
	StrongholdRules.to_held(w, c, lay)
	var um := UnitManager.new()
	w.add_child(um)
	um.setup(w, null)
	var goal_cell: Vector2i = (lay.courtyard[lay.courtyard.size() / 2] as Vector2i)
	var start_cell := _outside_start(grid, lay)
	SmokeTest._check("troops castle: an outside start cell", start_cell != Vector2i(-1, -1), "at %s" % start_cell)
	var path := Pathfind.find(grid, w.creeper, start_cell, goal_cell, UnitDefs.DEFS["soldier"], 6000, w.occupied)
	SmokeTest._check("troops castle: pathfind finds a route into the held courtyard", not path.is_empty(),
		"(%d waypoints)" % path.size())
	var u := um.spawn("soldier", (start_cell.x + 0.5) * Config.CELL, (start_cell.y + 0.5) * Config.CELL)
	um.order([u], Vector2((goal_cell.x + 0.5) * Config.CELL, (goal_cell.y + 0.5) * Config.CELL))
	var traveled := _march(um, u, grid)
	var du := Vector2(u.pos.x - (goal_cell.x + 0.5) * Config.CELL, u.pos.z - (goal_cell.y + 0.5) * Config.CELL).length()
	SmokeTest._check("troops castle: soldier ordered into a held castle reaches the courtyard", du < 3.0,
		"(%.1f m from goal, alive=%s)" % [du, u.alive])
	var outer: Array = lay.gates.filter(func(x): return x.ring == "outer")
	var crossed := false
	for gc in (outer[0].cells as Array):
		if traveled.has(gc):
			crossed = true
	SmokeTest._check("troops castle: the route goes through the gate passage", crossed)
	r.w.queue_free()


## Bailey taken, keep hostile: troops can reach the bailey, not the inner ward.
static func _bailey_taken(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var w: World = r.w
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var grid: Grid = w.grid
	CastleStages.set_stage(castles, c, 2)  # gate + bailey taken; keep hostile
	var um := UnitManager.new()
	w.add_child(um)
	um.setup(w, null)
	var bailey_cell: Vector2i = (lay.bailey[lay.bailey.size() / 2] as Vector2i)
	var start_cell := _outside_start(grid, lay)
	var path := Pathfind.find(grid, w.creeper, start_cell, bailey_cell, UnitDefs.DEFS["soldier"], 6000, w.occupied)
	SmokeTest._check("troops castle: pathfind finds a route into the taken bailey", not path.is_empty(),
		"(%d waypoints)" % path.size())
	var u := um.spawn("soldier", (start_cell.x + 0.5) * Config.CELL, (start_cell.y + 0.5) * Config.CELL)
	um.order([u], Vector2((bailey_cell.x + 0.5) * Config.CELL, (bailey_cell.y + 0.5) * Config.CELL))
	_march(um, u, grid)
	var du := Vector2(u.pos.x - (bailey_cell.x + 0.5) * Config.CELL, u.pos.z - (bailey_cell.y + 0.5) * Config.CELL).length()
	SmokeTest._check("troops castle: soldier ordered into a taken bailey arrives", du < 3.0,
		"(%.1f m from goal, alive=%s)" % [du, u.alive])
	# The inner gate is still the enemy's: the keep ward stays shut until it falls.
	var inner_gate: Vector2i = (lay.gates.filter(func(x): return x.ring == "inner")[0].cells[0] as Vector2i)
	var gate_faction: int = grid.gate[grid.idx(inner_gate.x, inner_gate.y)]
	SmokeTest._check("troops castle: inner gate still hostile before the keep falls", gate_faction == Grid.Faction.ENEMY)
	r.w.queue_free()


## A walkable cell outside the walls on the gate's side: step from the gate away
## from the castle centre until clear ground at least 15 cells out.
static func _outside_start(grid: Grid, lay: Dictionary) -> Vector2i:
	var outer: Array = lay.gates.filter(func(x): return x.ring == "outer")
	if outer.is_empty():
		return Vector2i(-1, -1)
	var cells: Array = outer[0].cells
	var gate_cell: Vector2i = cells[cells.size() / 2]
	var centre := Vector2(lay.rect.get_center())
	var away := Vector2(gate_cell) - centre
	var d := Vector2i(1, 0) if absf(away.x) >= absf(away.y) else Vector2i(0, 1)
	if (away.x < 0 and d.x > 0) or (away.y < 0 and d.y > 0):
		d = -d
	var probe := gate_cell
	for i in range(1, 45):
		probe = gate_cell + d * i
		if not grid.in_bounds(probe.x, probe.y):
			break
		if _walkable(grid, probe) and i >= 15:
			return probe
	return Vector2i(-1, -1)


static func _walkable(grid: Grid, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell.x, cell.y):
		return false
	var i := grid.idx(cell.x, cell.y)
	if grid.gate[i] != Grid.Faction.NONE and grid.gate[i] != Grid.Faction.PLAYER:
		return false
	return grid.height[i] < 90.0


## Drive the unit until it arrives (path empty) or the budget runs out.
## Returns the set of cells the unit's centre visited (for route assertions).
static func _march(um: UnitManager, u, grid: Grid) -> Dictionary:
	var traveled := {}
	var t := 0.0
	while t < MAX_WALK and u.alive and not u.path.is_empty():
		um.update(SIM_DT, [])
		traveled[grid.world_to_cell(u.pos.x, u.pos.z)] = true
		t += SIM_DT
	return traveled
