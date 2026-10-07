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
	return root
