class_name Pathfind
## A* over the terrain grid (8-way, no corner cutting). Limits come from the unit def:
## `climb` (max rise between neighbours) and `drop` (max fall). Creeper adds cost so units
## route around pools. `solid` marks cells units can't walk through (structures): a Dictionary
## keyed by grid idx (fast) or a Callable(x, z); the start and goal cells are exempt. Returns
## world-space XZ waypoints, string-pulled by PathSmooth. State lives in reused packed buffers
## stamped with a generation, so a search allocates nothing and never clears 25k cells.

const DX := [1, -1, 0, 0, 1, 1, -1, -1]
const DZ := [0, 0, 1, -1, 1, -1, 1, -1]
const DC := [1.0, 1.0, 1.0, 1.0, 1.414, 1.414, 1.414, 1.414]

static var _gen := 0
static var _cost := PackedFloat32Array()
static var _came := PackedInt32Array()
static var _seen := PackedInt32Array()     # == _gen when _cost/_came are valid this search
static var _done := PackedInt32Array()     # == _gen when the node was expanded
static var _hv := PackedFloat32Array()     # walk height cache
static var _hseen := PackedInt32Array()
static var _hk := PackedFloat32Array()     # heap keys (f)
static var _hi := PackedInt32Array()       # heap node ids
static var last_visited := 0               # nodes expanded by the latest find (stats/tests)
static var last_reached := false


static func step_ok(g: Grid, ax: int, az: int, bx: int, bz: int, def: Dictionary) -> bool:
	return g.step_ok(ax, az, bx, bz, def.climb, def.drop, Grid.Faction.PLAYER)


static func is_solid(solid: Variant, w: int, x: int, z: int) -> bool:
	if solid is Dictionary:
		return solid.has(z * w + x)
	if solid is Callable and solid.is_valid():
		return solid.call(x, z)
	return false


static func find(g: Grid, creeper: CreeperSim, start: Vector2i, goal: Vector2i, def: Dictionary, max_nodes := 6000, solid: Variant = null) -> Array[Vector2]:
	goal = Vector2i(clampi(goal.x, 0, g.w - 1), clampi(goal.y, 0, g.h - 1))
	start = Vector2i(clampi(start.x, 0, g.w - 1), clampi(start.y, 0, g.h - 1))
	var w := g.w
	var n := w * g.h
	if _cost.size() != n:
		_cost.resize(n)
		_came.resize(n)
		_seen.resize(n)
		_done.resize(n)
		_hv.resize(n)
		_hseen.resize(n)
		_seen.fill(0)
		_done.fill(0)
		_hseen.fill(0)
		_gen = 0
	_gen += 1
	var gen := _gen
	var climb: float = def.climb
	var drop: float = def.drop
	var depth := creeper.depth
	var s := start.y * w + start.x
	var t := goal.y * w + goal.x
	var gx := goal.x
	var gz := goal.y
	var sd: Dictionary = solid if solid is Dictionary else {}
	var use_set: bool = solid is Dictionary
	var use_call: bool = solid is Callable and solid.is_valid()
	var ok := [false, false, false, false, false, false, false, false]
	_hk.resize(256)
	_hi.resize(256)
	var hn := 0
	_cost[s] = 0.0
	_came[s] = -1
	_seen[s] = gen
	var best := s
	var best_h := Vector2(start.x - gx, start.y - gz).length()
	_hk[0] = best_h
	_hi[0] = s
	hn = 1
	var visited := 0
	var reached := false
	while hn > 0 and visited < max_nodes:
		# pop min
		var cur := _hi[0]
		hn -= 1
		if hn > 0:
			var lk := _hk[hn]
			var li := _hi[hn]
			var i := 0
			while true:
				var l := i * 2 + 1
				if l >= hn:
					break
				if l + 1 < hn and _hk[l + 1] < _hk[l]:
					l += 1
				if _hk[l] >= lk:
					break
				_hk[i] = _hk[l]
				_hi[i] = _hi[l]
				i = l
			_hk[i] = lk
			_hi[i] = li
		if _done[cur] == gen:
			continue
		_done[cur] = gen
		visited += 1
		if cur == t:
			best = t
			reached = true
			break
		var cx := cur % w
		var cz := cur / w
		var hc := _height(g, cur, cx, cz)
		var cc: float = _cost[cur]
		for k in 8:
			if k >= 4:
				var a: int = 0 if DX[k] > 0 else 1
				var b: int = 2 if DZ[k] > 0 else 3
				if not ok[a] or not ok[b]:
					ok[k] = false
					continue
			var nx: int = cx + DX[k]
			var nz: int = cz + DZ[k]
			ok[k] = false
			if nx < 0 or nz < 0 or nx >= w or nz >= g.h:
				continue
			var j := nz * w + nx
			var dh := _height(g, j, nx, nz) - hc
			if dh > climb or -dh > drop:
				continue
			if j != s and j != t:
				if use_set:
					if sd.has(j):
						continue
				elif use_call and solid.call(nx, nz):
					continue
			ok[k] = true
			var ng: float = cc + DC[k] + depth[j] * 4.0
			if _seen[j] == gen and ng >= _cost[j]:
				continue
			_seen[j] = gen
			_cost[j] = ng
			_came[j] = cur
			var hj := Vector2(nx - gx, nz - gz).length()
			if hj < best_h:
				best_h = hj
				best = j
			if hn >= _hk.size():
				_hk.resize(hn * 2)
				_hi.resize(hn * 2)
			var p := hn
			hn += 1
			var fk := ng + hj
			while p > 0:
				var q := (p - 1) >> 1
				if _hk[q] <= fk:
					break
				_hk[p] = _hk[q]
				_hi[p] = _hi[q]
				p = q
			_hk[p] = fk
			_hi[p] = j
	last_visited = visited
	last_reached = reached
	var cells: Array[int] = []
	var i := best
	while i != -1:
		cells.append(i)
		i = _came[i]
	cells.reverse()
	var out: Array[Vector2] = []
	for c in PathSmooth.run(g, cells, def, solid, start, goal):
		out.append(Vector2((c % w + 0.5) * Config.CELL, (c / w + 0.5) * Config.CELL))
	return out


static func _height(g: Grid, i: int, x: int, z: int) -> float:
	if _hseen[i] != _gen:
		_hseen[i] = _gen
		_hv[i] = g.walk_height(x, z, Grid.Faction.PLAYER)
	return _hv[i]
