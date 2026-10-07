class_name CastleShape
## Writes a castle into the grid during the level build (so walls are part of base_height)
## and returns its layout as plain data for Strongholds. Level row:
##   { id, name, x, z, size: 15, floor, variant: "ground" | "raised", moat, bridge,
##     gates: ["s"], climbs: ["e"], spire_h: 20 }
## Sides: n = low z, s = high z, w = low x, e = high x. `k` is the depth from the rect edge:
## 0..1 is the wall, 2+ the courtyard, -1/-2 the moat (or the cliff gap of a raised castle),
## -3/-4 the apron of flattened ground around it.
##  - Stone walls 2 thick, WALL_UP above the courtyard; their 2-wide top is the walkway.
##    Corner stairs (+1, +2) lead up from the courtyard.
##  - Gates (3 wide, mid-side) are faction gates: open ground for the owner only.
##  - Raised: the rect is a plateau RAISE above the floor. A drawbridge (Grid.deck) crosses
##    the gap from an approach ramp; a winch on the approach holds it to its owner.
##  - Climb routes: pillars on ring k = -2 rising one level each with one-cell gaps, ending
##    level with the wall top. Raiders can't jump gaps; the Operative can.

const WALL_UP := 3
const RAISE := 4
const MOAT_DEPTH := 2
const SEGMENT_MAX := 5  # wall columns per destructible segment


static func build(g: Grid, row: Dictionary) -> Dictionary:
	var n: int = row.get("size", 15)
	var r := Rect2i(row.x, row.z, n, n)
	var floor_h: int = row.floor
	var raised: bool = row.get("variant", "ground") == "raised"
	var moat: bool = row.get("moat", false)
	var yard := floor_h + (RAISE if raised else 0)
	var gates: Array = row.get("gates", ["s"])
	var lay := { "rect": r, "floor": floor_h, "yard": yard, "raised": raised, "moat": moat,
		"wall_top": yard + WALL_UP, "segments": [], "gates": [], "bridge": [], "winch": Vector2i(-1, -1),
		"climbs": [], "pump_cells": [], "courtyard": [] }
	for k in range(-4, 0):  # apron, then moat / gap
		for c in _ring(r, k):
			g.set_height(c.x, c.y, floor_h - (MOAT_DEPTH if moat and k >= -2 else 0))
			if k >= -2 and g.in_bounds(c.x, c.y):
				lay.pump_cells.append(c)
	_fill(g, r, yard, Grid.Mat.NATURAL)
	_walls(g, r, yard, gates, lay)
	for i in gates.size():
		_gate(g, r, gates[i], yard, lay, i == 0 and (raised or row.get("bridge", false)))
	_stairs(g, r, yard)
	lay["spire"] = SpireShape.build(g, Vector2i(r.position.x + n / 2, r.position.y + n / 2), yard, row.get("spire_h", 20))
	for side in row.get("climbs", []):
		lay.climbs.append(_climb(g, r, side, floor_h, yard + WALL_UP))
	var g0: String = gates[0]
	lay["home"] = _at(r, g0, n / 2, 2)
	lay["pump_at"] = _at(r, "s" if g0 == "n" else "n", n / 2, 3)
	for z in range(r.position.y + 2, r.end.y - 2):
		for x in range(r.position.x + 2, r.end.x - 2):
			if g.material[g.idx(x, z)] != Grid.Mat.SPIRE:
				lay.courtyard.append(Vector2i(x, z))
				g.yard[g.idx(x, z)] = 1
	return lay


## Cell on `side` at position t along it and depth k from the edge (k < 0 is outside).
static func _at(r: Rect2i, side: String, t: int, k: int) -> Vector2i:
	var x0 := r.position.x
	var z0 := r.position.y
	match side:
		"n": return Vector2i(x0 + t, z0 + k)
		"s": return Vector2i(x0 + t, r.end.y - 1 - k)
		"w": return Vector2i(x0 + k, z0 + t)
		_: return Vector2i(r.end.x - 1 - k, z0 + t)


## Every in-bounds cell of the square ring at depth k (k < 0 outside the rect).
static func _ring(r: Rect2i, k: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a := r.grow(-k)
	for z in range(a.position.y, a.end.y):
		for x in range(a.position.x, a.end.x):
			if x == a.position.x or z == a.position.y or x == a.end.x - 1 or z == a.end.y - 1:
				out.append(Vector2i(x, z))
	return out


static func _fill(g: Grid, r: Rect2i, h: int, mat: int) -> void:
	for z in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_put(g, Vector2i(x, z), h, mat)


static func _put(g: Grid, c: Vector2i, h: int, mat: int, block := true) -> void:
	if not g.in_bounds(c.x, c.y):
		return
	g.set_height(c.x, c.y, h)
	g.material[g.idx(c.x, c.y)] = mat
	if block:
		g.blocked[g.idx(c.x, c.y)] = 1


static func _gate_ts(n: int) -> Array:
	return [n / 2 - 1, n / 2, n / 2 + 1]


## Wall cells (k 0..1) split into segments of at most SEGMENT_MAX columns between gaps.
## Corner blocks belong to the n and s sides.
static func _walls(g: Grid, r: Rect2i, yard: int, gates: Array, lay: Dictionary) -> void:
	var n := r.size.x
	for side in ["n", "s", "w", "e"]:
		var ts := range(n) if side in ["n", "s"] else range(2, n - 2)
		var run: Array = []
		for t in ts + [-1]:
			var gap: bool = t < 0 or (side in gates and t in _gate_ts(n))
			if not gap:
				run.append(t)
				continue
			var parts := ceili(run.size() / float(SEGMENT_MAX))
			for p in parts:
				var cells: Array[Vector2i] = []
				for j in range(run.size() * p / parts, run.size() * (p + 1) / parts):
					for k in 2:
						var c := _at(r, side, run[j], k)
						_put(g, c, yard + WALL_UP, Grid.Mat.STONE)
						cells.append(c)
				lay.segments.append({ "side": side, "cells": cells })
			run = []


static func _gate(g: Grid, r: Rect2i, side: String, yard: int, lay: Dictionary, bridge: bool) -> void:
	var n := r.size.x
	var cells: Array[Vector2i] = []
	var outer: Array[Vector2i] = []
	for t in _gate_ts(n):
		for k in 2:
			var c := _at(r, side, t, k)
			_put(g, c, yard, Grid.Mat.STONE)
			g.gate[g.idx(c.x, c.y)] = Grid.Faction.ENEMY
			cells.append(c)
		for k in [-1, -2]:
			var c := _at(r, side, t, k)
			if not g.in_bounds(c.x, c.y):
				continue
			if bridge:  # the gap stays real ground; the deck is the owner's road over it
				g.deck[g.idx(c.x, c.y)] = yard
				g.deck_owner[g.idx(c.x, c.y)] = Grid.Faction.ENEMY
				g.blocked[g.idx(c.x, c.y)] = 1
				lay.bridge.append(c)
			else:  # causeway across the moat
				_put(g, c, yard, Grid.Mat.NATURAL, false)
			outer.append(c)
	lay.gates.append({ "side": side, "cells": cells, "outer": outer })
	if not bridge:
		return
	for t in range(n / 2 - 2, n / 2 + 3):  # approach head (5 wide), then a ramp down
		_put(g, _at(r, side, t, -3), yard, Grid.Mat.NATURAL, false)
	lay.winch = _at(r, side, n / 2 + 2, -3)
	g.blocked[g.idx(lay.winch.x, lay.winch.y)] = 1
	for k in range(-4, -24, -1):  # down one level per cell until it meets the ground
		var lvl := yard + k + 3
		var mid := _at(r, side, n / 2, k)
		if not g.in_bounds(mid.x, mid.y) or lvl <= g.height_at(mid.x, mid.y):
			break
		for t in _gate_ts(n):
			var c := _at(r, side, t, k)
			if g.in_bounds(c.x, c.y) and g.height_at(c.x, c.y) < lvl:
				_put(g, c, lvl, Grid.Mat.NATURAL, false)


## Courtyard corner stairs onto the wall walk: a +2 landing with +1 steps on both sides.
static func _stairs(g: Grid, r: Rect2i, yard: int) -> void:
	var x0 := r.position.x
	var z0 := r.position.y
	var x1 := r.end.x - 1
	var z1 := r.end.y - 1
	for corner in [Vector2i(x0 + 2, z0 + 2), Vector2i(x1 - 3, z0 + 2), Vector2i(x0 + 2, z1 - 3), Vector2i(x1 - 3, z1 - 3)]:
		var step_x: int = corner.x + 2 if corner.x < x0 + r.size.x / 2 else corner.x - 1
		var step_z: int = corner.y + 2 if corner.y < z0 + r.size.y / 2 else corner.y - 1
		for i in 2:
			for j in 2:
				_put(g, corner + Vector2i(i, j), yard + 2, Grid.Mat.STONE)
			_put(g, Vector2i(corner.x + i, step_z), yard + 1, Grid.Mat.STONE)
			_put(g, Vector2i(step_x, corner.y + i), yard + 1, Grid.Mat.STONE)


## Pillars on ring k = -2 of `side`: base+1, gap, base+2, gap ... up to the wall top.
static func _climb(g: Grid, r: Rect2i, side: String, base: int, top: int) -> Array:
	var cells := []
	for i in range(1, top - base + 1):
		var c := _at(r, side, 2 * i - 1, -2)
		if 2 * i - 1 >= r.size.x or not g.in_bounds(c.x, c.y):
			break
		_put(g, c, base + i, Grid.Mat.STONE)
		cells.append(c)
	return cells
