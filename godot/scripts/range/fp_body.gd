class_name FpBody
extends Node3D
## The player's own body in the world: body.glb under the player, feet on the floor, facing -Z. Clips follow
## velocity / crouch / airborne; legs yaw toward the move direction when strafing, walk reversed going backward.
## Head and world Arms sit on a render layer the player's camera skips (they still cast shadows).

const MODEL := "res://assets/models/operative/body.glb"
const HIDDEN_LAYER := 2  # render layer bit value; the camera's cull_mask excludes it
const SCALE := 0.965  # model eyes ~1.68 m, player eyes 1.62 m
const BACK := 0.26  # body sits this far behind the camera so the chest never reaches the near plane
const MAX_YAW := deg_to_rad(70.0)
const LOOPED := ["idle", "walk", "jog", "sprint", "crouch_idle", "crouch_walk", "jump"]
## Ground speed (m/s) at which each clip's feet stay planted (measured on the glb).
const CLIP_SPEED := {"walk": 0.9, "jog": 3.35, "sprint": 3.6, "crouch_walk": 0.5}
const WALK_MAX := 2.0
const JOG_MAX := 4.5

var player: TacticalPlayer
var anim: AnimationPlayer
var clip := ""
var auto := true  # false: the caller drives step() (tests)
var _yaw_node: Node3D
var _leg_yaw := 0.0
var _arms: Array[MeshInstance3D] = []


func setup(p: TacticalPlayer) -> void:
	player = p
	name = "FpBody"
	_yaw_node = Node3D.new()
	_yaw_node.position = Vector3(0, 0, BACK)
	add_child(_yaw_node)
	var scene := (load(MODEL) as PackedScene).instantiate() as Node3D
	scene.rotation.y = PI  # model faces +Z
	scene.scale = Vector3.ONE * SCALE
	_yaw_node.add_child(scene)
	anim = scene.find_children("*", "AnimationPlayer", true, false)[0]
	for n in LOOPED:
		anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "Head" or mi.name == "Arms":
			(mi as MeshInstance3D).layers = HIDDEN_LAYER
		if mi.name == "Arms":
			_arms.append(mi)
	p.cam.cull_mask = 0xFFFFF & ~HIDDEN_LAYER
	_play("idle", 1.0)


func _process(delta: float) -> void:
	if auto and player != null:
		step(delta, player.velocity, player.crouching, player.is_on_floor())


## vel is the world velocity; the player's yaw is read from the parent node.
func step(delta: float, vel: Vector3, crouching: bool, grounded: bool) -> void:
	var local: Vector3 = get_parent().global_transform.basis.inverse() * Vector3(vel.x, 0, vel.z)
	var speed: float = local.length()
	var want := "idle"
	var rate := 1.0
	var yaw_t := 0.0
	var reverse := false
	if not grounded:
		want = "jump"
	elif speed > 0.3:
		var th := atan2(local.x, -local.z)  # 0 forward, +right
		if absf(th) > PI * 0.5:
			reverse = true
			th -= signf(th) * PI
		yaw_t = clampf(th, -MAX_YAW, MAX_YAW)
		if crouching:
			want = "crouch_walk"
		else:
			want = locomotion(speed)
		rate = rate_for(want, speed)
	elif crouching:
		want = "crouch_idle"
	_leg_yaw = lerp_angle(_leg_yaw, -yaw_t, minf(1.0, delta * 10.0))
	_yaw_node.rotation.y = _leg_yaw
	_play(want, -rate if reverse else rate)


## Standing locomotion clip for a ground speed (m/s); shared with the enemy bots.
static func locomotion(speed: float) -> String:
	if speed < 0.3:
		return "idle"
	return "walk" if speed < WALK_MAX else ("jog" if speed < JOG_MAX else "sprint")


## Playback rate that keeps the clip's feet planted at this ground speed.
static func rate_for(clip_name: String, speed: float) -> float:
	return clampf(speed / float(CLIP_SPEED[clip_name]), 0.3, 4.0)


func _play(want: String, rate: float) -> void:
	if want != clip:
		clip = want
		anim.play(want, 0.15)
		if rate < 0.0:
			anim.seek(anim.get_animation(want).length * 0.5, true)
	anim.speed_scale = rate
