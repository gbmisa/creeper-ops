class_name FpArms
extends Node3D
## Viewmodel arms: a second body.glb (only `Arms` drawn) under the camera. Two-bone IK puts each hand bone on the
## gun's grip_r / grip_l (gun model space, WeaponDefs); the left hand goes to mag_l during a reload, or follows
## the ReloadTimeline (FB-R) on guns that have one.
## Fingers are curled around the grip. Everything is solved per frame from the gun model's transform.

const ROOT_POS := Vector3(0, -1.62, -0.02)  # shoulders land ~0.2 m out, 0.2 below and 0.04 behind the eye
const MODEL := "res://assets/models/operative/arms_fp.glb"  # body.glb skeleton + Arms only, arms 1.3x longer (Blender)
const POLE := Vector3(0.45, -1.0, 0.5)  # elbows hang down and out (x mirrored per side), a little back
const MAX_LEAN := 0.12  # last resort only (the support hand slides first): shoulders stay out of the view
const SLIDE_REACH := 0.93  # support hand at the hold: slid back along the gun until this share of the arm reaches it
const SLIDE_MAX := 0.3  # m, at most
## Support hand on a handguard (Gregory's hand-posed M4A1, fit from its mesh): wrist 4 cm left of grip_l, fingers wrapped
## across under the handguard to the right, palm up. Not pistols / SMGs (vertical or front grips).
const WRAP_OFF := Vector3(-0.041, -0.018, -0.032)
const WRAP_F := Vector3(0.91, 0.20, -0.36)
const WRAP_N := Vector3(-0.20, 0.98, 0.03)
const NO_WRAP := ["pistol", "smg"]
const CURL := [1.0, 1.15, 0.8]  # finger joint 1..3 curl (rad) around the grip
const FINGERS := ["index", "middle", "ring", "pinky"]
const PALM_DOWN := Vector3(0, -1, 0)  # rest pose: palms down, fingers along the bone's +Y

var skel: Skeleton3D
var _sides := {}
var _def := {}
var _reload := 0.0
var _reload_len := 1.0
var bolt: BoltCycle  # set while the held gun is a bolt-action: the right hand works the handle
var reload_tl: ReloadTimeline  # FB-R: set when the held gun has a reload timeline; it drives the left hand
var target := {}  # side -> world position of the wrist the last solve aimed at (tests)
var roll := 0.0  # viewmodel arms: ArmTwist.SHARE[0] (+ twist bones); 0 = the whole roll at the wrist (bots, as before)


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
	var scene := (load(MODEL) as PackedScene).instantiate() as Node3D
	add_child(scene)
	for ap in scene.find_children("*", "AnimationPlayer", true, false):
		ap.free()
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = mi.name == "Arms"
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skel = scene.find_children("*", "Skeleton3D", true, false)[0]
	var twist := ArmTwist.build(skel, scene.find_children("Arms", "MeshInstance3D", true, false)[0])
	roll = ArmTwist.SHARE[0]
	for side in ["r", "l"]:
		_sides[side] = _rig(side)
		_sides[side]["twist"] = twist[side]


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
	var fwd := Vector3(0, 0, -1)
	var mag_w := 0.0
	if _reload > 0.0:  # left hand fetches the mag early in the reload and stays through the middle
		var t := 1.0 - _reload / _reload_len
		mag_w = smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.8, 1.0, t))
	var hold := _hold_frame()
	var left_t: Vector3 = (hold[0] as Vector3).lerp(_def["mag_l"], mag_w)
	var left_f: Vector3 = hold[1]
	var left_n: Vector3 = hold[2]
	if reload_tl != null:
		mag_w = 0.0
		if reload_tl.playing():
			left_t = reload_tl.hand_l
			left_f = reload_tl.hand_f
			left_n = reload_tl.hand_n
	var grip_r: Vector3 = _def["grip_r"]
	if bolt != null:
		grip_r = bolt.hand_r(grip_r)
	var pos_r := gt * grip_r
	var pos_l := gt * left_t
	if reload_tl == null:
		pos_l = left_hold(gt).lerp(pos_l, mag_w)
	else:
		reload_tl.hold_l = gt.affine_inverse() * left_hold(gt)  # its "grip" anchor: no pop at the start / end
		reload_tl.hold_f = hold[1]
		reload_tl.hold_n = hold[2]
		if not reload_tl.playing():
			pos_l = gt * reload_tl.hold_l
	_lean_in(pos_r, pos_l)
	solve("r", pos_r, gt.basis * fwd, gt.basis * Vector3(-1, 0, 0), 1.0)
	solve("l", pos_l, gt.basis * left_f, gt.basis * left_n, 1.0 - mag_w * 0.7)


## World point the support hand holds at rest: grip_l, slid back along the gun (toward the butt, up to SLIDE_MAX)
## when the arm can't reach it from the shoulder (long guns at the hip: sniper, Mosin, PKM...).
func left_hold(gt: Transform3D) -> Vector3:
	position = ROOT_POS
	var p: Vector3 = gt * (_hold_frame()[0] as Vector3)
	var a: Dictionary = _sides["l"]
	var sh: Vector3 = skel.global_transform * a["rest_up"].origin
	var reach: float = (a["l1"] + a["l2"]) * FpBody.SCALE * SLIDE_REACH
	var back := gt.basis.z.normalized()
	var d := p - sh
	var b := d.dot(back)
	var c := d.length_squared() - reach * reach
	if c <= 0.0 or b * b - c < 0.0:  # in reach already, or never along this line (the lean takes the rest)
		return p
	return p + back * clampf(-b - sqrt(b * b - c), 0.0, SLIDE_MAX)


## Support hand at rest, gun space: [wrist point, finger dir, palm dir] (the wrap on handguard guns).
func _hold_frame() -> Array:
	var gl: Vector3 = _def["grip_l"]
	if String(_def["class"]) in NO_WRAP:
		return [gl, Vector3(0, 0, -1), Vector3(1, 0, 0) if _def["class"] == "pistol" else Vector3(0, 1, 0)]
	return [gl + WRAP_OFF, WRAP_F.normalized(), WRAP_N.normalized()]


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


## World-space wrist target + finger direction + palm normal. pole_w: world elbow direction (default: POLE).
func solve(side: String, pos_w: Vector3, f_w: Vector3, n_w: Vector3, grip: float, pole_w := Vector3.ZERO) -> void:
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
	var pole := ib * (Vector3(POLE.x * (1.0 if side == "r" else -1.0), POLE.y, POLE.z) if pole_w == Vector3.ZERO else pole_w)
	var perp := (pole - dir * pole.dot(dir)).normalized()
	var e := s + dir * along + perp * h
	var wrist := s + dir * d
	var q1: Quaternion = Quaternion((a["rest_lo"].origin - s).normalized(), (e - s).normalized())
	var up_b: Basis = Basis(q1) * a["rest_up"].basis
	skel.set_bone_pose_rotation(a["up"], (a["parent_b"].inverse() * up_b).get_rotation_quaternion())
	var h1: Vector3 = e + q1 * (a["rest_hand"].origin - a["rest_lo"].origin)
	var q2 := Quaternion((h1 - e).normalized(), (wrist - e).normalized())
	var lo_b: Basis = Basis(q2) * Basis(q1) * a["rest_lo"].basis
	var f0: Vector3 = a["rest_hand"].basis.y
	var frame_a := Basis(f0, PALM_DOWN, f0.cross(PALM_DOWN))
	var frame_b := Basis(f, n, f.cross(n))
	var hand_b: Basis = (frame_b * frame_a.inverse() * a["rest_hand"].basis).orthonormalized()
	if roll > 0.0:
		lo_b = _roll_forearm(a, lo_b, hand_b, (wrist - e).normalized())
	skel.set_bone_pose_rotation(a["lo"], (up_b.inverse() * lo_b).get_rotation_quaternion())
	skel.set_bone_pose_rotation(a["hand"], (lo_b.inverse() * hand_b).get_rotation_quaternion())
	for fg in a["fingers"]:
		skel.set_bone_pose_rotation(fg["bone"], (fg["rest"] as Quaternion) * Quaternion(fg["axis"], fg["k"] * grip))


## The forearm rolls about its own length by `roll` of the hand's twist (vs the rest pose), so the wrist skin only
## takes the rest of it. The wrist point stays put (the axis runs through it). Unwrapped against the last frame so
## the split never flips at 180 deg.
func _roll_forearm(a: Dictionary, lo_b: Basis, hand_b: Basis, axis: Vector3) -> Basis:
	var rest_rel: Basis = a["rest_lo"].basis.inverse() * a["rest_hand"].basis
	var q := (hand_b * (lo_b * rest_rel).inverse()).get_rotation_quaternion()
	var tw := wrapf(2.0 * atan2(Vector3(q.x, q.y, q.z).dot(axis), q.w), -PI, PI)
	if a.has("tw"):
		tw = float(a["tw"]) + wrapf(tw - float(a["tw"]), -PI, PI)
	a["tw"] = tw
	var ids: Array = a.get("twist", [])
	for k in ids.size():  # twist bones: children of the lowerarm, rolled about its +Y (the forearm) by their extra share
		skel.set_bone_pose_rotation(ids[k], Quaternion(Vector3.UP, tw * (float(ArmTwist.SHARE[k + 1]) - roll)))
	return (Basis(axis, tw * roll) * lo_b).orthonormalized()


## Where the hand bone is now, in world space.
func hand_pos(side: String) -> Vector3:
	return skel.global_transform * skel.get_bone_global_pose(_sides[side]["hand"]).origin
