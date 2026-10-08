class_name SmokeCastles2Walk
## Stage 21 interiors: a scripted Operative (PlayerController, fake keys) walks the concentric
## castle's tower stairs, gate passage and keep stair up to the roofs; the head stops under a
## roof; roofs stop rays; raiders and creeper only ever see the floor. Fresh Level 2 grid.


static func run(_g) -> void:
	var lvl := Level02.build()
	var grid: Grid = lvl.grid
	var rows: Array = lvl.castles.filter(func(c): return c.layout.get("plan", "") == "concentric")
	if rows.is_empty():
		SmokeTest._check("castles2 walk: a concentric castle to walk", false)
		return
	var lay: Dictionary = rows[0].layout
	var cam := Camera3D.new()
	var pc := PlayerController.new(cam)
	var inp := SmokeCastleWalk.FakeInput.new()
	var tower: Dictionary = lay.towers[0]
	_walk_to(pc, grid, inp, "corner tower stair to its roof", lay.bailey[0], tower.centre, tower.top)
	var gh: Dictionary = lay.towers.filter(func(t): return t.top == lay.yard + CastleDefs.TOWER_UP)[4]
	_walk_to(pc, grid, inp, "gate hall up a gatehouse tower", lay.zones.gate.cells[4], gh.centre, gh.top)
	var hall: Array = lay.zones.keep.cells
	_walk_to(pc, grid, inp, "ward into the keep hall", lay.ward[0], hall[0], lay.zones.keep.y)
	var roof_cell: Vector2i = hall[hall.size() / 2]
	_walk_to(pc, grid, inp, "keep stair to the roof", hall[0], roof_cell, lay.zones.keep.y_max)
	_ceiling(pc, grid, inp, lay)
	_layers(grid, lay)
	inp.free()
	cam.free()


## Finds a walking route (GridRoofs rules, no jumps) and drives the controller along it.
static func _walk_to(pc: PlayerController, grid: Grid, inp, what: String, from: Vector2i, to: Vector2i, level: int) -> void:
	var route := path(grid, from, Vector3i(to.x, to.y, level))
	if route.is_empty():
		SmokeTest._check("castles2 walk: %s (route exists)" % what, false)
		return
	pc.spawn(grid, from.x, from.y)
	var low := INF
	for s in route:
		SmokeCastleWalk._go(pc, grid, inp, Vector2i(s.x, s.y), false)
		var lid := GridRoofs.ceiling(grid, pc.pos.x, pc.pos.z, pc.pos.y)
		low = minf(low, lid - (pc.pos.y + GridRoofs.HEAD))
	var at := grid.world_to_cell(pc.pos.x, pc.pos.z)
	SmokeTest._check("castles2 walk: %s" % what, at == to and absf(pc.pos.y - level * Config.LEVEL_H) < 0.1,
		"(%d steps, at %s y %.2f want %d, head room %.2f m)" % [route.size(), at, pc.pos.y / Config.LEVEL_H, level, low])
	SmokeTest._check("castles2 walk: %s never puts the head in a roof" % what, low >= -0.01)


## Under a roof a jump stops at the slab; on the roof you stand on it.
static func _ceiling(pc: PlayerController, grid: Grid, inp, lay: Dictionary) -> void:
	var c: Vector2i = lay.zones.gate.cells[4]
	pc.spawn(grid, c.x, c.y)
	var lid := grid.roof[grid.idx(c.x, c.y)] * Config.LEVEL_H - GridRoofs.ROOF_THICK
	var top := 0.0
	pc.vel_y = 16.0  # a jump-pad kick: would rise ~7 m in the open
	pc.on_ground = false
	for i in 120:
		pc.update(1.0 / 60.0, inp, grid)
		top = maxf(top, pc.pos.y + GridRoofs.HEAD)
	SmokeTest._check("castles2 walk: a kick under the gate hall roof stops at the slab", absf(top - lid) < 0.05 and pc.on_ground,
		"(head %.2f, slab %.2f)" % [top, lid])
	var eye := Vector3(pc.pos.x, lid + 6.0, pc.pos.z)
	var hit = grid.raycast(eye, Vector3.DOWN, 20.0)
	SmokeTest._check("castles2 walk: rays from above stop on the roof", hit != null and absf(hit.y - (lid + GridRoofs.ROOF_THICK)) < GridRoofs.RAY_BAND + 0.01)


## The roof layer is the Operative's only: walkers and the creeper see the floor.
static func _layers(grid: Grid, lay: Dictionary) -> void:
	var c: Vector2i = lay.zones.keep.cells[0]
	var i := grid.idx(c.x, c.y)
	SmokeTest._check("castles2 walk: raiders walk the hall floor, not the roof", grid.walk_height(c.x, c.y, Grid.Faction.ENEMY) == grid.height[i]
		and grid.roof[i] > grid.height[i])
	var sim := CreeperSim.new(grid)
	sim.set_depth(c.x, c.y, 0.5)
	SmokeTest._check("castles2 walk: creeper lies on the hall floor under the roof", absf(sim.depth_at(c.x, c.y) - 0.5) < 0.001)
	var on_roof := GridRoofs.op_height(grid, c.x, c.y, grid.roof[i] * Config.LEVEL_H)
	var under := GridRoofs.op_height(grid, c.x, c.y, grid.height[i] * Config.LEVEL_H)
	SmokeTest._check("castles2 walk: the Operative has two layers there", on_roof == grid.roof[i] and under == grid.height[i])


## Breadth-first route over (cell, level) states by GridRoofs.op_height, no jumps.
static func path(g: Grid, from: Vector2i, goal: Vector3i) -> Array[Vector3i]:
	var start := Vector3i(from.x, from.y, int(g.walk_height(from.x, from.y, Grid.Faction.PLAYER)))
	var parent := { start: start }
	var queue: Array[Vector3i] = [start]
	var head := 0
	while head < queue.size():
		var s: Vector3i = queue[head]
		head += 1
		if s == goal:
			var out: Array[Vector3i] = []
			while s != start:
				out.push_front(s)
				s = parent[s]
			return out
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var x: int = s.x + d.x
			var z: int = s.y + d.y
			var lvl := GridRoofs.op_height(g, x, z, s.z * Config.LEVEL_H)
			if lvl >= 99.0 or lvl - s.z > Config.CLIMB:
				continue
			var n := Vector3i(x, z, int(roundf(lvl)))
			if not parent.has(n):
				parent[n] = s
				queue.append(n)
	return []
