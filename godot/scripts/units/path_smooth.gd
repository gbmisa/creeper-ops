class_name PathSmooth
## String-pulling for Pathfind: drops intermediate cells where a straight walk is legal.
## Lookahead is windowed (coarse steps, then a fine scan) so cost stays linear in path length.


static func ok(g: Grid, ax: int, az: int, bx: int, bz: int, def: Dictionary, solid: Variant, start: Vector2i, goal: Vector2i) -> bool:
	if not Pathfind.step_ok(g, ax, az, bx, bz, def):
		return false
	var b := Vector2i(bx, bz)
	return b == start or b == goal or not Pathfind.is_solid(solid, g.w, bx, bz)


static func run(g: Grid, cells: Array[int], def: Dictionary, solid: Variant, start: Vector2i, goal: Vector2i) -> Array[int]:
	var out: Array[int] = []
	if cells.size() < 3:
		return cells.slice(1)
	var win: int = Config.PATH_SMOOTH_WINDOW
	var anchor := 0
	var last := cells.size() - 1
	while anchor < last:
		var far := mini(anchor + win, last)
		var good := anchor + 1   # the next cell is always reachable (the A* step)
		var i := anchor + 4
		while i < far + 4:
			var c := mini(i, far)
			if _line_ok(g, cells[anchor], cells[c], def, solid, start, goal):
				good = c
				if c == far:
					break
				i += 4
			else:
				for f in range(maxi(good + 1, c - 3), c):
					if _line_ok(g, cells[anchor], cells[f], def, solid, start, goal):
						good = f
				break
		out.append(cells[good])
		anchor = good
	return out


## Walks the straight segment between two cell centres in quarter-cell samples, so every
## cell the unit's centre actually crosses is checked (no clipping past a tower corner).
static func _line_ok(g: Grid, a: int, b: int, def: Dictionary, solid: Variant, start: Vector2i, goal: Vector2i) -> bool:
	var w := g.w
	var ax := a % w
	var az := a / w
	var dx := float(b % w - ax)
	var dz := float(b / w - az)
	var n := maxi(1, ceili(sqrt(dx * dx + dz * dz) * 4.0))
	var cx := ax
	var cz := az
	for k in range(1, n + 1):
		var f := float(k) / n
		var x := floori(ax + 0.5 + dx * f)
		var z := floori(az + 0.5 + dz * f)
		if x == cx and z == cz:
			continue
		if not ok(g, cx, cz, x, z, def, solid, start, goal):
			return false
		cx = x
		cz = z
	return true
