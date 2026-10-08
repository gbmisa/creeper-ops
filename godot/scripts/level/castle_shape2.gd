class_name CastleShape2
## Concentric castle (Stage 21, docs/CASTLES2_DESIGN.md §1), written into the grid during the
## level build. Level rows opt in with "plan": "concentric"; CastleShape.build hands them here.
## k = depth from the outer rect edge: outer wall k 0..1, bailey k 2..B+1, inner wall k B+2..B+3,
## ward inside it, keep in the middle. Outer corner towers and the gatehouses (CastleStairs) are
## walkable inside; the keep hall holds the final capture point (CastleKeepShape).
## Returns the Stage 7 layout keys (so every old reader works) plus plan, bailey, ward, zones,
## interiors, stages, crown_at, keep_box, vaults, keep_posts and engine_posts.

const TURN := { "n": "e", "e": "s", "s": "w", "w": "n" }
const OPPOSITE := { "n": "s", "s": "n", "e": "w", "w": "e" }
const NORMAL := { "n": Vector2i(0, -1), "s": Vector2i(0, 1), "w": Vector2i(-1, 0), "e": Vector2i(1, 0) }


static func build(g: Grid, row: Dictionary) -> Dictionary:
	var n: int = maxi(CastleDefs.MIN_SIZE, row.get("size", 35))
	var b: int = row.get("bailey", CastleDefs.BAILEY)
	var r := Rect2i(row.x, row.z, n, n)
	var floor_h: int = row.floor
	var raised: bool = row.get("variant", "ground") == "raised"
	var moat: bool = row.get("moat", false)
	var yard := floor_h + (CastleShape.RAISE if raised else 0)
	var gates: Array = row.get("gates", ["s"])
	var inner: String = row.get("inner_gate", TURN[gates[0]])
	var ri := r.grow(-(b + 2))
	var m := n / 2
	var lay := { "plan": "concentric", "rect": r, "inner_rect": ri, "floor": floor_h, "yard": yard, "raised": raised,
		"moat": moat, "wall_top": yard + CastleDefs.OUTER_UP, "segments": [], "gates": [], "bridge": [],
		"winch": Vector2i(-1, -1), "climbs": [], "pump_cells": [], "courtyard": [], "bailey": [], "ward": [],
		"towers": [], "keep": {}, "zones": {}, "interiors": [], "stages": ["gate", "bailey", "keep"],
		"vaults": [], "keep_posts": [], "engine_posts": [], "inner_gate": inner }
	for k in range(-4, 0):  # apron, then moat / gap (Stage 7 rules)
		for c in CastleShape._ring(r, k):
			g.set_height(c.x, c.y, floor_h - (CastleShape.MOAT_DEPTH if moat and k >= -2 else 0))
			if k >= -2 and g.in_bounds(c.x, c.y):
				lay.pump_cells.append(c)
	CastleShape._fill(g, r, yard, Grid.Mat.NATURAL)
	var skip := {}
	var corners := []
	for cx in [0, n - 1]:
		for cz in [0, n - 1]:
			var inward := Vector2i(1 if cx == 0 else -1, 1 if cz == 0 else -1)
			var centre := r.position + Vector2i(cx, cz) + inward
			corners.append([centre, inward])
			_mark(skip, centre)
	for side in gates:
		for s in [-4, 4]:
			_mark(skip, CastleShape.at(r, side, m + s, 2))
		for t in range(m - 1, m + 2):
			for k in range(2, 2 + CastleDefs.GATE_HALL):
				skip[CastleShape.at(r, side, t, k)] = true
	_walls(g, r, yard + CastleDefs.OUTER_UP, gates, skip, lay, "outer")
	for i in gates.size():
		CastleShape._gate(g, r, gates[i], yard, lay, i == 0 and (raised or row.get("bridge", false)))
		lay.gates.back()["ring"] = "outer"
	var outer_top := yard + CastleDefs.TOWER_UP
	for cr in corners:
		_corner_tower(g, cr[0], cr[1], yard, outer_top, lay)
	for side in gates:
		_gatehouse(g, r, side, yard, outer_top, yard + CastleDefs.OUTER_UP, 2, lay)
	var gate0: String = gates[0]
	var hall: Array[Vector2i] = []
	for t in range(m - 1, m + 2):
		for k in range(2, 2 + CastleDefs.GATE_HALL):
			hall.append(CastleShape.at(r, gate0, t, k))
	lay.zones["gate"] = { "cells": hall, "y": yard, "y_max": outer_top }
	# Inner ring: taller wall, its own gatehouse (towers open to the ward and the wall walk only).
	var mi := ri.size.x / 2
	var iskip := {}
	for s in [-4, 4]:
		_mark(iskip, CastleShape.at(ri, inner, mi + s, 0))
	_walls(g, ri, yard + CastleDefs.INNER_UP, [inner], iskip, lay, "inner")
	CastleShape._gate(g, ri, inner, yard, lay, false)
	lay.gates.back()["ring"] = "inner"
	_gatehouse(g, ri, inner, yard, yard + CastleDefs.INNER_TOWER_UP, yard + CastleDefs.INNER_UP, 0, lay)
	var standard: Array[Vector2i] = []
	for t in range(mi - 1, mi + 2):
		for k in range(-5, -2):
			standard.append(CastleShape.at(ri, inner, t, k))
	lay.zones["bailey"] = { "cells": standard, "y": yard, "y_max": yard + CastleDefs.HEADROOM + 4 }
	for side in row.get("climbs", []):
		lay.climbs.append(_climb(g, r, side, floor_h, yard + CastleDefs.OUTER_UP, 6))
	for side in row.get("inner_climbs", [OPPOSITE[inner]]):
		lay.climbs.append(_climb(g, ri, side, yard, yard + CastleDefs.INNER_UP, 4))
	var ward_w := ri.size.x - 4
	var half := CastleDefs.KEEP_HALF if ward_w >= 2 * CastleDefs.KEEP_HALF + 5 else CastleDefs.KEEP_HALF_SMALL
	CastleKeepShape.build(g, r.position + Vector2i(m, m), yard, NORMAL[inner], half, row.get("spire_h", 20), lay)
	_classify(g, r, ri, yard, lay)
	lay["home"] = standard[4]
	lay["pump_at"] = _nearest(lay.bailey, CastleShape.at(r, OPPOSITE[gate0], m, 3))
	for cr in corners:
		lay.engine_posts.append(cr[0])
	return lay


static func _mark(skip: Dictionary, centre: Vector2i) -> void:
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			skip[centre + Vector2i(dx, dz)] = true


## Wall cells (k 0..1 of `rect`) at `top`, split into breachable segments between gaps.
static func _walls(g: Grid, rect: Rect2i, top: int, gates: Array, skip: Dictionary, lay: Dictionary, ring: String) -> void:
	var n := rect.size.x
	for side in ["n", "s", "w", "e"]:
		var ts := range(n) if side in ["n", "s"] else range(2, n - 2)
		var run: Array = []
		for t in ts + [-1]:
			var gap: bool = t < 0 or (side in gates and t in CastleShape._gate_ts(n))
			if not gap:
				run.append(t)
				continue
			var parts := ceili(run.size() / float(CastleShape.SEGMENT_MAX))
			for p in parts:
				var cells: Array[Vector2i] = []
				for j in range(run.size() * p / parts, run.size() * (p + 1) / parts):
					for k in 2:
						var c := CastleShape.at(rect, side, run[j], k)
						if skip.has(c):
							continue
						CastleShape.put(g, c, top, Grid.Mat.STONE)
						cells.append(c)
				if not cells.is_empty():
					lay.segments.append({ "side": side, "cells": cells, "ring": ring })
			run = []


## Outer corner tower: doors onto both wall walks and into the bailey.
static func _corner_tower(g: Grid, centre: Vector2i, inward: Vector2i, yard: int, top: int, lay: Dictionary) -> void:
	var walk := yard + CastleDefs.OUTER_UP
	var doors := [
		{ "cell": centre + Vector2i(2 * inward.x, -inward.y), "outside": walk },
		{ "cell": centre + Vector2i(-inward.x, 2 * inward.y), "outside": walk },
		{ "cell": centre + Vector2i(2 * inward.x, inward.y), "outside": yard },
	]
	lay.towers.append(CastleStairs.tower(g, centre, top, doors, lay))


## Two towers flanking the gate of `rect` on `side` (centred at depth `kc`), with the passage
## between them roofed at `top`. Outer (kc 2): towers open into the gate hall and onto the wall
## walk. Inner (kc 0): they open to the ward and the inner wall walk, never the bailey.
static func _gatehouse(g: Grid, rect: Rect2i, side: String, yard: int, top: int, walk: int, kc: int, lay: Dictionary) -> void:
	var m := rect.size.x / 2
	for s in [-1, 1]:
		var centre := CastleShape.at(rect, side, m + 4 * s, kc)
		var doors := [{ "cell": CastleShape.at(rect, side, m + 6 * s, 1), "outside": walk }]  # onto the wall walk
		if kc == 2:
			doors.append({ "cell": CastleShape.at(rect, side, m + 2 * s, kc + 1), "outside": yard })
		else:
			doors.append({ "cell": CastleShape.at(rect, side, m + 4 * s, kc + 2), "outside": yard })
		lay.towers.append(CastleStairs.tower(g, centre, top, doors, lay))
	var passage: Array[Vector2i] = []
	for t in range(m - 1, m + 2):
		for k in range(kc - 2, kc + 3):
			passage.append(CastleShape.at(rect, side, t, k))
	CastleStairs.add_roof(g, lay, "gatehouse", passage, top, CastleShape.at(rect, side, m, kc))


## Pillars on ring k = -2 of `rect` along `side`, from t0: base+1, gap, base+2 ... up to `top`.
static func _climb(g: Grid, rect: Rect2i, side: String, base: int, top: int, t0: int) -> Array:
	var cells := []
	for i in range(1, top - base + 1):
		var t := t0 + 2 * (i - 1)
		var c := CastleShape.at(rect, side, t, -2)
		if t >= rect.size.x - 4 or not g.in_bounds(c.x, c.y):
			break
		CastleShape.put(g, c, base + i, Grid.Mat.STONE)
		cells.append(c)
	return cells


## Open ground inside the walls: bailey (between the rings) and ward (inside the inner wall).
static func _classify(g: Grid, r: Rect2i, ri: Rect2i, yard: int, lay: Dictionary) -> void:
	var ward := ri.grow(-2)
	for z in range(r.position.y + 2, r.end.y - 2):
		for x in range(r.position.x + 2, r.end.x - 2):
			var i := g.idx(x, z)
			if g.material[i] != Grid.Mat.NATURAL or g.height[i] != yard or g.roof[i] > 0.0 or g.gate[i] != 0:
				continue
			var c := Vector2i(x, z)
			if ri.has_point(c) and not ward.has_point(c):
				continue  # inner climb pillars' gaps and the inner gate approach
			(lay.ward if ward.has_point(c) else lay.bailey).append(c)
			lay.courtyard.append(c)
			g.yard[i] = 1


static func _nearest(cells: Array, to: Vector2i) -> Vector2i:
	var best: Vector2i = cells[0]
	for c in cells:
		if (c - to).length_squared() < (best - to).length_squared():
			best = c
	return best
