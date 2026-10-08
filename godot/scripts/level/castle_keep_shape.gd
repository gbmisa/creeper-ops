class_name CastleKeepShape
## The keep of a concentric castle (docs/CASTLES2_DESIGN.md §1), written during the level build.
## (2 * half + 1) cells square: walls two thick at yard + KEEP_UP, a hall one level up inside
## them, a 3-wide door facing the inner gate, and a straight stair up the far wall to a hatch
## onto the roof. An 11x11 keep carries the spire's 3x3 obsidian column through the hall centre.
## The whole hall is roofed (Grid.roof) except the hatch. Fills lay.zones.keep, lay.crown_at,
## lay.spire, lay.vaults and lay.keep_box.


## `fwd`: unit step from the keep centre toward its door (the inner gate side).
static func build(g: Grid, centre: Vector2i, yard: int, fwd: Vector2i, half: int, spire_h: int, lay: Dictionary) -> void:
	var side := Vector2i(-fwd.y, fwd.x)
	var top := yard + CastleDefs.KEEP_UP
	var floor_h := yard + CastleDefs.HALL_UP
	var column := half >= CastleDefs.KEEP_HALF
	var at := func(a: int, b: int) -> Vector2i: return centre + fwd * a + side * b
	var walls: Array[Vector2i] = []
	var hall: Array[Vector2i] = []
	var col: Array[Vector2i] = []
	for a in range(-half, half + 1):
		for b in range(-half, half + 1):
			var c: Vector2i = at.call(a, b)
			var d := maxi(absi(a), absi(b))
			if column and d <= 1:
				CastleShape.put(g, c, yard + spire_h, Grid.Mat.SPIRE)
				col.append(c)
			elif d <= half - 2:
				CastleShape.put(g, c, floor_h, Grid.Mat.STONE)
				hall.append(c)
			else:
				CastleShape.put(g, c, top, Grid.Mat.STONE)
				walls.append(c)
	var door: Array[Vector2i] = []
	for a in [half - 1, half]:
		for b in range(-1, 2):
			var c: Vector2i = at.call(a, b)
			CastleShape.put(g, c, floor_h, Grid.Mat.STONE)
			walls.erase(c)
			door.append(c)
	var far := -(half - 2)
	var stair := CastleStairs.straight(g, at.call(far, -(half - 2)), side, floor_h + 1, top - 1)
	var roofed: Array[Vector2i] = []
	for c in hall + door:
		roofed.append(c)
	CastleStairs.add_roof(g, lay, "hall", roofed, top, centre)
	var zone: Array[Vector2i] = hall.filter(func(c): return not stair.has(c))
	lay.zones["keep"] = { "cells": zone, "y": floor_h, "y_max": top }
	var crown: Vector2i = at.call(2, 0) if column else centre
	lay["crown_at"] = { "cell": crown, "level": floor_h }
	var spire_top := yard + spire_h if column else top
	lay["spire"] = { "centre": centre, "top": spire_top, "column": col, "entry": at.call(half + 1, 0),
		"pad": [], "pad_levels": 0, "hall": true }
	lay["keep"] = { "cells": walls, "top": top, "door": door, "stair": stair, "column": column }
	lay["keep_box"] = Rect2i(centre - Vector2i(half, half), Vector2i(half * 2 + 1, half * 2 + 1))
	for b in [-(half + 2), half + 2]:  # vault slots for Salvage Engines (9b), beside the keep
		var v: Vector2i = at.call(0, b)
		if g.material[g.idx(v.x, v.y)] == Grid.Mat.NATURAL:
			lay.vaults.append(v)
	for a in [-half, half]:  # Sentinel posts on the keep wall corners
		for b in [-half, half]:
			lay.keep_posts.append(at.call(a, b))
