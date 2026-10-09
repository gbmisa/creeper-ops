class_name UnitMeshes
## Procedural unit meshes (facing +X) and the ground selection ring.



static func make(type: String) -> Node3D:
	var anim := CreatureAnim.make(CreatureAnim.id_of(type), 1.0, StructureMeshes.glow(Color("9dff7a"), 2.0))
	if anim != null:
		return anim
	var root := Node3D.new()
	if type == "soldier":
		_soldier(root)
	else:
		_wagon(root)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root


## Footman, 1.8 m (the Operative's height): mail, blue tabard, bronze helm, crossbow.
static func _soldier(root: Node3D) -> void:
	var mail := StructureMeshes.mat(Color("6c717c"), 0.6, 0.5)
	var dark := StructureMeshes.mat(Color("2e2c2a"), 0.2, 0.8)
	for sz in [-1.0, 1.0]:
		ShapeKit.taper(root, Vector3(0, 0.0, sz * 0.11), Vector3(0, 0.88, sz * 0.11), 0.07, 0.1, dark, 6)  # legs
		StructureMeshes.ball(root, 0.13, StructureMeshes.pal("bronze"), Vector3(0, 1.43, sz * 0.25), 8)
		ShapeKit.strut(root, Vector3(0, 1.38, sz * 0.25), Vector3(0.3, 1.08, sz * 0.12), 0.1, mail)
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.2, 0.82), Vector2(0.26, 1.2), Vector2(0.24, 1.45),
		Vector2(0.1, 1.5), Vector2(0.0, 1.5)]), mail, Vector3.ZERO, 8)
	StructureMeshes.box(root, Vector3(0.1, 0.62, 0.3), StructureMeshes.pal("cloth"), Vector3(0.21, 1.08, 0))
	StructureMeshes.box(root, Vector3(0.05, 0.08, 0.08), StructureMeshes.glow(Color("9dff7a"), 2.0), Vector3(0.27, 1.3, 0))
	StructureMeshes.ball(root, 0.12, StructureMeshes.mat(Color("c49478"), 0.0, 0.8), Vector3(0, 1.6, 0), 10)
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.15, 1.56), Vector2(0.14, 1.7), Vector2(0.08, 1.78),
		Vector2(0.0, 1.8)]), StructureMeshes.pal("bronze"), Vector3.ZERO, 8)
	StructureMeshes.box(root, Vector3(0.24, 0.1, 0.03), StructureMeshes.pal("cloth"), Vector3(-0.02, 1.82, 0))
	var cloak := StructureMeshes.box(root, Vector3(0.05, 1.0, 0.5), StructureMeshes.pal("cloth"), Vector3(-0.2, 0.95, 0))
	cloak.rotation.z = -0.12
	var shield := StructureMeshes.cyl(root, 0.26, 0.26, 0.05, StructureMeshes.pal("bronze"), 0.0, 12)  # round shield on the left arm
	shield.rotation.x = PI / 2.0
	shield.position = Vector3(0.12, 1.05, -0.3)
	StructureMeshes.ball(root, 0.06, StructureMeshes.pal("rune"), Vector3(0.12, 1.05, -0.34), 6)
	StructureMeshes.box(root, Vector3(0.62, 0.08, 0.08), StructureMeshes.pal("oak"), Vector3(0.42, 1.08, 0))
	StructureMeshes.box(root, Vector3(0.06, 0.05, 0.56), StructureMeshes.pal("bronze_dark"), Vector3(0.68, 1.1, 0))


## War wagon: oak hull plated in bronze on four wheels, a rune sprayer on a turret.
static func _wagon(root: Node3D) -> void:
	StructureMeshes.box(root, Vector3(2.0, 0.65, 1.2), StructureMeshes.pal("oak"), Vector3(0, 0.75, 0))
	var nose := StructureMeshes.box(root, Vector3(0.6, 0.12, 1.24), StructureMeshes.pal("bronze"), Vector3(1.05, 0.85, 0))
	nose.rotation.z = -0.7
	for sz in [-1.0, 1.0]:
		StructureMeshes.box(root, Vector3(2.0, 0.42, 0.06), StructureMeshes.pal("bronze_dark"), Vector3(0, 0.82, sz * 0.62))
		for x in [-0.62, 0.62]:
			var wheel := StructureMeshes.cyl(root, 0.38, 0.38, 0.14, StructureMeshes.pal("oak"), 0.0, 10)
			wheel.rotation.x = PI / 2.0
			wheel.position = Vector3(x, 0.38, sz * 0.72)
	StructureMeshes.cyl(root, 0.32, 0.4, 0.32, StructureMeshes.pal("bronze"), 1.07, 10)
	ShapeKit.rod(root, Vector3(0.1, 1.26, 0), Vector3(1.0, 1.32, 0), 0.07, StructureMeshes.pal("iron"), 8)
	StructureMeshes.crystal(root, 0.1, 0.3, StructureMeshes.glow(Color("9dff7a"), 2.0), Vector3(1.08, 1.33, 0)).rotation.z = -PI / 2.0
	StructureMeshes.box(root, Vector3(0.5, 0.06, 0.5), StructureMeshes.pal("cloth"), Vector3(-0.6, 1.1, 0))


static func selection_ring(radius: float) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = radius + 0.15
	t.outer_radius = radius + 0.3
	t.rings = 24
	var mi := MeshInstance3D.new()
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("9dff7a")
	mi.material_override = m
	mi.scale = Vector3(1, 0.2, 1)
	mi.position.y = 0.1
	mi.visible = false
	return mi
