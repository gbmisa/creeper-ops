class_name RaiderField
extends RefCounted
## One flow field shared by every nest raider: breadth-first distance (in steps) from every
## cell to the nearest player structure. A step may rise or fall by one terrace only
## (RAIDER_CLIMB / RAIDER_DROP). Raiders walk toward the neighbour with the lowest distance.
## Checked every RAIDER_FIELD_INTERVAL and rebuilt only when the goals (your structures) or
## the ground (Bus.terrain_changed: craters, Terp, breaches, gates) changed, so a hundred raiders cost one search instead of a
## hundred A* runs. -1 means no walking route; raiders do not scale that cliff.
## A rebuild (RaiderFieldBuild) runs RAIDER_FIELD_BUDGET_MS a frame; raiders follow the old
## field until it is done.

const DIRS := RaiderFieldBuild.DIRS

var grid: Grid
var dist := PackedInt32Array()
var timer := 0.0
var has_goals := false
var areas := PackedInt32Array()  # walking area id per cell (4-way, one terrace a step)
var _areas_dirty := true
var _job: RaiderFieldBuild = null
var _goal_key := 0  # hash of the goal cells the field was built for
var _dirty := true  # terrain, gates or decks changed since the last build
var _wh := PackedFloat32Array()  # enemy walk height per cell (_refresh_heights)
var _special := PackedInt32Array()  # gate and deck cells
var _special_scanned := false
var _next := PackedInt32Array()  # cached next_step per cell: target cell index, -1 no route, -2 unset


func _init(g: Grid) -> void:
	grid = g
	dist.resize(g.w * g.h)
	dist.fill(-1)
	_next.resize(g.w * g.h)
	_next.fill(-2)


func update(dt: float, goal_cells: Array) -> void:
	if _job != null:
		if _job.step(int(Config.RAIDER_FIELD_BUDGET_MS * 1000.0)):
			_finish()
		return
	timer -= dt
	if timer > 0.0:
		return
	timer = Config.RAIDER_FIELD_INTERVAL
	_next.fill(-2)  # gates and decks can flip without a terrain edit
	var key := goal_cells.hash()
	if key == _goal_key and not _dirty:
		return  # same goals, same ground: the field is still right
	_goal_key = key
	_dirty = false
	_refresh_heights()
	_job = RaiderFieldBuild.new(grid, _wh, goal_cells)
	if _job.step(int(Config.RAIDER_FIELD_BUDGET_MS * 1000.0)):
		_finish()


## Terrain changed: rebuild soon instead of waiting out the interval. Edits within
## RAIDER_FIELD_COALESCE share one rebuild; a build already running restarts on new heights.
func invalidate() -> void:
	timer = minf(timer, Config.RAIDER_FIELD_COALESCE)
	_dirty = true
	_job = null
	_areas_dirty = true
	_next.fill(-2)


## Build the whole field now (tests, and anything that needs it this frame).
func rebuild(goal_cells: Array) -> void:
	_refresh_heights()
	_job = RaiderFieldBuild.new(grid, _wh, goal_cells)
	_job.step(0)
	_finish()


func _finish() -> void:
	dist = _job.dist
	_next.fill(-2)
	has_goals = _job.has_goals
	_job = null


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
	_refresh_heights()
	var wh := _wh  # enemy walk height per cell, so each step is one compare
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


## Enemy walk height per cell: terrain heights, patched where a gate or deck changes them.
## Gate and deck cells are fixed at level build; only their state changes, so the list is
## scanned once and their heights are refreshed on every rebuild.
func _refresh_heights() -> void:
	if not _special_scanned:
		_special_scanned = true
		for i in grid.gate.size():
			if grid.gate[i] != Grid.Faction.NONE or grid.deck_owner[i] != Grid.Faction.NONE:
				_special.append(i)
	_wh = grid.height.duplicate()
	for i in _special:
		_wh[i] = grid.walk_height(i % grid.w, i / grid.w, Grid.Faction.ENEMY)


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
	var i := grid.idx(c.x, c.y)
	var hit := _next[i]
	if hit == -2:
		hit = _compute_next(c)
		_next[i] = hit
	if hit < 0:
		return null
	return Vector2((hit % grid.w + 0.5) * Config.CELL, (hit / grid.w + 0.5) * Config.CELL)


func _compute_next(c: Vector2i) -> int:
	var here := dist[grid.idx(c.x, c.y)]
	if here < 0:
		return -1
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
	return grid.idx(best.x, best.y)


## Nearest prey (straight line) in the raider's walking area, or {}. Areas are the same
## connectivity as the field's 8-way, no-corner-cut steps.
func nearest_on_foot(from: Vector3, prey: Array) -> Dictionary:
	var start := grid.world_to_cell(from.x, from.z)
	if not grid.in_bounds(start.x, start.y):
		return {}
	if _areas_dirty:
		_label_areas()
	var mine := areas[grid.idx(start.x, start.y)]
	var best: Dictionary = {}
	var bd := INF
	for q in prey:
		if not q.alive.call():
			continue
		var qp: Vector3 = q.node.position
		var c := grid.world_to_cell(qp.x, qp.z)
		if not grid.in_bounds(c.x, c.y) or areas[grid.idx(c.x, c.y)] != mine:
			continue
		var d := Vector2(qp.x - from.x, qp.z - from.z).length()
		if d < bd:
			bd = d
			best = q
	return best
