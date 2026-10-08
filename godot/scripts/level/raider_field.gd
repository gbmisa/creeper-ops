class_name RaiderField
extends RefCounted
## One flow field shared by every nest raider: breadth-first distance (in steps) from every
## cell to the nearest player structure. A step may rise or fall by one terrace only
## (RAIDER_CLIMB / RAIDER_DROP). Raiders walk toward the neighbour with the lowest distance.
## Rebuilt every RAIDER_FIELD_INTERVAL, so a hundred raiders cost one search instead of a
## hundred A* runs. -1 means no walking route; raiders do not scale that cliff.

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var grid: Grid
var dist := PackedInt32Array()
var timer := 0.0
var has_goals := false
var areas := PackedInt32Array()  # walking area id per cell (4-way, one terrace a step)
var _areas_dirty := true


func _init(g: Grid) -> void:
	grid = g
	dist.resize(g.w * g.h)
	dist.fill(-1)


func update(dt: float, goal_cells: Array) -> void:
	timer -= dt
	if timer > 0.0:
		return
	timer = Config.RAIDER_FIELD_INTERVAL
	rebuild(goal_cells)


## Terrain changed: rebuild on the next update instead of waiting out the interval.
func invalidate() -> void:
	timer = 0.0
	_areas_dirty = true


## Can a raider at `from` walk to within striking distance of `to` (prey of `radius` m)?
## True when a cell within reach of the target (structures and gates stand on their own
## cells) shares the raider's walking area. Raiders ignore prey up a cliff instead of
## pressing into the rock.
func reachable(from: Vector3, to: Vector3, radius := 1.0) -> bool:
	if _areas_dirty:
		_label_areas()
	var a := grid.world_to_cell(from.x, from.z)
	if not grid.in_bounds(a.x, a.y):
		return false
	var mine := areas[grid.idx(a.x, a.y)]
	var c := grid.world_to_cell(to.x, to.z)
	var k := maxi(1, ceili((radius + 1.0) / Config.CELL))
	for dz in range(-k, k + 1):
		for dx in range(-k, k + 1):
			var x := c.x + dx
			var z := c.y + dz
			# ...and close enough in height to strike from (not at the foot of a tall cliff)
			if grid.in_bounds(x, z) and areas[grid.idx(x, z)] == mine \
					and absf(grid.cell_ground(x, z).y - to.y) <= radius + 3.0:
				return true
	return false


## Flood-fill walking areas. Diagonal steps need both side cells walkable, so 4-way
## connectivity gives the same areas for a quarter of the checks.
func _label_areas() -> void:
	_areas_dirty = false
	areas.resize(grid.w * grid.h)
	areas.fill(-1)
	var next := 0
	var w := grid.w
	var h := grid.h
	var wh := PackedFloat32Array()  # enemy walk height per cell, so each step is one compare
	wh.resize(w * h)
	for i in wh.size():
		wh[i] = grid.walk_height(i % w, int(i / w), Grid.Faction.ENEMY)
	var up := Config.RAIDER_CLIMB
	var down := Config.RAIDER_DROP
	var open := PackedInt32Array()
	for start in areas.size():
		if areas[start] >= 0:
			continue
		areas[start] = next
		open.clear()
		open.append(start)
		var head := 0
		while head < open.size():
			var b := open[head]
			head += 1
			var bx := b % w
			var bz := int(b / w)
			if bx + 1 < w and areas[b + 1] < 0 and wh[b + 1] - wh[b] <= up and wh[b] - wh[b + 1] <= down:
				areas[b + 1] = next
				open.append(b + 1)
			if bx > 0 and areas[b - 1] < 0 and wh[b - 1] - wh[b] <= up and wh[b] - wh[b - 1] <= down:
				areas[b - 1] = next
				open.append(b - 1)
			if bz + 1 < h and areas[b + w] < 0 and wh[b + w] - wh[b] <= up and wh[b] - wh[b + w] <= down:
				areas[b + w] = next
				open.append(b + w)
			if bz > 0 and areas[b - w] < 0 and wh[b - w] - wh[b] <= up and wh[b] - wh[b - w] <= down:
				areas[b - w] = next
				open.append(b - w)
		next += 1


func rebuild(goal_cells: Array) -> void:
	dist.fill(-1)
	var open := PackedInt32Array()
	for c in goal_cells:
		if grid.in_bounds(c.x, c.y):
			var i := grid.idx(c.x, c.y)
			if dist[i] < 0:
				dist[i] = 0
				open.append(i)
	has_goals = not open.is_empty()
	var head := 0
	while head < open.size():
		var b := open[head]
		head += 1
		var bx := b % grid.w
		var bz := b / grid.w
		for d in DIRS:
			var ax: int = bx + d.x
			var az: int = bz + d.y
			if not grid.in_bounds(ax, az):
				continue
			var a := grid.idx(ax, az)
			if dist[a] >= 0 or not step_ok(ax, az, bx, bz):
				continue
			dist[a] = dist[b] + 1
			open.append(a)


## Can a raider walk from cell a onto cell b? One terrace either way. No corner cutting:
## a diagonal needs both side cells walkable, or the raider (which slides per axis) would
## press into the cliff corner and stop for good.
func step_ok(ax: int, az: int, bx: int, bz: int) -> bool:
	if not _one(ax, az, bx, bz):
		return false
	if ax == bx or az == bz:
		return true
	return _one(ax, az, bx, az) and _one(bx, az, bx, bz) and _one(ax, az, ax, bz) and _one(ax, bz, bx, bz)


func _one(ax: int, az: int, bx: int, bz: int) -> bool:
	return grid.step_ok(ax, az, bx, bz, Config.RAIDER_CLIMB, Config.RAIDER_DROP, Grid.Faction.ENEMY)


## Next cell centre (world XZ) to walk toward, or null when there is no route from here.
func next_step(x: float, z: float) -> Variant:
	var c := grid.world_to_cell(x, z)
	if not grid.in_bounds(c.x, c.y):
		return null
	var here := dist[grid.idx(c.x, c.y)]
	if here < 0:
		return null
	var best := c
	var bd := here
	for d in DIRS:
		var n: Vector2i = c + d
		if not grid.in_bounds(n.x, n.y) or not step_ok(c.x, c.y, n.x, n.y):
			continue
		var v := dist[grid.idx(n.x, n.y)]
		if v >= 0 and v < bd:
			bd = v
			best = n
	return Vector2((best.x + 0.5) * Config.CELL, (best.y + 0.5) * Config.CELL)


## Nearest prey that shares a one-terrace walking route, or {}.
func nearest_on_foot(from: Vector3, prey: Array) -> Dictionary:
	var g := grid
	var start := g.world_to_cell(from.x, from.z)
	if not g.in_bounds(start.x, start.y):
		return {}
	var at := {}
	for q in prey:
		if not q.alive.call():
			continue
		var qp: Vector3 = q.node.position
		var c := g.world_to_cell(qp.x, qp.z)
		if not g.in_bounds(c.x, c.y):
			continue
		var i := g.idx(c.x, c.y)
		if not at.has(i):
			at[i] = []
		(at[i] as Array).append(q)
	var seen := PackedByteArray()
	seen.resize(g.w * g.h)
	var open := PackedInt32Array()
	open.append(g.idx(start.x, start.y))
	seen[g.idx(start.x, start.y)] = 1
	var best: Dictionary = {}
	var bd := INF
	var head := 0
	while head < open.size():
		var b := open[head]
		head += 1
		var bx := b % g.w
		var bz := int(b / g.w)
		if at.has(b):
			for q in at[b]:
				var qp: Vector3 = q.node.position
				var d := Vector2(qp.x - from.x, qp.z - from.z).length()
				if d < bd:
					bd = d
					best = q
		for dir in DIRS:
			var nx: int = bx + dir.x
			var nz: int = bz + dir.y
			if not g.in_bounds(nx, nz) or not step_ok(bx, bz, nx, nz):
				continue
			var ni := g.idx(nx, nz)
			if seen[ni] != 0:
				continue
			seen[ni] = 1
			open.append(ni)
	return best
