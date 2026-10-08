class_name RaiderMeshes
## Blight raiders, facing +X, standing on y = 0: chitin, bone and fungal glow in the tier
## colour. Dispatch on tier.name: Skitter (low spider), Brute (horned beetle), Ravager
## (mantis with scythes), Behemoth (hulking tusked quadruped), Sentinel (tall robed archer
## with a spine-bow). Unknown names fall back to a generic six-legged bug. <= 15 meshes each.



static func chitin() -> StandardMaterial3D:
	return StructureMeshes.mat(Color("4a3242"), 0.3, 0.38)


static func bone() -> StandardMaterial3D:
	return StructureMeshes.mat(Color("cbbd96"), 0.0, 0.7)


static func make(tier: Dictionary) -> Node3D:
	var root := Node3D.new()
	var s: float = tier.size
	var glow := StructureMeshes.glow(tier.color, 1.4)
	match tier.get("name", ""):
		"Skitter": _skitter(root, s * 2.0, glow)
		"Brute": _brute(root, s * 1.8, glow)
		"Ravager": _ravager(root, s * 1.8, glow)
		"Behemoth": _behemoth(root, s * 1.7, glow)
		"Sentinel": _sentinel(root, s * 1.6, glow)
		_: _bug(root, s, glow)
	return root


static func _p(pts: Array, u: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in pts:
		out.append(v * u)
	return out


## Two-segment leg: hip -> raised knee -> foot.
static func _leg(root: Node3D, hip: Vector3, foot: Vector3, lift: float, t: float, m: Material) -> void:
	var knee := (hip + foot) * 0.5 + Vector3(0, lift, 0)
	ShapeKit.strut(root, hip, knee, t, m)
	ShapeKit.strut(root, knee, foot, t * 0.75, m)


static func _skitter(r: Node3D, u: float, glow: Material) -> void:
	var abd := StructureMeshes.ball(r, 0.3 * u, chitin(), Vector3(-0.22, 0.36, 0) * u, 10)
	abd.scale = Vector3(1.35, 0.7, 1.0)
	StructureMeshes.ball(r, 0.12 * u, glow, Vector3(-0.3, 0.52, 0) * u, 8)
	StructureMeshes.ball(r, 0.15 * u, chitin(), Vector3(0.18, 0.3, 0) * u, 8)
	StructureMeshes.ball(r, 0.07 * u, glow, Vector3(0.3, 0.34, 0) * u, 6)
	for sz in [-1.0, 1.0]:
		for x in [0.15, -0.12]:
			_leg(r, Vector3(x, 0.32, sz * 0.1) * u, Vector3(x * 3.2, 0.0, sz * 0.6) * u, 0.5 * u, 0.04 * u, chitin())
		ShapeKit.strut(r, Vector3(0.28, 0.25, sz * 0.06) * u, Vector3(0.45, 0.12, sz * 0.02) * u, 0.035 * u, bone())


static func _brute(r: Node3D, u: float, glow: Material) -> void:
	StructureMeshes.ball(r, 0.3 * u, glow, Vector3(0, 0.38, 0) * u, 8)  # glowing belly under the shell
	var shell := ShapeKit.lathe(r, _p([Vector2(0.52, 0.0), Vector2(0.5, 0.18), Vector2(0.38, 0.38),
		Vector2(0.16, 0.5), Vector2(0.0, 0.52)], u), chitin(), Vector3(-0.05, 0.32, 0) * u, 9)
	shell.scale = Vector3(1.3, 1.0, 1.0)
	StructureMeshes.ball(r, 0.2 * u, chitin(), Vector3(0.55, 0.42, 0) * u, 8)
	ShapeKit.cone(r, 0.1 * u, 0.5 * u, bone(), Vector3(0.62, 0.5, 0) * u, 6).rotation.z = -1.0
	StructureMeshes.ball(r, 0.06 * u, glow, Vector3(0.7, 0.45, 0.1) * u, 6)
	for sz in [-1.0, 1.0]:
		for x in [0.3, -0.35]:
			_leg(r, Vector3(x, 0.38, sz * 0.35) * u, Vector3(x * 1.4, 0.0, sz * 0.75) * u, 0.15 * u, 0.12 * u, chitin())


static func _ravager(r: Node3D, u: float, glow: Material) -> void:
	var abd := StructureMeshes.ball(r, 0.34 * u, chitin(), Vector3(-0.5, 0.6, 0) * u, 10)
	abd.scale = Vector3(1.6, 0.8, 0.9)
	ShapeKit.strut(r, Vector3(-0.2, 0.55, 0) * u, Vector3(0.2, 1.1, 0) * u, 0.28 * u, chitin())
	ShapeKit.cone(r, 0.15 * u, 0.4 * u, chitin(), Vector3(0.22, 1.12, 0) * u, 6).rotation.z = -1.3
	StructureMeshes.ball(r, 0.09 * u, glow, Vector3(0.36, 1.18, 0) * u, 6)
	ShapeKit.cone(r, 0.08 * u, 0.45 * u, bone(), Vector3(-0.55, 0.72, 0) * u, 5).rotation.z = 0.5  # dorsal spine
	for sz in [-1.0, 1.0]:
		var sh := Vector3(0.18, 1.0, sz * 0.15) * u
		var el := Vector3(0.55, 1.25, sz * 0.3) * u
		ShapeKit.strut(r, sh, el, 0.08 * u, chitin())
		var mid := Vector3(0.9, 1.0, sz * 0.3) * u  # hooked bone scythe
		ShapeKit.strut(r, el, mid, 0.07 * u, bone(), 0.16 * u)
		ShapeKit.strut(r, mid, Vector3(0.95, 0.45, sz * 0.25) * u, 0.06 * u, bone(), 0.14 * u)
		ShapeKit.strut(r, Vector3(-0.1, 0.55, sz * 0.12) * u, Vector3(0.2, 0.0, sz * 0.6) * u, 0.06 * u, chitin())
		ShapeKit.strut(r, Vector3(-0.35, 0.5, sz * 0.12) * u, Vector3(-0.75, 0.0, sz * 0.6) * u, 0.06 * u, chitin())


static func _behemoth(r: Node3D, u: float, glow: Material) -> void:
	var body := StructureMeshes.ball(r, 0.6 * u, chitin(), Vector3(-0.1, 0.85, 0) * u, 12)
	body.scale = Vector3(1.4, 0.9, 1.1)
	StructureMeshes.ball(r, 0.3 * u, chitin(), Vector3(0.78, 0.62, 0) * u, 10)
	for i in 3:  # bone plates down the hump
		ShapeKit.cone(r, 0.16 * u, 0.5 * u, bone(), Vector3(-0.5 + i * 0.4, 1.32 - absf(i - 1) * 0.08, 0) * u, 5).rotation.z = 0.35
	for sz in [-1.0, 1.0]:
		StructureMeshes.ball(r, 0.17 * u, glow, Vector3(-0.35, 1.18, sz * 0.38) * u, 8)  # fungal sacs
		ShapeKit.strut(r, Vector3(0.9, 0.5, sz * 0.15) * u, Vector3(1.25, 0.8, sz * 0.32) * u, 0.07 * u, bone())
		for x in [0.4, -0.6]:
			ShapeKit.rod(r, Vector3(x, 0.7, sz * 0.45) * u, Vector3(x * 1.1, 0.0, sz * 0.55) * u, 0.13 * u, chitin(), 6)
	StructureMeshes.ball(r, 0.07 * u, glow, Vector3(1.04, 0.7, 0) * u, 6)


static func _sentinel(r: Node3D, u: float, glow: Material) -> void:
	var robe := StructureMeshes.mat(Color("2a1630"), 0.0, 0.85)
	ShapeKit.lathe(r, _p([Vector2(0.55, 0.0), Vector2(0.42, 0.5), Vector2(0.26, 1.5),
		Vector2(0.3, 1.9), Vector2(0.18, 2.05), Vector2(0.0, 2.1)], u), robe, Vector3.ZERO, 7)
	ShapeKit.lathe(r, _p([Vector2(0.2, 1.95), Vector2(0.22, 2.2), Vector2(0.1, 2.45),
		Vector2(0.0, 2.6)], u), chitin(), Vector3.ZERO, 6)
	StructureMeshes.box(r, Vector3(0.05, 0.05, 0.18) * u, glow, Vector3(0.19, 2.2, 0) * u)
	for sz in [-1.0, 1.0]:
		ShapeKit.cone(r, 0.08 * u, 0.45 * u, bone(), Vector3(0, 1.9, sz * 0.28) * u, 5).rotation.x = sz * 0.6
	ShapeKit.strut(r, Vector3(0.05, 1.8, -0.25) * u, Vector3(0.55, 1.55, -0.1) * u, 0.09 * u, robe)
	var bow := Vector3(0.6, 1.55, 0) * u
	var pts := [Vector3(-0.12, -0.7, 0), Vector3(0.1, -0.35, 0), Vector3(0.16, 0.0, 0), Vector3(0.1, 0.35, 0), Vector3(-0.12, 0.7, 0)]
	for i in 4:  # spine-bow of bone, string of glow
		ShapeKit.strut(r, bow + pts[i] * u, bow + pts[i + 1] * u, 0.06 * u, bone())
	ShapeKit.rod(r, bow + pts[0] * u, bow + pts[4] * u, 0.02 * u, glow, 4)


## Fallback: the original six-legged bug.
static func _bug(r: Node3D, s: float, glow: Material) -> void:
	var body := StructureMeshes.ball(r, s * 0.55, chitin(), Vector3(0, s * 0.6, 0))
	body.scale = Vector3(1.5, 0.8, 1.0)
	StructureMeshes.ball(r, s * 0.32, glow, Vector3(s * 0.75, s * 0.65, 0))
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := StructureMeshes.box(r, Vector3(s * 0.12, s * 0.12, s * 0.9), chitin(), Vector3((i - 1) * s * 0.45, s * 0.35, side * s * 0.55))
			leg.rotation.x = side * 0.7
