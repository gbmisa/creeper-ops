class_name HazardMeshes
## Procedural meshes for enemy structures and set pieces. Animated parts are named children.




static func _glow(c: Color, e := 2.5) -> StandardMaterial3D:
	return StructureMeshes.mat(c, 0.0, 0.3, c, e)


static func emitter() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 1.0, 1.5, 0.6, StructureMeshes.mat(Color("1d2a52"), 0.3, 0.5))
	var orb := Node3D.new()
	orb.name = "Orb"
	orb.position.y = 1.4
	r.add_child(orb)
	StructureMeshes.ball(orb, 0.7, _glow(Color("3d7bff"), 3.0))
	return r


static func shield(radius: float) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.83, 0.55, 1.0, 0.25)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A glowing beam between two world points (the Rift -> shielded emitter power link).
static func link(a: Vector3, b: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.18, 0.18, a.distance_to(b))
	mi.mesh = bm
	mi.material_override = Effects.glow_mat(Color(0.5, 0.25, 0.7), 0.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
	return mi


static func vent() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 0.6, 0.9, 0.3, StructureMeshes.mat(Color("2a2a40"), 0.2, 0.7))
	var ring := Node3D.new()
	ring.name = "Ring"
	ring.position.y = 0.4
	r.add_child(ring)
	var t := TorusMesh.new()
	t.inner_radius = 0.5
	t.outer_radius = 0.65
	StructureMeshes._add(ring, t, _glow(Color("3d7bff"), 2.0), Vector3.ZERO)
	return r


static func spire() -> Node3D:
	var r := Node3D.new()
	var shell := StructureMeshes.mat(Color("3a4a2a"), 0.3, 0.6)
	StructureMeshes.cyl(r, 0.9, 2.2, 7.0, shell, 0.0, 8)
	var sac := Node3D.new()
	sac.name = "Sac"
	sac.position.y = 7.6
	r.add_child(sac)
	StructureMeshes.ball(sac, 1.1, _glow(Color("88ff55"), 2.0))
	return r


static func rift() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 1.4, 1.8, 0.3, StructureMeshes.mat(Color("150a22"), 0.0, 0.9))
	var mk := Node3D.new()
	mk.name = "Marker"
	mk.position.y = 1.6
	r.add_child(mk)
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.1
	StructureMeshes._add(mk, t, _glow(Color("b48cff"), 2.5), Vector3.ZERO).rotation.x = PI / 2.0
	return r


static func nest() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 0.9, 1.6, 0.8, StructureMeshes.mat(Color("3a3020"), 0.1, 0.8), 0.0, 9)
	var sac := Node3D.new()
	sac.name = "Sac"
	sac.position.y = 1.2
	r.add_child(sac)
	StructureMeshes.ball(sac, 0.85, _glow(Color("a8ff5a"), 1.5))
	return r


static func core() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 1.2, 1.8, 1.0, StructureMeshes.mat(Color("301018"), 0.3, 0.6))
	var heart := Node3D.new()
	heart.name = "Heart"
	heart.position.y = 2.6
	r.add_child(heart)
	StructureMeshes.ball(heart, 1.2, _glow(Color("ff3355"), 2.5))
	return r


static func pylon() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 0.3, 0.6, 2.2, StructureMeshes.mat(Color("2a2036"), 0.4, 0.5), 0.0, 6)
	var crystal := Node3D.new()
	crystal.name = "Crystal"
	crystal.position.y = 3.0
	r.add_child(crystal)
	StructureMeshes.box(crystal, Vector3(0.6, 1.2, 0.6), _glow(Color("c070ff"), 2.5)).rotation = Vector3(0.6, 0, 0.6)
	return r


static func pad() -> Node3D:
	var r := Node3D.new()
	StructureMeshes.cyl(r, 1.4, 1.5, 0.2, StructureMeshes.mat(Color("2a3450"), 0.6, 0.4))
	StructureMeshes.cyl(r, 1.0, 1.0, 0.05, _glow(Color("6688ff"), 2.0), 0.2)
	return r


static func mite(color := Color("a8ff5a")) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = 0.32
	s.height = 0.64
	s.radial_segments = 10
	s.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = _glow(color, 1.4)
	return mi


## Six-legged bug facing +X, scaled by tier size, glowing in the tier colour.
static func raider(tier: Dictionary) -> Node3D:
	var root := Node3D.new()
	var s: float = tier.size
	var shell := StructureMeshes.mat(Color("1e2414"), 0.2, 0.6)
	var glow := StructureMeshes.mat(tier.color, 0.0, 0.3, tier.color, 2.0)
	var body := StructureMeshes.ball(root, s * 0.55, shell, Vector3(0, s * 0.6, 0))
	body.scale = Vector3(1.5, 0.8, 1.0)
	StructureMeshes.ball(root, s * 0.32, glow, Vector3(s * 0.75, s * 0.65, 0))
	StructureMeshes.ball(root, s * 0.3, glow, Vector3(-s * 0.55, s * 0.85, 0))
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := StructureMeshes.box(root, Vector3(s * 0.12, s * 0.12, s * 0.9), shell,
				Vector3((i - 1) * s * 0.45, s * 0.35, side * s * 0.55))
			leg.rotation.x = side * 0.7
	return root
