class_name SupportMeshes
## Every structure that isn't an armed weapon: the Command Node citadel, collectors, relays,
## outposts, miners, reactor, storage, barracks, Forge and the Totem. Same "Arcane Forge" kit as
## weapon_meshes.gd. Named parts: "Spin", "Glow" (see StructureMeshes).



static func build(type: String, root: Node3D) -> void:
	match type:
		"node": node(root)
		"collector": collector(root)
		"relay": relay(root)
		"outpost", "keep": outpost(root)
		"miner": miner(root)
		"reactor": reactor(root)
		"storage": storage(root)
		"barracks": barracks(root)
		"forge": forge(root)
		"beacon": beacon(root)


## Command Node: the tallest thing you own. Buttressed citadel tower, merlons, banners and a
## turning crown of bronze arms round a great rune crystal.
static func node(root: Node3D) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(2.8, 0.0), Vector2(2.8, 0.7), Vector2(2.3, 0.9),
		Vector2(0.0, 0.9)]), StructureMeshes.pal("stone_dark"), Vector3.ZERO, 8)
	ShapeKit.lathe(root, PackedVector2Array([Vector2(2.1, 0.9), Vector2(1.55, 1.6), Vector2(1.35, 6.6),
		Vector2(1.8, 7.1), Vector2(1.8, 7.6), Vector2(0.0, 7.6)]), StructureMeshes.pal("stone"), Vector3.ZERO, 8)
	StructureMeshes.cyl(root, 1.47, 1.5, 0.2, StructureMeshes.pal("bronze"), 3.6, 8)
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(root, d * 2.55 + Vector3(0, 0.7, 0), d * 1.35 + Vector3(0, 4.2, 0), 0.5, StructureMeshes.pal("stone"))
	for i in 8:
		var a := i * TAU / 8.0 + PI / 8.0
		StructureMeshes.box(root, Vector3(0.5, 0.55, 0.5), StructureMeshes.pal("stone"), Vector3(cos(a) * 1.62, 7.85, sin(a) * 1.62))
	for sz in [-1.0, 1.0]:
		ShapeKit.banner(root, 1.0, 2.6, StructureMeshes.pal("cloth"), Vector3(0, 6.6, sz * 1.42))
		StructureMeshes.box(root, Vector3(0.45, 0.6, 0.06), StructureMeshes.pal("rune"), Vector3(0, 2.4, sz * 1.5))
	var spin := StructureMeshes._part(root, "Spin", 7.6)
	for i in 4:
		var a := i * TAU / 4.0
		var tip := Vector3(cos(a) * 1.2, 1.9, sin(a) * 1.2)
		ShapeKit.strut(spin, Vector3(cos(a) * 0.5, 0.2, sin(a) * 0.5), tip, 0.16, StructureMeshes.pal("bronze"))
		StructureMeshes.crystal(spin, 0.14, 0.5, StructureMeshes.pal("rune"), tip + Vector3(0, 0.25, 0))
	StructureMeshes.torus(spin, 1.0, 1.15, StructureMeshes.pal("bronze_dark"), Vector3(0, 1.2, 0))
	StructureMeshes.crystal(spin, 0.6, 2.4, StructureMeshes.pal("rune_deep"), Vector3(0, 2.5, 0))


## Collector: a rune-well obelisk with three turning bronze vanes round a green crystal.
static func collector(root: Node3D) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.7, 0.0), Vector2(0.7, 0.3), Vector2(0.4, 0.45),
		Vector2(0.26, 1.7), Vector2(0.36, 1.85), Vector2(0.0, 1.85)]), StructureMeshes.pal("stone"), Vector3.ZERO, 6)
	var green := StructureMeshes.glow(Color("5dff8a"), 2.0)
	StructureMeshes.box(root, Vector3(0.08, 0.6, 0.06), green, Vector3(0, 1.0, 0.33))
	var spin := StructureMeshes._part(root, "Spin", 1.85)
	for i in 3:
		var a := i * TAU / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.strut(spin, d * 0.15, d * 0.75 + Vector3(0, 0.3, 0), 0.08, StructureMeshes.pal("bronze"), 0.3)
	StructureMeshes.crystal(spin, 0.18, 0.7, green, Vector3(0, 0.45, 0))


## Relay: a slender stone pylon with a turning bronze yard and three cyan crystals.
static func relay(root: Node3D) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.55, 0.3), Vector2(0.32, 0.45),
		Vector2(0.17, 2.85), Vector2(0.28, 2.95), Vector2(0.0, 2.95)]), StructureMeshes.pal("stone"), Vector3.ZERO, 4)
	StructureMeshes.cyl(root, 0.22, 0.24, 0.12, StructureMeshes.pal("bronze"), 1.6, 8)
	var spin := StructureMeshes._part(root, "Spin", 2.95)
	StructureMeshes.box(spin, Vector3(1.4, 0.1, 0.1), StructureMeshes.pal("bronze"), Vector3(0, 0.1, 0))
	for sx in [-0.7, 0.7]:
		StructureMeshes.crystal(spin, 0.07, 0.3, StructureMeshes.pal("rune"), Vector3(sx, 0.25, 0))
	StructureMeshes.crystal(spin, 0.16, 0.6, StructureMeshes.pal("rune"), Vector3(0, 0.45, 0))


## Outpost: a crenellated stone watchtower with a banner and a cradled rune crystal on top.
static func outpost(root: Node3D) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(2.0, 0.0), Vector2(2.0, 0.4), Vector2(1.4, 0.6),
		Vector2(1.2, 3.4), Vector2(1.5, 3.7), Vector2(1.5, 3.9), Vector2(0.0, 3.9)]), StructureMeshes.pal("stone"), Vector3.ZERO, 10)
	for i in 8:  # crenellated top
		var a := i * TAU / 8.0
		StructureMeshes.box(root, Vector3(0.5, 0.55, 0.4), StructureMeshes.pal("stone"), Vector3(cos(a) * 1.35, 4.15, sin(a) * 1.35)).rotation.y = -a
	for i in 3:  # bronze cradle holding the outpost crystal
		var a := i * TAU / 3.0
		ShapeKit.strut(root, Vector3(cos(a) * 0.9, 3.9, sin(a) * 0.9), Vector3(cos(a) * 0.35, 5.0, sin(a) * 0.35), 0.12, StructureMeshes.pal("bronze"))
	StructureMeshes.crystal(root, 0.42, 1.5, StructureMeshes.pal("rune_deep"), Vector3(0, 5.0, 0))
	for i in 4:
		var a := i * TAU / 4.0
		StructureMeshes.box(root, Vector3(0.12, 0.5, 0.12), StructureMeshes.pal("rune"), Vector3(cos(a) * 1.22, 2.7, sin(a) * 1.22))
	ShapeKit.banner(root, 0.9, 1.6, StructureMeshes.pal("cloth"), Vector3(0, 3.7, 1.32))


## Reactor: an alchemist's kiln with a fire mouth, a chimney and a turning amber ring.
static func reactor(root: Node3D) -> void:
	var amber := StructureMeshes.glow(Color("ffb13b"), 2.5)
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.9, 0.0), Vector2(0.92, 0.6), Vector2(0.75, 1.2),
		Vector2(0.4, 1.6), Vector2(0.0, 1.65)]), StructureMeshes.pal("stone"), Vector3.ZERO, 8)
	StructureMeshes.box(root, Vector3(0.4, 0.45, 0.3), amber, Vector3(0, 0.35, 0.8))
	StructureMeshes.cyl(root, 0.18, 0.22, 1.0, StructureMeshes.pal("stone_dark"), 1.5, 8)
	var spin := StructureMeshes._part(root, "Spin", 2.1)
	StructureMeshes.torus(spin, 0.42, 0.55, StructureMeshes.mat(Color("c98a3a"), 0.8, 0.35, Color("ff8a1a"), 1.2)).rotation.x = PI / 2.0
	StructureMeshes.crystal(root, 0.22, 0.6, amber, Vector3(0, 2.75, 0))


## Storage: a hexagonal rune vault banded in bronze under a bronze lid.
static func storage(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.8, 0.88, 1.7, StructureMeshes.pal("stone"), 0.0, 6)
	for y in [0.3, 1.35]:
		StructureMeshes.cyl(root, 0.84, 0.86, 0.14, StructureMeshes.pal("bronze"), y, 6)
	StructureMeshes.cyl(root, 0.82, 0.82, 0.1, StructureMeshes.pal("rune_soft"), 0.85, 6)
	ShapeKit.cone(root, 0.9, 0.55, StructureMeshes.pal("bronze_dark"), Vector3(0, 1.7, 0), 6)
	StructureMeshes.crystal(root, 0.14, 0.45, StructureMeshes.pal("rune"), Vector3(0, 2.4, 0))


## Barracks: stone guardhouse with a half-timbered upper floor, slate roof and weathervane.
static func barracks(root: Node3D) -> void:
	StructureMeshes.box(root, Vector3(4.8, 0.3, 4.8), StructureMeshes.pal("stone_dark"), Vector3(0, 0.15, 0))
	StructureMeshes.box(root, Vector3(4.4, 1.8, 4.4), StructureMeshes.pal("stone"), Vector3(0, 1.2, 0))
	StructureMeshes.box(root, Vector3(4.6, 1.4, 4.6), StructureMeshes.mat(Color("d8cdb0"), 0.0, 0.9), Vector3(0, 2.8, 0))
	for sz in [-1.0, 1.0]:
		for x in [-2.0, -0.7, 0.7, 2.0]:
			StructureMeshes.box(root, Vector3(0.14, 1.4, 0.06), StructureMeshes.pal("oak"), Vector3(x, 2.8, sz * 2.31))
		StructureMeshes.box(root, Vector3(4.6, 0.14, 0.06), StructureMeshes.pal("oak"), Vector3(0, 3.45, sz * 2.31))
		var roof := StructureMeshes.box(root, Vector3(5.0, 0.16, 3.4), StructureMeshes.pal("slate"), Vector3(0, 4.2, sz * 1.2))
		roof.rotation.x = sz * 0.55
	StructureMeshes.box(root, Vector3(5.1, 0.2, 0.2), StructureMeshes.pal("oak"), Vector3(0, 5.12, 0))  # ridge beam
	StructureMeshes.box(root, Vector3(0.16, 1.0, 2.6), StructureMeshes.pal("stone"), Vector3(-2.2, 4.05, 0))  # gable ends
	StructureMeshes.box(root, Vector3(0.16, 1.0, 2.6), StructureMeshes.pal("stone"), Vector3(2.2, 4.05, 0))
	StructureMeshes.box(root, Vector3(1.0, 1.4, 0.1), StructureMeshes.pal("oak"), Vector3(0, 0.95, 2.22))  # door
	ShapeKit.banner(root, 0.9, 1.2, StructureMeshes.pal("cloth"), Vector3(1.4, 2.0, 2.24))
	StructureMeshes.ball(root, 0.18, StructureMeshes.glow(Color("9dff7a"), 2.0), Vector3(-0.85, 1.6, 2.3), 8)
	var spin := StructureMeshes._part(root, "Spin", 4.9)
	ShapeKit.rod(spin, Vector3.ZERO, Vector3(0, 0.6, 0), 0.03, StructureMeshes.pal("bronze"), 6)
	StructureMeshes.box(spin, Vector3(0.9, 0.06, 0.06), StructureMeshes.pal("bronze"), Vector3(0, 0.5, 0))
	StructureMeshes.box(spin, Vector3(0.05, 0.25, 0.3), StructureMeshes.pal("bronze"), Vector3(-0.42, 0.5, 0))


## Forge: a walled foundry with four slate-roofed towers, a furnace mouth and bronze arms
## holding the turning Aether ring and orb.
static func forge(root: Node3D) -> void:
	var aether := StructureMeshes.glow(Color("9040ff"), 0.9)
	StructureMeshes.box(root, Vector3(9.0, 0.5, 9.0), StructureMeshes.pal("stone_dark"), Vector3(0, 0.25, 0))
	StructureMeshes.box(root, Vector3(6.8, 2.6, 6.8), StructureMeshes.pal("stone"), Vector3(0, 1.8, 0))
	ShapeKit.lathe(root, PackedVector2Array([Vector2(2.6, 3.1), Vector2(2.3, 4.0), Vector2(1.4, 4.8),
		Vector2(0.6, 5.1), Vector2(0.0, 5.1)]), StructureMeshes.pal("bronze_dark"), Vector3.ZERO, 12)
	StructureMeshes.box(root, Vector3(1.8, 1.4, 0.2), StructureMeshes.glow(Color("ff8a2a"), 2.2), Vector3(0, 1.3, 3.35))
	ShapeKit.arch(root, 2.2, 1.0, 0.3, 0.5, StructureMeshes.pal("stone_dark"), Vector3(0, 2.0, 3.45), 5)
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		var p := Vector3(cos(a), 0, sin(a)) * 4.6
		StructureMeshes.cyl(root, 0.75, 0.9, 5.2, StructureMeshes.pal("stone"), 0.0, 8).position += Vector3(p.x, 0, p.z)
		ShapeKit.cone(root, 1.0, 1.6, StructureMeshes.pal("slate"), p + Vector3(0, 5.2, 0), 8)
		ShapeKit.strut(root, p * 0.85 + Vector3(0, 5.0, 0), p * 0.2 + Vector3(0, 6.6, 0), 0.2, StructureMeshes.pal("bronze"))
	var spin := StructureMeshes._part(root, "Spin", 6.9)
	StructureMeshes.torus(spin, 1.2, 1.45, aether)
	StructureMeshes.ball(root, 0.75, StructureMeshes.glow(Color("9a50e0"), 0.9), Vector3(0, 6.9, 0), 16)
	StructureMeshes.box(root, Vector3(1.2, 0.6, 0.6), StructureMeshes.pal("iron"), Vector3(2.2, 3.4, 2.2))  # anvil


## Totem: a carved standing stone with a pulsing teal rune ("Glow") and a crystal cap.
static func beacon(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.6, 0.7, 0.3, StructureMeshes.pal("stone_dark"), 0.0, 6)
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.42, 0.3), Vector2(0.26, 2.2), Vector2(0.0, 2.35)]), StructureMeshes.pal("stone"), Vector3.ZERO, 4).rotation.y = PI / 4.0
	var teal := StructureMeshes.glow(Color("66ffcc"), 2.0)
	var g := StructureMeshes._part(root, "Glow", 0.5)
	for sz in [-1.0, 1.0]:
		StructureMeshes.box(g, Vector3(0.1, 1.4, 0.05), teal, Vector3(0, 0.75, sz * 0.27))
	StructureMeshes.crystal(root, 0.14, 0.45, teal, Vector3(0, 2.55, 0))


## Miner: a stone well with a bronze drill and an amber crystal, short enough to read as a machine.
static func miner(root: Node3D) -> void:
	ShapeKit.lathe(root, PackedVector2Array([Vector2(0.75, 0.0), Vector2(0.75, 0.22), Vector2(0.38, 0.4),
		Vector2(0.0, 0.4)]), StructureMeshes.pal("stone"), Vector3.ZERO, 6)
	StructureMeshes.cyl(root, 0.1, 0.16, 0.8, StructureMeshes.pal("bronze_dark"), 0.4, 6)
	var spin := StructureMeshes._part(root, "Spin", 1.2)
	StructureMeshes.crystal(spin, 0.2, 0.7, StructureMeshes.glow(Color("e0a24a"), 1.6), Vector3(0, 0.4, 0))
