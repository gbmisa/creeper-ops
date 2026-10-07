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


## Can a raider walk from cell a onto cell b? One terrace either way.
func step_ok(ax: int, az: int, bx: int, bz: int) -> bool:
	var rise := grid.height_at(bx, bz) - grid.height_at(ax, az)
	return rise <= Config.RAIDER_CLIMB and -rise <= Config.RAIDER_DROP


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
