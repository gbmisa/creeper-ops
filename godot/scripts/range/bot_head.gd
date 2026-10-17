class_name BotHead
extends RefCounted
## An enemy's neck (BotBody): turns the head back to the front against the bladed torso, levels the gaze (the clips'
## necks were keyed for spines we replace, so crouch-walking bots looked at the sky), then adds the drop onto the
## stock and the glances. Look only: the eye is BotPose's. While the bot stands or crouches still, `track` keeps the
## visible head on its hitbox (BotBody moves the pelvis and bends the spine by `fix`).

const LEVEL := 0.8  # share of the gaze's pitch off level taken out before the extra pitch
const LEAN_BACK := 0.45  # share of the torso's lean roll the neck takes back (head toward upright, onto the stock)
const FIX_RATE := 12.0  # 1/s: how fast the head is drawn onto its hitbox (exponential)
const FIX_MIN := Vector3(-0.3, -0.15, -0.3)  # m: correction range per axis (bot frame); lift capped by the legs' reach
const FIX_MAX := Vector3(0.3, 0.03, 0.3)
const FIX_FREE := 0.02  # m: the head moves freely this far from its hitbox centre (sway, breathing, glances)

var skel: Skeleton3D
var _neck := -1
var _head := -1
var _up := Vector3.UP
var _axis := Vector3.RIGHT
var _roll := Vector3.BACK  # the neck's forward axis (roll)
var _fwd := Vector3.BACK  # the head's forward in its own frame (the skeleton's +Z at rest: the model faces +Z)
var _centre := Vector3.ZERO  # the head mesh's centre in the head bone's frame
var fix := Vector3.ZERO  # bot-frame move that puts the head on its hitbox (applied by BotBody next frame)


func _init(s: Skeleton3D) -> void:
	skel = s
	_neck = s.find_bone("neck_01")
	_head = s.find_bone("Head_2")
	_up = s.get_bone_global_rest(_neck).basis.inverse() * Vector3.UP
	_axis = s.get_bone_global_rest(_neck).basis.inverse() * Vector3.RIGHT
	_roll = s.get_bone_global_rest(_neck).basis.inverse() * Vector3.BACK
	_fwd = (s.get_bone_global_rest(_head).basis.inverse() * Vector3.BACK).normalized()
	var c := Vector3(0, 1.66, 0)
	for mi in s.get_parent().find_children("Head", "MeshInstance3D", true, false):
		c = (mi as MeshInstance3D).get_aabb().get_center()  # bind pose: skeleton rest space
	_centre = s.get_bone_global_rest(_head).affine_inverse() * c


## The visible head's centre, skeleton space.
func centre() -> Vector3:
	return skel.get_bone_global_pose(_head) * _centre


## err: head centre - hitbox centre (bot frame). on: standing / crouching still (else the fix fades out).
func track(err: Vector3, on: bool, dt: float) -> void:
	var over := Vector3.ZERO
	for i in 3:
		over[i] = signf(err[i]) * maxf(absf(err[i]) - FIX_FREE, 0.0)
	var want := (fix - over).clamp(FIX_MIN, FIX_MAX) if on else Vector3.ZERO
	fix = fix.lerp(want, 1.0 - exp(-dt * FIX_RATE))


## After the clip and the spine: yaw (rad, + toward the bot's -X) and pitch (rad, + down) on top of a level gaze;
## lean: the spine's total lean roll (rad), partly rolled back.
func pose(yaw: float, pitch: float, lean := 0.0) -> void:
	var clip_q := skel.get_bone_pose_rotation(_neck)
	skel.set_bone_pose_rotation(_neck, clip_q * Quaternion(_up, yaw))
	var f := (skel.get_bone_global_pose(_head).basis * _fwd).normalized()
	var level := asin(clampf(f.y, -1.0, 1.0)) * LEVEL  # + = looking up: tip the head down by that much
	skel.set_bone_pose_rotation(_neck, clip_q * Quaternion(_roll, -lean * LEAN_BACK) * Quaternion(_up, yaw) * Quaternion(_axis, level + pitch))
