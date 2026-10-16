class_name ViewmodelClip
## FB-H (CHANGES P6): z_clip_scale on every material under a viewmodel node, so the gun and hands never clip the
## camera near plane. Materials are duplicated per mesh, so world copies of the same glb are unaffected.


static func apply(root: Node, only_name := "") -> int:
	var n := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if only_name != "" and mi.name != only_name:
			continue
		n += _mesh(mi as MeshInstance3D)
	return n


static func _mesh(mi: MeshInstance3D) -> int:
	var n := 0
	if mi.material_override is BaseMaterial3D:
		mi.material_override = _clip(mi.material_override)
		n += 1
	if mi.mesh == null:
		return n
	for i in mi.mesh.get_surface_count():
		var m := mi.get_surface_override_material(i)
		if m == null:
			m = mi.mesh.surface_get_material(i)
		if m is BaseMaterial3D:
			mi.set_surface_override_material(i, _clip(m))
			n += 1
	return n


static func _clip(m: Material) -> Material:
	var d := m.duplicate() as BaseMaterial3D
	d.use_z_clip_scale = true
	d.z_clip_scale = TacticalConfig.VM_Z_CLIP
	return d


## Every material under root has z-clip scale on (tests).
static func all_clipped(root: Node) -> bool:
	var seen := 0
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for mi in meshes:
		var m := mi as MeshInstance3D
		var list: Array = [m.material_override]
		for i in (m.mesh.get_surface_count() if m.mesh != null else 0):
			list.append(m.get_surface_override_material(i))
		for x in list:
			if x is BaseMaterial3D:
				seen += 1
				if not x.use_z_clip_scale:
					return false
	return seen > 0
