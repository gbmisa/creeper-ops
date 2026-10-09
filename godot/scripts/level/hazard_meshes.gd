class_name HazardMeshes
## Procedural meshes for enemy structures and set pieces. Animated parts are named children.




static func _glow(c: Color, e := 2.5) -> StandardMaterial3D:
	return StructureMeshes.glow(c, e)


static func emitter() -> Node3D:
	var r := Node3D.new()
	ShapeKit.lathe(r, PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.3, 0.5), Vector2(0.9, 0.8), Vector2(1.0, 1.0),
		Vector2(0.0, 1.0)]), RaiderMeshes.chitin(), Vector3.ZERO, 7)
	for i in 5:  # bone ribs curling up round the orb
		var a := i * TAU / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(r, d * 1.2 + Vector3(0, 0.6, 0), d * 1.0 + Vector3(0, 2.0, 0), 0.16, RaiderMeshes.bone())
		ShapeKit.strut(r, d * 1.0 + Vector3(0, 2.0, 0), d * 0.5 + Vector3(0, 2.5, 0), 0.12, RaiderMeshes.bone())
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
	ShapeKit.lathe(r, PackedVector2Array([Vector2(2.3, 0.0), Vector2(1.6, 1.0), Vector2(1.1, 3.0), Vector2(0.8, 5.5),
		Vector2(1.05, 6.4), Vector2(0.6, 7.0), Vector2(0.0, 7.1)]), StructureMeshes.mat(Color("3a3324"), 0.2, 0.5), Vector3.ZERO, 7)
	for i in 4:  # bone thorns
		var a := i * TAU / 4.0 + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(r, d * 1.1 + Vector3(0, 2.0 + i * 1.0, 0), d * 2.2 + Vector3(0, 3.2 + i * 1.0, 0), 0.18, RaiderMeshes.bone())
	for y in [1.6, 4.2]:
		StructureMeshes.ball(r, 0.35, _glow(Color("88ff55"), 1.6), Vector3(1.05, y, 0.6), 8)
	var sac := Node3D.new()
	sac.name = "Sac"
	sac.position.y = 7.6
	r.add_child(sac)
	StructureMeshes.ball(sac, 1.1, _glow(Color("88ff55"), 2.0))
	return r


static func rift() -> Node3D:
	var r := Node3D.new()  # a dark pool ringed by leaning menhirs
	StructureMeshes.cyl(r, 1.6, 1.9, 0.25, StructureMeshes.mat(Color("150a22"), 0.0, 0.4))
	for i in 5:
		var a := i * TAU / 5.0
		var m := ShapeKit.lathe(r, PackedVector2Array([Vector2(0.35, 0.0), Vector2(0.25, 2.2), Vector2(0.0, 2.5)]),
			StructureMeshes.mat(Color("4a4450"), 0.0, 0.9), Vector3(cos(a) * 2.3, 0, sin(a) * 2.3), 4)
		m.rotation = Vector3(sin(a) * 0.15, a, -cos(a) * 0.15)
	var mk := Node3D.new()
	mk.name = "Marker"
	mk.position.y = 1.6
	r.add_child(mk)
	StructureMeshes.torus(mk, 0.9, 1.1, _glow(Color("7a3ad0"), 0.6)).rotation.x = PI / 2.0
	return r


static func nest() -> Node3D:
	var r := Node3D.new()
	ShapeKit.lathe(r, PackedVector2Array([Vector2(2.0, 0.0), Vector2(1.7, 0.5), Vector2(1.1, 1.0), Vector2(0.9, 1.3),
		Vector2(0.0, 1.35)]), StructureMeshes.mat(Color("4a3a26"), 0.1, 0.75), Vector3.ZERO, 9)
	for i in 6:  # bone tusks round the mound
		var a := i * TAU / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(r, d * 1.4 + Vector3(0, 0.4, 0), d * 1.9 + Vector3(0, 1.6, 0), 0.16, RaiderMeshes.bone())
	for i in 3:  # fungal caps
		var a := i * TAU / 3.0 + 0.5
		StructureMeshes.ball(r, 0.3, _glow(Color("c060ff"), 1.2), Vector3(cos(a) * 1.4, 0.55, sin(a) * 1.4), 8)
	var sac := Node3D.new()
	sac.name = "Sac"
	sac.position.y = 1.5
	r.add_child(sac)
	StructureMeshes.ball(sac, 0.85, _glow(Color("a8ff5a"), 1.5))
	return r


static func core() -> Node3D:
	var r := Node3D.new()  # a flesh heart caged in bone ribs
	ShapeKit.lathe(r, PackedVector2Array([Vector2(1.9, 0.0), Vector2(1.5, 0.6), Vector2(1.0, 1.0), Vector2(0.0, 1.1)]),
		StructureMeshes.mat(Color("4a1a26"), 0.1, 0.7), Vector3.ZERO, 9)
	for i in 6:
		var a := i * TAU / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(r, d * 1.4 + Vector3(0, 0.6, 0), d * 1.9 + Vector3(0, 2.6, 0), 0.22, RaiderMeshes.bone())
		ShapeKit.strut(r, d * 1.9 + Vector3(0, 2.6, 0), d * 0.6 + Vector3(0, 4.2, 0), 0.18, RaiderMeshes.bone())
	var heart := Node3D.new()
	heart.name = "Heart"
	heart.position.y = 2.6
	r.add_child(heart)
	StructureMeshes.ball(heart, 1.2, _glow(Color("ff3355"), 1.2))
	return r


static func pylon() -> Node3D:
	var r := Node3D.new()  # obsidian obelisk with a bone collar
	ShapeKit.lathe(r, PackedVector2Array([Vector2(0.7, 0.0), Vector2(0.45, 0.3), Vector2(0.3, 2.2), Vector2(0.0, 2.5)]),
		StructureMeshes.mat(Color("2a2730"), 0.2, 0.3), Vector3.ZERO, 4)
	for i in 3:
		var a := i * TAU / 3.0
		ShapeKit.strut(r, Vector3(cos(a) * 0.3, 1.8, sin(a) * 0.3), Vector3(cos(a) * 0.7, 2.9, sin(a) * 0.7), 0.1, RaiderMeshes.bone())
	var crystal := Node3D.new()
	crystal.name = "Crystal"
	crystal.position.y = 3.0
	r.add_child(crystal)
	StructureMeshes.crystal(crystal, 0.4, 1.3, _glow(Color("c070ff"), 1.2))
	return r


## Blight Pylon danger-zone aura: a faint purple ground disc plus a brighter
## perimeter ring at the pylon's damage radius (world units). Added to the
## pylon's node when it finishes growing; it dies with the node.
static func blight_aura(radius_world: float) -> Node3D:
	var r := Node3D.new()
	r.name = "Aura"
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = radius_world
	dm.bottom_radius = radius_world
	dm.height = 0.06
	dm.radial_segments = 48
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.albedo_color = Color(0.42, 0.23, 0.54, 0.10)
	dmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disc.material_override = dmat
	disc.position = Vector3(0, 0.12, 0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(disc)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius_world - 0.5
	tm.outer_radius = radius_world
	tm.rings = 48
	tm.ring_segments = 8
	ring.mesh = tm
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.albedo_color = Color(0.55, 0.32, 0.72, 0.55)
	rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = rmat
	ring.position = Vector3(0, 0.25, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(ring)
	return r


static func pad() -> Node3D:
	var r := Node3D.new()  # rune circle: stone disc, bronze rim, glowing sigil ring, four rune stones
	StructureMeshes.cyl(r, 1.4, 1.5, 0.2, StructureMeshes.pal("stone_dark"), 0.0, 12)
	StructureMeshes.torus(r, 1.35, 1.5, StructureMeshes.pal("bronze"), Vector3(0, 0.2, 0))
	StructureMeshes.torus(r, 0.8, 0.95, StructureMeshes.pal("rune"), Vector3(0, 0.22, 0)).scale.y = 0.3
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		StructureMeshes.box(r, Vector3(0.25, 0.5, 0.25), StructureMeshes.pal("stone"), Vector3(cos(a) * 1.25, 0.45, sin(a) * 1.25))
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


## Raider by tier (RaiderMeshes dispatches on tier.name), facing +X.
static func raider(tier: Dictionary) -> Node3D:
	return RaiderMeshes.make(tier)
