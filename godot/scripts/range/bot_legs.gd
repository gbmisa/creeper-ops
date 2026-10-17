class_name BotLegs
extends RefCounted
## Moves an enemy's pelvis (weight on one leg, soft knees when aiming) and keeps both feet where the clip put them:
## two-bone IK per leg in skeleton space, the knee bending in its own plane, the foot keeping its clip rotation.
## Look only (BotBody): hitboxes and the eye are BotPose's.

var skel: Skeleton3D
var _pelvis := -1
var _legs: Array = []  # [thigh, calf, foot] bone ids, left then right
var _rest_inv := Basis.IDENTITY  # the pelvis's rest rotation, inverted


func _init(s: Skeleton3D) -> void:
	skel = s
	_pelvis = s.find_bone("pelvis")
	_rest_inv = s.get_bone_global_rest(_pelvis).basis.inverse()
	for side in ["l", "r"]:
		_legs.append([s.find_bone("thigh_" + side), s.find_bone("calf_" + side), s.find_bone("foot_" + side)])


## The clip's pelvis roll now (rad, about the skeleton's forward axis, vs the rest pose).
func pelvis_roll() -> float:
	return (skel.get_bone_global_pose(_pelvis).basis * _rest_inv).get_euler().z


## off: pelvis move, roll: pelvis tilt (rad) about `axis`; all in skeleton space. Call after the clip has posed the
## legs and before anything reads the upper body (the spine hangs off the pelvis).
func apply(off: Vector3, roll: float, axis: Vector3) -> void:
	if off.length_squared() < 1e-8 and absf(roll) < 1e-4:
		return
	var feet: Array[Transform3D] = []
	for l in _legs:
		feet.append(skel.get_bone_global_pose(l[2]))
	var pg := skel.get_bone_global_pose(_pelvis)
	var parent := skel.get_bone_parent(_pelvis)
	var pb := skel.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	skel.set_bone_pose_position(_pelvis, skel.get_bone_pose_position(_pelvis) + pb.inverse() * off)
	skel.set_bone_pose_rotation(_pelvis, (pb.inverse() * Basis(Quaternion(axis.normalized(), roll)) * pg.basis).get_rotation_quaternion())
	for i in _legs.size():
		_solve(_legs[i], feet[i])


func _solve(l: Array, foot: Transform3D) -> void:
	var tg := skel.get_bone_global_pose(l[0])
	var cg := skel.get_bone_global_pose(l[1])
	var h := tg.origin
	var k := cg.origin
	var u := h - k
	var v := skel.get_bone_global_pose(l[2]).origin - k
	var a := u.length()
	var b := v.length()
	var c := clampf(h.distance_to(foot.origin), absf(a - b) + 0.001, a + b - 0.001)
	var axis := v.cross(u)
	axis = axis.normalized() if axis.length() > 1e-5 else tg.basis.x.normalized()
	var want := acos(clampf((a * a + b * b - c * c) / (2.0 * a * b), -1.0, 1.0))
	var qk := Quaternion(axis, u.angle_to(v) - want)  # opens / closes the knee to the length the foot needs
	var ankle := k + qk * v
	var qh := Quaternion((ankle - h).normalized(), (foot.origin - h).normalized())  # then swings the thigh onto it
	var tb := Basis(qh) * tg.basis
	var cb := Basis(qh) * Basis(qk) * cg.basis
	var pb := skel.get_bone_global_pose(skel.get_bone_parent(l[0])).basis
	skel.set_bone_pose_rotation(l[0], (pb.inverse() * tb).get_rotation_quaternion())
	skel.set_bone_pose_rotation(l[1], (tb.inverse() * cb).get_rotation_quaternion())
	skel.set_bone_pose_rotation(l[2], (cb.inverse() * foot.basis).get_rotation_quaternion())
