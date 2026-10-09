class_name CastleProps
## Stage 21b P3: interior props for concentric castles — keep-hall dais, two long tables,
## two weapon racks, a runner rug; a winch + chains per gate hall; a stone trim on each
## tower-stair step edge. Decoration only: walkers read the grid; props stay off the
## door -> crown -> stair walking line (checked in core/smoke_castles2b_props.gd).

## Builds the props under `root`; returns a descriptor dict for the smoke test.
static func build(root: Node3D, g: Grid, lay: Dictionary) -> Dictionary:
	var desc := { "dais_cell": Vector2i(-1, -1), "dais_top_y": 0.0, "tables": [],
		"racks": [], "rug_cells": [], "winches": [], "trims": 0 }
	if lay.get("plan", "") != "concentric":
		return desc
	_keep_hall(root, lay, desc)
	for it in lay.get("interiors", []):
		if it.kind == "gatehouse":
			_gate_hall(root, g, lay, it, desc)
	_stair_trims(root, g, lay, desc)
	return desc


static func _keep_hall(root: Node3D, lay: Dictionary, desc: Dictionary) -> void:
	var kd: Dictionary = lay.keep
	var box: Rect2i = lay.keep_box
	var centre := Vector2i(box.get_center())
	var door_c := Vector2i.ZERO
	for c in kd.door:
		door_c += c
	door_c = door_c / maxi(1, kd.door.size())
	var fwd := Vector2i(signi(door_c.x - centre.x), signi(door_c.y - centre.y))
	if fwd == Vector2i.ZERO:
		fwd = Vector2i(1, 0)
	var side := Vector2i(-fwd.y, fwd.x)
	var zone: Array = (lay.zones.keep as Dictionary).cells
	var floor_y := float((lay.zones.keep as Dictionary).y) * Config.LEVEL_H
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var oak := StructureMeshes.pal("oak")
	var crown: Vector2i = (lay.crown_at as Dictionary).cell
	var cp := Vector3((crown.x + 0.5) * Config.CELL, floor_y, (crown.y + 0.5) * Config.CELL)
	var sh := CastleDefs.DAIS_H * 0.5  # two steps under the crown nest
	StructureMeshes.box(root, Vector3(5.0, sh, 5.0), stone, cp + Vector3(0, sh * 0.5, 0))
	StructureMeshes.box(root, Vector3(3.6, sh, 3.6), stone, cp + Vector3(0, sh * 1.5, 0))
	desc["dais_cell"] = crown
	desc["dais_top_y"] = floor_y + CastleDefs.DAIS_H
	_tables(root, centre, fwd, side, floor_y, zone, oak, desc)
	_racks(root, centre, fwd, side, floor_y, zone, oak, desc)
	_rug(root, lay, centre, fwd, floor_y, zone, crown, desc)


## Two long tables on the longest runs of hall cells two cells either side of the aisle
## (door-end cells; 3 not 4 when the run is short, so the racks still fit).
static func _tables(root: Node3D, centre: Vector2i, fwd: Vector2i, side: Vector2i,
		floor_y: float, zone: Array, oak: Material, desc: Dictionary) -> void:
	for s in [1, -1]:
		var coords: Array = []
		for c in zone:
			var rel: Vector2i = c - centre
			if rel.x * side.x + rel.y * side.y == 2 * s:
				coords.append(rel.x * fwd.x + rel.y * fwd.y)
		coords.sort()
		var run := _run(coords)
		run = run.slice(maxi(0, run.size() - (3 if run.size() == 4 else mini(4, run.size()))))
		if run.size() < 2:
			continue
		var cells: Array = []
		for a in run:
			cells.append(centre + fwd * a + side * (2 * s))
		(desc["tables"] as Array).append(cells)
		var n := run.size()
		var mid_a := (float(run[0]) + float(run[n - 1])) / 2.0
		var tc: Vector2 = Vector2(centre) + Vector2(fwd) * mid_a + Vector2(side) * (2 * s)
		var pos := Vector3((tc.x + 0.5) * Config.CELL, floor_y, (tc.y + 0.5) * Config.CELL)
		var len := n * Config.CELL - 0.3
		var xl := fwd.x != 0
		StructureMeshes.box(root, Vector3(len, 0.14, 1.3) if xl else Vector3(1.3, 0.14, len),
			oak, pos + Vector3(0, CastleDefs.TABLE_H, 0))
		for ex in [-1.0, 1.0]:
			for ez in [-1.0, 1.0]:
				var off := Vector3(ex * (len / 2 - 0.35), 0, ez * 0.45) if xl \
					else Vector3(ex * 0.45, 0, ez * (len / 2 - 0.35))
				StructureMeshes.box(root, Vector3(0.14, CastleDefs.TABLE_H, 0.14), oak,
					pos + off + Vector3(0, CastleDefs.TABLE_H * 0.5, 0))


## Longest run of consecutive ints in a sorted array (ties: the door-end run).
static func _run(vals: Array) -> Array:
	var best: Array = []
	var cur: Array = []
	for v in vals:
		if not cur.is_empty() and v != cur.back() + 1:
			if cur.size() >= best.size():
				best = cur
			cur = []
		cur.append(v)
	if cur.size() >= best.size():
		best = cur
	return best


## Two freestanding weapon racks (posts, crossbars, leaning blades) on the back cells of
## the table rows — never table cells.
static func _racks(root: Node3D, centre: Vector2i, fwd: Vector2i, side: Vector2i,
		floor_y: float, zone: Array, oak: Material, desc: Dictionary) -> void:
	var taken := {}
	for cells in desc["tables"]:
		for c in cells:
			taken[c] = true
	var iron := StructureMeshes.pal("iron")
	for s in [1, -1]:
		var back := 1 << 20
		for c in zone:
			var rel: Vector2i = c - centre
			if rel.x * side.x + rel.y * side.y == 2 * s and not taken.has(c):
				back = mini(back, rel.x * fwd.x + rel.y * fwd.y)
		if back > 1 << 19: continue
		var cell: Vector2i = centre + fwd * back + side * (2 * s)
		var rack := Node3D.new()
		rack.position = Vector3((cell.x + 0.5) * Config.CELL, floor_y, (cell.y + 0.5) * Config.CELL)
		rack.rotation.y = atan2(float(-s * side.x), float(-s * side.y))
		root.add_child(rack)
		for px in [-0.6, 0.6]:
			StructureMeshes.box(rack, Vector3(0.12, 1.6, 0.12), oak, Vector3(px, 0.8, 0))
		for by in [0.45, 1.25]:
			StructureMeshes.box(rack, Vector3(1.4, 0.1, 0.1), oak, Vector3(0, by, 0))
		var i := 0
		for wx in [-0.45, -0.15, 0.15, 0.45]:
			var w := StructureMeshes.box(rack, Vector3(0.08, 1.5, 0.08),
				iron if i % 2 == 0 else oak, Vector3(wx, 0.85, 0.12))
			w.rotation.x = 0.12
			i += 1
		(desc["racks"] as Array).append(cell)


## Runner rug on the aisle from the dais edge to the last aisle cell (door cells
## included); flat (8 cm): walkers step over it like a threshold.
static func _rug(root: Node3D, lay: Dictionary, centre: Vector2i, fwd: Vector2i,
		floor_y: float, zone: Array, crown: Vector2i, desc: Dictionary) -> void:
	var crown_a := (crown.x - centre.x) * fwd.x + (crown.y - centre.y) * fwd.y
	var top_a := crown_a
	var cells: Array = []
	for c in zone + (lay.keep as Dictionary).door:
		var rel: Vector2i = c - centre
		if rel.x * -fwd.y + rel.y * fwd.x == 0 and rel.x * fwd.x + rel.y * fwd.y >= crown_a:
			top_a = maxi(top_a, rel.x * fwd.x + rel.y * fwd.y)
			cells.append(c)
	var fm := Vector3(fwd.x, 0, fwd.y)
	var start := Vector3((crown.x + 0.5) * Config.CELL, 0, (crown.y + 0.5) * Config.CELL) + fm * 2.65
	var ec: Vector2i = centre + fwd * top_a
	var end := Vector3((ec.x + 0.5) * Config.CELL, 0, (ec.y + 0.5) * Config.CELL) + fm * Config.CELL * 0.5
	var len := (end - start).length()
	if len < 1.2:
		return
	var mid := (start + end) * 0.5
	StructureMeshes.box(root, Vector3(len, 0.08, 1.5) if fwd.x != 0 else Vector3(1.5, 0.08, len),
		StructureMeshes.mat(Color("6a1f1f"), 0.0, 0.95), Vector3(mid.x, floor_y + 0.04, mid.z))
	desc["rug_cells"] = cells


## A winch wheel in the gate hall's inner corner and chains over the gate cells for the
## portcullis, up into the slab.
static func _gate_hall(root: Node3D, g: Grid, lay: Dictionary, it: Dictionary, desc: Dictionary) -> void:
	var cells: Array = it.cells
	var light: Vector2i = it.light
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var ax := Vector2i(1, 0) if hi.x - lo.x >= hi.y - lo.y else Vector2i(0, 1)
	var perp := Vector2i(-ax.y, ax.x)
	var rc := Vector2((lay.rect as Rect2i).get_center())
	var s := -1 if (Vector2(light) - rc).x * ax.x + (Vector2(light) - rc).y * ax.y > 0.0 else 1
	var u := func(c): return s * (c.x * ax.x + c.y * ax.y)
	var inner_end := -(1 << 20)
	var outer_end := 1 << 20
	for c in cells:
		inner_end = maxi(inner_end, u.call(c))
		outer_end = mini(outer_end, u.call(c))
	var wcell := Vector2i(-1, -1)
	var wbest := -1
	for c in cells:  # inner-end corner: off the middle walking column
		if u.call(c) != inner_end:
			continue
		var p: int = absi((c.x - light.x) * perp.x + (c.y - light.y) * perp.y)
		if p > wbest:
			wbest = p
			wcell = c
	var wp := Vector3((wcell.x + 0.5) * Config.CELL, g.height_at(wcell.x, wcell.y) * Config.LEVEL_H,
		(wcell.y + 0.5) * Config.CELL)
	_winch(root, wp, ax, float(it.roof) * Config.LEVEL_H - GridRoofs.ROOF_THICK)
	(desc["winches"] as Array).append(wcell)
	var iron := StructureMeshes.pal("iron")
	var y0 := float(it.roof) * Config.LEVEL_H - GridRoofs.ROOF_THICK
	var y1 := float(lay.yard) * Config.LEVEL_H + Grid.GATE_H * Config.LEVEL_H - 0.7
	for q in [-1, 0, 1]:
		var cc: Vector2i = light + perp * q + ax * (s * (outer_end - u.call(light)))
		if cells.has(cc):
			var cp := Vector3((cc.x + 0.5) * Config.CELL, 0, (cc.y + 0.5) * Config.CELL)
			ShapeKit.rod(root, cp + Vector3(0, y0, 0), cp + Vector3(0, y1, 0), 0.06, iron, 6)


## Stone posts, an oak drum on an iron axle, a spoked wheel, and a chain up to the slab.
static func _winch(root: Node3D, at: Vector3, ax: Vector2i, slab_y: float) -> void:
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var oak := StructureMeshes.pal("oak")
	var iron := StructureMeshes.pal("iron")
	var xa := Vector3(ax.x, 0, ax.y)
	var x_long := absi(ax.x) == 1
	for e in [-1.0, 1.0]:
		StructureMeshes.box(root, Vector3(0.3, 1.7, 0.3), stone, at + xa * e * 0.65 + Vector3(0, 0.85, 0))
	ShapeKit.rod(root, at - xa * 0.85 + Vector3(0, 1.55, 0), at + xa * 0.85 + Vector3(0, 1.55, 0), 0.1, iron, 8)
	var drum := StructureMeshes.cyl(root, 0.42, 0.42, 0.9, oak, 0.0, 10)
	drum.position = at + Vector3(0, 1.55, 0)
	drum.rotation = Vector3(0.0 if x_long else PI * 0.5, 0.0, PI * 0.5 if x_long else 0.0)
	var wheel := StructureMeshes.torus(root, CastleDefs.WINCH_WHEEL_R - 0.12, CastleDefs.WINCH_WHEEL_R, iron)
	wheel.position = at + xa * 0.78 + Vector3(0, 1.55, 0)
	wheel.rotation = Vector3(0.0 if x_long else PI * 0.5, 0.0, PI * 0.5 if x_long else 0.0)
	for a in [0.0, PI * 0.5]:  # spokes spin in the wheel plane
		var sp := StructureMeshes.box(root, Vector3(0.07, CastleDefs.WINCH_WHEEL_R * 1.7, 0.07),
			oak, wheel.position)
		if x_long:
			sp.rotation.x = a
		else:
			sp.rotation.z = a
	ShapeKit.rod(root, at + Vector3(0, 1.9, 0), Vector3(at.x, slab_y, at.z), 0.05, iron, 6)


## A stone lip on each tower step's downhill edge (one trim per step edge between ring cells).
static func _stair_trims(root: Node3D, g: Grid, lay: Dictionary, desc: Dictionary) -> void:
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var ring := CastleStairs.RING
	var in_ring := {}
	for o in ring:
		in_ring[o] = true
	var n := 0
	var th := CastleDefs.STAIR_TRIM_H
	for tw in lay.get("towers", []):
		var centre: Vector2i = tw.centre
		for o in ring:
			var c: Vector2i = centre + o
			var h := g.height_at(c.x, c.y)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not in_ring.has(o + d) or g.height_at(c.x + d.x, c.y + d.y) != h - 1:
					continue
				StructureMeshes.box(root,
					Vector3(Config.CELL + 0.06, th, 0.3) if d.y == 0 else Vector3(0.3, th, Config.CELL + 0.06),
					stone, Vector3((c.x + 0.5 + d.x * 0.5) * Config.CELL,
						h * Config.LEVEL_H + 0.06 - th * 0.5, (c.y + 0.5 + d.y * 0.5) * Config.CELL))
				n += 1
	desc["trims"] = n
