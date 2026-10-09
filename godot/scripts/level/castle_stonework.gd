class_name CastleStonework
## P1 stone detail for concentric castles: parapet merlons on roof edges that border open
## air, stone arches over interior doors, inner-wall string courses and buttresses in a
## darker stone, and moss bands at the moat line. Pure decoration: walkers read the grid.

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const MOSS := Color("4a5a33")


static func build(root: Node3D, g: Grid, lay: Dictionary) -> void:
	if lay.get("plan", "") != "concentric":
		return
	parapets(root, g, lay)
	door_arches(root, g, lay)


## Merlons along every gatehouse/keep roof edge whose neighbour cell is open air (2+
## levels below the roof). Tower slabs are skipped: tower crowns already carry merlons
## (CastleDecor._tower_crown). Returns the merlon count (for smoke).
static func parapets(root: Node3D, g: Grid, lay: Dictionary) -> int:
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var n := 0
	for it in lay.get("interiors", []):
		if it.kind != "gatehouse" and it.kind != "hall":
			continue
		var roof: int = it.roof
		var set := {}
		for c in it.cells:
			set[c] = true
		for c in it.cells:
			for d in DIRS:
				var nb: Vector2i = c + d
				if set.has(nb) or not g.in_bounds(nb.x, nb.y):
					continue
				if g.height_at(nb.x, nb.y) > roof - 2:
					continue  # a wall meets the roof, or the stair hatch: not open air
				var mid := Vector3((c.x + 0.5) * Config.CELL, roof * Config.LEVEL_H, (c.y + 0.5) * Config.CELL)
				mid += Vector3(d.x, 0, d.y) * Config.CELL * 0.5
				StructureMeshes.box(root, Vector3(0.7, 0.8, 0.7), stone, mid + Vector3(0, 0.4, 0))
				n += 1
	return n


## A stone arch over every interior door: tower doors from CastleStairs.tower's "doors"
## cells, and one wide arch over the keep's 3-wide door (lay.keep.door). Returns the count.
static func door_arches(root: Node3D, g: Grid, lay: Dictionary) -> int:
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var n := 0
	for tw in lay.get("towers", []):
		var centre: Vector2i = tw.centre
		for dc in tw.get("doors", []):
			var out := _axis(dc - centre)
			var at := Node3D.new()
			at.position = Vector3((dc.x + 0.5) * Config.CELL,
				g.height_at(dc.x, dc.y) * Config.LEVEL_H + CastleDefs.ARCH_SPRING,
				(dc.y + 0.5) * Config.CELL)
			at.rotation.y = PI * 0.5 if absi(out.x) > 0 else 0.0
			root.add_child(at)
			ShapeKit.arch(at, 2.6, 1.0, 0.45, 0.9, stone, Vector3.ZERO, 9)
			n += 1
	var door: Array = (lay.get("keep", {}) as Dictionary).get("door", [])
	if not door.is_empty():
		var kc: Vector2i = (lay.spire as Dictionary).centre
		var mid := Vector2.ZERO
		for c in door:
			mid += Vector2(c)
		mid /= door.size()
		var fwd := _axis(Vector2i(mid) - kc)
		var far := -1
		for c in door:
			far = maxi(far, (c.x - kc.x) * fwd.x + (c.y - kc.y) * fwd.y)
		var row: Array = door.filter(func(c): return (c.x - kc.x) * fwd.x + (c.y - kc.y) * fwd.y == far)
		var mc := Vector2.ZERO
		for c in row:
			mc += Vector2(c)
		mc /= row.size()
		var at := Node3D.new()
		at.position = Vector3((mc.x + 0.5) * Config.CELL,
			g.height_at(int(mc.x), int(mc.y)) * Config.LEVEL_H + CastleDefs.KEEP_ARCH_SPRING,
			(mc.y + 0.5) * Config.CELL)
		at.rotation.y = PI * 0.5 if absi(fwd.x) > 0 else 0.0
		root.add_child(at)
		ShapeKit.arch(at, 6.6, 1.5, 0.5, 1.0, stone, Vector3.ZERO, 13)
		n += 1
	return n


## Dominant axis of v as a unit step (doors sit on ring walls, so this is axis-aligned).
static func _axis(v: Vector2i) -> Vector2i:
	if absi(v.x) >= absi(v.y):
		return Vector2i(signi(v.x), 0)
	return Vector2i(0, signi(v.y))


## Per-segment trim, parented under the segment node so it hides with a breached wall.
## Merlons use the segment's real top (fixes inner merlons floating a level low) and a
## darker stone on the inner ring; the inner ring also gets a string course and
## buttresses, the outer ring a moss band at the moat line.
static func wall_trim(a: Node3D, g: Grid, seg: Dictionary, lay: Dictionary, outward: Vector3) -> void:
	var concentric: bool = lay.get("plan", "") == "concentric"
	var ring: String = seg.get("ring", "outer")
	var mat := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	if concentric and ring == "inner":
		mat = StructureMeshes.mat(StrongholdMeshes.INNER_STONE, 0.0, 0.92)
	for i in range(0, seg.cells.size(), 2):  # even cells are the outer row
		var c: Vector2i = seg.cells[i]
		var wtop: float = g.height_at(c.x, c.y) * Config.LEVEL_H
		var off: Vector3 = StrongholdMeshes.cell_pos(c.x, c.y, 0) - a.position \
			+ Vector3(0, wtop, 0) + outward * 0.6
		StructureMeshes.box(a, Vector3(0.8, 0.9, 0.8), mat, off + Vector3(0, 0.45, 0))
	if not concentric:
		return
	if ring == "inner":
		_string_course(a, g, seg, outward, mat)
		_buttresses(a, g, seg, lay, outward, mat)
	elif bool(lay.get("moat", false)):
		_moss_band(a, g, seg, lay, outward)


## A thin box hugging a wall face: `along` runs along the wall, `thick` into it.
static func _face_box(a: Node3D, along: float, thick: float, h: float, mat: Material,
		at: Vector3, outward: Vector3) -> void:
	var s := Vector3(along, h, thick) if absf(outward.z) > 0.0 else Vector3(thick, h, along)
	StructureMeshes.box(a, s, mat, at)


## Dark string course two levels under the inner wall's top, on its outer face.
static func _string_course(a: Node3D, g: Grid, seg: Dictionary, outward: Vector3, mat: Material) -> void:
	for i in range(0, seg.cells.size(), 2):
		var c: Vector2i = seg.cells[i]
		var wtop: float = g.height_at(c.x, c.y) * Config.LEVEL_H
		var at: Vector3 = StrongholdMeshes.cell_pos(c.x, c.y, 0) - a.position \
			+ Vector3(0, wtop - 2.0 * Config.LEVEL_H, 0) + outward * (Config.CELL * 0.5 + 0.08)
		_face_box(a, Config.CELL + 0.06, 0.22, 0.45, mat, at, outward)


## Tapered buttresses every 4 cells on the inner wall's outer face.
static func _buttresses(a: Node3D, g: Grid, seg: Dictionary, lay: Dictionary,
		outward: Vector3, mat: Material) -> void:
	var base: float = (int(lay.floor) - 3) * Config.LEVEL_H
	for i in range(0, seg.cells.size(), 8):
		var c: Vector2i = seg.cells[i]
		var wtop: float = g.height_at(c.x, c.y) * Config.LEVEL_H
		var foot: Vector3 = StrongholdMeshes.cell_pos(c.x, c.y, 0) - a.position \
			+ Vector3(0, base, 0) + outward * (Config.CELL * 0.5 + 0.35)
		ShapeKit.taper(a, foot, foot + Vector3(0, wtop - base - 1.0, 0), 0.55, 0.3, mat, 4)


## Moss/stain band on the outer wall's outer face, just above the moat waterline.
static func _moss_band(a: Node3D, g: Grid, seg: Dictionary, lay: Dictionary, outward: Vector3) -> void:
	var moss := StructureMeshes.mat(MOSS, 0.0, 0.95)
	var y: float = (int(lay.floor) - 1) * Config.LEVEL_H + 0.45
	for i in range(0, seg.cells.size(), 2):
		var c: Vector2i = seg.cells[i]
		var at: Vector3 = StrongholdMeshes.cell_pos(c.x, c.y, 0) - a.position \
			+ Vector3(0, y, 0) + outward * (Config.CELL * 0.5 + 0.02)
		_face_box(a, Config.CELL + 0.06, 0.16, 0.9, moss, at, outward)
