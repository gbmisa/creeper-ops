class_name HiveMeshes
## Hive part meshes. The berm itself is terrain (HiveShape); these are the Core, pits,
## spitter turrets and the spore launcher. The anchor only exists so the old Sac pulse
## in the spawner still has a node to scale.


static func anchor() -> Node3D:
	var root := Node3D.new()
	var sac := Node3D.new()
	sac.name = "Sac"
	root.add_child(sac)
	return root


static func part(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"core":
			var anim := CreatureAnim.make("core", 1.0, StructureMeshes.glow(Color("ff3355"), 1.4))
			if anim != null:
				root.add_child(anim)
			else:
				_core(root)
		"pit":
			_pit(root)
		"spitter":
			_spitter(root)
		"launcher":
			_launcher(root)
		"mortar":
			_mortar(root)
		"roost":
			_roost(root)
		_:
			StructureMeshes.ball(root, 0.4, StructureMeshes.glow(Color("ff8844"), 1.0), Vector3(0, 0.6, 0))
	return root


static func _core(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.55, 0.8, 0.35, StructureMeshes.mat(Color("4a1a26"), 0.1, 0.6), 0.15)
	for i in 4:
		var a := i * TAU / 4.0
		ShapeKit.strut(root, Vector3(cos(a) * 0.7, 0.3, sin(a) * 0.7), Vector3(cos(a) * 0.2, 1.5, sin(a) * 0.2),
			0.08, RaiderMeshes.bone())
	StructureMeshes.ball(root, 0.42, StructureMeshes.glow(Color("ff3355"), 1.4), Vector3(0, 1.15, 0))


static func _pit(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.85, 0.7, 0.28, StructureMeshes.mat(Color("2a1a14"), 0.0, 0.9), 0.1)
	StructureMeshes.ball(root, 0.22, StructureMeshes.glow(Color("6fd820"), 0.8), Vector3(0, 0.28, 0))


static func _spitter(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.28, 0.4, 0.7, StructureMeshes.mat(Color("3a4a18"), 0.1, 0.55), 0.35)
	StructureMeshes.ball(root, 0.28, StructureMeshes.glow(Color("d6ff3a"), 1.3), Vector3(0.35, 0.85, 0))


static func _launcher(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.2, 0.45, 1.1, StructureMeshes.mat(Color("3a2450"), 0.1, 0.5), 0.55)
	StructureMeshes.ball(root, 0.34, StructureMeshes.glow(Color("c060ff"), 1.2), Vector3(0, 1.35, 0))


static func _mortar(root: Node3D) -> void:
	StructureMeshes.cyl(root, 0.55, 0.7, 0.35, StructureMeshes.mat(Color("2a2420"), 0.05, 0.7), 0.12)
	StructureMeshes.cyl(root, 0.22, 0.28, 1.35, StructureMeshes.mat(Color("4a3028"), 0.15, 0.45), 0.7)
	StructureMeshes.ball(root, 0.2, StructureMeshes.glow(Color("ff4422"), 1.5), Vector3(0.15, 1.55, 0.35))


static func _roost(root: Node3D) -> void:
	var bone := RaiderMeshes.bone()
	StructureMeshes.cyl(root, 0.5, 0.75, 0.3, StructureMeshes.mat(Color("2a2420"), 0.0, 0.9), 0.1)
	for i in 3:  # three bone masts holding a hanging nest
		var a := i * TAU / 3.0
		ShapeKit.taper(root, Vector3(cos(a) * 0.55, 0.2, sin(a) * 0.55), Vector3(cos(a) * 0.15, 2.0, sin(a) * 0.15), 0.07, 0.02, bone, 5)
	var nest := StructureMeshes.ball(root, 0.4, StructureMeshes.mat(Color("3a2a3e"), 0.0, 0.85), Vector3(0, 1.7, 0), 8)
	nest.scale = Vector3(1.2, 0.8, 1.2)
	StructureMeshes.ball(root, 0.16, StructureMeshes.glow(Color("a8ff5a"), 1.2), Vector3(0, 1.55, 0.2), 6)
