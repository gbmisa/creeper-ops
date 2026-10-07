class_name UnitMeshes
## Procedural unit meshes (facing +X) and the ground selection ring.


static func make(type: String) -> Node3D:
	var root := Node3D.new()
	var body := StructureMeshes.mat(Color("6b7d5a"), 0.3, 0.6)
	var dark := StructureMeshes.mat(Color("2f3540"), 0.4, 0.6)
	var lamp := StructureMeshes.mat(Color("9dff7a"), 0.0, 0.3, Color("9dff7a"), 2.0)
	if type == "soldier":
		StructureMeshes.cyl(root, 0.22, 0.26, 0.9, body, 0.0, 10)
		StructureMeshes.ball(root, 0.2, dark, Vector3(0, 1.1, 0))
		StructureMeshes.box(root, Vector3(0.12, 0.04, 0.12), lamp, Vector3(0.14, 1.12, 0))
		StructureMeshes.box(root, Vector3(0.6, 0.08, 0.08), dark, Vector3(0.3, 0.7, 0.18))
	else:
		StructureMeshes.box(root, Vector3(1.8, 0.6, 1.2), body, Vector3(0, 0.45, 0))
		for sz in [-0.6, 0.6]:
			StructureMeshes.box(root, Vector3(1.9, 0.4, 0.3), dark, Vector3(0, 0.25, sz))
		StructureMeshes.cyl(root, 0.3, 0.35, 0.35, dark, 0.75, 10)
		StructureMeshes.box(root, Vector3(1.0, 0.14, 0.14), dark, Vector3(0.55, 1.0, 0))
		StructureMeshes.ball(root, 0.12, lamp, Vector3(1.05, 1.0, 0))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root


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
