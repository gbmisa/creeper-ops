class_name LookScatter
## Ground cover and trees as MultiMeshes: dead-grass tufts, fallen leaves, bare / autumn trees, and a far ground plane so the
## map does not end at a cliff. Visual only; headless skips it. Seeded, so every run looks the same.

const SK := {"half": 60.0, "tufts": 9000, "leaves": 4200, "trees": 26, "grass": Color(0.36, 0.3, 0.14), "grass2": Color(0.26, 0.27, 0.12),
	"leaf": [Color(0.5, 0.22, 0.08), Color(0.55, 0.36, 0.1), Color(0.38, 0.16, 0.06), Color(0.45, 0.4, 0.14)]}


static func skirmish(parent: Node3D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1950
	var n := Node3D.new()
	n.name = "LookScatter"
	parent.add_child(n)
	_far_ground(n, "skirmish", 0.0)
	var H: float = SK["half"]
	var pts := _points(rng, SK["tufts"], Rect2(-H + 1, -H + 1, H * 2 - 2, H * 2 - 2), 0.0, true)
	_multi(n, _tuft_mesh(), pts, rng, [SK["grass"], SK["grass2"]], 0.7, 1.4, 60.0)
	_multi(n, _leaf_mesh(), _points(rng, SK["leaves"], Rect2(-H + 1, -H + 1, H * 2 - 2, H * 2 - 2), 0.01, false), rng, SK["leaf"], 0.8, 1.5, 45.0, true)
	var trees := []
	for i in SK["trees"]:   # ring outside the wall, plus a few inside the corners
		var a := rng.randf() * TAU
		var r := rng.randf_range(H + 6.0, H + 40.0)
		var p := Vector3(cos(a), 0, sin(a)) * r
		trees.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.5)), Vector3(clampf(p.x, -H - 40, H + 40), -0.5, clampf(p.z, -H - 40, H + 40))))
	for c in [Vector2(-56, 56), Vector2(56, 56), Vector2(56, -2), Vector2(-56, 4)]:
		trees.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * 0.9), Vector3(c.x, 0, c.y)))
	_trees(n, trees, rng)


## Range: tufts along both sides and on the berm tops, far ground plane. Lanes themselves stay bare.
static func range_hub(parent: Node3D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var n := Node3D.new()
	n.name = "LookScatter"
	parent.add_child(n)
	_far_ground(n, "range", -0.03)
	var pts := PackedVector3Array()
	for i in 5000:   # side strips between the lane edge (x 11..20) and berms
		var x := rng.randf_range(11.0, 20.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		pts.append(Vector3(x, 0.0, rng.randf_range(-RangeLayout.LENGTH + 4.0, 12.0)))
	for i in 3500:   # on the berm tops (y = 3.5)
		var x := rng.randf_range(HALF_BERM_IN, HALF_BERM_IN + 6.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		pts.append(Vector3(x, 3.5, rng.randf_range(-RangeLayout.LENGTH, 12.0)))
	_multi(n, _tuft_mesh(), pts, rng, [Color(0.55, 0.5, 0.25), Color(0.42, 0.45, 0.2)], 0.8, 1.6, 90.0)
	var trees := []
	for i in 30:
		var side := 1.0 if i % 2 == 0 else -1.0
		var z := rng.randf_range(-RangeLayout.LENGTH + 20.0, 10.0)
		if side > 0.0 and z > -50.0:   # the kill house yard sits east of the booth
			z = rng.randf_range(-RangeLayout.LENGTH + 20.0, -50.0)
		trees.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(1.0, 1.7)),
			Vector3(side * rng.randf_range(32.0, 60.0), -0.1, z)))
	_trees(n, trees, rng)


const HALF_BERM_IN := 20.0


static func _points(rng: RandomNumberGenerator, count: int, area: Rect2, y: float, avoid: bool) -> PackedVector3Array:
	var out := PackedVector3Array()
	var guard := 0
	while out.size() < count and guard < count * 4:
		guard += 1
		var p := Vector3(rng.randf_range(area.position.x, area.end.x), y, rng.randf_range(area.position.y, area.end.y))
		if avoid and _in_building(p):
			continue
		out.append(p)
	return out


static func _in_building(p: Vector3) -> bool:
	for b in SkirmishData.BUILDINGS.values():
		var r: Array = b["rect"]
		if p.x > r[0] - 0.4 and p.x < r[2] + 0.4 and p.z > r[1] - 0.4 and p.z < r[3] + 0.4:
			return true
	return false


static func _multi(parent: Node3D, mesh: Mesh, pts: PackedVector3Array, rng: RandomNumberGenerator, cols: Array, smin: float,
		smax: float, fade: float, flat := false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = pts.size()
	for i in pts.size():
		var s := rng.randf_range(smin, smax)
		var b := Basis(Vector3.UP, rng.randf() * TAU)
		if flat:
			b = b.rotated(Vector3.RIGHT, rng.randf_range(-0.15, 0.15))
		mm.set_instance_transform(i, Transform3D(b.scaled(Vector3(s, s, s)), pts[i]))
		mm.set_instance_color(i, (cols[rng.randi() % cols.size()] as Color) * rng.randf_range(0.8, 1.15))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = fade
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	mi.material_override = m
	parent.add_child(mi)


static func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var a := float(i) / 5.0 * TAU
		var d := Vector3(cos(a), 0, sin(a))
		var side := d.cross(Vector3.UP) * 0.012
		var lean := d * 0.04
		var h := 0.12 + 0.04 * float(i % 3)
		st.add_vertex(d * 0.04 - side)
		st.add_vertex(d * 0.04 + side)
		st.add_vertex(d * 0.04 + lean + Vector3(0, h, 0))
	return st.commit()


static func _leaf_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3(-0.06, 0, -0.04), Vector3(0.06, 0, -0.04), Vector3(0.06, 0, 0.04), Vector3(-0.06, 0, -0.04), Vector3(0.06, 0, 0.04), Vector3(-0.06, 0, 0.04)]:
		st.add_vertex(v)
	return st.commit()


## Shared mesh: trunk + a few branches (tapered boxes via a hexagonal prism) and a clumped crown.
static func _trees(parent: Node3D, xf: Array, rng: RandomNumberGenerator) -> void:
	var trunk := _prism_tree(rng)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = trunk
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, Color(0.9, 0.85, 0.75) * rng.randf_range(0.7, 1.1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	mi.material_override = m
	parent.add_child(mi)


static func _prism_tree(rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bark := Color(0.22, 0.17, 0.13)
	_limb(st, Vector3.ZERO, Vector3(0, 5.5, 0), 0.28, 0.1, bark)
	for i in 9:
		var a := float(i) * 2.4
		var y0 := 2.2 + float(i) * 0.4
		var dir := Vector3(cos(a), 0.9, sin(a)).normalized()
		var tip := Vector3(0, y0, 0) + dir * rng.randf_range(1.6, 2.8)
		_limb(st, Vector3(0, y0, 0), tip, 0.1, 0.03, bark)
		var leaf := Color(0.42, 0.2, 0.07) if i % 3 != 0 else Color(0.5, 0.36, 0.1)
		for k in 2:   # leaf clump: tetra-ish triangles round the tip
			var c := tip + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.0, 0.5), rng.randf_range(-0.5, 0.5))
			_clump(st, c, 0.38, leaf)
	st.generate_normals()
	return st.commit()


static func _limb(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, col: Color) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.RIGHT if absf(axis.x) < 0.9 else Vector3.FORWARD).normalized()
	var v := axis.cross(u)
	for i in 5:
		var a0 := float(i) / 5.0 * TAU
		var a1 := float(i + 1) / 5.0 * TAU
		var p0 := u * cos(a0) + v * sin(a0)
		var p1 := u * cos(a1) + v * sin(a1)
		st.set_color(col)
		for q in [a + p0 * r0, a + p1 * r0, b + p1 * r1, a + p0 * r0, b + p1 * r1, b + p0 * r1]:
			st.set_color(col)
			st.add_vertex(q)


static func _clump(st: SurfaceTool, c: Vector3, r: float, col: Color) -> void:
	var top := c + Vector3(0, r * 0.7, 0)
	var bot := c - Vector3(0, r * 0.5, 0)
	var ring := []
	for i in 5:
		var a := float(i) / 5.0 * TAU
		ring.append(c + Vector3(cos(a), 0, sin(a)) * r)
	for i in 5:
		var q0: Vector3 = ring[i]
		var q1: Vector3 = ring[(i + 1) % 5]
		for tri in [[top, q0, q1], [bot, q1, q0]]:
			for q in tri:
				st.set_color(col.darkened(0.12 if tri[0] == bot else 0.0))
				st.add_vertex(q)


static func _far_ground(parent: Node3D, map: String, y: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	mi.mesh = pm
	mi.position = Vector3(0, y - 0.1 if map == "skirmish" else y, -150.0 if map == "range" else 0.0)
	mi.material_override = LookMaterials.get_mat("dirt_berm", Color(0.24, 0.26, 0.14) if map == "skirmish" else Color(0.22, 0.28, 0.14), "far")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
