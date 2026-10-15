class_name FpArms
extends Node3D
## Viewmodel arms: a second body.glb (only `Arms` drawn) under the camera. Two-bone IK puts each hand bone on the
## gun's grip_r / grip_l (gun model space, WeaponDefs); the left hand goes to mag_l during a reload.
## Fingers are curled around the grip. Everything is solved per frame from the gun model's transform.

const ROOT_POS := Vector3(0, -1.62, -0.22)  # shoulders land ~0.2 m out, 0.2 below and 0.15 ahead of the eye
const POLE := Vector3(0.45, -1.0, 0.5)  # elbows hang down and out (x mirrored per side), a little back
const MAX_LEAN := 0.3
const CURL := [1.0, 1.15, 0.8]  # finger joint 1..3 curl (rad) around the grip
const FINGERS := ["index", "middle", "ring", "pinky"]
const PALM_DOWN := Vector3(0, -1, 0)  # rest pose: palms down, fingers along the bone's +Y

var skel: Skeleton3D
var _sides := {}
var _def := {}
var _reload := 0.0
var _reload_len := 1.0
var bolt: BoltCycle  # set while the held gun is a bolt-action: the right hand works the handle
var target := {}  # side -> world position of the wrist the last solve aimed at (tests)


## own_skel: rig an existing skeleton (the enemy bots' bodies) instead of building the viewmodel arms.
func _init(own_skel: Skeleton3D = null) -> void:
	name = "FpArms"
	if own_skel != null:
		skel = own_skel
		for side in ["r", "l"]:
			_sides[side] = _rig(side)
		return
	position = ROOT_POS
	rotation.y = PI
	scale = Vector3.ONE * FpBody.SCALE
	var scene := (load(FpBody.MODEL) as PackedScene).instantiate() as Node3D
	add_child(scene)
	for ap in scene.find_children("*", "AnimationPlayer", true, false):
		ap.free()
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = mi.name == "Arms"
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skel = scene.find_children("*", "Skeleton3D", true, false)[0]
	for side in ["r", "l"]:
		_sides[side] = _rig(side)


func _rig(side: String) -> Dictionary:
	var up := skel.find_bone("upperarm_" + side)
	var lo := skel.find_bone("lowerarm_" + side)
	var hand := skel.find_bone("hand_" + side)
	var a := {"up": up, "lo": lo, "hand": hand, "rest_up": skel.get_bone_global_rest(up), "rest_lo": skel.get_bone_global_rest(lo),
		"rest_hand": skel.get_bone_global_rest(hand), "fingers": []}
	a["parent_b"] = skel.get_bone_global_rest(skel.get_bone_parent(up)).basis
	a["l1"] = a["rest_up"].origin.distance_to(a["rest_lo"].origin)
	a["l2"] = a["rest_lo"].origin.distance_to(a["rest_hand"].origin)
	var f0: Vector3 = a["rest_hand"].basis.y
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		if not n.ends_with("_" + side) or not FINGERS.has(n.split("_")[0]):
			continue
		var j := int(n.split("_")[1]) - 1
		if j < 0 or j > 2:
			continue
		var axis_g := f0.cross(PALM_DOWN)  # curl direction toward the palm
		a["fingers"].append({"bone": i, "k": CURL[j], "axis": skel.get_bone_global_rest(i).basis.inverse() * axis_g,
			"rest": skel.get_bone_rest(i).basis.get_rotation_quaternion()})
	return a


## Re-reads the arm chains' rest data from the skeleton's current pose (arm bones reset), for bodies whose spine moves.
func rebase() -> void:
	for side in _sides:
		var a: Dictionary = _sides[side]
		for k in ["up", "lo", "hand"]:
			skel.reset_bone_pose(a[k])
		a["rest_up"] = skel.get_bone_global_pose(a["up"])
		a["rest_lo"] = skel.get_bone_global_pose(a["lo"])
		a["rest_hand"] = skel.get_bone_global_pose(a["hand"])
		a["parent_b"] = skel.get_bone_global_pose(skel.get_bone_parent(a["up"])).basis


func set_gun(def: Dictionary) -> void:
	_def = def


func reload(secs: float) -> void:
	_reload = secs
	_reload_len = maxf(secs, 0.1)


## gun: the viewmodel's gun node (grip points are in its space).
func update(gun: Node3D, delta: float) -> void:
	if _def.is_empty() or gun == null:
		return
	visible = gun.visible
	_reload = maxf(0.0, _reload - delta)
	var gt := gun.global_transform
	var pistol: bool = _def["class"] == "pistol"
	var fwd := Vector3(0, 0, -1)
	var mag_w := 0.0
	if _reload > 0.0:  # left hand fetches the mag early in the reload and stays through the middle
		var t := 1.0 - _reload / _reload_len
		mag_w = smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.8, 1.0, t))
	var left_t: Vector3 = (_def["grip_l"] as Vector3).lerp(_def["mag_l"], mag_w)
	var left_n := Vector3(1, 0, 0) if pistol else Vector3(0, 1, 0)
	var grip_r: Vector3 = _def["grip_r"]
	if bolt != null:
		grip_r = bolt.hand_r(grip_r)
	var pos_r := gt * grip_r
	var pos_l := gt * left_t
	_lean_in(pos_r, pos_l)
	solve("r", pos_r, gt.basis * fwd, gt.basis * Vector3(-1, 0, 0), 1.0)
	solve("l", pos_l, gt.basis * fwd, gt.basis * left_n, 1.0 - mag_w * 0.7)


## Long guns put a hand beyond arm's reach: the shoulders lean toward the farther target (max MAX_LEAN).
func _lean_in(pos_r: Vector3, pos_l: Vector3) -> void:
	position = ROOT_POS
	for _i in 2:
		var shift := Vector3.ZERO
		for pair in [["r", pos_r], ["l", pos_l]]:
			var a: Dictionary = _sides[pair[0]]
			var sh: Vector3 = skel.global_transform * a["rest_up"].origin
			var reach: float = (a["l1"] + a["l2"]) * FpBody.SCALE * 0.97
			var over := sh.distance_to(pair[1]) - reach
			if over > shift.length():
				shift = (pair[1] - sh).normalized() * over
		position += (get_parent() as Node3D).global_transform.basis.inverse() * shift
		position = ROOT_POS + (position - ROOT_POS).limit_length(MAX_LEAN)


## World-space wrist target + finger direction + palm normal.
func solve(side: String, pos_w: Vector3, f_w: Vector3, n_w: Vector3, grip: float) -> void:
	target[side] = pos_w
	var a: Dictionary = _sides[side]
	var inv := skel.global_transform.affine_inverse()
	var ib := skel.global_transform.basis.orthonormalized().inverse()
	var t: Vector3 = inv * pos_w
	var f := (ib * f_w).normalized()
	var n := (ib * n_w).normalized()
	var s: Vector3 = a["rest_up"].origin
	var l1: float = a["l1"]
	var l2: float = a["l2"]
	var d := clampf(t.distance_to(s), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := (t - s).normalized()
	var along := (l1 * l1 + d * d - l2 * l2) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - along * along, 0.0))
	var pole := ib * Vector3(POLE.x * (1.0 if side == "r" else -1.0), POLE.y, POLE.z)
	var perp := (pole - dir * pole.dot(dir)).normalized()
	var e := s + dir * along + perp * h
	var wrist := s + dir * d
	var q1: Quaternion = Quaternion((a["rest_lo"].origin - s).normalized(), (e - s).normalized())
	var up_b: Basis = Basis(q1) * a["rest_up"].basis
	skel.set_bone_pose_rotation(a["up"], (a["parent_b"].inverse() * up_b).get_rotation_quaternion())
	var h1: Vector3 = e + q1 * (a["rest_hand"].origin - a["rest_lo"].origin)
	var q2 := Quaternion((h1 - e).normalized(), (wrist - e).normalized())
	var lo_b: Basis = Basis(q2) * Basis(q1) * a["rest_lo"].basis
	skel.set_bone_pose_rotation(a["lo"], (up_b.inverse() * lo_b).get_rotation_quaternion())
	var f0: Vector3 = a["rest_hand"].basis.y
	var frame_a := Basis(f0, PALM_DOWN, f0.cross(PALM_DOWN))
	var frame_b := Basis(f, n, f.cross(n))
	var hand_b: Basis = (frame_b * frame_a.inverse() * a["rest_hand"].basis).orthonormalized()
	skel.set_bone_pose_rotation(a["hand"], (lo_b.inverse() * hand_b).get_rotation_quaternion())
	for fg in a["fingers"]:
		skel.set_bone_pose_rotation(fg["bone"], (fg["rest"] as Quaternion) * Quaternion(fg["axis"], fg["k"] * grip))


## Where the hand bone is now, in world space.
func hand_pos(side: String) -> Vector3:
	return skel.global_transform * skel.get_bone_global_pose(_sides[side]["hand"]).origin
