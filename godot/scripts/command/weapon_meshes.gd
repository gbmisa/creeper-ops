class_name WeaponMeshes
## Armed weapons as fantasy siege engines: carved stone tower -> bronze yaw ring ("Turret",
## yawed by WeaponLogic) -> jointed arm ("Arm", pitched by WeaponLogic: shoulder pin, twin
## upper beams, elbow pin, forearm, piston brace) -> weapon head at the wrist ("Muzzle" at
## its tip). Heads point +X. Titans (bertha, thor) are in titan_meshes.gd.



static func build(type: String, root: Node3D) -> bool:
	match type:
		"cannon": cannon(root)
		"mortar": mortar(root)
		"beam": beam(root)
		"sniper": sniper(root)
		"nullifier": nullifier(root)
		"bertha": TitanMeshes.bertha(root)
		"thor": TitanMeshes.thor(root)
		"terp": TitanMeshes.terp(root)
		_: return false
	return true


## Octagonal stone tower with a flared plinth, corbelled lip, bronze band and rune slits.
static func tower(root: Node3D, r: float, h: float, sides := 8) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(r * 1.3, 0.0), Vector2(r * 1.3, 0.3), Vector2(r * 1.02, 0.42),
		Vector2(r * 0.9, h - 0.32), Vector2(r * 1.12, h - 0.18), Vector2(r * 1.12, h), Vector2(0.0, h)]), StructureMeshes.pal("stone"), Vector3.ZERO, sides)
	StructureMeshes.cyl(root, r * 0.97, r * 0.99, 0.14, StructureMeshes.pal("bronze"), h * 0.42, sides)
	for sz in [-1.0, 1.0]:
		StructureMeshes.box(root, Vector3(0.1, h * 0.28, 0.06), StructureMeshes.pal("rune"), Vector3(0, h * 0.68, sz * r * 0.93))


## Bronze yaw ring on the tower top and the oak turntable above it; returns the Turret.
static func yaw(root: Node3D, y: float, r: float) -> Node3D:
	StructureMeshes.cyl(root, r, r * 1.05, 0.14, StructureMeshes.pal("bronze"), y, 16)
	var tur := StructureMeshes._part(root, "Turret", y + 0.14)
	StructureMeshes.cyl(tur, r * 0.85, r * 0.9, 0.16, StructureMeshes.pal("oak"), 0.0, 12)
	return tur


## Jointed arm on `tur`. o: at (shoulder, Vector2 x/y), up/up_a (upper length/angle from +X),
## fore/fore_a, w (half gap of the twin beams), t (beam thickness). Returns the wrist node.
static func arm(tur: Node3D, o: Dictionary, named := true) -> Node3D:
	var at: Vector2 = o.at
	var w: float = o.get("w", 0.2)
	var t: float = o.get("t", 0.18)
	for sz in [-1.0, 1.0]:  # shoulder bracket: two bronze cheek plates
		StructureMeshes.box(tur, Vector3(t * 3.2, at.y + t * 1.5, 0.07), StructureMeshes.pal("bronze_dark"), Vector3(at.x, (at.y + t * 1.5) * 0.5, sz * (w + t)))
	var a := Node3D.new()
	a.name = "Arm" if named else "ArmB"
	a.position = Vector3(at.x, at.y, 0)
	tur.add_child(a)
	var e := Vector3(cos(o.up_a), sin(o.up_a), 0) * float(o.up)
	var wr := e + Vector3(cos(o.fore_a), sin(o.fore_a), 0) * float(o.fore)
	ShapeKit.axle(a, Vector3.ZERO, t * 0.75, (w + t) * 2.0 + 0.1, StructureMeshes.pal("bronze"))
	for sz in [-1.0, 1.0]:
		ShapeKit.strut(a, Vector3(0, 0, sz * w), e + Vector3(0, 0, sz * w), t, StructureMeshes.pal("iron"), t * 0.8)
	ShapeKit.axle(a, e, t * 0.85, w * 2.0 + t * 1.6, StructureMeshes.pal("bronze"))
	ShapeKit.strut(a, e, wr, t * 1.3, StructureMeshes.pal("bronze_dark"))
	var p0 := Vector3(-at.y * 0.35, -at.y * 0.75, 0)  # piston brace from the turntable
	var mid := e * 0.55
	ShapeKit.rod(a, p0, p0.lerp(mid, 0.55), t * 0.55, StructureMeshes.pal("bronze"))
	ShapeKit.rod(a, p0.lerp(mid, 0.5), mid, t * 0.32, StructureMeshes.pal("iron"))
	var head := Node3D.new()
	head.position = wr
	a.add_child(head)
	StructureMeshes.ball(head, t * 0.9, StructureMeshes.pal("bronze"), Vector3.ZERO, 8)
	return head


static func muzzle(head: Node3D, at: Vector3) -> void:
	var m := Node3D.new()
	m.name = "Muzzle"
	m.position = at
	head.add_child(m)


## Barrel lathe laid along +X (profile y runs breech -> muzzle).
static func barrel(head: Node3D, profile: PackedVector2Array, m: Material, at := Vector3.ZERO, sides := 12) -> MeshInstance3D:
	var mi := ShapeKit.lathe(head, profile, m, at, sides)
	mi.rotation.z = -PI / 2.0
	return mi


## Pulse Cannon: a bronze bombard with a rune crystal in its breech.
static func cannon(root: Node3D) -> void:
	tower(root, 0.55, 1.7)
	var tur := yaw(root, 1.7, 0.62)
	var h := arm(tur, { "at": Vector2(-0.25, 0.4), "up": 1.3, "up_a": 1.4, "fore": 0.45, "fore_a": 0.0 })
	barrel(h, PackedVector2Array([Vector2(0.0, -0.62), Vector2(0.2, -0.56), Vector2(0.27, -0.4), Vector2(0.27, -0.24),
		Vector2(0.19, -0.18), Vector2(0.17, 0.42), Vector2(0.25, 0.48), Vector2(0.25, 0.64), Vector2(0.13, 0.64),
		Vector2(0.11, 0.4)]), StructureMeshes.pal("bronze"))
	for sz in [-1.0, 1.0]:
		StructureMeshes.box(h, Vector3(0.3, 0.26, 0.05), StructureMeshes.pal("iron"), Vector3(0, 0, sz * 0.26))
	StructureMeshes.crystal(h, 0.14, 0.42, StructureMeshes.pal("rune"), Vector3(-0.72, 0, 0)).rotation.z = PI / 2.0
	muzzle(h, Vector3(0.66, 0, 0))


## Mortar: a squat stone mortar bowl in a cradle on a short, heavy arm.
static func mortar(root: Node3D) -> void:
	tower(root, 0.68, 1.3)
	for i in 4:  # merlons round the tower top
		var a := i * TAU / 4.0 + PI / 4.0
		StructureMeshes.box(root, Vector3(0.3, 0.35, 0.3), StructureMeshes.pal("stone"), Vector3(cos(a) * 0.68, 1.47, sin(a) * 0.68))
	var tur := yaw(root, 1.3, 0.6)
	var h := arm(tur, { "at": Vector2(-0.3, 0.35), "up": 0.95, "up_a": 1.25, "fore": 0.3, "fore_a": 0.5, "w": 0.28, "t": 0.16 })
	var bowl := Node3D.new()
	bowl.rotation.z = -0.75  # mouth up and forward
	h.add_child(bowl)
	ShapeKit.lathe(bowl, PackedVector2Array([Vector2(0.0, -0.3), Vector2(0.33, -0.27), Vector2(0.44, -0.05),
		Vector2(0.46, 0.2), Vector2(0.4, 0.42), Vector2(0.48, 0.48), Vector2(0.48, 0.6), Vector2(0.3, 0.6),
		Vector2(0.26, 0.25)]), StructureMeshes.pal("iron"), Vector3.ZERO, 10)
	StructureMeshes.torus(bowl, 0.4, 0.5, StructureMeshes.pal("bronze"), Vector3(0, 0.05, 0))
	StructureMeshes.ball(bowl, 0.2, StructureMeshes.glow(Color("ffb347"), 2.2), Vector3(0, 0.32, 0), 8)
	ShapeKit.axle(h, Vector3.ZERO, 0.1, 1.0, StructureMeshes.pal("bronze"))
	muzzle(bowl, Vector3(0, 0.6, 0))


## Beam: a ruby focus crystal held in a bronze claw on a tall staff arm.
static func beam(root: Node3D) -> void:
	tower(root, 0.42, 2.4)
	var tur := yaw(root, 2.4, 0.5)
	var h := arm(tur, { "at": Vector2(-0.15, 0.3), "up": 1.4, "up_a": 1.5, "fore": 0.6, "fore_a": 0.3, "w": 0.13, "t": 0.1 })
	var ruby := StructureMeshes.glow(Color("ff2a2a"), 1.3)
	StructureMeshes.crystal(h, 0.2, 0.8, ruby, Vector3(0.45, 0, 0)).rotation.z = -PI / 2.0
	StructureMeshes.torus(h, 0.24, 0.3, StructureMeshes.pal("bronze"), Vector3(0.38, 0, 0)).rotation.z = PI / 2.0
	for i in 3:  # three claw prongs
		var a := i * TAU / 3.0
		var off := Vector3(0, cos(a), sin(a))
		ShapeKit.strut(h, Vector3.ZERO, Vector3(0.3, 0, 0) + off * 0.32, 0.06, StructureMeshes.pal("bronze"))
		ShapeKit.strut(h, Vector3(0.3, 0, 0) + off * 0.32, Vector3(0.62, 0, 0) + off * 0.16, 0.05, StructureMeshes.pal("bronze"))
	muzzle(h, Vector3(0.85, 0, 0))


## Sniper: a long arbalest (ballista) with spread bow limbs and a rune-tipped bolt.
static func sniper(root: Node3D) -> void:
	tower(root, 0.42, 2.2, 6)
	var tur := yaw(root, 2.2, 0.5)
	var h := arm(tur, { "at": Vector2(-0.3, 0.3), "up": 1.35, "up_a": 1.3, "fore": 0.3, "fore_a": 0.0, "w": 0.16 })
	StructureMeshes.box(h, Vector3(1.8, 0.14, 0.16), StructureMeshes.pal("oak"), Vector3(0.1, 0.05, 0))
	StructureMeshes.box(h, Vector3(0.25, 0.22, 0.24), StructureMeshes.pal("bronze"), Vector3(-0.55, 0.05, 0))
	for sz in [-1.0, 1.0]:
		var tip := Vector3(0.55, 0.1, sz * 0.75)
		ShapeKit.strut(h, Vector3(0.85, 0.08, sz * 0.05), tip, 0.07, StructureMeshes.pal("bronze_dark"))
		ShapeKit.rod(h, tip, Vector3(-0.2, 0.1, 0), 0.012, StructureMeshes.pal("iron"), 4)
	ShapeKit.rod(h, Vector3(-0.2, 0.16, 0), Vector3(0.95, 0.16, 0), 0.03, StructureMeshes.pal("oak"), 6)
	StructureMeshes.crystal(h, 0.06, 0.24, StructureMeshes.pal("rune"), Vector3(1.02, 0.16, 0)).rotation.z = -PI / 2.0
	muzzle(h, Vector3(1.1, 0.16, 0))


## Nullifier: three stone claw-arms on a rune plinth cradling the void crystal ("Core").
static func nullifier(root: Node3D) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.95, 0.0), Vector2(0.95, 0.25), Vector2(0.75, 0.4),
		Vector2(0.7, 0.9), Vector2(0.0, 0.9)]), StructureMeshes.pal("stone"), Vector3.ZERO, 6)
	StructureMeshes.cyl(root, 0.72, 0.72, 0.1, StructureMeshes.glow(Color("c070ff"), 1.4), 0.55, 6)
	for i in 3:
		var a := i * TAU / 3.0 + PI / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		var s := d * 0.6 + Vector3(0, 0.9, 0)
		var e := d * 0.95 + Vector3(0, 2.4, 0)
		var tip := d * 0.42 + Vector3(0, 3.7, 0)
		ShapeKit.strut(root, s, e, 0.2, StructureMeshes.pal("stone"))
		StructureMeshes.ball(root, 0.16, StructureMeshes.pal("bronze"), e, 8)
		ShapeKit.strut(root, e, tip, 0.14, StructureMeshes.pal("bronze_dark"))
		StructureMeshes.crystal(root, 0.07, 0.3, StructureMeshes.pal("rune"), tip + Vector3(0, 0.15, 0))
	var core := StructureMeshes._part(root, "Core", 2.75)
	StructureMeshes.crystal(core, 0.42, 1.2, StructureMeshes.glow(Color("c070ff"), 2.6))
	StructureMeshes.ball(core, 0.18, StructureMeshes.glow(Color("f0d0ff"), 3.0), Vector3.ZERO, 8)
