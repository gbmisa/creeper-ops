class_name CastleBanners
## Stage 21b P2: cloth for concentric castles — banners on the gatehouse fronts and
## the keep's four faces, the bailey standard (pole + flag that rises with the bailey
## stage) and a small gate-hall banner that rises with the gate stage. Every cloth mesh
## goes into the view's banners list so StrongholdMeshes.refresh dyes it by owner.
## Read-only w.r.t. the rules: animate_flags only reads c.stage / c.ring.

const OUTWARD := { "n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1),
	"w": Vector3(-1, 0, 0), "e": Vector3(1, 0, 0) }


## Builds the cloth; returns { standard?, gate_banner? } flag-rise descriptors.
static func build(root: Node3D, g: Grid, lay: Dictionary, banners: Array) -> Dictionary:
	var out := {}
	if lay.get("plan", "") != "concentric":
		return out
	_gatehouse_fronts(root, lay, banners)
	_keep_faces(root, lay, banners)
	var bs := _standard(root, lay, banners)
	if not bs.is_empty():
		out["standard"] = bs
	var gb := _gate_banner(root, g, lay, banners)
	if not gb.is_empty():
		out["gate_banner"] = gb
	return out


## A wide banner over every gate (outer and inner), hung on the gatehouse's outer face.
static func _gatehouse_fronts(root: Node3D, lay: Dictionary, banners: Array) -> void:
	for gt in lay.gates:
		var b := StrongholdMeshes._bounds(gt.cells, lay.yard)
		var out: Vector3 = OUTWARD[gt.side]
		var wall_up: int = CastleDefs.INNER_UP if gt.get("ring", "outer") == "inner" else CastleDefs.OUTER_UP
		var top_y: float = (int(lay.yard) + wall_up) * Config.LEVEL_H
		var hang := Node3D.new()
		hang.position = Vector3(b[0].x, top_y - 0.3, b[0].z) + out * (Config.CELL * 0.5 + 0.35)
		hang.rotation.y = atan2(out.x, out.z)
		root.add_child(hang)
		for mi in ShapeKit.banner(hang, 3.4, 2.8, CastleDecor.cloth("enemy"), Vector3.ZERO).get_children():
			banners.append(mi)


## A banner down each of the keep's four faces.
static func _keep_faces(root: Node3D, lay: Dictionary, banners: Array) -> void:
	var kd: Dictionary = lay.get("keep", {})
	if kd.is_empty():
		return
	var box: Rect2i = lay.keep_box
	var c := box.get_center()
	var hx := box.size.x / 2
	var hz := box.size.y / 2
	var top_y: float = float(kd.top) * Config.LEVEL_H
	for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var fc := Vector2i(c.x + d.x * hx, c.y + d.y * hz)
		var hang := Node3D.new()
		hang.position = Vector3((fc.x + 0.5) * Config.CELL, top_y - 0.4, (fc.y + 0.5) * Config.CELL) \
			+ Vector3(d.x, 0, d.y) * 0.35
		hang.rotation.y = atan2(d.x, d.y)
		root.add_child(hang)
		for mi in ShapeKit.banner(hang, 1.9, 3.6, CastleDecor.cloth("enemy"), Vector3.ZERO).get_children():
			banners.append(mi)


## The bailey standard: an iron-shod pole on the zone's centre cell; the flag rises with
## the bailey stage's progress and flies the owner's colour once taken (via refresh).
static func _standard(root: Node3D, lay: Dictionary, banners: Array) -> Dictionary:
	if not lay.zones.has("bailey"):
		return {}
	var cells: Array = lay.zones.bailey.cells
	var c: Vector2i = cells[cells.size() / 2]
	var base_y: float = float(lay.yard) * Config.LEVEL_H
	var px := (c.x + 0.5) * Config.CELL
	var pz := (c.y + 0.5) * Config.CELL
	StructureMeshes.box(root, Vector3(1.0, 0.6, 1.0),
		StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92), Vector3(px, base_y + 0.3, pz))
	ShapeKit.rod(root, Vector3(px, base_y + 0.4, pz), Vector3(px, base_y + CastleDefs.STANDARD_H, pz),
		0.09, StructureMeshes.pal("iron"), 8)
	var base_flag_y := base_y + 1.2
	var flag := Node3D.new()
	flag.position = Vector3(px, base_flag_y, pz)
	root.add_child(flag)
	for mi in ShapeKit.banner(flag, 1.8, 1.1, CastleDecor.cloth("enemy"), Vector3.ZERO).get_children():
		banners.append(mi)
	return { "node": flag, "base_y": base_flag_y, "travel": CastleDefs.STANDARD_H - 2.2,
		"stage_idx": (lay.stages as Array).find("bailey") }


## A small war banner on a pole in the gate hall; hoisted as the gate stage progresses.
static func _gate_banner(root: Node3D, g: Grid, lay: Dictionary, banners: Array) -> Dictionary:
	if not lay.zones.has("gate"):
		return {}
	var cells: Array = lay.zones.gate.cells
	var c: Vector2i = cells[cells.size() / 2]
	var floor_y: float = g.height_at(c.x, c.y) * Config.LEVEL_H
	var roof_y: float = (int(lay.yard) + CastleDefs.TOWER_UP) * Config.LEVEL_H
	var px := (c.x + 0.5) * Config.CELL + 0.6
	var pz := (c.y + 0.5) * Config.CELL + 0.6
	var base_flag_y := floor_y + 1.9
	var travel: float = roof_y - 0.5 - base_flag_y
	ShapeKit.rod(root, Vector3(px, floor_y, pz), Vector3(px, floor_y + travel + 2.0, pz),
		0.07, StructureMeshes.pal("oak"), 8)
	var flag := Node3D.new()
	flag.position = Vector3(px, base_flag_y, pz)
	root.add_child(flag)
	for mi in ShapeKit.banner(flag, 1.6, 1.8, CastleDecor.cloth("enemy"), Vector3.ZERO).get_children():
		banners.append(mi)
	return { "node": flag, "base_y": base_flag_y, "travel": travel,
		"stage_idx": (lay.stages as Array).find("gate") }


## Hoist the standard and the gate banner from the state's stage progress (read-only).
static func animate_flags(v: Dictionary, c: Dictionary) -> void:
	for key in ["standard", "gate_banner"]:
		if not v.has(key):
			continue
		var d: Dictionary = v[key]
		var idx: int = d.stage_idx
		if idx < 0:
			continue
		var cur: int = int(c.get("stage", 99))
		var prog := 0.0
		if cur == idx:
			prog = float((c.get("ring", {}) as Dictionary).get("progress", 0.0))
		elif cur > idx:
			prog = 1.0
		(d.node as Node3D).position.y = float(d.base_y) + prog * float(d.travel)
