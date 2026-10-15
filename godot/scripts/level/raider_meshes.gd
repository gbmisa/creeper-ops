class_name RaiderMeshes
## Blight raiders, facing +X, standing on y = 0: chitin, bone and fungal glow in the tier
## colour. Dispatch on tier.name: Skitter (low spider), Brute (horned beetle), Ravager
## (mantis with scythes), Behemoth (hulking tusked quadruped), Sentinel (tall robed archer
## with a spine-bow). Unknown names fall back to a generic six-legged bug. <= 15 meshes each.



static func chitin() -> StandardMaterial3D:
	return StructureMeshes.mat(Color("4a3242"), 0.05, 0.85)


## Sickly Blight green: every tier carries it (eyes, fungus), the tier colour marks the rank.
static func sick() -> StandardMaterial3D:
	return StructureMeshes.glow(Color("6fd820"), 1.0)


static func plate() -> StandardMaterial3D:
	return StructureMeshes.mat(Color("6a5a48"), 0.0, 0.95)


static func bone() -> StandardMaterial3D:
	return StructureMeshes.mat(Color("cbbd96"), 0.0, 0.7)


static func make(tier: Dictionary) -> Node3D:
	var glow := CreatureAnim.creature_glow(tier.color)
	var anim := CreatureAnim.make(CreatureAnim.id_of(str(tier.get("name", ""))), anim_scale(tier), glow)
	if anim != null:
		return anim
	var root := Node3D.new()
	var s: float = tier.size
	match tier.get("name", ""):
		"Skitter": _skitter(root, s * 2.0, glow)
		"Brute": _brute(root, s * 1.8, glow)
		"Ravager": _ravager(root, s * 1.8, glow)
		"Behemoth": _behemoth(root, s * 1.7, glow)
		"Sentinel": _sentinel(root, glow)  # fixed 2.4 m design height, whatever its hit size
		"Spitter", "Lancer", "Warden", "Spotter", "Burrower":
			RaiderMeshesRanged.add(root, tier.name, s * 1.8, glow)
		_: _bug(root, s, glow)
	return root


## The scale Opus authors the .glb at (u=1, same unit the procedural builders take):
## the same tier.size * k the procedural mesh uses; Sentinel is a fixed design.
static func anim_scale(tier: Dictionary) -> float:
	var s: float = tier.size
	match str(tier.get("name", "")):
		"Skitter":
			return s * 2.0
		"Brute", "Ravager":
			return s * 1.8
		"Behemoth":
			return s * 1.7
		"Sentinel":
			return 1.0
		"Spitter", "Lancer", "Warden", "Spotter", "Burrower":
			return s * 1.8
		_:
			return s


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
	var abd := StructureMeshes.ball(r, 0.3 * u, chitin(), Vector3(-0.22, 0.36, 0) * u, 7)
	abd.scale = Vector3(1.35, 0.7, 1.0)
	StructureMeshes.ball(r, 0.11 * u, glow, Vector3(-0.32, 0.52, 0) * u, 6)  # tier spore gland
	for sz in [-1.0, 1.0]:  # green pustules on the abdomen flanks
		StructureMeshes.ball(r, 0.08 * u, sick(), Vector3(-0.15, 0.45, sz * 0.2) * u, 5)
	StructureMeshes.ball(r, 0.15 * u, chitin(), Vector3(0.18, 0.3, 0) * u, 6)
	StructureMeshes.ball(r, 0.07 * u, sick(), Vector3(0.3, 0.34, 0) * u, 5)
	for sz in [-1.0, 1.0]:
		for x in [0.15, -0.12]:
			_leg(r, Vector3(x, 0.32, sz * 0.1) * u, Vector3(x * 3.2, 0.0, sz * 0.6) * u, 0.5 * u, 0.04 * u, chitin())
		ShapeKit.taper(r, Vector3(0.28, 0.27, sz * 0.06) * u, Vector3(0.48, 0.12, sz * 0.02) * u, 0.03 * u, 0.005, bone(), 4)


static func _brute(r: Node3D, u: float, glow: Material) -> void:
	StructureMeshes.ball(r, 0.3 * u, glow, Vector3(0, 0.38, 0) * u, 6)  # glowing belly under the shell
	var shell := ShapeKit.lathe(r, _p([Vector2(0.52, 0.0), Vector2(0.5, 0.18), Vector2(0.38, 0.38),
		Vector2(0.16, 0.5), Vector2(0.0, 0.52)], u), chitin(), Vector3(-0.05, 0.32, 0) * u, 7)
	shell.scale = Vector3(1.3, 1.0, 1.0)
	for x in [-0.35, 0.05]:  # bone plates along the ridge
		ShapeKit.taper(r, Vector3(x, 0.78, 0) * u, Vector3(x - 0.15, 1.05, 0) * u, 0.16 * u, 0.02, plate(), 4)
	StructureMeshes.ball(r, 0.2 * u, sick(), Vector3(-0.45, 0.62, 0.25) * u, 5)  # fungal blooms
	StructureMeshes.ball(r, 0.14 * u, sick(), Vector3(-0.2, 0.7, -0.32) * u, 5)
	StructureMeshes.ball(r, 0.2 * u, chitin(), Vector3(0.55, 0.42, 0) * u, 6)
	ShapeKit.horn(r, Vector3(0.62, 0.5, 0) * u, Vector3(0.82, 0.62, 0) * u, Vector3(0.9, 0.9, 0) * u, 0.09 * u, bone())
	StructureMeshes.ball(r, 0.07 * u, sick(), Vector3(0.7, 0.45, 0.12) * u, 5)
	for sz in [-1.0, 1.0]:
		for x in [0.3, -0.35]:
			ShapeKit.taper(r, Vector3(x, 0.4, sz * 0.38) * u, Vector3(x * 1.4, 0.0, sz * 0.75) * u, 0.09 * u, 0.04 * u, chitin())


static func _ravager(r: Node3D, u: float, glow: Material) -> void:
	var abd := StructureMeshes.ball(r, 0.42 * u, chitin(), Vector3(-0.5, 0.6, 0) * u, 7)
	abd.scale = Vector3(1.6, 0.85, 1.0)
	var cara := ShapeKit.lathe(r, _p([Vector2(0.72, 0.0), Vector2(0.62, 0.22), Vector2(0.3, 0.4), Vector2(0.0, 0.44)], u),
		plate(), Vector3(-0.4, 0.78, 0) * u, 7)  # broad armoured carapace over the back
	cara.scale = Vector3(1.45, 1.0, 1.3)
	for sz in [-1.0, 1.0]:  # bone flank plates splaying out from under the carapace
		ShapeKit.taper(r, Vector3(-0.4, 0.85, sz * 0.6) * u, Vector3(-0.55, 0.75, sz * 1.15) * u, 0.2 * u, 0.03, bone(), 4)
	for p in [Vector3(-0.85, 1.12, 0), Vector3(-0.45, 1.2, 0.3), Vector3(-0.45, 1.2, -0.3)]:  # green pustules along the back
		StructureMeshes.ball(r, 0.13 * u, sick(), p * u, 5)
	StructureMeshes.ball(r, 0.1 * u, glow, Vector3(-0.2, 1.05, 0) * u, 5)  # tier gland on the hump
	ShapeKit.strut(r, Vector3(-0.2, 0.55, 0) * u, Vector3(0.2, 1.1, 0) * u, 0.28 * u, chitin())
	ShapeKit.cone(r, 0.15 * u, 0.4 * u, chitin(), Vector3(0.22, 1.12, 0) * u, 6).rotation.z = -1.3
	StructureMeshes.ball(r, 0.1 * u, sick(), Vector3(0.36, 1.18, 0) * u, 5)
	for sz in [-1.0, 1.0]:  # hooked bone scythes and two walking legs a side
		ShapeKit.horn(r, Vector3(0.18, 1.0, sz * 0.15) * u, Vector3(0.6, 1.3, sz * 0.32) * u, Vector3(0.95, 0.5, sz * 0.25) * u, 0.09 * u, bone())
		ShapeKit.taper(r, Vector3(-0.1, 0.55, sz * 0.12) * u, Vector3(0.2, 0.0, sz * 0.6) * u, 0.06 * u, 0.02 * u, chitin())
		ShapeKit.taper(r, Vector3(-0.35, 0.5, sz * 0.12) * u, Vector3(-0.75, 0.0, sz * 0.6) * u, 0.06 * u, 0.02 * u, chitin())


static func _behemoth(r: Node3D, u: float, glow: Material) -> void:
	var body := StructureMeshes.ball(r, 0.6 * u, chitin(), Vector3(-0.1, 0.85, 0) * u, 8)
	body.scale = Vector3(1.4, 0.9, 1.1)
	StructureMeshes.ball(r, 0.3 * u, chitin(), Vector3(0.78, 0.62, 0) * u, 10)
	for i in 3:  # bone plates down the hump
		ShapeKit.cone(r, 0.2 * u, 0.55 * u, plate(), Vector3(-0.5 + i * 0.4, 1.3 - absf(i - 1) * 0.08, 0) * u, 4).rotation.z = 0.35
	for sz in [-1.0, 1.0]:
		StructureMeshes.ball(r, 0.2 * u, sick(), Vector3(-0.35, 1.15, sz * 0.42) * u, 7)  # fungal sacs
		ShapeKit.strut(r, Vector3(0.9, 0.5, sz * 0.15) * u, Vector3(1.25, 0.8, sz * 0.32) * u, 0.07 * u, bone())
		for x in [0.4, -0.6]:
			ShapeKit.rod(r, Vector3(x, 0.7, sz * 0.45) * u, Vector3(x * 1.1, 0.0, sz * 0.55) * u, 0.13 * u, chitin(), 6)
	StructureMeshes.ball(r, 0.1 * u, glow, Vector3(1.04, 0.7, 0) * u, 6)
	StructureMeshes.ball(r, 0.22 * u, glow, Vector3(-0.85, 1.0, 0) * u, 7)  # tier-coloured spore gland


## Sentinel: a tall (2.4 m to the brow) upright robed archer. Its spine-bow is held out from
## the body on the left, strung with green glow, a glowing bolt nocked. Fixed size: the
## tier's hit size never scales the design.
static func _sentinel(r: Node3D, glow: Material) -> void:
	var robe := StructureMeshes.mat(Color("6e3a7c"), 0.0, 0.85)
	ShapeKit.lathe(r, PackedVector2Array([Vector2(0.58, 0.0), Vector2(0.42, 0.5), Vector2(0.28, 1.3), Vector2(0.4, 1.72),
		Vector2(0.44, 1.84), Vector2(0.18, 2.0), Vector2(0.0, 2.02)]), robe, Vector3.ZERO, 7)
	StructureMeshes.cyl(r, 0.5, 0.56, 0.1, sick(), 0.12, 7)  # glowing hem
	ShapeKit.horn(r, Vector3(-0.3, 1.7, 0), Vector3(-0.45, 2.5, 0), Vector3(-0.35, 3.3, 0), 0.1, bone())  # spine crest
	ShapeKit.lathe(r, PackedVector2Array([Vector2(0.16, 1.95), Vector2(0.18, 2.25), Vector2(0.1, 2.5),
		Vector2(0.0, 2.7)]), chitin(), Vector3.ZERO, 6)  # pointed chitin hood
	StructureMeshes.box(r, Vector3(0.05, 0.05, 0.2), sick(), Vector3(0.16, 2.3, 0))  # eye slit
	StructureMeshes.ball(r, 0.11, sick(), Vector3(-0.22, 1.6, 0.12), 5)  # pustule on the back
	for sz in [-1.0, 1.0]:  # bone horns rising off the shoulders
		ShapeKit.horn(r, Vector3(0, 1.82, sz * 0.26), Vector3(-0.05, 2.25, sz * 0.4), Vector3(-0.15, 2.65, sz * 0.36), 0.07, bone())
	var hand := Vector3(0.35, 1.55, -1.05)
	ShapeKit.strut(r, Vector3(0.0, 1.78, -0.28), hand, 0.1, robe)  # bow arm, straight out to the side
	ShapeKit.strut(r, Vector3(0.0, 1.78, 0.28), Vector3(0.0, 1.55, -1.05), 0.09, robe)  # draw hand at the string
	var top := hand + Vector3(-0.2, 1.2, 0)
	var bot := hand + Vector3(-0.2, -1.2, 0)
	ShapeKit.horn(r, hand, hand + Vector3(0.12, 0.7, 0), top, 0.08, bone())  # spine-bow limbs
	ShapeKit.horn(r, hand, hand + Vector3(0.12, -0.7, 0), bot, 0.08, bone())
	ShapeKit.rod(r, top, bot, 0.02, sick(), 4)  # bow string
	ShapeKit.rod(r, Vector3(-0.1, 1.55, -1.05), hand + Vector3(0.7, 0, 0), 0.04, glow, 4)  # nocked bolt in the tier glow


## Fallback: the original six-legged bug.
static func _bug(r: Node3D, s: float, glow: Material) -> void:
	var body := StructureMeshes.ball(r, s * 0.55, chitin(), Vector3(0, s * 0.6, 0))
	body.scale = Vector3(1.5, 0.8, 1.0)
	StructureMeshes.ball(r, s * 0.32, glow, Vector3(s * 0.75, s * 0.65, 0))
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := StructureMeshes.box(r, Vector3(s * 0.12, s * 0.12, s * 0.9), chitin(), Vector3((i - 1) * s * 0.45, s * 0.35, side * s * 0.55))
			leg.rotation.x = side * 0.7
