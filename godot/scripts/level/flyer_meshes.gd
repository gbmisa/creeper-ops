class_name FlyerMeshes
## Blight flyers, facing +X, origin at the body centre (the flyer node floats at altitude).
## Wings are Node3D pivots named WingL (+Z) and WingR (-Z); Flyers rotates them about X to flap.
## Gasbag tendrils hang under a "Tendrils" node that sways.


static func make(row: Dictionary) -> Node3D:
	var glow := CreatureAnim.creature_glow(row.color)
	var anim := CreatureAnim.make(CreatureAnim.id_of(str(row.name)), float(row.size), glow)
	if anim != null:
		return anim
	var root := Node3D.new()
	match str(row.name):
		"Spore Bat": _bat(root, float(row.size), glow)
		"Gasbag": _gasbag(root, float(row.size), glow)
		"Wyvern": _wyvern(root, float(row.size), glow)
		_: StructureMeshes.ball(root, float(row.size) * 0.4, glow)
	return root


static func _wing(root: Node3D, side: float, span: float, chord: float, m: Material, bone: Material) -> void:
	var pivot := Node3D.new()
	pivot.name = "WingL" if side > 0.0 else "WingR"
	root.add_child(pivot)
	ShapeKit.strut(pivot, Vector3(0, 0, side * 0.05), Vector3(-0.1 * chord, 0, side * span), 0.03 * span, bone)
	StructureMeshes.box(pivot, Vector3(chord * 0.9, 0.02 * span, span * 0.95), m, Vector3(-0.45 * chord, 0, side * span * 0.5))
	ShapeKit.taper(pivot, Vector3(0, 0, side * span), Vector3(-0.2 * chord, 0, side * span * 1.12), 0.02 * span, 0.004, bone, 4)


static func _bat(r: Node3D, s: float, glow: Material) -> void:
	var skin := StructureMeshes.mat(Color("3a2a3e"), 0.0, 0.85)
	var body := StructureMeshes.ball(r, 0.28 * s, skin, Vector3.ZERO, 8)
	body.scale = Vector3(1.4, 0.8, 0.9)
	StructureMeshes.ball(r, 0.2 * s, skin, Vector3(0.38, 0.05, 0) * s, 7)
	StructureMeshes.ball(r, 0.1 * s, glow, Vector3(-0.3, -0.08, 0) * s, 6)  # spore gland
	for z in [-0.08, 0.08]:
		StructureMeshes.ball(r, 0.04 * s, RaiderMeshes.sick(), Vector3(0.52, 0.1, z) * s, 4)
		ShapeKit.taper(r, Vector3(0.38, 0.2, z * 1.6) * s, Vector3(0.42, 0.42, z * 2.4) * s, 0.05 * s, 0.01, RaiderMeshes.bone(), 4)
	var wing := StructureMeshes.mat(Color("8a5aa0"), 0.0, 0.9)
	for side in [1.0, -1.0]:
		_wing(r, side, 1.1 * s, 0.8 * s, wing, RaiderMeshes.bone())


static func _gasbag(r: Node3D, s: float, glow: Material) -> void:
	var skin := StructureMeshes.mat(Color("6a7a3a"), 0.0, 0.7)
	var bladder := StructureMeshes.ball(r, 0.55 * s, skin, Vector3(0, 0.2, 0) * s, 12)
	bladder.scale = Vector3(1.25, 1.0, 1.0)
	StructureMeshes.ball(r, 0.3 * s, glow, Vector3(0, -0.22, 0) * s, 8)  # glowing sac
	for z in [-0.3, 0.3]:
		StructureMeshes.ball(r, 0.14 * s, RaiderMeshes.sick(), Vector3(0.1, 0.62, z) * s, 5)
	var tend := Node3D.new()
	tend.name = "Tendrils"
	r.add_child(tend)
	for i in 6:
		var a := i * TAU / 6.0
		var top := Vector3(cos(a) * 0.3, -0.25, sin(a) * 0.3) * s
		var bot := Vector3(cos(a) * 0.45, -1.0 - 0.15 * (i % 3), sin(a) * 0.45) * s
		ShapeKit.taper(tend, top, bot, 0.05 * s, 0.01 * s, RaiderMeshes.sick(), 4)
	StructureMeshes.ball(r, 0.16 * s, RaiderMeshes.chitin(), Vector3(0.7, 0.1, 0) * s, 6)  # blind head
	var fin := StructureMeshes.mat(Color("8a9a4a"), 0.0, 0.9)
	for side in [1.0, -1.0]:
		_wing(r, side, 0.55 * s, 0.5 * s, fin, RaiderMeshes.bone())


static func _wyvern(r: Node3D, s: float, glow: Material) -> void:
	var skin := StructureMeshes.mat(Color("4a2a22"), 0.05, 0.75)
	var body := StructureMeshes.ball(r, 0.3 * s, skin, Vector3.ZERO, 9)
	body.scale = Vector3(1.7, 0.85, 0.9)
	ShapeKit.taper(r, Vector3(0.35, 0.05, 0) * s, Vector3(0.75, 0.3, 0) * s, 0.16 * s, 0.09 * s, skin, 6)  # neck
	var head := StructureMeshes.ball(r, 0.14 * s, skin, Vector3(0.82, 0.34, 0) * s, 7)
	head.scale = Vector3(1.5, 0.8, 0.9)
	StructureMeshes.ball(r, 0.07 * s, glow, Vector3(0.88, 0.4, 0.08) * s, 5)
	StructureMeshes.ball(r, 0.07 * s, glow, Vector3(0.88, 0.4, -0.08) * s, 5)
	ShapeKit.taper(r, Vector3(-0.35, 0, 0) * s, Vector3(-1.3, -0.15, 0) * s, 0.14 * s, 0.015 * s, skin, 5)  # tail
	ShapeKit.horn(r, Vector3(0.76, 0.42, 0.06) * s, Vector3(0.62, 0.55, 0.1) * s, Vector3(0.5, 0.7, 0.12) * s, 0.03 * s, RaiderMeshes.bone())
	ShapeKit.horn(r, Vector3(0.76, 0.42, -0.06) * s, Vector3(0.62, 0.55, -0.1) * s, Vector3(0.5, 0.7, -0.12) * s, 0.03 * s, RaiderMeshes.bone())
	StructureMeshes.ball(r, 0.12 * s, glow, Vector3(-0.1, -0.2, 0) * s, 6)  # fire gland
	var wing := StructureMeshes.mat(Color("7a3a2a"), 0.0, 0.9)
	for side in [1.0, -1.0]:
		_wing(r, side, 1.5 * s, 1.0 * s, wing, RaiderMeshes.bone())
