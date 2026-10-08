class_name RaiderMeshesRanged
## Silhouettes for the Stage 8 roster that are not the original four. Same Blight kit as
## RaiderMeshes (chitin, bone, sick glow, tier colour). Facing +X, feet at y = 0.
## `u` is the tier size already scaled by the caller.


static func add(root: Node3D, name: String, u: float, glow: Material) -> void:
	match name:
		"Spitter": _spitter(root, u, glow)
		"Lancer": _lancer(root, u, glow)
		"Warden": _warden(root, u, glow)
		"Spotter": _spotter(root, u, glow)
		"Burrower": _burrower(root, u, glow)
		_: RaiderMeshes._bug(root, u * 0.5, glow)


## Low body, swollen rear sac, forward nozzle.
static func _spitter(r: Node3D, u: float, glow: Material) -> void:
	var sac := StructureMeshes.ball(r, 0.42 * u, RaiderMeshes.chitin(), Vector3(-0.15, 0.4, 0) * u, 7)
	sac.scale = Vector3(1.4, 0.9, 1.0)
	StructureMeshes.ball(r, 0.22 * u, glow, Vector3(-0.35, 0.55, 0) * u, 6)
	StructureMeshes.ball(r, 0.16 * u, RaiderMeshes.sick(), Vector3(0.25, 0.38, 0) * u, 5)
	ShapeKit.taper(r, Vector3(0.35, 0.36, 0) * u, Vector3(0.85, 0.32, 0) * u, 0.08 * u, 0.02, glow, 5)
	for sz in [-1.0, 1.0]:
		RaiderMeshes._leg(r, Vector3(0.05, 0.3, sz * 0.12) * u, Vector3(0.35, 0.0, sz * 0.45) * u, 0.25 * u, 0.04 * u, RaiderMeshes.chitin())
		RaiderMeshes._leg(r, Vector3(-0.25, 0.28, sz * 0.14) * u, Vector3(-0.45, 0.0, sz * 0.5) * u, 0.2 * u, 0.035 * u, RaiderMeshes.chitin())


## Tall and thin, with a spine lance longer than the body.
static func _lancer(r: Node3D, u: float, glow: Material) -> void:
	ShapeKit.taper(r, Vector3(-0.1, 0.15, 0) * u, Vector3(0.05, 1.15, 0) * u, 0.16 * u, 0.07 * u, RaiderMeshes.chitin(), 6)
	StructureMeshes.ball(r, 0.12 * u, RaiderMeshes.sick(), Vector3(0.08, 1.25, 0) * u, 5)
	ShapeKit.rod(r, Vector3(0.05, 0.7, 0) * u, Vector3(1.7, 0.85, 0) * u, 0.035 * u, glow, 5)
	StructureMeshes.ball(r, 0.06 * u, glow, Vector3(1.75, 0.86, 0) * u, 4)
	for sz in [-1.0, 1.0]:
		RaiderMeshes._leg(r, Vector3(0.0, 0.35, sz * 0.08) * u, Vector3(0.15, 0.0, sz * 0.28) * u, 0.3 * u, 0.03 * u, RaiderMeshes.bone())
		ShapeKit.taper(r, Vector3(-0.05, 0.8, sz * 0.08) * u, Vector3(0.35, 0.55, sz * 0.02) * u, 0.04 * u, 0.01, RaiderMeshes.bone(), 4)


## Broad shield in front, short heavy legs. The aura ring is added on the raider, not here.
static func _warden(r: Node3D, u: float, glow: Material) -> void:
	var body := StructureMeshes.ball(r, 0.34 * u, RaiderMeshes.chitin(), Vector3(-0.05, 0.5, 0) * u, 7)
	body.scale = Vector3(0.8, 1.1, 1.15)
	var shield := StructureMeshes.box(r, Vector3(0.08, 0.7, 0.7) * u, RaiderMeshes.plate(), Vector3(0.32, 0.55, 0) * u)
	shield.rotation.y = 0.15
	StructureMeshes.ball(r, 0.1 * u, glow, Vector3(0.34, 0.85, 0) * u, 5)
	for sz in [-1.0, 1.0]:
		RaiderMeshes._leg(r, Vector3(-0.05, 0.35, sz * 0.18) * u, Vector3(0.05, 0.0, sz * 0.32) * u, 0.2 * u, 0.06 * u, RaiderMeshes.chitin())
		StructureMeshes.ball(r, 0.08 * u, RaiderMeshes.sick(), Vector3(-0.2, 0.7, sz * 0.2) * u, 4)


## Small body on a tall eye stalk.
static func _spotter(r: Node3D, u: float, glow: Material) -> void:
	StructureMeshes.ball(r, 0.22 * u, RaiderMeshes.chitin(), Vector3(0, 0.25, 0) * u, 6)
	ShapeKit.rod(r, Vector3(0, 0.35, 0) * u, Vector3(0.05, 1.15, 0) * u, 0.04 * u, RaiderMeshes.bone(), 5)
	StructureMeshes.ball(r, 0.16 * u, glow, Vector3(0.08, 1.28, 0) * u, 6)
	StructureMeshes.ball(r, 0.06 * u, RaiderMeshes.sick(), Vector3(0.2, 1.3, 0) * u, 4)
	for sz in [-1.0, 1.0]:
		RaiderMeshes._leg(r, Vector3(0, 0.2, sz * 0.08) * u, Vector3(0.2, 0.0, sz * 0.3) * u, 0.15 * u, 0.025 * u, RaiderMeshes.chitin())


## Wedge head, digging claws, almost no height.
static func _burrower(r: Node3D, u: float, glow: Material) -> void:
	var wedge := StructureMeshes.ball(r, 0.28 * u, RaiderMeshes.chitin(), Vector3(0.15, 0.22, 0) * u, 6)
	wedge.scale = Vector3(1.8, 0.45, 0.8)
	StructureMeshes.ball(r, 0.12 * u, glow, Vector3(-0.35, 0.2, 0) * u, 5)
	for sz in [-1.0, 1.0]:
		ShapeKit.horn(r, Vector3(0.4, 0.18, sz * 0.12) * u, Vector3(0.7, 0.08, sz * 0.2) * u, Vector3(0.95, 0.02, sz * 0.08) * u, 0.05 * u, RaiderMeshes.bone())
		RaiderMeshes._leg(r, Vector3(-0.1, 0.16, sz * 0.1) * u, Vector3(-0.35, 0.0, sz * 0.35) * u, 0.12 * u, 0.03 * u, RaiderMeshes.chitin())
