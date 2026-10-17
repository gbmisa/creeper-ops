class_name BotBody
extends Node3D
## An enemy's visible body: body.glb dyed per kind, driven by AnimationPlayer (advanced by hand). Upper-body bone
## tracks are stripped from the shared clips so the spine can pitch with the aim and FpArms' two-bone IK puts both
## hands on the gun's grips. Hitboxes are separate (HitboxRig). Faces -Z, feet at y = 0.

const STRIPPED := ["clavicle_", "upperarm_", "lowerarm_", "hand_", "thumb_", "index_", "middle_", "ring_", "pinky_", "spine_0"]
const SPINE := ["spine_01", "spine_02", "spine_03"]
const SPINE_SHARE := 0.6  # of the gun pitch, spread over the three spine bones
const BOOTS := Color(0.1, 0.1, 0.09)
const ARMBAND := Color(0.8, 0.1, 0.1)

## Ragdoll: the physical bones, joint tables and launch live in BotRagdoll (local cosmetic physics, no multiplayer sync).

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
var _vel := Vector3.ZERO  # the body's own world velocity (from its last two positions), handed to the ragdoll at death
var _last_pos := Vector3.ZERO
var _have_last := false
var _spine: Array[int] = []
var _spine_rest: Array[Quaternion] = []
var _spine_axis: Array[Vector3] = []
var _spine_roll: Array[Vector3] = []  # bone-local forward axis (lean)
var _spine_up: Array[Vector3] = []  # bone-local up axis (blade)
var _neck := -1
var _neck_up := Vector3.UP
var _neck_axis := Vector3.RIGHT
var _hold := BotHold.STOCKED
var _engage := 0.0  # 0 lowered .. 1 level (from the aim pitch)
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
	pivot = Node3D.new()
	add_child(pivot)
	_build_ragdoll()
	_play("idle", 1.0)


func _build_ragdoll() -> void:
	sim = PhysicalBoneSimulator3D.new()
	sim.name = "RagdollSim"
	skel.add_child(sim)
	_pbones = BotRagdoll.build(skel, sim)


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
	# Read the bones' motion: sample the pose, advance the clip one step, sample again, then stop it.
	var p0 := BotRagdoll.sample(skel, _pbones)
	anim.advance(BotRagdoll.ANIM_DT)
	var p1 := BotRagdoll.sample(skel, _pbones)
	anim.stop()
	BotRagdoll.launch(sim, _pbones, p0, p1, _vel)
	var target: String = BotRagdoll.ZONE_BONES.get(zone, "spine_03")
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


func capsule_center(bone: String) -> Vector3:
	var pb: PhysicalBone3D = _pbones.get(bone)
	return BotRagdoll.capsule_center(pb) if pb != null else Vector3.ZERO


func ragdoll_bones() -> Array:
	return _pbones.keys()


## Advance the clip, pitch (and lean-roll) the spine, then solve both arms onto the gun. `lean` -1..1 toward the
## bot's -X..+X, already scaled for crouch: the head moves LEAN_OFFSET x lean to that side (BotPose's hitboxes).
func update(delta: float, speed: float, pitch: float, gun: Node3D, crouch := false, lean := 0.0) -> void:
	if not dead:
		var want := FpBody.locomotion(speed)
		if crouch:
			want = "crouch_idle" if speed < 0.3 else "crouch_walk"
		_play(want, 1.0 if want in ["idle", "crouch_idle"] else FpBody.rate_for(want, speed))
	if delta > 0.0 and is_inside_tree():
		_vel = (global_position - _last_pos) / delta if _have_last else Vector3.ZERO
		_last_pos = global_position
		_have_last = true
	anim.advance(delta)
	if dead:
		_tick_sleep(delta)
		return
	var roll := asin(clampf(TacticalConfig.LEAN_OFFSET * lean / _lean_reach, -1.0, 1.0))
	var blade: float = _hold["blade"]
	for k in _spine.size():
		var q := Quaternion(_spine_axis[k], -pitch * SPINE_SHARE / _spine.size()) * Quaternion(_spine_roll[k], roll) \
			* Quaternion(_spine_up[k], -blade / _spine.size())
		skel.set_bone_pose_rotation(_spine[k], _spine_rest[k] * q)
	_engage = clampf(1.0 + pitch / BotMesh.LOW_PITCH, 0.0, 1.0)
	# The head turns back to the front and drops onto the stock while engaged (the clip keys the neck every frame).
	var nq := Quaternion(_neck_up, blade) * Quaternion(_neck_axis, float(_hold["head"]) * _engage)
	skel.set_bone_pose_rotation(_neck, skel.get_bone_pose_rotation(_neck) * nq)
	arms.rebase()
	var sh_r := to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_r")).origin)
	var mount := sh_r
	if _hold["mount"] == "chest":
		mount = (sh_r + to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_l")).origin)) * 0.5
	pivot.position = mount + (_hold["at"] as Vector3) + Vector3(0, float(_hold["lift"]) * _engage, 0)
	pivot.rotation.x = pitch
	pivot.rotation.z = -lean * deg_to_rad(TacticalConfig.LEAN_ROLL_DEG)  # the gun cants like the player's view
	var gt := gun.global_transform
	var fwd := gt.basis * Vector3(0, 0, -1)
	var pistol: bool = _grip["class"] == "pistol"
	var b := global_transform.basis
	arms.solve("r", gt * (_grip["grip_r"] as Vector3), fwd, gt.basis * Vector3(-1, 0, 0), 1.0, b * (_hold["pole_r"] as Vector3))
	var la: Dictionary = arms._sides["l"]
	var grip_l := BotHold.reach_back(gt * (_grip["grip_l"] as Vector3), -fwd.normalized(), skel.global_transform * (la["rest_up"] as Transform3D).origin,
		(float(la["l1"]) + float(la["l2"])) * skel.global_transform.basis.get_scale().x * 0.98)
	arms.solve("l", grip_l, fwd, gt.basis * (Vector3(1, 0, 0) if pistol else Vector3(0, 1, 0)), 1.0,
		b * (_hold["pole_l"] as Vector3))


func _play(want: String, rate: float, blend := 0.2) -> void:
	if want != clip:
		clip = want
		anim.play(want, blend)
	anim.speed_scale = rate
