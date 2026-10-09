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
		"trebuchet": trebuchet_p(root)
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
## fore/fore_a, w (half gap of the twin oak beams), t (beam thickness). Bronze knuckles at
## shoulder, elbow and wrist; a bronze piston braces the upper arm. Returns the wrist node.
static func arm(tur: Node3D, o: Dictionary, named := true) -> Node3D:
	var K := StructureMeshes
	var at: Vector2 = o.at
	var t: float = o.get("t", 0.28)
	var w: float = o.get("w", t * 0.45)
	for sz in [-1.0, 1.0]:  # shoulder bracket: two bronze cheek plates
		K.box(tur, Vector3(t * 2.4, at.y + t, 0.08), K.pal("bronze_dark"), Vector3(at.x, (at.y + t) * 0.5, sz * (w + t * 0.7)))
	var a := Node3D.new()
	a.name = "Arm" if named else "ArmB"
	a.position = Vector3(at.x, at.y, 0)
	tur.add_child(a)
	var e := Vector3(cos(o.up_a), sin(o.up_a), 0) * float(o.up)
	var wr := e + Vector3(cos(o.fore_a), sin(o.fore_a), 0) * float(o.fore)
	ShapeKit.axle(a, Vector3.ZERO, t * 0.4, (w + t) * 2.0 + 0.12, K.pal("bronze"))
	K.ball(a, t * 0.75, K.pal("bronze"), Vector3.ZERO, 10)
	for sz in [-1.0, 1.0]:
		ShapeKit.strut(a, Vector3(0, 0, sz * w), e + Vector3(0, 0, sz * w), t * 0.8, K.pal("oak"), t * 0.7)
	K.ball(a, t * 0.7, K.pal("bronze"), e, 10)
	ShapeKit.strut(a, e, wr, t, K.pal("bronze_dark"), t * 0.9)
	var p0 := Vector3(-at.y * 0.4, -at.y * 0.8, 0)  # piston brace from the turntable
	var mid := e * 0.55
	ShapeKit.rod(a, p0, p0.lerp(mid, 0.55), t * 0.32, K.pal("bronze"))
	ShapeKit.rod(a, p0.lerp(mid, 0.5), mid, t * 0.18, K.pal("iron"))
	var head := Node3D.new()
	head.position = wr
	a.add_child(head)
	K.ball(head, t * 0.6, K.pal("bronze"), Vector3.ZERO, 8)
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


## Pulse Cannon: a thick bronze bombard held level, a rune crystal in its breech.
static func cannon(root: Node3D) -> void:
	tower(root, 0.62, 1.6)
	var tur := yaw(root, 1.6, 0.7)
	var h := arm(tur, { "at": Vector2(-0.35, 0.35), "up": 1.25, "up_a": 1.45, "fore": 0.55, "fore_a": 0.15 })
	barrel(h, PackedVector2Array([Vector2(0.0, -0.8), Vector2(0.32, -0.75), Vector2(0.44, -0.55), Vector2(0.44, -0.3),
		Vector2(0.33, -0.22), Vector2(0.3, 0.3), Vector2(0.37, 0.34), Vector2(0.37, 0.46), Vector2(0.29, 0.5),
		Vector2(0.27, 1.0), Vector2(0.43, 1.1), Vector2(0.43, 1.28), Vector2(0.2, 1.28), Vector2(0.17, 0.9)]), StructureMeshes.pal("bronze"), Vector3(0.2, 0, 0), 14)
	for sz in [-1.0, 1.0]:
		StructureMeshes.box(h, Vector3(0.5, 0.4, 0.07), StructureMeshes.pal("iron"), Vector3(0.1, 0, sz * 0.4))
	StructureMeshes.crystal(h, 0.2, 0.55, StructureMeshes.pal("rune"), Vector3(-0.85, 0, 0)).rotation.z = PI / 2.0
	muzzle(h, Vector3(1.5, 0, 0))


## Mortar: a wide, squat iron bowl, mouth to the sky, lifted on a forked cradle at the end
## of a short heavy arm. Verdigris (green-copper) trim sets it apart from the bronze cannon.
static func mortar(root: Node3D) -> void:
	tower(root, 0.74, 1.3)
	var verd := StructureMeshes.mat(Color("4f9a80"), 0.6, 0.5)
	for i in 4:  # merlons round the tower top
		var a := i * TAU / 4.0 + PI / 4.0
		StructureMeshes.box(root, Vector3(0.34, 0.4, 0.34), StructureMeshes.pal("stone"), Vector3(cos(a) * 0.76, 1.5, sin(a) * 0.76))
	var tur := yaw(root, 1.3, 0.66)
	var h := arm(tur, { "at": Vector2(-0.45, 0.3), "up": 1.2, "up_a": 1.3, "fore": 0.55, "fore_a": 0.35, "t": 0.3 })
	for sz in [-1.0, 1.0]:  # cradle fork lifting the bowl clear of the arm
		ShapeKit.strut(h, Vector3.ZERO, Vector3(0.1, 0.45, sz * 1.25), 0.2, StructureMeshes.pal("bronze_dark"))
		ShapeKit.strut(h, Vector3(0.1, 0.45, sz * 1.25), Vector3(0.1, 0.75, sz * 1.25), 0.18, StructureMeshes.pal("bronze_dark"))
		StructureMeshes.ball(h, 0.17, verd, Vector3(0.1, 0.78, sz * 1.25), 8)
	var bowl := Node3D.new()
	bowl.position = Vector3(0.1, 0.45, 0)
	bowl.rotation.z = -0.25  # mouth up, a little forward
	h.add_child(bowl)
	ShapeKit.lathe(bowl, PackedVector2Array([Vector2(0.0, -0.32), Vector2(0.62, -0.3), Vector2(0.88, -0.05),
		Vector2(0.92, 0.18), Vector2(0.84, 0.36), Vector2(0.98, 0.42), Vector2(0.98, 0.58), Vector2(0.66, 0.58),
		Vector2(0.58, 0.2)]), StructureMeshes.pal("iron"), Vector3.ZERO, 14)
	StructureMeshes.torus(bowl, 0.86, 1.0, verd, Vector3(0, 0.05, 0))
	StructureMeshes.ball(bowl, 0.45, StructureMeshes.glow(Color("b84a0c"), 0.5), Vector3(0, 0.25, 0), 10)
	ShapeKit.axle(bowl, Vector3.ZERO, 0.12, 2.5, verd)
	muzzle(bowl, Vector3(0, 0.6, 0))


## Player Trebuchet (castle_only): the enemy war engine's model in player blue, plus a
## Muzzle node so shot effects start at the arm. WeaponLogic throws the arm on each shot.
static func trebuchet_p(root: Node3D) -> void:
	var t := CastleEngineMeshes.trebuchet()
	root.add_child(t)
	var glow := t.get_node_or_null("Glow") as MeshInstance3D
	if glow:
		glow.material_override = StructureMeshes.glow(StrongholdMeshes.PLAYER, 1.8)
	var m := Node3D.new()
	m.name = "Muzzle"
	m.position = Vector3(0, 3.5, 0)
	t.add_child(m)


## Beam: a large cyan lens ring round a ruby focus, held high on a staff arm.
static func beam(root: Node3D) -> void:
	tower(root, 0.48, 2.4)
	var tur := yaw(root, 2.4, 0.56)
	var h := arm(tur, { "at": Vector2(-0.2, 0.3), "up": 1.3, "up_a": 1.4, "fore": 0.7, "fore_a": 0.2, "t": 0.26 })
	var ring := StructureMeshes.torus(h, 0.92, 1.12, StructureMeshes.pal("bronze"), Vector3(0.6, 0, 0))
	ring.rotation.z = PI / 2.0
	var lens := StructureMeshes.torus(h, 0.72, 0.92, StructureMeshes.pal("rune"), Vector3(0.62, 0, 0))
	lens.rotation.z = PI / 2.0
	StructureMeshes.crystal(h, 0.2, 0.7, StructureMeshes.glow(Color("ff3030"), 1.2), Vector3(0.6, 0, 0)).rotation.z = -PI / 2.0
	for i in 3:  # three bronze spokes from the wrist to the ring
		var a := i * TAU / 3.0 + PI / 2.0
		ShapeKit.strut(h, Vector3.ZERO, Vector3(0.6, cos(a) * 1.0, sin(a) * 1.0), 0.09, StructureMeshes.pal("bronze"))
	muzzle(h, Vector3(0.95, 0, 0))


## Sniper: a long horizontal ballista with wide bow limbs and a rune-tipped bolt.
static func sniper(root: Node3D) -> void:
	tower(root, 0.5, 2.0, 6)
	var tur := yaw(root, 2.0, 0.58)
	var h := arm(tur, { "at": Vector2(-0.3, 0.3), "up": 1.3, "up_a": 1.35, "fore": 0.35, "fore_a": 0.0, "t": 0.26 })
	StructureMeshes.box(h, Vector3(3.0, 0.22, 0.24), StructureMeshes.pal("oak"), Vector3(0.5, 0.08, 0))
	StructureMeshes.box(h, Vector3(0.4, 0.32, 0.36), StructureMeshes.pal("bronze"), Vector3(-0.8, 0.08, 0))
	StructureMeshes.box(h, Vector3(0.3, 0.36, 0.4), StructureMeshes.pal("bronze"), Vector3(1.75, 0.08, 0))
	for sz in [-1.0, 1.0]:
		var tip := Vector3(1.15, 0.12, sz * 1.4)
		ShapeKit.strut(h, Vector3(1.75, 0.1, sz * 0.15), tip, 0.13, StructureMeshes.pal("bronze_dark"), 0.18)
		ShapeKit.rod(h, tip, Vector3(-0.3, 0.2, 0), 0.02, StructureMeshes.pal("iron"), 4)
	ShapeKit.rod(h, Vector3(-0.3, 0.24, 0), Vector3(2.0, 0.24, 0), 0.05, StructureMeshes.pal("oak"), 6)
	StructureMeshes.crystal(h, 0.09, 0.35, StructureMeshes.pal("rune"), Vector3(2.12, 0.24, 0)).rotation.z = -PI / 2.0
	muzzle(h, Vector3(2.25, 0.24, 0))


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
	StructureMeshes.ball(core, 0.18, StructureMeshes.glow(Color("d27aff"), 3.0), Vector3.ZERO, 8)
