class_name BotBody
extends Node3D
## An enemy's visible body: body.glb dyed per kind, driven by AnimationPlayer (advanced by hand). Upper-body bone
## tracks are stripped from the shared clips so the spine can pitch with the aim and FpArms' two-bone IK puts both
## hands on the gun's grips. Hitboxes are separate (HitboxRig). Faces -Z, feet at y = 0.

const STRIPPED := ["clavicle_", "upperarm_", "lowerarm_", "hand_", "thumb_", "index_", "middle_", "ring_", "pinky_", "spine_0"]
const SPINE := ["spine_01", "spine_02", "spine_03"]
const BOOTS := Color(0.1, 0.1, 0.09)
const ARMBAND := Color(0.8, 0.1, 0.1)

## Ragdoll (FB-A). Physical bones are built at _init under a PhysicalBoneSimulator3D and sit inert
## until die() starts the simulation from the current pose. Local cosmetic only: no multiplayer
## sync (MULTIPLAYER.md rule 8 — purely cosmetic physics stays local).
## Hit zone -> physical bone for the death impulse.
const ZONE_BONES := {
	"head": "Head_2", "thorax": "spine_03", "stomach": "spine_01",
	"larm": "upperarm_l", "rarm": "upperarm_r", "lleg": "thigh_l", "rleg": "thigh_r",
}
## bone: [mass kg, capsule radius, joint type, joint params].
## Joint 0 = none (pelvis root); 2 = cone {swing, twist} rad; 3 = hinge {lower, upper} rad about
## the bone's X axis (joint frame rotated so hinge-Z == bone-X; knees/elbows can't bend backwards).
const RAGDOLL := {
	"pelvis":     [14.0, 0.14,  0, {}],
	"spine_01":   [7.0,  0.10,  2, {"swing": 0.5, "twist": 0.4}],
	"spine_02":   [7.0,  0.10,  2, {"swing": 0.5, "twist": 0.4}],
	"spine_03":   [9.0,  0.10,  2, {"swing": 0.5, "twist": 0.4}],
	"neck_01":    [2.0,  0.06,  2, {"swing": 0.6, "twist": 0.5}],
	"Head_2":     [4.5,  0.11,  2, {"swing": 0.7, "twist": 0.6}],
	"clavicle_l": [1.0,  0.045, 2, {"swing": 0.4, "twist": 0.3}],
	"clavicle_r": [1.0,  0.045, 2, {"swing": 0.4, "twist": 0.3}],
	"upperarm_l": [2.2,  0.055, 2, {"swing": 1.0, "twist": 0.8}],
	"upperarm_r": [2.2,  0.055, 2, {"swing": 1.0, "twist": 0.8}],
	"lowerarm_l": [1.4,  0.05,  3, {"lower": -2.4, "upper": 0.0}],
	"lowerarm_r": [1.4,  0.05,  3, {"lower": -2.4, "upper": 0.0}],
	"hand_l":     [0.5,  0.05,  2, {"swing": 0.6, "twist": 0.5}],
	"hand_r":     [0.5,  0.05,  2, {"swing": 0.6, "twist": 0.5}],
	"thigh_l":    [8.0,  0.08,  2, {"swing": 1.1, "twist": 0.8}],
	"thigh_r":    [8.0,  0.08,  2, {"swing": 1.1, "twist": 0.8}],
	"calf_l":     [3.5,  0.065, 3, {"lower": 0.0, "upper": 2.4}],
	"calf_r":     [3.5,  0.065, 3, {"lower": 0.0, "upper": 2.4}],
	"foot_l":     [1.0,  0.055, 2, {"swing": 0.7, "twist": 0.5}],
	"foot_r":     [1.0,  0.055, 2, {"swing": 0.7, "twist": 0.5}],
}
## bone -> child bone used to orient the capsule (bone origin -> child joint). Empty = manual capsule.
const RAGDOLL_CHILD := {
	"pelvis": "", "spine_01": "spine_02", "spine_02": "spine_03", "spine_03": "neck_01",
	"neck_01": "Head_2", "Head_2": "", "clavicle_l": "upperarm_l", "clavicle_r": "upperarm_r",
	"upperarm_l": "lowerarm_l", "upperarm_r": "lowerarm_r",
	"lowerarm_l": "hand_l", "lowerarm_r": "hand_r", "hand_l": "", "hand_r": "",
	"thigh_l": "calf_l", "thigh_r": "calf_r", "calf_l": "foot_l", "calf_r": "foot_r",
	"foot_l": "", "foot_r": "",
}
## Manual capsules for bones without a chain child: [height, center].
const RAGDOLL_MANUAL := {
	"pelvis": [0.30, Vector3.ZERO],
	"Head_2": [0.24, Vector3(0, 0.06, 0)],
	"hand_l": [0.16, Vector3(0, 0.05, 0)],
	"hand_r": [0.16, Vector3(0, 0.05, 0)],
	"foot_l": [0.22, Vector3(0, 0.08, 0)],
	"foot_r": [0.22, Vector3(0, 0.08, 0)],
}

static var _lib: AnimationLibrary

var anim: AnimationPlayer
var clip := ""
var dead := false
var skel: Skeleton3D
var arms: FpArms
var pivot: Node3D  # sits on the right shoulder, pitches with the aim; the gun hangs off it
var sim: PhysicalBoneSimulator3D
var _pbones := {}  # bone name -> PhysicalBone3D
var _sleep_t := -1.0
var _spine: Array[int] = []
var _spine_rest: Array[Quaternion] = []
var _spine_axis: Array[Vector3] = []
var _spine_roll: Array[Vector3] = []  # bone-local forward axis (lean)
var _spine_up: Array[Vector3] = []  # bone-local up axis (blade)
var _neck := -1
var _neck_up := Vector3.UP
var _neck_axis := Vector3.RIGHT
var _hold := BotHold.STOCKED
var _engage := 0.0  # 0 lowered .. 1 aimed (BotMesh.raise, eased)
var _calm := 0.0  # 0 low ready .. 1 patrol carry (eased)
var _idle: BotIdle
var _legs: BotLegs
var _lean_reach := 1.0  # sum of the spine bones' heights below the head: roll per bone = asin(offset / this)
var _grip := {}
var _half_len := 0.4
var _flip := false


func _init(uniform: Color) -> void:
	name = "BotBody"
	var scene := (load(FpBody.MODEL) as PackedScene).instantiate() as Node3D
	scene.rotation.y = PI
	add_child(scene)
	skel = scene.find_children("*", "Skeleton3D", true, false)[0]
	anim = scene.find_children("*", "AnimationPlayer", true, false)[0]
	_use_library()
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_dye(scene, uniform)
	for b in SPINE:
		var i := skel.find_bone(b)
		_spine.append(i)
		_spine_rest.append(skel.get_bone_rest(i).basis.get_rotation_quaternion())
		_spine_axis.append(skel.get_bone_global_rest(i).basis.inverse() * Vector3.RIGHT)
		_spine_roll.append(skel.get_bone_global_rest(i).basis.inverse() * Vector3.BACK)
		_spine_up.append(skel.get_bone_global_rest(i).basis.inverse() * Vector3.UP)
	_neck = skel.find_bone("neck_01")
	_neck_up = skel.get_bone_global_rest(_neck).basis.inverse() * Vector3.UP
	_neck_axis = skel.get_bone_global_rest(_neck).basis.inverse() * Vector3.RIGHT
	var head_y := skel.get_bone_global_rest(skel.find_bone("Head_2")).origin.y
	_lean_reach = 0.0
	for i in _spine:
		_lean_reach += head_y - skel.get_bone_global_rest(i).origin.y
	arms = FpArms.new(skel)
	add_child(arms)
	_idle = BotIdle.new(hash(get_instance_id()))
	_legs = BotLegs.new(skel)
	pivot = Node3D.new()
	add_child(pivot)
	_build_ragdoll()
	_play("idle", 1.0)


func _build_ragdoll() -> void:
	sim = PhysicalBoneSimulator3D.new()
	sim.name = "RagdollSim"
	skel.add_child(sim)
	for bone in RAGDOLL:
		_make_pbone(bone)


func _make_pbone(bone: String) -> void:
	var spec: Array = RAGDOLL[bone]
	var bi := skel.find_bone(bone)
	if bi < 0:
		return
	var pb := PhysicalBone3D.new()
	pb.bone_name = bone
	pb.mass = spec[0]
	# Corpses are unshootable and untouchable: nothing collides with them, they rest on the world.
	pb.collision_layer = 0
	pb.collision_mask = TacticalConfig.LAYER_WORLD
	pb.linear_damp = TacticalConfig.RAGDOLL_LIN_DAMP
	pb.angular_damp = TacticalConfig.RAGDOLL_ANG_DAMP
	pb.can_sleep = true
	var radius: float = spec[1]
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	var child: String = RAGDOLL_CHILD[bone]
	if child != "":
		var ci := skel.find_bone(child)
		var off: Vector3 = skel.get_bone_rest(ci).origin
		cap.height = off.length() + radius
		cs.transform = Transform3D(_basis_y_to(off), off * 0.5)
	else:
		var man: Array = RAGDOLL_MANUAL[bone]
		cap.height = man[0]
		cs.position = man[1]
	cs.shape = cap
	pb.add_child(cs)
	# Park at the bone's rest pose (in skeleton space); die() re-syncs to the live pose.
	pb.transform = skel.get_bone_rest(bi)
	var jt: int = spec[2]
	pb.joint_type = jt
	var jp: Dictionary = spec[3]
	if jt == PhysicalBone3D.JOINT_TYPE_CONE:
		pb.set("joint_constraints/swing_span", jp["swing"] * TacticalConfig.RAGDOLL_LIMIT)
		pb.set("joint_constraints/twist_span", jp["twist"] * TacticalConfig.RAGDOLL_LIMIT)
	elif jt == PhysicalBone3D.JOINT_TYPE_HINGE:
		# The hinge rotates about the joint's Z; rotate the joint frame so hinge-Z == bone-X,
		# the anatomical flexion axis (verified: HingeJoint3D is Z-axis in Godot 4).
		pb.set("joint_rotation", Vector3(0, PI * 0.5, 0))
		pb.set("joint_constraints/angular_limit_enabled", true)
		pb.set("joint_constraints/angular_limit_lower", jp["lower"] * TacticalConfig.RAGDOLL_LIMIT)
		pb.set("joint_constraints/angular_limit_upper", jp["upper"] * TacticalConfig.RAGDOLL_LIMIT)
	sim.add_child(pb)
	_pbones[bone] = pb


## Orthonormal basis with +Y along `dir`.
static func _basis_y_to(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := y.cross(Vector3(0, 0, 1))
	if x.length() < 0.01:
		x = y.cross(Vector3(1, 0, 0))
	x = x.normalized()
	return Basis(x, y, x.cross(y))


func _use_library() -> void:
	if _lib == null:
		_lib = AnimationLibrary.new()
		for n in anim.get_animation_list():
			var a := anim.get_animation(n).duplicate() as Animation
			if n in FpBody.LOOPED:
				a.loop_mode = Animation.LOOP_LINEAR
			for t in range(a.get_track_count() - 1, -1, -1):
				var bone := str(a.track_get_path(t)).get_slice(":", 1)
				if n != "death" and STRIPPED.any(func(p): return bone.begins_with(p)):
					a.remove_track(t)
			_lib.add_animation(n, a)
	for l in anim.get_animation_library_list():
		anim.remove_animation_library(l)
	anim.add_animation_library("", _lib)


func _dye(scene: Node3D, uniform: Color) -> void:
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "Head":
			continue
		(mi as MeshInstance3D).material_override = RangeLayout.colour(BOOTS if mi.name == "Boots" else (uniform.darkened(0.2) if mi.name == "Legs" else uniform))
	var att := BoneAttachment3D.new()
	att.bone_name = "upperarm_l"
	skel.add_child(att)
	var band := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.075
	c.bottom_radius = 0.075
	c.height = 0.09
	band.mesh = c
	band.material_override = RangeLayout.colour(ARMBAND)
	band.position = Vector3(0, 0.13, 0)
	att.add_child(band)


## Mounts the gun: grips and size come from the gun's def, the hold (BotHold) from its class. The gun's rear end
## sits on the pivot, which update() puts in the shoulder pocket (pistols: out in front of the chest).
func hold(gun: Node3D, gun_def: Dictionary, half_len: float) -> void:
	_grip = gun_def
	_half_len = half_len
	_flip = gun_def.get("flip", false)
	_hold = BotHold.of(gun_def)
	pivot.add_child(gun)
	gun.position = Vector3(0, 0, -half_len)


## Death: stop the canned animation, start the ragdoll from the current pose, and throw the
## hit bone along `impulse` (zero for bleed-out). Local cosmetic only — no multiplayer sync.
func die(impulse := Vector3.ZERO, zone := "") -> void:
	if dead:
		return
	dead = true
	anim.stop()
	# Sync the bodies to the current animated pose before the physics server takes over.
	for bone in _pbones:
		var pb: PhysicalBone3D = _pbones[bone]
		pb.global_transform = skel.global_transform * skel.get_bone_global_pose(skel.find_bone(bone))
	sim.physical_bones_start_simulation()
	var target: String = ZONE_BONES.get(zone, "spine_03")
	var pb: PhysicalBone3D = _pbones.get(target, _pbones["spine_03"])
	if impulse.length_squared() > 0.0 and pb != null:
		pb.apply_central_impulse(impulse)
	elif pb != null:
		# Bleed-out (no kill impulse): nudge the torso to ensure the limp body topples
		# instead of balancing. Small vs DEATH_IMPULSE (250 N·s).
		var nudge := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		if nudge.length_squared() < 0.01:
			nudge = Vector3(1.0, 0.0, 0.0)
		pb.apply_central_impulse(nudge.normalized() * TacticalConfig.RAGDOLL_NUDGE)
	if TacticalConfig.RAGDOLL_SLEEP > 0.0:
		_sleep_t = 0.0


func _tick_sleep(dt: float) -> void:
	if _sleep_t < 0.0:
		return
	_sleep_t += dt
	if _sleep_t >= TacticalConfig.RAGDOLL_SLEEP:
		_sleep_t = -1.0
		# Freeze in place: stopping the simulation would snap the skeleton back to its animated pose.
		for pb: PhysicalBone3D in _pbones.values():
			PhysicsServer3D.body_set_mode(pb.get_rid(), PhysicsServer3D.BODY_MODE_STATIC)


func bone_pos(bone: String) -> Vector3:
	var pb: PhysicalBone3D = _pbones.get(bone)
	return pb.global_position if pb != null else Vector3.ZERO


func ragdoll_bones() -> Array:
	return _pbones.keys()


## Advance the clip, pose the legs (weight shift, soft knees: BotLegs) and the spine (lean into the gun, breathing,
## sway, peek lean-roll), then solve both arms onto the gun. raise: 0 lowered .. 1 aimed (BotMesh). `lean` -1..1
## toward the bot's -X..+X, already scaled for crouch: the head moves LEAN_OFFSET x lean to that side (BotPose's hitboxes).
func update(delta: float, speed: float, raise: float, gun: Node3D, crouch := false, lean := 0.0, calm := false) -> void:
	if not dead:
		var want := FpBody.locomotion(speed)
		if crouch:
			want = "crouch_idle" if speed < 0.3 else "crouch_walk"
		_play(want, 1.0 if want in ["idle", "crouch_idle"] else FpBody.rate_for(want, speed))
	anim.advance(delta)
	if dead:
		_tick_sleep(delta)
		return
	_engage = smoothstep(0.0, 1.0, raise)
	_calm = move_toward(_calm, 1.0 if calm and raise <= 0.0 else 0.0, delta * 1.5)
	_idle.tick(delta, speed < 0.3 and not crouch, _engage, calm)
	var low := 1.0 - _engage
	var pitch := lerpf(lerpf(float(_hold["low"]), float(_hold["carry"]), _calm), 0.0, _engage)
	var sk := global_transform.basis.inverse() * skel.global_transform.basis  # skeleton axes in the bot's frame
	var st := _idle.still
	var drop := (BotIdle.SHIFT_DROP * absf(_idle.shift) * low + BotIdle.SOFT_KNEE_M * _engage) * st
	var hip := _idle.shift * BotIdle.SHIFT_ROLL * low * st
	_legs.apply(sk.inverse() * Vector3(_idle.shift * BotIdle.SHIFT_M * low * st, -drop, 0.0), hip, sk.inverse() * Vector3.BACK)
	var roll := asin(clampf(TacticalConfig.LEAN_OFFSET * lean / _lean_reach, -1.0, 1.0))
	var blade: float = _hold["blade"]
	var fwd := lerpf(float(_hold["fwd_low"]), float(_hold["fwd_aim"]), _engage)
	var n := _spine.size()
	for k in n:
		var bend := fwd / n - (_idle.breath * 0.5 if k > 0 else 0.0)  # inhale lifts the chest (spine_02, spine_03)
		var q := Quaternion(_spine_axis[k], bend) * Quaternion(_spine_roll[k], roll + (_idle.sway.x + hip) / n) 			* Quaternion(_spine_up[k], (-blade + _idle.sway.y + _idle.glance.x * 0.3) / n)
		skel.set_bone_pose_rotation(_spine[k], _spine_rest[k] * q)
	# The head turns back to the front and drops onto the stock while engaged (the clip keys the neck every frame);
	# lowered, it glances round (BotIdle; the spine takes 30 % of the turn).
	var nq := Quaternion(_neck_up, blade + _idle.glance.x * 0.7) * Quaternion(_neck_axis, float(_hold["head"]) * _engage + _idle.glance.y)
	skel.set_bone_pose_rotation(_neck, skel.get_bone_pose_rotation(_neck) * nq)
	arms.rebase()
	var sh_r := to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_r")).origin)
	var mount := sh_r
	if _hold["mount"] == "chest":
		mount = (sh_r + to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_l")).origin)) * 0.5
	pivot.position = mount + (_hold["at"] as Vector3) + Vector3(0, float(_hold["lift"]) * _engage, 0) + (_hold["low_at"] as Vector3) * low
	pivot.rotation.x = pitch
	pivot.rotation.y = float(_hold["carry_yaw"]) * _calm * low  # patrol carry: muzzle across the body
	pivot.rotation.z = -lean * deg_to_rad(TacticalConfig.LEAN_ROLL_DEG)  # the gun cants like the player's view
	var gt := gun.global_transform
	var fwd_w := gt.basis * Vector3(0, 0, -1)
	var pistol: bool = _grip["class"] == "pistol"
	var b := global_transform.basis
	arms.solve("r", gt * (_grip["grip_r"] as Vector3), fwd_w, gt.basis * Vector3(-1, 0, 0), 1.0, b * (_hold["pole_r"] as Vector3))
	var la: Dictionary = arms._sides["l"]
	var grip_l := BotHold.reach_back(gt * (_grip["grip_l"] as Vector3), -fwd_w.normalized(), skel.global_transform * (la["rest_up"] as Transform3D).origin,
		(float(la["l1"]) + float(la["l2"])) * skel.global_transform.basis.get_scale().x * 0.98)
	arms.solve("l", grip_l, fwd_w, gt.basis * (Vector3(1, 0, 0) if pistol else Vector3(0, 1, 0)), 1.0,
		b * (_hold["pole_l"] as Vector3))


func _play(want: String, rate: float, blend := 0.2) -> void:
	if want != clip:
		clip = want
		anim.play(want, blend)
	anim.speed_scale = rate
