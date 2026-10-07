class_name SpireShape
## A castle spire: 7x7 cells of indestructible Spire material in the courtyard. A 2-wide
## ramp winds once round the outside (16 steps, one level each: corner, 3 side steps,
## corner, ...), so step 1 is one level above the courtyard. The 3x3 column in the middle
## stands `spire_h` levels up; its top holds the crown nest and the capture zone. When the
## column is more than one level above the last step, a jump pad on that step bridges it.

const STEPS := 16


static func build(g: Grid, centre: Vector2i, yard: int, spire_h: int) -> Dictionary:
	var top := yard + spire_h
	var steps := _steps()
	var column: Array[Vector2i] = []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			column.append(centre + Vector2i(dx, dz))
			_put(g, centre + Vector2i(dx, dz), top)
	var pad: Array[Vector2i] = []
	for k in steps.size():
		var lvl := yard + mini(k + 1, spire_h)
		for o in steps[k]:
			_put(g, centre + o, lvl)
			if k == STEPS - 1:
				pad.append(centre + o)
	var last := yard + mini(STEPS, spire_h)
	return { "centre": centre, "top": top, "column": column, "entry": centre + steps[0][0],
		"pad": pad if top - last > 1 else [], "pad_levels": top - last }


static func _put(g: Grid, c: Vector2i, h: int) -> void:
	if g.in_bounds(c.x, c.y):
		g.set_height(c.x, c.y, h)
		g.material[g.idx(c.x, c.y)] = Grid.Mat.SPIRE
		g.blocked[g.idx(c.x, c.y)] = 1


## Offsets from the centre for each ramp step, in climbing order. Starts at the (-x, +z)
## corner, runs east along +z, north along +x, west along -z and south along -x, so the
## last step (-x side, dz = 1) sits beside the column.
static func _steps() -> Array:
	var out := []
	var corner := func(sx: int, sz: int) -> Array:
		return [Vector2i(sx * 2, sz * 2), Vector2i(sx * 3, sz * 2), Vector2i(sx * 2, sz * 3), Vector2i(sx * 3, sz * 3)]
	out.append(corner.call(-1, 1))
	for d in [-1, 0, 1]:
		out.append([Vector2i(d, 2), Vector2i(d, 3)])
	out.append(corner.call(1, 1))
	for d in [1, 0, -1]:
		out.append([Vector2i(2, d), Vector2i(3, d)])
	out.append(corner.call(1, -1))
	for d in [1, 0, -1]:
		out.append([Vector2i(d, -2), Vector2i(d, -3)])
	out.append(corner.call(-1, -1))
	for d in [-1, 0, 1]:
		out.append([Vector2i(-2, d), Vector2i(-3, d)])
	return out
