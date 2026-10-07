class_name SmokeTraversal
## Stage 7c: each nest can walk most of the non-Blight map, and the only shelves a
## raider cannot reach are Spire Heights (Blight) and castle interiors.


static func run(g) -> void:
	var grid: Grid = g.surface.grid
	var field := RaiderField.new(grid)
	var level: Dictionary = g.level
	var non_blight := 0
	for z in grid.h:
		for x in grid.w:
			if grid.zone_at(x, z) != Grid.Zone.BLIGHT:
				non_blight += 1
	var union := PackedByteArray()
	union.resize(grid.w * grid.h)
	for n in level.nests:
		var seen := _flood(grid, field, Vector2i(n.x, n.z))
		var got := 0
		for i in seen.size():
			if seen[i] == 0:
				continue
			union[i] = 1
			var x: int = i % grid.w
			var z: int = int(i / grid.w)
			if grid.zone_at(x, z) != Grid.Zone.BLIGHT:
				got += 1
		var pct := 100.0 * float(got) / float(non_blight)
		print("[traverse] nest %s reaches %d/%d non-blight (%.1f%%)" % [n.name, got, non_blight, pct])
		SmokeTest._check("traverse: %s reaches 70%% of non-blight" % n.name, pct >= 70.0, "%.1f%%" % pct)
	var total: int = grid.w * grid.h
	var best := _largest(grid, field)
	print("[traverse] largest region %d/%d walkable (%.1f%%)" % [best, total, 100.0 * float(best) / float(total)])
	var stray := _shelves(grid, field, level, union)
	SmokeTest._check("traverse: no stray isolated plateau", stray.is_empty(), str(stray))
	_landing(g)


static func _largest(grid: Grid, field: RaiderField) -> int:
	var seen := PackedByteArray()
	seen.resize(grid.w * grid.h)
	var best := 0
	for z in grid.h:
		for x in grid.w:
			if seen[grid.idx(x, z)] != 0:
				continue
			var comp := _flood(grid, field, Vector2i(x, z))
			var n := 0
			for i in comp.size():
				if comp[i] != 0:
					seen[i] = 1
					n += 1
			best = maxi(best, n)
	return best


static func _shelves(grid: Grid, field: RaiderField, level: Dictionary, union: PackedByteArray) -> Array:
	var used := union.duplicate()
	var stray: Array = []
	for z in grid.h:
		for x in grid.w:
			if used[grid.idx(x, z)] != 0:
				continue
			var comp := _flood(grid, field, Vector2i(x, z))
			var cells: Array[Vector2i] = []
			for i in comp.size():
				if comp[i] == 0:
					continue
				used[i] = 1
				cells.append(Vector2i(i % grid.w, int(i / grid.w)))
			if cells.size() < 12 or _blight(grid, cells) or _castle(level, cells):
				continue
			stray.append("%d cells at %s" % [cells.size(), cells[0]])
	print("[traverse] stray shelves: ", stray)
	return stray


static func _blight(grid: Grid, cells: Array[Vector2i]) -> bool:
	for c in cells:
		if grid.zone_at(c.x, c.y) != Grid.Zone.BLIGHT:
			return false
	return true


static func _castle(level: Dictionary, cells: Array[Vector2i]) -> bool:
	for c in cells:
		var inside := false
		for row in level.castles:
			var r: Rect2i = row.layout.rect
			if r.grow(4).has_point(c):
				inside = true
				break
		if not inside:
			return false
	return true


## The smoke harness has already landed and may have soaked the hint. Put the
## footprint back to bare ground for the check, then restore it.
static func _landing(g) -> void:
	var hint: Vector2i = g.level.landing_hint
	var grid: Grid = g.surface.grid
	var sm: StructureManager = g.structures
	var creeper: CreeperSim = g.surface.creeper
	var saved := {}
	var depths := {}
	for c in Placement.footprint_cells("node", hint.x, hint.y):
		if not grid.in_bounds(c.x, c.y):
			continue
		var i := grid.idx(c.x, c.y)
		if sm.occupied.has(i):
			saved[i] = sm.occupied[i]
			sm.occupied.erase(i)
		depths[i] = creeper.depth_at(c.x, c.y)
		creeper.set_depth(c.x, c.y, 0.0)
	var land: Dictionary = Placement.can_land(sm, g.level, hint.x, hint.y)
	for i in saved:
		sm.occupied[i] = saved[i]
	for i in depths:
		var x: int = i % grid.w
		var z: int = int(i / grid.w)
		creeper.set_depth(x, z, depths[i])
	SmokeTest._check("traverse: landing hint can land", land.ok, land.reason)


static func _flood(grid: Grid, field: RaiderField, start: Vector2i) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(grid.w * grid.h)
	if not grid.in_bounds(start.x, start.y):
		return seen
	var open: Array[Vector2i] = [start]
	seen[grid.idx(start.x, start.y)] = 1
	var head := 0
	while head < open.size():
		var a := open[head]
		head += 1
		for d in field.DIRS:
			var b: Vector2i = a + d
			if not grid.in_bounds(b.x, b.y):
				continue
			var i: int = grid.idx(b.x, b.y)
			if seen[i] != 0 or not field.step_ok(a.x, a.y, b.x, b.y):
				continue
			seen[i] = 1
			open.append(b)
	return seen
