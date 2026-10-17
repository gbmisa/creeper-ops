class_name BotRagdoll
## Ragdoll of an enemy body (FB-A, F144): the physical-bone tables, the build, the launch from the live pose.
## Bones sit on LAYER_RAGDOLL (mask WORLD | RAGDOLL) so arms and legs collide with the torso and each other; pairs
## that are jointed or overlap at rest get a collision exception. Nothing else collides with a corpse.
## Local cosmetic only: no multiplayer sync (MULTIPLAYER.md rule 8).

## Hit zone -> physical bone for the death impulse.
const ZONE_BONES := {
	"head": "Head_2", "thorax": "spine_03", "stomach": "spine_01",
	"larm": "upperarm_l", "rarm": "upperarm_r", "lleg": "thigh_l", "rleg": "thigh_r",
}
## bone: [mass kg, capsule radius, joint type, joint params (anatomical ranges, rad)].
## Joint 0 = none (pelvis root); 2 = cone {swing, twist}; 3 = hinge {lower, upper} about the bone's X axis (joint
## frame rotated so hinge-Z == bone-X; knees/elbows can't bend backwards).
const RAGDOLL := {
	"pelvis":     [14.0, 0.14,  0, {}],
	"spine_01":   [7.0,  0.10,  2, {"swing": 0.3, "twist": 0.2}],
	"spine_02":   [7.0,  0.10,  2, {"swing": 0.3, "twist": 0.2}],
	"spine_03":   [9.0,  0.10,  2, {"swing": 0.3, "twist": 0.2}],
	"neck_01":    [2.0,  0.06,  2, {"swing": 0.5, "twist": 0.5}],
	"Head_2":     [4.5,  0.11,  2, {"swing": 0.6, "twist": 0.5}],
	"clavicle_l": [1.0,  0.045, 2, {"swing": 0.25, "twist": 0.15}],
	"clavicle_r": [1.0,  0.045, 2, {"swing": 0.25, "twist": 0.15}],
	"upperarm_l": [2.2,  0.055, 2, {"swing": 1.6, "twist": 1.0}],
	"upperarm_r": [2.2,  0.055, 2, {"swing": 1.6, "twist": 1.0}],
	"lowerarm_l": [1.4,  0.05,  3, {"lower": -2.4, "upper": 0.0}],
	"lowerarm_r": [1.4,  0.05,  3, {"lower": -2.4, "upper": 0.0}],
	"hand_l":     [0.5,  0.05,  2, {"swing": 0.7, "twist": 0.3}],
	"hand_r":     [0.5,  0.05,  2, {"swing": 0.7, "twist": 0.3}],
	"thigh_l":    [8.0,  0.08,  2, {"swing": 1.4, "twist": 0.7}],
	"thigh_r":    [8.0,  0.08,  2, {"swing": 1.4, "twist": 0.7}],
	"calf_l":     [3.5,  0.065, 3, {"lower": 0.0, "upper": 2.4}],
	"calf_r":     [3.5,  0.065, 3, {"lower": 0.0, "upper": 2.4}],
	"foot_l":     [1.0,  0.055, 2, {"swing": 0.6, "twist": 0.3}],
	"foot_r":     [1.0,  0.055, 2, {"swing": 0.6, "twist": 0.3}],
}
## bone -> child bone used to orient the capsule (bone origin -> child joint). Empty = manual capsule.
const CHILD := {
	"pelvis": "", "spine_01": "spine_02", "spine_02": "spine_03", "spine_03": "neck_01",
	"neck_01": "Head_2", "Head_2": "", "clavicle_l": "upperarm_l", "clavicle_r": "upperarm_r",
	"upperarm_l": "lowerarm_l", "upperarm_r": "lowerarm_r",
	"lowerarm_l": "hand_l", "lowerarm_r": "hand_r", "hand_l": "", "hand_r": "",
	"thigh_l": "calf_l", "thigh_r": "calf_r", "calf_l": "foot_l", "calf_r": "foot_r",
	"foot_l": "", "foot_r": "",
}
## Manual capsules for bones without a chain child: [height, center].
const MANUAL := {
	"pelvis": [0.30, Vector3.ZERO],
	"Head_2": [0.24, Vector3(0, 0.06, 0)],
	"hand_l": [0.16, Vector3(0, 0.05, 0)],
	"hand_r": [0.16, Vector3(0, 0.05, 0)],
	"foot_l": [0.22, Vector3(0, 0.08, 0)],
	"foot_r": [0.22, Vector3(0, 0.08, 0)],
}
const OVERLAP_SHRINK := 0.8  # radii scale for the "overlaps at rest" test, so only real overlaps lose collision
const ANIM_DT := 1.0 / 60.0  # the animation is advanced this far at death to read the bones' velocities


## Builds one PhysicalBone3D per RAGDOLL row under `sim`; returns bone name -> PhysicalBone3D.
static func build(skel: Skeleton3D, sim: PhysicalBoneSimulator3D) -> Dictionary:
	var out := {}
	for bone in RAGDOLL:
		var pb := _make_pbone(skel, bone)
		if pb != null:
			sim.add_child(pb)
			out[bone] = pb
	_add_exceptions(skel, out)
	return out


static func _make_pbone(skel: Skeleton3D, bone: String) -> PhysicalBone3D:
	var spec: Array = RAGDOLL[bone]
	var bi := skel.find_bone(bone)
	if bi < 0:
		return null
	var pb := PhysicalBone3D.new()
	pb.bone_name = bone
	pb.mass = spec[0]
	# Corpses are unshootable and untouchable: only the world and other corpse bones collide with them.
	pb.collision_layer = TacticalConfig.LAYER_RAGDOLL
	pb.collision_mask = TacticalConfig.LAYER_WORLD | TacticalConfig.LAYER_RAGDOLL
	pb.linear_damp = TacticalConfig.RAGDOLL_LIN_DAMP
	pb.angular_damp = TacticalConfig.RAGDOLL_ANG_DAMP
	pb.can_sleep = true
	var radius: float = spec[1]
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	var seg := segment_local(skel, bone)
	if CHILD[bone] != "":
		var off: Vector3 = seg[1]
		cap.height = off.length() + radius
		cs.transform = Transform3D(_basis_y_to(off), off * 0.5)
	else:
		cap.height = MANUAL[bone][0]
		cs.position = MANUAL[bone][1]
	cs.shape = cap
	pb.add_child(cs)
	# Park at the bone's rest pose (in skeleton space); die() re-syncs to the live pose.
	pb.transform = skel.get_bone_rest(bi)
	var jt: int = spec[2]
	pb.joint_type = jt
	var jp: Dictionary = spec[3]
	if jt == PhysicalBone3D.JOINT_TYPE_CONE:
		pb.set("joint_constraints/swing_span", jp["swing"])
		pb.set("joint_constraints/twist_span", jp["twist"])
		_soften(pb)
	elif jt == PhysicalBone3D.JOINT_TYPE_HINGE:
		# The hinge rotates about the joint's Z; rotate the joint frame so hinge-Z == bone-X (flexion axis).
		pb.set("joint_rotation", Vector3(0, PI * 0.5, 0))
		pb.set("joint_constraints/angular_limit_enabled", true)
		pb.set("joint_constraints/angular_limit_lower", jp["lower"])
		pb.set("joint_constraints/angular_limit_upper", jp["upper"])
		_soften(pb)
	return pb


static func _soften(pb: PhysicalBone3D) -> void:
	pb.set("joint_constraints/bias", TacticalConfig.RAGDOLL_JOINT_BIAS)
	pb.set("joint_constraints/softness", TacticalConfig.RAGDOLL_JOINT_SOFTNESS)
	pb.set("joint_constraints/relaxation", TacticalConfig.RAGDOLL_JOINT_RELAXATION)


## A bone's capsule axis in the bone's own frame: [start, end].
static func segment_local(skel: Skeleton3D, bone: String) -> Array:
	var child: String = CHILD[bone]
	if child != "":
		return [Vector3.ZERO, skel.get_bone_rest(skel.find_bone(child)).origin]
	var man: Array = MANUAL[bone]
	var half: float = maxf(man[0] * 0.5 - float(RAGDOLL[bone][1]), 0.0)
	return [man[1] - Vector3(0, half, 0), man[1] + Vector3(0, half, 0)]


## No collision between jointed neighbours (nearest ragdoll ancestor) or pairs whose capsules overlap at rest.
static func _add_exceptions(skel: Skeleton3D, pbs: Dictionary) -> void:
	var names: Array = pbs.keys()
	var segs := {}
	for n: String in names:
		var g := skel.get_bone_global_rest(skel.find_bone(n))
		var s := segment_local(skel, n)
		segs[n] = [g * (s[0] as Vector3), g * (s[1] as Vector3)]
	for n: String in names:
		var pi := skel.get_bone_parent(skel.find_bone(n))
		while pi >= 0 and not pbs.has(skel.get_bone_name(pi)):
			pi = skel.get_bone_parent(pi)
		if pi >= 0:
			(pbs[n] as PhysicalBone3D).add_collision_exception_with(pbs[skel.get_bone_name(pi)])
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: String = names[i]
			var b: String = names[j]
			var reach: float = (float(RAGDOLL[a][1]) + float(RAGDOLL[b][1])) * OVERLAP_SHRINK
			if segment_dist(segs[a][0], segs[a][1], segs[b][0], segs[b][1]) < reach:
				(pbs[a] as PhysicalBone3D).add_collision_exception_with(pbs[b])


## Distance between segments p1-q1 and p2-q2.
static func segment_dist(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0
	if a > 1e-9 and e > 1e-9:
		var c := d1.dot(r)
		var bb := d1.dot(d2)
		var den := a * e - bb * bb
		s = clampf((bb * f - c * e) / den, 0.0, 1.0) if den > 1e-9 else 0.0
		t = (bb * s + f) / e
		if t < 0.0:
			t = 0.0
			s = clampf(-c / a, 0.0, 1.0)
		elif t > 1.0:
			t = 1.0
			s = clampf((bb - c) / a, 0.0, 1.0)
	elif a > 1e-9:
		s = clampf(-d1.dot(r) / a, 0.0, 1.0)
	elif e > 1e-9:
		t = clampf(f / e, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(p2 + d2 * t)


## World-space centre of a bone's capsule.
static func capsule_center(pb: PhysicalBone3D) -> Vector3:
	return pb.global_transform * (pb.get_child(0) as CollisionShape3D).position


## Live skeleton-space pose of every bone, in world space.
static func sample(skel: Skeleton3D, pbs: Dictionary) -> Dictionary:
	var out := {}
	for bone in pbs:
		out[bone] = skel.global_transform * skel.get_bone_global_pose(skel.find_bone(bone))
	return out


## Places the bones on `p0` and gives each the velocity it had: the body's own motion plus the animation's
## change from `p0` to `p1` (one ANIM_DT apart), so the body crumples from the pose it was in.
static func launch(sim: PhysicalBoneSimulator3D, pbs: Dictionary, p0: Dictionary, p1: Dictionary, body_vel: Vector3) -> void:
	for bone in pbs:
		var pb: PhysicalBone3D = pbs[bone]
		var a: Transform3D = p0[bone]
		var b: Transform3D = p1[bone]
		pb.global_transform = a
	sim.physical_bones_start_simulation()
	for bone in pbs:
		var pb: PhysicalBone3D = pbs[bone]
		var a: Transform3D = p0[bone]
		var b: Transform3D = p1[bone]
		var q := (b.basis * a.basis.inverse()).get_rotation_quaternion()
		var ang := q.get_axis() * q.get_angle() / ANIM_DT if q.get_angle() > 1e-4 else Vector3.ZERO
		PhysicsServer3D.body_set_state(pb.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, body_vel + (b.origin - a.origin) / ANIM_DT)
		PhysicsServer3D.body_set_state(pb.get_rid(), PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, ang)


static func _basis_y_to(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := y.cross(Vector3(0, 0, 1))
	if x.length() < 0.01:
		x = y.cross(Vector3(1, 0, 0))
	x = x.normalized()
	return Basis(x, y, x.cross(y))
