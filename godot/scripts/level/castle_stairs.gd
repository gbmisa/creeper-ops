class_name CastleStairs
## Walkable castle interiors on the terrace grid (docs/CASTLES2_DESIGN.md §2), written during the
## level build. A tower is 5x5: a stone ring wall and a centre pillar at `top`, and a 3x3 ring of
## stair cells between them. The stair is a split spiral: the ring cell `p` is the hatch at
## top - 1 (open to the sky, one step below the roof) and every other ring cell is one level
## lower per ring step away from it, so the cell opposite the hatch sits at top - 5. Doors are
## cells of the ring wall cut down between the outside ground and the stair cell beside them.
## Roofs (Grid.roof, Operative only) cover every stair and door cell with >= HEADROOM levels.

## Ring cells round the centre, in order (each is 4-adjacent to the next).
const RING := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0),
	Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0)]


## Tower at `centre` with its roof at `top` (absolute level). `doors`: [{ cell, outside }] where
## `cell` is a ring-wall cell (not a corner) and `outside` the level of the ground beyond it.
## Returns { cells, top, centre, hatch, ok, doors } (doors: the ring-wall door cells, for
## door-frame decor) and appends an interior row to lay.interiors.
static func tower(g: Grid, centre: Vector2i, top: int, doors: Array, lay: Dictionary) -> Dictionary:
	var cells: Array[Vector2i] = []
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var c := centre + Vector2i(dx, dz)
			CastleShape.put(g, c, top, Grid.Mat.STONE)
			cells.append(c)
	var best := -1
	var best_score := 1 << 20
	for p in RING.size():
		var s := _score(centre, top, p, doors)
		if s < best_score:
			best_score = s
			best = p
	var roofed: Array[Vector2i] = []
	for i in RING.size():
		var c: Vector2i = centre + RING[i]
		var lvl := _ring_h(top, best, i)
		CastleShape.put(g, c, lvl, Grid.Mat.STONE)
		if top - lvl >= CastleDefs.HEADROOM:
			roofed.append(c)
	for d in doors:
		var i := _ring_index(centre, d.cell)
		if i < 0:
			continue
		var lvl := door_level(_ring_h(top, best, i), int(d.outside))
		CastleShape.put(g, d.cell, lvl, Grid.Mat.STONE)
		if top - lvl >= CastleDefs.HEADROOM:
			roofed.append(d.cell)
	add_roof(g, lay, "tower", roofed, top, centre)
	var door_cells: Array = []
	for d in doors:
		door_cells.append(d.cell)
	return { "cells": cells, "top": top, "centre": centre, "hatch": centre + RING[best], "ok": best_score < 1000,
		"doors": door_cells }


## Ring cell i's level when the hatch is ring cell p.
static func _ring_h(top: int, p: int, i: int) -> int:
	var d := absi(i - p)
	return top - 1 - mini(d, RING.size() - d)


## Index of the ring cell 4-adjacent to the ring-wall cell `door`, or -1 (corners have none).
static func _ring_index(centre: Vector2i, door: Vector2i) -> int:
	for i in RING.size():
		var c: Vector2i = centre + RING[i]
		if absi(c.x - door.x) + absi(c.y - door.y) == 1:
			return i
	return -1


## Sum of level gaps between each door's outside ground and its stair cell (>= 1000: a door
## can't be walked: the gap is more than two levels, one step each side of the threshold).
static func _score(centre: Vector2i, top: int, p: int, doors: Array) -> int:
	var s := 0
	for d in doors:
		var i := _ring_index(centre, d.cell)
		if i < 0:
			return 1 << 20
		var gap := absi(_ring_h(top, p, i) - int(d.outside))
		s += gap if gap <= 2 else 1000
	return s


## Threshold level between a stair cell at `ring` and outside ground at `outside`.
static func door_level(ring: int, outside: int) -> int:
	if absi(ring - outside) <= 1:
		return outside
	return (ring + outside) / 2


## A straight stair from `from` stepping by `dir`: levels first, first+1, ... up to `last`.
## Returns the cells in climbing order. Cells already at or above a step are left alone.
static func straight(g: Grid, from: Vector2i, dir: Vector2i, first: int, last: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in range(last - first + 1):
		var c := from + dir * k
		CastleShape.put(g, c, first + k, Grid.Mat.STONE)
		out.append(c)
	return out


## Writes a roof at `level` over `cells` and records the interior for meshes and lights.
static func add_roof(g: Grid, lay: Dictionary, kind: String, cells: Array[Vector2i], level: int, light: Vector2i) -> void:
	var kept: Array[Vector2i] = []
	for c in cells:
		if g.in_bounds(c.x, c.y) and level - g.height_at(c.x, c.y) >= CastleDefs.HEADROOM:
			g.roof[g.idx(c.x, c.y)] = level
			g.blocked[g.idx(c.x, c.y)] = 1
			kept.append(c)
	if not kept.is_empty():
		lay.interiors.append({ "kind": kind, "cells": kept, "roof": level, "light": light })
