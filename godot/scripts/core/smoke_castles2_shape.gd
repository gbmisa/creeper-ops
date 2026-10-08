class_name SmokeCastles2Shape
## Stage 21: concentric castle terrain (CastleShape2): rings, heights, towers, roofs, zones.
## Builds Level 2 fresh, so it doesn't touch the running game.


static func run(_g) -> void:
	var lvl := Level02.build()
	var grid: Grid = lvl.grid
	var rows: Array = lvl.castles.filter(func(c): return c.layout.get("plan", "") == "concentric")
	SmokeTest._check("castles2: Level 2 has concentric castles", not rows.is_empty())
	for row in rows:
		_one(grid, row.id, row.layout)
	var old: Array = Level01.build().castles.filter(func(c): return c.layout.get("plan", "") != "concentric")
	var single: bool = old.all(func(c): return c.layout.stages == ["keep"] and c.layout.zones.has("keep") and c.layout.has("crown_at"))
	SmokeTest._check("castles2: Stage 7 rows keep a single keep stage", single)


static func _one(grid: Grid, id: String, lay: Dictionary) -> void:
	var yard: int = lay.yard
	var outer: Array = lay.segments.filter(func(s): return s.ring == "outer")
	var inner: Array = lay.segments.filter(func(s): return s.ring == "inner")
	SmokeTest._check("castles2 %s: outer and inner wall segments" % id, not outer.is_empty() and not inner.is_empty())
	var c0: Vector2i = outer[0].cells[0]
	var c1: Vector2i = inner[0].cells[0]
	SmokeTest._check("castles2 %s: inner wall overlooks the outer" % id, grid.height_at(c0.x, c0.y) == yard + CastleDefs.OUTER_UP
		and grid.height_at(c1.x, c1.y) == yard + CastleDefs.INNER_UP)
	SmokeTest._check("castles2 %s: gates on both rings" % id, lay.gates.any(func(g): return g.ring == "outer") and lay.gates.any(func(g): return g.ring == "inner"))
	SmokeTest._check("castles2 %s: every tower stair lines up its doors" % id, lay.towers.all(func(t): return t.ok), str(lay.towers.filter(func(t): return not t.ok).map(func(t): return t.centre)))
	var low := 0
	var hatch_roofed := 0
	for it in lay.interiors:
		for c in it.cells:
			if grid.roof[grid.idx(c.x, c.y)] - grid.height_at(c.x, c.y) < CastleDefs.HEADROOM:
				low += 1
	for t in lay.towers:
		if grid.roof[grid.idx(t.hatch.x, t.hatch.y)] > 0.0:
			hatch_roofed += 1
	SmokeTest._check("castles2 %s: roofs keep HEADROOM levels of headroom" % id, low == 0, "(%d low)" % low)
	SmokeTest._check("castles2 %s: stair hatches are open to the roof" % id, hatch_roofed == 0)
	for z in ["gate", "bailey", "keep"]:
		SmokeTest._check("castles2 %s: %s capture zone" % [id, z], lay.zones.has(z) and not lay.zones[z].cells.is_empty())
	var hall_cover: bool = lay.zones.keep.cells.all(func(c): return grid.roof[grid.idx(c.x, c.y)] > 0.0)
	var gate_cover: bool = lay.zones.gate.cells.all(func(c): return grid.roof[grid.idx(c.x, c.y)] > 0.0)
	SmokeTest._check("castles2 %s: gate hall and keep hall are roofed" % id, hall_cover and gate_cover)
	var bailey := {}
	for c in lay.bailey:
		bailey[c] = true
	var split: bool = lay.ward.all(func(c): return not bailey.has(c))
	SmokeTest._check("castles2 %s: bailey and ward split the courtyard" % id, not lay.bailey.is_empty() and not lay.ward.is_empty()
		and split and lay.courtyard.size() == lay.bailey.size() + lay.ward.size())
	SmokeTest._check("castles2 %s: bailey standard is open bailey ground" % id, lay.zones.bailey.cells.all(func(c): return bailey.has(c)))
	var whole := true
	var r: Rect2i = lay.rect.grow(4)
	for z in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if grid.in_bounds(x, z) and (grid.height_at(x, z) != roundf(grid.height_at(x, z)) or grid.roof[grid.idx(x, z)] != roundf(grid.roof[grid.idx(x, z)])):
				whole = false
	SmokeTest._check("castles2 %s: whole levels only" % id, whole)
	SmokeTest._check("castles2 %s: crown sits in the keep hall" % id, lay.zones.keep.cells.has(lay.crown_at.cell) or lay.keep_box.has_point(lay.crown_at.cell))
