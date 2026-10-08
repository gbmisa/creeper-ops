class_name CastleTowers
## Opt-in castle dressing for CastleShape (all terrain, so walls stay one system):
##   "towers": true     3x3 towers on the four wall corners, TOWER_UP above the wall walk
##   "gatehouse": true  two towers flanking every gate
##   "keep": true       a low inner wall round the spire with a door on each side
## Each tower is { cells, top, centre } in `lay.towers`; the keep is { cells, top } in `lay.keep`.
## A tower is reached from the wall walk by a one-level step on its inner side, so the
## climb is wall_top -> +1 -> +2 with the Operative's normal CLIMB.

const TOWER_UP := 2
const KEEP_UP := 2
const GATEHOUSE_MIN := 19  # castle size that leaves the corner-stair exits free


## [{ centre: Vector2i, steps: Array[Vector2i] }] for the row's towers (no terrain written).
static func plan(r: Rect2i, row: Dictionary, gates: Array) -> Array:
	var out := []
	var n := r.size.x
	if row.get("towers", false):
		for cx in [r.position.x, r.end.x - 1]:
			for cz in [r.position.y, r.end.y - 1]:
				var ix: int = 1 if cx == r.position.x else -1
				var iz: int = 1 if cz == r.position.y else -1
				out.append({ "centre": Vector2i(cx, cz),
					"steps": [Vector2i(cx + 2 * ix, cz), Vector2i(cx + 2 * ix, cz + iz)] })
	if row.get("gatehouse", false) and n >= GATEHOUSE_MIN:  # smaller walls have no room beside the corner stairs
		for side in gates:
			for sgn in [-1, 1]:
				var t: int = n / 2 + 3 * sgn
				out.append({ "centre": CastleShape.at(r, side, t, 0),
					"steps": [CastleShape.at(r, side, t + 2 * sgn, 0), CastleShape.at(r, side, t + 2 * sgn, 1)] })
	return out


## Every cell of the planned towers, so the wall segments can leave them alone.
static func cells(planned: Array) -> Dictionary:
	var out := {}
	for t in planned:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				out[t.centre + Vector2i(dx, dz)] = true
	return out


static func build(g: Grid, planned: Array, wall_top: int, lay: Dictionary) -> void:
	var top := wall_top + TOWER_UP
	for t in planned:
		var cs: Array[Vector2i] = []
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var c: Vector2i = t.centre + Vector2i(dx, dz)
				CastleShape.put(g, c, top, Grid.Mat.STONE)
				cs.append(c)
		for c in t.steps:
			CastleShape.put(g, c, wall_top + 1, Grid.Mat.STONE)
		lay.towers.append({ "cells": cs, "top": top, "centre": t.centre })


## Low ring at Chebyshev distance 5 round the spire; the courtyard corner stairs (|d| >= 4 on
## both axes) are left alone and each side keeps a 3-wide door.
static func keep(g: Grid, centre: Vector2i, yard: int, lay: Dictionary) -> void:
	var cs: Array[Vector2i] = []
	for dz in range(-5, 6):
		for dx in range(-5, 6):
			if maxi(absi(dx), absi(dz)) != 5:
				continue
			var along: int = dz if absi(dx) == 5 else dx
			if absi(along) >= 4 or absi(along) <= 1:
				continue
			var c := centre + Vector2i(dx, dz)
			CastleShape.put(g, c, yard + KEEP_UP, Grid.Mat.STONE)
			cs.append(c)
	lay["keep"] = { "cells": cs, "top": yard + KEEP_UP }
