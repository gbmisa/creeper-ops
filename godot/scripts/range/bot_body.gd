class_name BotBody
extends Node3D
## An enemy's visible body: body.glb dyed per kind, driven by AnimationPlayer (advanced by hand). Upper-body bone
## tracks are stripped from the shared clips so the spine can pitch with the aim and FpArms' two-bone IK puts both
## hands on the gun's grips. Hitboxes are separate (HitboxRig). Faces -Z, feet at y = 0.

const STRIPPED := ["clavicle_", "upperarm_", "lowerarm_", "hand_", "thumb_", "index_", "middle_", "ring_", "pinky_", "spine_0"]
const SPINE := ["spine_01", "spine_02", "spine_03"]
const BOOTS := Color(0.1, 0.1, 0.09)
const FIX_HIPS := 0.6  # share of the head fix's sideways part done by the pelvis (feet planted); the spine rolls the rest
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
var _head: BotHead
var _hold := BotHold.STOCKED
var _engage := 0.0  # 0 lowered .. 1 aimed (BotMesh.raise, eased)
var _calm := 0.0  # 0 low ready .. 1 patrol carry (eased)
var _head_sh := Vector3.INF  # head - right shoulder (bot frame) when last not leaning
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
	_head = BotHead.new(skel)
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


## Advance the clip, pose the legs (weight shift, soft knees: BotLegs) and the spine (lean into the gun, breathing,
## sway, peek lean-roll), then solve both arms onto the gun. raise: 0 lowered .. 1 aimed (BotMesh). `lean` -1..1
## toward the bot's -X..+X, already scaled for crouch: the head moves LEAN_OFFSET x lean to that side (BotPose's hitboxes).
func update(delta: float, speed: float, raise: float, gun: Node3D, crouch := false, lean := 0.0, calm := false, head_at := Vector3(0, 1.66, 0)) -> void:
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
	_engage = smoothstep(0.0, 1.0, raise)
	_calm = move_toward(_calm, 1.0 if calm and raise <= 0.0 else 0.0, delta * 1.5)
	_idle.tick(delta, speed, crouch, _engage, calm)
	var steady := -_legs.pelvis_roll() * BotIdle.GAIT_STEADY * _idle.gait  # shoulders steadier than the hips on the move
	var low := 1.0 - _engage
	var pitch := lerpf(lerpf(float(_hold["low"]), float(_hold["carry"]), _calm), 0.0, _engage)
	var sk := global_transform.basis.inverse() * skel.global_transform.basis  # skeleton axes in the bot's frame
	var st := _idle.still
	var drop := (BotIdle.SHIFT_DROP * absf(_idle.shift) * low + BotIdle.SOFT_KNEE_M * _engage) * st
	var hip := _idle.shift * BotIdle.SHIFT_ROLL * low * st
	var fx := _head.fix
	_legs.apply(sk.inverse() * Vector3(_idle.shift * BotIdle.SHIFT_M * low * st + fx.x * FIX_HIPS, fx.y - drop, 0.0), hip, sk.inverse() * Vector3.BACK)
	var roll := asin(clampf(TacticalConfig.LEAN_OFFSET * lean / _lean_reach, -1.0, 1.0))
	var blade: float = _hold["blade"]
	var fwd := lerpf(float(_hold["fwd_low"]), float(_hold["fwd_aim"]), _engage)
	var n := _spine.size()
	for k in n:
		var bend := (fwd - fx.z / _lean_reach * n) / n - (_idle.breath * 0.5 if k > 0 else 0.0)  # inhale lifts the chest
		var q := Quaternion(_spine_axis[k], bend) * Quaternion(_spine_roll[k], roll + fx.x * (1.0 - FIX_HIPS) / _lean_reach + (_idle.sway.x + hip + steady) / n) \
			* Quaternion(_spine_up[k], (-blade + _idle.sway.y + _idle.glance.x * 0.3) / n)
		skel.set_bone_pose_rotation(_spine[k], _spine_rest[k] * q)
	# The head turns back to the front, looks level and drops onto the stock while engaged; lowered, it glances round
	# (BotIdle; the spine takes 30 % of the turn).
	_head.pose(blade + _idle.glance.x * 0.7, float(_hold["head"]) * _engage + _idle.glance.y, roll * n)
	_head.track(to_local(skel.global_transform * _head.centre()) - head_at, speed < 0.3, delta)  # head on its hitbox
	arms.rebase()
	var sh_r := to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_r")).origin)
	var mount := sh_r
	if _hold["mount"] == "chest":
		mount = (sh_r + to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_l")).origin)) * 0.5
	var at := (_hold["at"] as Vector3) + Vector3(0, float(_hold["lift"]) * _engage, 0) + ((_hold["low_at"] as Vector3) + (_hold["run_at"] as Vector3) * _idle.run) * low
	# Leaning, the hold tilts with the torso and follows the head where the spine roll moves it past a rigid tilt.
	var tilt := Basis(Vector3.BACK, -lean * TacticalConfig.BOT_LEAN_RAD)
	var head_sh := to_local(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Head_2")).origin) - sh_r
	if absf(lean) < 0.02:
		_head_sh = head_sh
	pivot.position = mount + tilt * at + (head_sh - tilt * _head_sh if absf(lean) >= 0.02 and _head_sh.is_finite() else Vector3.ZERO)
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
