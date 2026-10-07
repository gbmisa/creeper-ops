class_name LevelRamps
## Straight stairs and a one-terrace cap for level terrain. Stairs are whole levels,
## at least 3 cells wide, one level per cell or per 2 cells. A tread never sits below
## the ground already there unless the line cuts down through a hill.

const ORTHO: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func mask(g: Grid) -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(g.w * g.h)
	return m


static func cover_disc(m: PackedByteArray, g: Grid, cx: int, cz: int, r: float) -> void:
	for c in g.cells_in_radius(cx, cz, r):
		m[g.idx(c.x, c.y)] = 1


static func cover_rect(m: PackedByteArray, g: Grid, x0: int, z0: int, x1: int, z1: int) -> void:
	for z in range(mini(z0, z1), maxi(z0, z1) + 1):
		for x in range(mini(x0, x1), maxi(x0, x1) + 1):
			if g.in_bounds(x, z):
				m[g.idx(x, z)] = 1


static func uncover_rect(m: PackedByteArray, g: Grid, x0: int, z0: int, x1: int, z1: int) -> void:
	for z in range(mini(z0, z1), maxi(z0, z1) + 1):
		for x in range(mini(x0, x1), maxi(x0, x1) + 1):
			if g.in_bounds(x, z):
				m[g.idx(x, z)] = 0


## Lower unprotected cells until orthogonal neighbours differ by at most 1 level.
## Only lowers, so a valley floor stays a valley. `keep` cells (shelves, stairs,
## castle footprints) are left sheer.
static func smooth_lowland(g: Grid, keep: PackedByteArray) -> void:
	for i in g.height.size():
		g.height[i] = clampf(roundf(g.height[i]), 0.0, Config.MAX_LEVEL)
	for _pass in 48:
		var changed := false
		for z in g.h:
			for x in g.w:
				var i := g.idx(x, z)
				if keep[i] != 0:
					continue
				var h := g.height_at(x, z)
				var cap := h
				for d in ORTHO:
					var nx: int = x + d.x
					var nz: int = z + d.y
					if not g.in_bounds(nx, nz) or keep[g.idx(nx, nz)] != 0:
						continue
					var nh := g.height_at(nx, nz)
					if h > nh + 1.0:
						cap = minf(cap, nh + 1.0)
				if cap < h:
					g.set_height(x, z, cap)
					changed = true
		if not changed:
			return


## Axis-aligned stair. `cells_per_level` is 1 or 2. Fills ground up to the tread and
## cuts a hill only where it stands above the tread.
static func stairs(g: Grid, from: Vector2i, to: Vector2i, width: int, cells_per_level := 1) -> void:
	var dx := to.x - from.x
	var dz := to.y - from.y
	var along_x := absi(dx) >= absi(dz)
	var steps := absi(dx) if along_x else absi(dz)
	if steps < 1 or width < 1:
		return
	var h0 := roundf(g.height_at(from.x, from.y))
	var h1 := roundf(g.height_at(to.x, to.y))
	var span := absi(int(h1 - h0))
	var pitch := maxi(1, cells_per_level)
	if span > 0 and steps < span * pitch:
		pitch = 1
	if span > steps:
		span = steps
		h1 = h0 + signf(h1 - h0) * float(span)
	var dir := Vector2i(signi(dx), 0) if along_x else Vector2i(0, signi(dz))
	var perp := Vector2i(0, 1) if along_x else Vector2i(1, 0)
	var mid := int(width / 2)
	var rising := h1 >= h0
	for i in steps + 1:
		var levels := mini(span, int(i / pitch))
		var stair_h := h0 + float(levels) if rising else h0 - float(levels)
		var cx := from.x + dir.x * i
		var cz := from.y + dir.y * i
		for w in width:
			var o := w - mid
			_lay(g, cx + perp.x * o, cz + perp.y * o, stair_h)


static func _lay(g: Grid, x: int, z: int, stair_h: float) -> void:
	if not g.in_bounds(x, z):
		return
	# Below the tread: fill. Above it: the path is cutting through a hill.
	g.set_height(x, z, stair_h)
