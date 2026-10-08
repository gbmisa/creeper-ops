class_name SmokeTerpJobs
## Terp packet steps: one cell at a time, occupied cells, and shared work.


## `by` is the signed level change the paint asks for (+2 checks the halfway level).
static func _step(g, grid: Grid, paint: TerpPaint, terps: Array[Structure], c: Vector2i, by: int) -> void:
	_settle(g, grid, paint, terps)
	var h0 := grid.height_at(c.x, c.y)
	_paint_cell(paint, g.command, c, int(round(h0)) + by)
	var i := grid.idx(c.x, c.y)
	var goal := h0 + float(by)
	var asked := false
	var saw_mid := false
	var t := 0.0
	while t < 30.0 and not (absf(grid.height_at(c.x, c.y) - goal) < 0.01 and grid.terp_target[i] < 0.0):
		if _needs(g, terps):
			asked = true
		if by > 1 and absf(grid.height_at(c.x, c.y) - (h0 + 1.0)) < 0.01 and grid.terp_target[i] >= 0.0:
			saw_mid = true
		SmokeTerp._tick(g)
		t += 0.05
	var done := absf(grid.height_at(c.x, c.y) - goal) < 0.01 and grid.terp_target[i] < 0.0 and grid.material[i] == Grid.Mat.EARTH
	if by > 0:
		SmokeTest._check("terp: requests terp packets", asked)
	var name := "terp: raises one level, then finishes" if by > 1 else "terp: lowers and clears paint"
	SmokeTest._check(name, done and (saw_mid or by < 0), "h %.2f paint %.2f" % [grid.height_at(c.x, c.y), grid.terp_target[i]])


static func _occupied(g, sm: StructureManager, grid: Grid, paint: TerpPaint, terps: Array[Structure], pad: Vector2i) -> void:
	_settle(g, grid, paint, terps)
	var near := pad + Vector2i(0, -2)
	var far := pad + Vector2i(2, -2)
	var hn := grid.height_at(near.x, near.y)
	var hf := grid.height_at(far.x, far.y)
	_paint_cell(paint, g.command, near, int(round(hn)) + 1)
	_paint_cell(paint, g.command, far, int(round(hf)) + 1)
	var blocker := sm.place("relay", near.x, near.y, true)
	for s in terps:
		s.job = {}
	var stole := false
	var t := 0.0
	while t < 25.0 and absf(grid.height_at(far.x, far.y) - (hf + 1.0)) > 0.01:
		SmokeTerp._tick(g)
		t += 0.05
		for s in terps:
			if int(s.job.get("x", -1)) == near.x and int(s.job.get("z", -1)) == near.y:
				stole = true
	var skipped := not stole and absf(grid.height_at(near.x, near.y) - hn) < 0.01 and absf(grid.height_at(far.x, far.y) - (hf + 1.0)) < 0.01
	SmokeTest._check("terp: skips an occupied cell", skipped, "near %.2f far %.2f %s" % [grid.height_at(near.x, near.y), grid.height_at(far.x, far.y), _state(terps)])
	if blocker:
		sm.remove(blocker, "recycled")


static func _share(g, grid: Grid, paint: TerpPaint, terps: Array[Structure], c: Vector2i) -> void:
	_settle(g, grid, paint, terps)
	var h0 := grid.height_at(c.x, c.y)
	_paint_cell(paint, g.command, c, int(round(h0)) + 1)
	var dup := false
	var saw := false
	var t := 0.0
	var i := grid.idx(c.x, c.y)
	while t < 25.0 and grid.terp_target[i] >= 0.0:
		SmokeTerp._tick(g)
		t += 0.05
		var seen := {}
		for s in terps:
			var x := int(s.job.get("x", -1))
			var z := int(s.job.get("z", -1))
			if s.job.is_empty() or x < 0:
				continue
			var key := grid.idx(x, z)
			if seen.has(key):
				dup = true
			seen[key] = true
			if float(s.job.get("timer", 0.0)) > 0.0:
				saw = true
	SmokeTest._check("terp: two terps never share a cell", not dup and saw, _state(terps))


static func _needs(g, terps: Array[Structure]) -> bool:
	for s in terps:
		if PacketRequests.need(g.structures.network, s) == "terp":
			return true
	return false


static func _paint_cell(paint: TerpPaint, cm: CommandMode, c: Vector2i, level: int) -> void:
	paint.level = clampi(level, 0, Config.MAX_LEVEL)
	paint.pinned = true
	paint.anchor = c
	paint.commit(cm, c, false)


static func _settle(g, grid: Grid, paint: TerpPaint, terps: Array[Structure]) -> void:
	_wipe(grid, paint, terps)
	_idle(g, terps)


static func _wipe(grid: Grid, paint: TerpPaint, terps: Array[Structure]) -> void:
	for i in grid.terp_target.size():
		grid.terp_target[i] = -1.0
		grid.terp_mat[i] = 0
	for s in terps:
		s.job = {}
	paint.sync()


static func _idle(g, terps: Array[Structure]) -> void:
	var t := 0.0
	while t < 15.0:
		var fly := false
		for s in terps:
			s.job = {}
			if s.in_flight > 0:
				fly = true
		if not fly:
			return
		SmokeTerp._tick(g)
		t += 0.05


static func _state(terps: Array[Structure]) -> String:
	var bits := []
	for s in terps:
		bits.append("%d,%d c%d d%d f%d %s" % [s.x, s.z, 1 if s.connected else 0, 1 if s.dead else 0, s.in_flight, str(s.job)])
	return " ".join(bits)


static func _pad(g) -> Vector2i:
	var grid: Grid = g.surface.grid
	var node: Structure = g.structures.command_node()
	var max_r := maxi(maxi(node.x, node.z), maxi(grid.w - node.x, grid.h - node.z))
	for r in max_r + 1:
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var x: int = node.x + dx
				var z: int = node.z + dz
				if x >= 3 and z >= 3 and x < grid.w - 3 and z < grid.h - 3 and _flat(g, x, z):
					return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _flat(g, x: int, z: int) -> bool:
	var grid: Grid = g.surface.grid
	var h := grid.height_at(x, z)
	if h < 1.0 or h > float(Config.MAX_LEVEL) - 2.0:
		return false
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var i := grid.idx(x + dx, z + dz)
			if absf(grid.height[i] - h) > 0.01 or grid.blocked[i] or grid.zone[i] != Grid.Zone.NONE:
				return false
			if grid.gate[i] != Grid.Faction.NONE or grid.material[i] >= Grid.Mat.STONE or grid.deck_owner[i] != Grid.Faction.NONE:
				return false
			if g.structures.structure_at(x + dx, z + dz) != null or g.surface.creeper.depth_at(x + dx, z + dz) > Config.MIN_DEPTH:
				return false
	return true


static func _link(g, x: int, z: int, avoid: Rect2i) -> void:
	var sm: StructureManager = g.structures
	var guard := 0
	while not sm.network.in_range(sm.list, x, z, 6.0, null) and guard < 8:
		guard += 1
		var from := _anchor(sm, x, z)
		var dir := Vector2(x - from.x, z - from.y)
		var dist := dir.length()
		if dist < 1.0:
			return
		dir /= dist
		var step := minf(12.0, dist)
		var c := _dry_free(g, int(round(from.x + dir.x * step)), int(round(from.y + dir.y * step)), avoid)
		if c.x < 0:
			return
		sm.place("relay", c.x, c.y, true)
		SmokeTerp._tick(g)


static func _anchor(sm: StructureManager, x: int, z: int) -> Vector2i:
	var best := sm.command_node()
	var bd := Vector2(best.x - x, best.z - z).length()
	for s in sm.list:
		if s.connected and s.def.get("relays", false):
			var d := Vector2(s.x - x, s.z - z).length()
			if d < bd:
				bd = d
				best = s
	return Vector2i(best.x, best.z)


static func _dry_free(g, x: int, z: int, avoid: Rect2i) -> Vector2i:
	var grid: Grid = g.surface.grid
	for r in 8:
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var cx := x + dx
				var cz := z + dz
				if not grid.in_bounds(cx, cz) or avoid.has_point(Vector2i(cx, cz)):
					continue
				if g.surface.creeper.depth_at(cx, cz) > Config.MIN_DEPTH or g.structures.structure_at(cx, cz) != null:
					continue
				return Vector2i(cx, cz)
	return Vector2i(-1, -1)
