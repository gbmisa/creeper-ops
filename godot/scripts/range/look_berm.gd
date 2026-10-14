class_name LookBerm
## Range berms and backdrop (visual only): rounded crown over the flat berm tops, timber revetment with posts on the lane face,
## sandbag courses on top, and far ridge silhouettes so the horizon is not a wall edge. Headless skips it.

const WOOD := Color(0.3, 0.2, 0.12)
const BAG := Color(0.55, 0.5, 0.36)


static func build(n: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var z0 := -RangeLayout.LENGTH
	var zc := (z0 + 14.0) * 0.5
	var len := 14.0 - z0
	for sx in [-1.0, 1.0]:
		# rounded crown (squashed cylinder along z) over the berm top, soft-edged
		var crown := LookFacades._cyl(n, Vector3(sx * 22.0, 3.55, zc), 2.6, len, Color(0.3, 0.3, 0.14))
		crown.rotation_degrees.x = 90.0
		crown.scale = Vector3(1.0, 1.0, 0.22)
		crown.material_override = LookMaterials.get_mat("dirt_berm", Color(0.34, 0.3, 0.16), "berm_crown")
		# revetment: vertical planks on the lower inner face, posts every 3 m, a cap beam
		var xf: float = sx * 20.04
		LookFacades.box(n, Vector3(xf, 0.8, zc), Vector3(0.08, 1.6, len), Color(0.26, 0.2, 0.14), 0.95)
		LookFacades.box(n, Vector3(xf + sx * 0.05, 1.62, zc), Vector3(0.18, 0.14, len), WOOD, 0.9)
		LookFacades.box(n, Vector3(xf + sx * 0.04, 0.05, zc), Vector3(0.14, 0.1, len), WOOD.darkened(0.4), 0.9)
		var post := BoxMesh.new()
		post.size = Vector3(0.2, 1.7, 0.2)
		_multi(n, post, WOOD, _line(sx * 19.98, 0.85, z0, 14.0, 3.0, rng, 0.0), 1.0)
		# sandbag courses on the berm crest (inner edge), two layers staggered
		var bag := BoxMesh.new()
		bag.size = Vector3(0.7, 0.26, 0.4)
		_multi(n, bag, BAG, _line(sx * 20.4, 3.62, z0, 14.0, 0.72, rng, 0.06), 1.0, true)
		_multi(n, bag, BAG.darkened(0.12), _line(sx * 20.4, 3.88, z0 + 0.36, 14.0, 0.72, rng, 0.06), 1.0, true)
	for z in [14.0 + 3.0]:   # back berm: same revetment so the booth rear is not a bare wall
		LookFacades.box(n, Vector3(0, 0.8, z - 3.0 + 0.04), Vector3(HALF_BACK, 1.6, 0.08), Color(0.26, 0.2, 0.14), 0.95)
	_far_berm(n)
	_ridges(n, rng)


const HALF_BACK := 32.0


## Far berm: sandbag crest and a revetment so the target-end backstop reads as built, not as a flat slab.
static func _far_berm(n: Node3D) -> void:
	var z := -RangeLayout.LENGTH
	LookFacades.box(n, Vector3(0, 0.9, z + 0.04), Vector3(RangeLayout.HALF_W * 2.0 + 12.0, 1.8, 0.1), Color(0.26, 0.2, 0.14), 0.95)
	LookFacades.box(n, Vector3(0, 1.85, z + 0.06), Vector3(RangeLayout.HALF_W * 2.0 + 12.0, 0.16, 0.2), WOOD, 0.9)
	for k in 20:
		var c := Color(0.55, 0.5, 0.36).darkened(0.1 * (k % 3))
		LookFacades.box(n, Vector3(-15.0 + k * 1.5, 3.65, z - 0.4), Vector3(1.0, 0.3, 0.45), c, 1.0)


static func _line(x: float, y: float, z0: float, z1: float, step: float, rng: RandomNumberGenerator, jit: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var z := z0
	while z < z1:
		pts.append(Vector3(x + rng.randf_range(-jit, jit), y, z))
		z += step
	return pts


static func _multi(n: Node3D, mesh: Mesh, col: Color, pts: PackedVector3Array, _s: float, tint := false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.0), pts[i]))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = LookFacades.mat(col, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)


## Far ridge silhouettes beyond the far berm and along both sides, tinted toward the fog so they sit in the distance.
static func _ridges(n: Node3D, rng: RandomNumberGenerator) -> void:
	var layers := [[-420.0, 38.0, Color(0.34, 0.3, 0.26)], [-520.0, 70.0, Color(0.42, 0.4, 0.42)], [-640.0, 95.0, Color(0.5, 0.5, 0.56)]]
	for l in layers:
		_ridge(n, Vector3(0, -2.0, l[0]), 900.0, l[1], l[2], rng)
	for sx in [-1.0, 1.0]:
		var side := _ridge(n, Vector3(sx * 330.0, -2.0, -150.0), 700.0, 45.0, Color(0.38, 0.35, 0.3), rng)
		side.rotation_degrees.y = 90.0


static func _ridge(n: Node3D, c: Vector3, width: float, hgt: float, col: Color, rng: RandomNumberGenerator) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 48
	var ph := rng.randf() * 10.0
	var prev_x := -width * 0.5
	var prev_h := _h(prev_x, hgt, ph)
	for i in range(1, seg + 1):
		var x := -width * 0.5 + width * i / seg
		var h := _h(x, hgt, ph)
		var q := [Vector3(prev_x, 0, 0), Vector3(prev_x, prev_h, 0), Vector3(x, h, 0), Vector3(x, 0, 0)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(col.lightened(0.18 * (q[k].y / maxf(hgt, 1.0))))
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(q[k])
		prev_x = x
		prev_h = h
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = c
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	return mi


static func _h(x: float, hgt: float, ph: float) -> float:
	return hgt * (0.55 + 0.3 * sin(x * 0.011 + ph) + 0.2 * sin(x * 0.027 + ph * 2.0) + 0.08 * sin(x * 0.09 + ph * 3.0))
