class_name Props
## Decorative rocks (and cave stalagmites) scattered on the terrain. Visual only: they sit
## on cells that have no gameplay meaning (steep or edge ground) and never block anything.


static func scatter(g: Grid, cave: bool, seed_value: int, keep_clear: Callable) -> Node3D:
	var root := Node3D.new()
	root.name = "Props"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rock := SphereMesh.new()
	rock.radial_segments = 7
	rock.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("4a4440") if not cave else Color("3a3048")
	mat.roughness = 1.0
	var count := 120 if not cave else 70
	for n in count:
		var x := rng.randi_range(1, g.w - 2)
		var z := rng.randi_range(1, g.h - 2)
		if g.blocked[g.idx(x, z)] or (keep_clear.is_valid() and keep_clear.call(x, z)):
			continue
		if g.height_at(x, z) >= 6.9 and cave:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = rock
		mi.material_override = mat
		var s := rng.randf_range(0.25, 0.7)
		var p := Vector3((x + rng.randf()) * Config.CELL, 0, (z + rng.randf()) * Config.CELL)
		p.y = g.smooth_y(p.x, p.z) + s * 0.15
		mi.position = p
		mi.scale = Vector3(s * rng.randf_range(0.8, 1.6), s * 0.7, s)
		mi.rotation.y = rng.randf() * TAU
		root.add_child(mi)
	if cave:
		_fungus(g, rng, root)
	return root


## Bioluminescent fungus clusters in the cave: emissive caps on short stems.
static func _fungus(g: Grid, rng: RandomNumberGenerator, root: Node3D) -> void:
	var stem := CylinderMesh.new()
	stem.top_radius = 0.06
	stem.bottom_radius = 0.1
	stem.height = 0.5
	var cap := SphereMesh.new()
	cap.radial_segments = 8
	cap.rings = 4
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("46f2d8")  # unshaded bright teal; bloom picks it up
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color("2c3440")
	stem_mat.roughness = 1.0
	for n in 26:
		var x := rng.randi_range(1, g.w - 2)
		var z := rng.randi_range(1, g.h - 2)
		if g.blocked[g.idx(x, z)] or g.height_at(x, z) >= 6.9:
			continue
		var cluster := Node3D.new()
		var p := Vector3((x + rng.randf()) * Config.CELL, 0, (z + rng.randf()) * Config.CELL)
		p.y = g.smooth_y(p.x, p.z)
		cluster.position = p
		for k in rng.randi_range(3, 6):
			var off := Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))
			var h := rng.randf_range(0.25, 0.6)
			var st := MeshInstance3D.new()
			st.mesh = stem
			st.material_override = stem_mat
			st.position = off + Vector3(0, h * 0.5, 0)
			st.scale = Vector3.ONE * rng.randf_range(0.7, 1.3)
			st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var cp := MeshInstance3D.new()
			cp.mesh = cap
			cp.material_override = glow
			cp.position = off + Vector3(0, h, 0)
			cp.scale = Vector3.ONE * rng.randf_range(0.12, 0.22)
			cp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cluster.add_child(st)
			cluster.add_child(cp)
		root.add_child(cluster)
