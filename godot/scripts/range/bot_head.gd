class_name BotHead
extends RefCounted
## An enemy's neck (BotBody): turns the head back to the front against the bladed torso, levels the gaze (the clips'
## necks were keyed for spines we replace, so crouch-walking bots looked at the sky), then adds the drop onto the
## stock and the glances. Look only: the eye is BotPose's.

const LEVEL := 0.8  # share of the gaze's pitch off level taken out before the extra pitch
const LEAN_BACK := 0.45  # share of the torso's lean roll the neck takes back (head toward upright, onto the stock)

var skel: Skeleton3D
var _neck := -1
var _head := -1
var _up := Vector3.UP
var _axis := Vector3.RIGHT
var _roll := Vector3.BACK  # the neck's forward axis (roll)
var _fwd := Vector3.BACK  # the head's forward in its own frame (the skeleton's +Z at rest: the model faces +Z)


func _init(s: Skeleton3D) -> void:
	skel = s
	_neck = s.find_bone("neck_01")
	_head = s.find_bone("Head_2")
	_up = s.get_bone_global_rest(_neck).basis.inverse() * Vector3.UP
	_axis = s.get_bone_global_rest(_neck).basis.inverse() * Vector3.RIGHT
	_roll = s.get_bone_global_rest(_neck).basis.inverse() * Vector3.BACK
	_fwd = (s.get_bone_global_rest(_head).basis.inverse() * Vector3.BACK).normalized()


## After the clip and the spine: yaw (rad, + toward the bot's -X) and pitch (rad, + down) on top of a level gaze;
## lean: the spine's total lean roll (rad), partly rolled back.
func pose(yaw: float, pitch: float, lean := 0.0) -> void:
	var clip_q := skel.get_bone_pose_rotation(_neck)
	skel.set_bone_pose_rotation(_neck, clip_q * Quaternion(_up, yaw))
	var f := (skel.get_bone_global_pose(_head).basis * _fwd).normalized()
	var level := asin(clampf(f.y, -1.0, 1.0)) * LEVEL  # + = looking up: tip the head down by that much
	skel.set_bone_pose_rotation(_neck, clip_q * Quaternion(_roll, -lean * LEAN_BACK) * Quaternion(_up, yaw) * Quaternion(_axis, level + pitch))
