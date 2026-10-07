class_name Pathfind
## A* over the terrain grid (8-way, no corner cutting). Limits come from the unit def:
## `climb` (max rise between neighbours) and `drop` (max fall). Creeper adds cost so units
## route around pools. Returns world-space XZ waypoints, string-pulled where walkable.

const DIRS := [[1, 0, 1.0], [-1, 0, 1.0], [0, 1, 1.0], [0, -1, 1.0],
	[1, 1, 1.414], [1, -1, 1.414], [-1, 1, 1.414], [-1, -1, 1.414]]


static func step_ok(g: Grid, ax: int, az: int, bx: int, bz: int, def: Dictionary) -> bool:
	return g.step_ok(ax, az, bx, bz, def.climb, def.drop, Grid.Faction.PLAYER)


static func find(g: Grid, creeper: CreeperSim, start: Vector2i, goal: Vector2i, def: Dictionary, max_nodes := 6000) -> Array[Vector2]:
	goal = Vector2i(clampi(goal.x, 0, g.w - 1), clampi(goal.y, 0, g.h - 1))
	start = Vector2i(clampi(start.x, 0, g.w - 1), clampi(start.y, 0, g.h - 1))
	var w := g.w
	var n := w * g.h
	var cost := PackedFloat32Array()
	cost.resize(n)
	cost.fill(INF)
	var came := PackedInt32Array()
	came.resize(n)
	came.fill(-1)
	var s := start.y * w + start.x
	var t := goal.y * w + goal.x
	var heap := [[_h(s, w, goal), s]]
	cost[s] = 0.0
	var best := s
	var best_h := _h(s, w, goal)
	var visited := 0
	while not heap.is_empty() and visited < max_nodes:
		visited += 1
		var cur: int = _pop(heap)[1]
		if cur == t:
			best = t
			break
		var cx := cur % w
		var cz := cur / w
		for d in DIRS:
			var nx: int = cx + d[0]
			var nz: int = cz + d[1]
			if not step_ok(g, cx, cz, nx, nz, def):
				continue
			if d[0] != 0 and d[1] != 0 and (not step_ok(g, cx, cz, cx + d[0], cz, def) or not step_ok(g, cx, cz, cx, cz + d[1], def)):
				continue
			var j := nz * w + nx
			var ng: float = cost[cur] + d[2] + creeper.depth[j] * 4.0
			if ng >= cost[j]:
				continue
			cost[j] = ng
			came[j] = cur
			var hj := _h(j, w, goal)
			if hj < best_h:
				best_h = hj
				best = j
			_push(heap, [ng + hj, j])
	var cells: Array[int] = []
	var i := best
	while i != -1:
		cells.push_front(i)
		i = came[i]
	var out: Array[Vector2] = []
	for c in _smooth(g, cells, def):
		out.append(Vector2((c % w + 0.5) * Config.CELL, (c / w + 0.5) * Config.CELL))
	return out


static func _h(i: int, w: int, goal: Vector2i) -> float:
	return Vector2(i % w - goal.x, i / w - goal.y).length()


static func _push(heap: Array, item: Array) -> void:
	heap.append(item)
	var i := heap.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if heap[p][0] <= heap[i][0]:
			break
		var tmp = heap[p]
		heap[p] = heap[i]
		heap[i] = tmp
		i = p


static func _pop(heap: Array) -> Array:
	var top: Array = heap[0]
	var last: Array = heap.pop_back()
	if not heap.is_empty():
		heap[0] = last
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < heap.size() and heap[l][0] < heap[m][0]: m = l
			if r < heap.size() and heap[r][0] < heap[m][0]: m = r
			if m == i:
				break
			var tmp = heap[m]
			heap[m] = heap[i]
			heap[i] = tmp
			i = m
	return top


## Drop intermediate cells when a straight walk between kept points is legal.
static func _smooth(g: Grid, cells: Array[int], def: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if cells.size() < 3:
		return cells.slice(1)
	var anchor := 0
	for i in range(2, cells.size()):
		if not _line_ok(g, cells[anchor], cells[i], def):
			out.append(cells[i - 1])
			anchor = i - 1
	out.append(cells[cells.size() - 1])
	return out


static func _line_ok(g: Grid, a: int, b: int, def: Dictionary) -> bool:
	var w := g.w
	var ax := a % w
	var az := a / w
	var bx := b % w
	var bz := b / w
	var steps := maxi(absi(bx - ax), absi(bz - az))
	var x := ax
	var z := az
	for k in range(1, steps + 1):
		var nx := roundi(ax + float(bx - ax) * k / steps)
		var nz := roundi(az + float(bz - az) * k / steps)
		if not step_ok(g, x, z, nx, nz, def):
			return false
		x = nx
		z = nz
	return true
