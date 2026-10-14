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
const STOCK_BACK := 0.04  # the gun's rear sits this far inside the shoulder pivot
const PIVOT_IN := Vector3(-0.07, -0.04, 0.0)  # shoulder joint to the stock pocket

static var _lib: AnimationLibrary

var anim: AnimationPlayer
var clip := ""
var dead := false
var skel: Skeleton3D
var arms: FpArms
var pivot: Node3D  # sits on the right shoulder, pitches with the aim; the gun hangs off it
var _spine: Array[int] = []
var _spine_rest: Array[Quaternion] = []
var _spine_axis: Array[Vector3] = []
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
	arms = FpArms.new(skel)
	add_child(arms)
	pivot = Node3D.new()
	add_child(pivot)
	_play("idle", 1.0)


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


## Mounts the gun: grips and size come from the gun's def.
func hold(gun: Node3D, gun_def: Dictionary, half_len: float) -> void:
	_grip = gun_def
	_half_len = half_len
	_flip = gun_def.get("flip", false)
	pivot.add_child(gun)
	gun.position = PIVOT_IN + Vector3(0, 0, -(half_len - float(gun_def.get("butt", 0.0)) - STOCK_BACK))


func die() -> void:
	dead = true
	_play("death", 1.0, 0.1)


## Advance the clip, pitch the spine, then solve both arms onto the gun.
func update(delta: float, speed: float, pitch: float, gun: Node3D) -> void:
	if not dead:
		var want := FpBody.locomotion(speed)
		_play(want, 1.0 if want == "idle" else FpBody.rate_for(want, speed))
	anim.advance(delta)
	if dead:
		return
	for k in _spine.size():
		var q := Quaternion(_spine_axis[k], -pitch * SPINE_SHARE / _spine.size())
		skel.set_bone_pose_rotation(_spine[k], _spine_rest[k] * q)
	arms.rebase()
	pivot.global_position = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("upperarm_r")).origin
	pivot.rotation.x = pitch
	var gt := gun.global_transform
	var fwd := gt.basis * Vector3(0, 0, -1)
	var pistol: bool = _grip["class"] == "pistol"
	arms.solve("r", gt * (_grip["grip_r"] as Vector3), fwd, gt.basis * Vector3(-1, 0, 0), 1.0)
	arms.solve("l", gt * (_grip["grip_l"] as Vector3), fwd, gt.basis * (Vector3(1, 0, 0) if pistol else Vector3(0, 1, 0)), 1.0)


func _play(want: String, rate: float, blend := 0.2) -> void:
	if want != clip:
		clip = want
		anim.play(want, blend)
	anim.speed_scale = rate
