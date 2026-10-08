class_name TitanMeshes
## Titan siege engines (3x3 footprint, 6-9 m): Big Bertha (great bombard on a crane arm),
## Thor (floating storm rock with a twin arm) and the Terp (geomancer tower whose crane arm
## swings a rune hammer at the ground; "Spin" turns while it works). Built with the
## WeaponMeshes tower/yaw/arm kit.



## Big Bertha: square bastion, wide turntable, crane arm with counterweight, great bombard.
static func bertha(root: Node3D) -> void:
	StructureMeshes.box(root, Vector3(5.2, 0.4, 5.2), StructureMeshes.pal("stone_dark"), Vector3(0, 0.2, 0))
	StructureMeshes.box(root, Vector3(4.6, 1.9, 4.6), StructureMeshes.pal("stone"), Vector3(0, 1.35, 0))
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		StructureMeshes.box(root, Vector3(0.7, 0.55, 0.7), StructureMeshes.pal("stone"), Vector3(cos(a) * 3.0, 2.55, sin(a) * 3.0))
	for sz in [-1.0, 1.0]:
		ShapeKit.banner(root, 1.1, 1.5, StructureMeshes.pal("cloth"), Vector3(0, 2.1, sz * 2.33))
		StructureMeshes.box(root, Vector3(1.3, 0.14, 0.14), StructureMeshes.pal("bronze"), Vector3(0, 2.15, sz * 2.36))
	var tur := WeaponMeshes.yaw(root, 2.3, 1.9)
	StructureMeshes.box(tur, Vector3(1.0, 1.0, 1.4), StructureMeshes.pal("stone_dark"), Vector3(-1.45, 0.66, 0))  # counterweight
	var h := WeaponMeshes.arm(tur, { "at": Vector2(-0.7, 0.75), "up": 3.4, "up_a": 1.2, "fore": 1.3, "fore_a": 0.45, "w": 0.42, "t": 0.26 })
	var e := Vector3(-0.7 + cos(1.2) * 3.4, 0.75 + sin(1.2) * 3.4, 0)
	for sz in [-1.0, 1.0]:  # crane stays from the counterweight to the elbow
		ShapeKit.rod(tur, Vector3(-1.6, 1.15, sz * 0.5), e + Vector3(0, 0, sz * 0.5), 0.04, StructureMeshes.pal("iron"), 4)
	var gun := Node3D.new()
	gun.rotation.z = 0.7
	h.add_child(gun)
	WeaponMeshes.barrel(gun, PackedVector2Array([Vector2(0.0, -1.0), Vector2(0.45, -0.95), Vector2(0.6, -0.7), Vector2(0.6, -0.4),
		Vector2(0.45, -0.3), Vector2(0.4, 0.9), Vector2(0.55, 1.0), Vector2(0.55, 1.3), Vector2(0.3, 1.3),
		Vector2(0.26, 0.9)]), StructureMeshes.pal("bronze"), Vector3(0.3, 0, 0), 14)
	StructureMeshes.torus(gun, 0.42, 0.5, StructureMeshes.pal("bronze_dark"), Vector3(0.9, 0, 0)).rotation.z = PI / 2.0
	StructureMeshes.crystal(gun, 0.3, 0.8, StructureMeshes.pal("rune"), Vector3(-0.95, 0, 0)).rotation.z = PI / 2.0
	WeaponMeshes.muzzle(gun, Vector3(1.6, 0, 0))


## Thor: a floating rock with rune pylons on its rim and a twin arm holding a storm crystal.
static func thor(root: Node3D) -> void:
	var hull := StructureMeshes._part(root, "Hull", 0.0)
	ShapeKit.lathe(hull, PackedVector2Array([Vector2(0.0, -2.4), Vector2(0.9, -1.6), Vector2(1.8, -0.7),
		Vector2(2.4, -0.15), Vector2(2.5, 0.05), Vector2(2.3, 0.3), Vector2(0.0, 0.32)]), StructureMeshes.pal("stone_dark"), Vector3.ZERO, 7)
	StructureMeshes.cyl(hull, 2.35, 2.45, 0.12, StructureMeshes.pal("bronze"), 0.0, 14)
	var storm := StructureMeshes.glow(Color("5fd0ff"), 1.5)
	for i in 3:
		var a := i * TAU / 3.0 + PI / 3.0
		var p := Vector3(cos(a) * 1.9, 0.3, sin(a) * 1.9)
		ShapeKit.lathe(hull, PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.18, 1.6), Vector2(0.0, 1.8)]), StructureMeshes.pal("stone"), p, 4)
		StructureMeshes.crystal(hull, 0.22, 0.8, storm, p + Vector3(0, 2.2, 0))
	StructureMeshes.crystal(hull, 0.3, 1.0, storm, Vector3(0, -2.5, 0)).rotation.z = PI  # keel shard
	var tur := WeaponMeshes.yaw(hull, 0.32, 1.0)
	var h := WeaponMeshes.arm(tur, { "at": Vector2(-0.5, 0.3), "up": 2.0, "up_a": 1.25, "fore": 0.9, "fore_a": 0.2, "w": 0.55, "t": 0.2 })
	for sz in [-1.0, 1.0]:  # second forearm from the far beam: the twin grip
		ShapeKit.strut(h, Vector3(-0.8, -0.2, sz * 0.55), Vector3(0.15, 0, sz * 0.3), 0.12, StructureMeshes.pal("oak"))
	StructureMeshes.crystal(h, 0.5, 1.9, storm, Vector3(0.75, 0, 0)).rotation.z = -PI / 2.0
	for x in [0.35, 1.05]:
		StructureMeshes.torus(h, 0.4, 0.5, StructureMeshes.pal("bronze"), Vector3(x, 0, 0)).rotation.z = PI / 2.0
	WeaponMeshes.muzzle(h, Vector3(1.7, 0, 0))


## Terp: geomancer tower. A tall stone shaft with amber earth-runes; on top, a turning crane
## ("Spin") whose jointed arm swings a rune hammer down at the ground.
static func terp(root: Node3D) -> void:
	var amber := StructureMeshes.glow(Color("ffa83a"), 2.2)
	ShapeKit.lathe(root, PackedVector2Array([Vector2(2.4, 0.0), Vector2(2.4, 0.5), Vector2(1.6, 0.8),
		Vector2(1.1, 4.6), Vector2(1.45, 4.9), Vector2(1.45, 5.3), Vector2(0.0, 5.3)]), StructureMeshes.pal("stone"), Vector3.ZERO, 6)
	for i in 6:  # buttresses and earth-rune slits
		var a := i * TAU / 6.0 + PI / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(root, d * 2.2 + Vector3(0, 0.4, 0), d * 1.2 + Vector3(0, 3.0, 0), 0.35, StructureMeshes.pal("stone_dark"))
		if i % 2 == 0:
			StructureMeshes.box(root, Vector3(0.12, 1.2, 0.12), amber, d.rotated(Vector3.UP, PI / 6.0) * 1.22 + Vector3(0, 3.6, 0))
	StructureMeshes.cyl(root, 1.32, 1.36, 0.18, StructureMeshes.pal("bronze"), 2.2, 6)
	var glow := StructureMeshes._part(root, "Glow", 0.5)
	StructureMeshes.crystal(glow, 0.5, 1.2, amber, Vector3(0, 0.3, 0))  # earth-heart in the plinth
	var spin := StructureMeshes._part(root, "Spin", 5.3)
	StructureMeshes.cyl(spin, 1.1, 1.2, 0.2, StructureMeshes.pal("bronze"), 0.0, 12)
	var h := WeaponMeshes.arm(spin, { "at": Vector2(-0.4, 0.4), "up": 1.6, "up_a": 0.8, "fore": 1.8, "fore_a": -0.9, "w": 0.3, "t": 0.18 }, false)
	ShapeKit.rod(h, Vector3(0, 0.3, 0), Vector3(0, -0.9, 0), 0.08, StructureMeshes.pal("oak"), 6)  # hammer haft
	StructureMeshes.box(h, Vector3(0.9, 0.5, 0.55), StructureMeshes.pal("stone_dark"), Vector3(0, -1.1, 0))
	StructureMeshes.box(h, Vector3(0.95, 0.12, 0.6), StructureMeshes.pal("bronze"), Vector3(0, -0.9, 0))
	StructureMeshes.box(h, Vector3(0.95, 0.12, 0.6), StructureMeshes.pal("bronze"), Vector3(0, -1.3, 0))
	StructureMeshes.crystal(h, 0.12, 0.35, amber, Vector3(0, -1.1, 0.3)).rotation.x = PI / 2.0
	StructureMeshes.box(spin, Vector3(0.8, 0.8, 1.0), StructureMeshes.pal("stone_dark"), Vector3(-1.0, 0.6, 0))  # counterweight
