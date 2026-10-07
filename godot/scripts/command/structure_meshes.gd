class_name StructureMeshes
## Procedural meshes for every structure. Each returns a body Node3D; animated parts are
## named children: "Spin" (rotates), "Turret" (aims), "Core" (nullifier/charge), "Glow".

const METAL := Color("8a96a6")
const DARK := Color("2f3540")
const ACCENT := Color("5fd4ff")


static func mat(color: Color, metal := 0.6, rough := 0.4, emit := Color.BLACK, emit_e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_e
	return m


static func cyl(parent: Node3D, top: float, bottom: float, h: float, m: Material, y := 0.0, sides := 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = sides
	return _add(parent, c, m, Vector3(0, y + h * 0.5, 0))


static func box(parent: Node3D, size: Vector3, m: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _add(parent, b, m, at)


static func ball(parent: Node3D, r: float, m: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return _add(parent, s, m, at)


static func _add(parent: Node3D, mesh: Mesh, m: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
	return mi


static func _part(parent: Node3D, part_name: String, y := 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = part_name
	n.position.y = y
	parent.add_child(n)
	return n


static func make(type: String) -> Node3D:
	var root := Node3D.new()
	var metal := mat(METAL)
	var dark := mat(DARK, 0.4, 0.6)
	var glow := mat(ACCENT, 0.0, 0.3, ACCENT, 2.5)
	match type:
		"node":
			cyl(root, 2.6, 3.0, 1.0, dark)
			cyl(root, 2.0, 2.5, 1.4, metal, 1.0)
			var spin := _part(root, "Spin", 2.4)
			cyl(spin, 0.3, 1.6, 0.5, metal)
			ball(spin, 0.55, glow, Vector3(0, 0.9, 0))
			for i in 4:
				box(spin, Vector3(0.25, 0.25, 2.6), metal, Vector3(0, 0.3, 0)).rotation.y = i * PI / 4.0
		"collector":
			cyl(root, 0.5, 0.7, 0.4, dark)
			var spin := _part(root, "Spin", 0.4)
			for i in 3:
				var arm := box(spin, Vector3(1.4, 0.08, 0.22), metal, Vector3(0, 0.25, 0))
				arm.rotation.y = i * TAU / 3.0
			ball(spin, 0.22, mat(Color("5dff8a"), 0, 0.3, Color("5dff8a"), 2.0), Vector3(0, 0.45, 0))
		"relay":
			cyl(root, 0.2, 0.55, 2.4, metal)
			var spin := _part(root, "Spin", 2.5)
			box(spin, Vector3(1.2, 0.1, 0.1), metal)
			ball(spin, 0.3, glow, Vector3(0, 0.35, 0))
		"outpost":
			cyl(root, 1.55, 1.75, 0.4, dark)
			cyl(root, 0.45, 0.65, 1.1, metal, 0.4)
			var ring := TorusMesh.new()
			ring.inner_radius = 0.85
			ring.outer_radius = 1.15
			_add(root, ring, glow, Vector3(0, 1.5, 0)).rotation.x = PI / 2.0
			ball(root, 0.2, glow, Vector3(0, 1.65, 0))
		"reactor":
			cyl(root, 0.9, 1.0, 0.6, dark)
			var spin := _part(root, "Spin", 1.1)
			var ring := TorusMesh.new()
			ring.inner_radius = 0.45
			ring.outer_radius = 0.65
			_add(spin, ring, mat(Color("ffb13b"), 0.2, 0.3, Color("ff8a1a"), 2.5), Vector3.ZERO).rotation.x = PI / 2.0
			ball(root, 0.35, mat(Color("ffd27a"), 0, 0.2, Color("ffb13b"), 3.0), Vector3(0, 1.1, 0))
		"storage":
			cyl(root, 0.8, 0.9, 1.0, metal, 0.0, 6)
			cyl(root, 0.65, 0.65, 0.12, glow, 1.0, 6)
		"barracks":
			box(root, Vector3(4.6, 1.6, 4.6), dark, Vector3(0, 0.8, 0))
			box(root, Vector3(3.6, 0.5, 3.6), metal, Vector3(0, 1.85, 0))
			var spin := _part(root, "Spin", 2.3)
			box(spin, Vector3(1.8, 0.12, 0.12), metal)
			ball(root, 0.3, mat(Color("9dff7a"), 0, 0.3, Color("9dff7a"), 2.0), Vector3(1.6, 2.2, 1.6))
		"nullifier":
			cyl(root, 0.7, 1.0, 0.8, dark)
			var core := _part(root, "Core", 1.6)
			ball(core, 0.5, mat(Color("d38cff"), 0, 0.2, Color("b060ff"), 3.0))
			for i in 3:
				box(root, Vector3(0.15, 1.8, 0.15), metal, Vector3(cos(i * TAU / 3) * 0.75, 1.2, sin(i * TAU / 3) * 0.75))
		"cannon":
			cyl(root, 0.55, 0.7, 0.5, dark)
			var tur := _part(root, "Turret", 0.75)
			ball(tur, 0.38, metal)
			box(tur, Vector3(1.1, 0.16, 0.16), metal, Vector3(0.55, 0.05, 0))
			ball(tur, 0.1, mat(Color("fff27a"), 0, 0.3, Color("fff27a"), 3.0), Vector3(1.1, 0.05, 0))
		"mortar":
			cyl(root, 0.75, 0.9, 0.6, dark)
			var tur := _part(root, "Turret", 0.9)
			cyl(tur, 0.32, 0.4, 0.9, metal).rotation.z = -0.5
			ball(tur, 0.2, mat(Color("ffb347"), 0, 0.3, Color("ffb347"), 2.0), Vector3(0, -0.1, 0))
		"beam":
			cyl(root, 0.35, 0.6, 1.0, dark)
			var tur := _part(root, "Turret", 1.3)
			box(tur, Vector3(0.9, 0.22, 0.22), metal, Vector3(0.3, 0, 0))
			ball(tur, 0.18, mat(Color("ff6a6a"), 0, 0.2, Color("ff4040"), 3.0), Vector3(0.8, 0, 0))
		"sniper":
			cyl(root, 0.25, 0.5, 1.4, dark)
			var tur := _part(root, "Turret", 1.6)
			box(tur, Vector3(1.8, 0.1, 0.1), metal, Vector3(0.7, 0, 0))
			box(tur, Vector3(0.4, 0.18, 0.18), dark, Vector3(0.1, 0.12, 0))
		"bertha":
			box(root, Vector3(4.2, 1.0, 4.2), dark, Vector3(0, 0.5, 0))
			var tur := _part(root, "Turret", 1.6)
			ball(tur, 1.0, metal)
			cyl(tur, 0.35, 0.5, 4.0, metal).rotation.z = -1.1
			ball(root, 0.3, glow, Vector3(1.6, 1.2, 1.6))
		"thor":
			var hull := _part(root, "Hull", 0.0)
			box(hull, Vector3(4.4, 0.7, 2.2), metal, Vector3.ZERO)
			box(hull, Vector3(1.6, 0.5, 4.6), dark, Vector3.ZERO)
			var tur := _part(root, "Turret", -0.4)
			box(tur, Vector3(1.6, 0.25, 0.25), metal, Vector3(0.8, 0, 0))
			for sx in [-1.8, 1.8]:
				ball(hull, 0.35, mat(Color("7fe0ff"), 0, 0.2, Color("7fe0ff"), 3.0), Vector3(sx, -0.35, 0))
		"forge":
			box(root, Vector3(8.6, 0.8, 8.6), dark, Vector3(0, 0.4, 0))
			box(root, Vector3(6.4, 1.6, 6.4), metal, Vector3(0, 1.6, 0))
			for i in 4:
				var a := i * TAU / 4.0 + PI / 4.0
				cyl(root, 0.35, 0.5, 3.6, dark, 1.8).position += Vector3(cos(a) * 3.2, 0, sin(a) * 3.2)
			var spin := _part(root, "Spin", 3.0)
			var ring := TorusMesh.new()
			ring.inner_radius = 1.2
			ring.outer_radius = 1.5
			_add(spin, ring, mat(Color("d38cff"), 0.2, 0.3, Color("b060ff"), 2.5), Vector3.ZERO)
			ball(root, 0.7, mat(Color("f0d0ff"), 0, 0.2, Color("c080ff"), 3.0), Vector3(0, 3.0, 0))
		"beacon":
			cyl(root, 0.3, 0.7, 0.3, dark)
			var g := _part(root, "Glow", 0.3)
			cyl(g, 0.12, 0.2, 1.6, mat(Color("66ffcc"), 0, 0.2, Color("116644"), 2.0))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root


## Translucent copy used as the placement / move ghost.
static func ghost(type: String, ok: bool) -> Node3D:
	var g := make(type)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.45, 1.0, 0.8, 0.7) if ok else Color(1.0, 0.35, 0.35, 0.7)
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return g
