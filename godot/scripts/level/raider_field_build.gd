class_name RaiderFieldBuild
extends RefCounted
## One RaiderField breadth-first search, runnable a slice at a time (step) so a 160x160 map
## never costs one long frame. The field keeps its old distances until the build is done.

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const CHECK_EVERY := 128  # cells between clock reads

var dist := PackedInt32Array()
var has_goals := false
var _open := PackedInt32Array()
var _head := 0
var _wh: PackedFloat32Array
var _w: int
var _h: int


func _init(grid: Grid, wh: PackedFloat32Array, goal_cells: Array) -> void:
	_wh = wh
	_w = grid.w
	_h = grid.h
	dist.resize(_w * _h)
	dist.fill(-1)
	for c in goal_cells:
		if grid.in_bounds(c.x, c.y):
			var i := grid.idx(c.x, c.y)
			if dist[i] < 0:
				dist[i] = 0
				_open.append(i)
	has_goals = not _open.is_empty()


## Expand cells for up to budget_usec microseconds (<= 0: run to the end). True when done.
func step(budget_usec: int) -> bool:
	var end := Time.get_ticks_usec() + budget_usec
	var w := _w
	var h := _h
	var wh := _wh
	var n := 0
	while _head < _open.size():
		var b := _open[_head]
		_head += 1
		var bx := b % w
		var bz := b / w
		var nd := dist[b] + 1
		for d in DIRS:
			var ax: int = bx + d.x
			var az: int = bz + d.y
			if ax < 0 or az < 0 or ax >= w or az >= h:
				continue
			var a := az * w + ax
			if dist[a] >= 0 or not walk(wh, w, ax, az, bx, bz):
				continue
			dist[a] = nd
			_open.append(a)
		n += 1
		if budget_usec > 0 and n % CHECK_EVERY == 0 and Time.get_ticks_usec() >= end:
			return false
	return true


## Grid.step_ok for the ENEMY faction on cached walk heights (both cells in bounds). No
## corner cutting: a diagonal needs both side cells walkable.
static func walk(wh: PackedFloat32Array, w: int, ax: int, az: int, bx: int, bz: int) -> bool:
	var a := az * w + ax
	var b := bz * w + bx
	if not _ok(wh, a, b):
		return false
	if ax == bx or az == bz:
		return true
	var s1 := az * w + bx
	var s2 := bz * w + ax
	return _ok(wh, a, s1) and _ok(wh, s1, b) and _ok(wh, a, s2) and _ok(wh, s2, b)


static func _ok(wh: PackedFloat32Array, a: int, b: int) -> bool:
	var d := wh[b] - wh[a]
	return d <= Config.RAIDER_CLIMB and -d <= Config.RAIDER_DROP
