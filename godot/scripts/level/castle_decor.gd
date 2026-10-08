class_name CastleDecor
## Pure decoration on a castle's terrain walls: round corner towers with slate cone roofs and
## flags, and a gatehouse (two square towers, a stone arch and a crenellated breastwork) on
## every gate. Banner meshes are returned so StrongholdMeshes.refresh can dye them in the
## owner's colour. No collision: walkers only ever read the grid.

const ENEMY_CLOTH := Color("8e1f30")
const PLAYER_CLOTH := Color("1f6f96")


static func cloth(owner: String) -> StandardMaterial3D:
	return StructureMeshes.mat(ENEMY_CLOTH if owner == "enemy" else PLAYER_CLOTH, 0.0, 0.95)


## Builds the decor under `root`; returns every banner MeshInstance3D.
static func build(root: Node3D, lay: Dictionary) -> Array:
	var banners: Array = []
	var r: Rect2i = lay.rect
	var lh := Config.LEVEL_H
	var c := Config.CELL
	var base: float = (lay.floor - 3) * lh
	var top: float = lay.wall_top * lh
	var corners := [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)]
	for k in corners:
		var p := Vector3(k.x * c, 0, k.y * c)
		var t := Node3D.new()
		t.position = p
		root.add_child(t)
		_round_tower(t, base, top + 2.6, 2.1, banners)
	for gt in lay.gates:
		_gatehouse(root, gt, lay, banners)
	return banners


static func _round_tower(t: Node3D, base: float, top: float, rad: float, banners: Array) -> void:
	var stone := StructureMeshes.mat(StrongholdMeshes.STONE, 0.0, 0.92)
	ShapeKit.lathe(t, PackedVector2Array([Vector2(rad * 1.12, base), Vector2(rad, base + 2.0), Vector2(rad, top - 0.6),
		Vector2(rad * 1.15, top - 0.3), Vector2(rad * 1.15, top), Vector2(0.0, top)]), stone, Vector3.ZERO, 12)
	for i in 8:
		var a := i * TAU / 8.0
		StructureMeshes.box(t, Vector3(0.7, 0.8, 0.5), stone, Vector3(cos(a) * rad * 1.05, top + 0.4, sin(a) * rad * 1.05)).rotation.y = -a
	for i in 4:  # arrow slits
		var a := i * TAU / 4.0 + PI / 4.0
		StructureMeshes.box(t, Vector3(0.2, 1.0, 0.2), StructureMeshes.mat(Color("1a1612"), 0.0, 1.0),
			Vector3(cos(a) * rad * 0.98, top - 2.2, sin(a) * rad * 0.98))
	ShapeKit.cone(t, rad * 1.05, 3.4, StructureMeshes.pal("slate"), Vector3(0, top + 0.6, 0), 12)
	ShapeKit.rod(t, Vector3(0, top + 3.8, 0), Vector3(0, top + 5.4, 0), 0.05, StructureMeshes.pal("bronze"), 6)
	var flag := StructureMeshes.box(t, Vector3(1.4, 0.8, 0.05), cloth("enemy"), Vector3(0.72, top + 4.95, 0))
	banners.append(flag)


static func _gatehouse(root: Node3D, gt: Dictionary, lay: Dictionary, banners: Array) -> void:
	var lh := Config.LEVEL_H
	var b := StrongholdMeshes._bounds(gt.cells, lay.yard)
	var g := Node3D.new()
	g.position = b[0]
	var out := { "n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "w": Vector3(-1, 0, 0), "e": Vector3(1, 0, 0) }[gt.side] as Vector3
	g.rotation.y = 0.0 if gt.side in ["n", "s"] else PI / 2.0
	root.add_child(g)
	var face := 1.0 if (g.basis.inverse() * out).z > 0.0 else -1.0  # local z of the outer face
	var stone := StructureMeshes.mat(StrongholdMeshes.STONE, 0.0, 0.92)
	var wall_h: float = (lay.wall_top - lay.yard) * lh
	var low: float = -3.0 * lh
	for sx in [-1.0, 1.0]:
		var h := wall_h + 3.2 - low
		StructureMeshes.box(g, Vector3(2.6, h, 4.6), stone, Vector3(sx * 4.4, low + h * 0.5, 0))
		for mz in [-1.6, 0.0, 1.6]:
			StructureMeshes.box(g, Vector3(0.6, 0.8, 0.6), stone, Vector3(sx * 4.4 + sx * 1.0, wall_h + 3.6, mz))
		var bn := ShapeKit.banner(g, 1.3, 3.0, cloth("enemy"), Vector3(sx * 4.4, wall_h + 2.6, face * 2.34))
		for mi in bn.get_children():
			banners.append(mi)
	ShapeKit.arch(g, 6.2, 1.6, 0.55, 1.0, stone, Vector3(0, wall_h - 1.7, face * 1.9), 12)
	StructureMeshes.box(g, Vector3(6.2, 1.4, 1.0), stone, Vector3(0, wall_h + 0.5, face * 1.9))
	for i in 4:
		StructureMeshes.box(g, Vector3(0.7, 0.7, 0.6), stone, Vector3(-2.4 + i * 1.6, wall_h + 1.55, face * 2.1))
