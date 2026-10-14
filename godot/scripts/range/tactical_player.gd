class_name TacticalPlayer
extends CharacterBody3D
## First-person body for the range: walk / sprint / crouch / lean / jump with inertia and leg stamina.
## Mouse look needs captured mouse. The weapon system writes recoil_off / sway_off (degrees) and ads_amt.

const EYE_STAND := 1.62
const EYE_CROUCH := 1.05
const SENS := 0.0022
const JUMP_V := 4.2
const ACCEL := 16.0
const BASE_FOV := 75.0
const RESPAWN_TIME := 3.5

signal hit_taken(from: Vector3, res: Dictionary)
signal died
signal respawned

var input: InputState
var enabled := true
var yaw := 0.0
var pitch := 0.0
var lean := 0.0
var crouching := false
var sprinting := false
var leg_stamina := 1.0
var carried_kg := 0.0
var move_mult := 1.0  # body health slows (fractured legs)
var ads_amt := 0.0  # set by PlayerWeapons
var spot_mult := 1.0  # bots notice this player from range x this (laser lit); set by PlayerWeapons
var recoil_off := Vector2.ZERO  # deg, x = pitch up, y = yaw
var sway_off := Vector2.ZERO
var body := BodyHealth.new()  # zones the bots shoot at
var label_name := "You"
var god := false  # --god (screenshots): body health never drops
var dead_t := 0.0
var rig := {}
var head: Node3D
var cam: Camera3D
var _shape: CollisionShape3D
var _eye := EYE_STAND
var _exhausted := false
var _jump := false
var _step_t := 0.0
var _was_floor := true


func _init() -> void:
	name = "Player"
	collision_layer = TacticalConfig.LAYER_BODY
	collision_mask = TacticalConfig.LAYER_WORLD
	_shape = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	_shape.shape = cap
	_shape.position.y = 0.9
	add_child(_shape)
	head = Node3D.new()
	head.position.y = EYE_STAND
	add_child(head)
	cam = Camera3D.new()
	cam.fov = BASE_FOV
	cam.near = 0.03
	cam.far = 700.0
	cam.current = true
	head.add_child(cam)


func _ready() -> void:
	rig = HitboxRig.build(self, body, self)


## Called by RangeFeedback with the Ballistics.body_hit dictionary (a bot's bullet).
func on_hit(res: Dictionary) -> void:
	hit_taken.emit(res.get("origin", global_position), res)


## Bleeds, death and respawn. Called every frame, also when the menu is open.
func tick_body(delta: float) -> void:
	if god:
		body.reset()
	if dead_t > 0.0:
		dead_t -= delta
		if dead_t <= 0.0:
			respawn()
		return
	body.tick(delta)
	move_mult = body.move_mult()
	if body.dead:
		enabled = false
		dead_t = RESPAWN_TIME
		for z in rig:
			(rig[z] as CollisionObject3D).collision_layer = 0
		died.emit()


func respawn() -> void:
	body.reset()
	global_position = RangeLayout.SPAWN
	velocity = Vector3.ZERO
	yaw = 0.0
	pitch = 0.0
	leg_stamina = 1.0
	enabled = true
	for z in rig:
		(rig[z] as CollisionObject3D).collision_layer = TacticalConfig.LAYER_HITBOX
	respawned.emit()


func eye_pos() -> Vector3:
	return cam.global_position


func _process(delta: float) -> void:
	tick_body(delta)
	var crouch_k := (1.2 if crouching else 1.8) / 1.8
	for z in rig:  # hitboxes follow a crouch
		(rig[z] as Node3D).position.y = (HitboxRig.SHAPES[z][0] as Vector3).y * crouch_k
	if dead_t > 0.0:  # down: the camera drops and rolls
		_eye = lerpf(_eye, 0.3, minf(1.0, delta * 4.0))
		head.position.y = _eye
		head.rotation.z = lerpf(head.rotation.z, 0.9, minf(1.0, delta * 3.0))
	if not enabled:
		return
	if input.act("t_jump"):
		_jump = true
	if input.act("t_crouch"):
		crouching = not crouching
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var k := cam.fov / BASE_FOV
		yaw -= input.mouse_delta.x * SENS * k
		pitch = clampf(pitch - input.mouse_delta.y * SENS * k, -1.5, 1.5)
	var lean_t := 0.0
	if input.held("t_lean_left"):
		lean_t -= 1.0
	if input.held("t_lean_right"):
		lean_t += 1.0
	lean = move_toward(lean, lean_t, delta * 6.0)
	_eye = lerpf(_eye, EYE_CROUCH if crouching else EYE_STAND, minf(1.0, delta * 10.0))
	rotation.y = yaw
	head.position = Vector3(lean * TacticalConfig.LEAN_OFFSET, _eye, 0)
	head.rotation = Vector3(pitch + deg_to_rad(recoil_off.x + sway_off.x), deg_to_rad(recoil_off.y + sway_off.y),
		-lean * deg_to_rad(TacticalConfig.LEAN_ROLL_DEG))
	var h := 1.2 if crouching else 1.8
	(_shape.shape as CapsuleShape3D).height = h
	_shape.position.y = h * 0.5


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if enabled:
		dir.y = float(input.held("t_back")) - float(input.held("t_forward"))
		dir.x = float(input.held("t_right")) - float(input.held("t_left"))
	var want_sprint: bool = enabled and input.held("t_sprint") and dir.y < 0.0 and not crouching \
		and ads_amt < 0.1 and not _exhausted and is_on_floor()
	sprinting = want_sprint
	if sprinting:
		leg_stamina = maxf(0.0, leg_stamina - TacticalConfig.LEG_STAMINA_DRAIN * delta)
		if leg_stamina <= 0.0:
			_exhausted = true
	elif velocity.length() < 5.0:
		leg_stamina = minf(1.0, leg_stamina + TacticalConfig.LEG_STAMINA_REGEN * delta)
		if leg_stamina > 0.25:
			_exhausted = false
	var speed := TacticalConfig.SPRINT if sprinting else TacticalConfig.WALK
	if crouching:
		speed *= 0.55
	speed *= lerpf(1.0, 0.6, ads_amt) * move_mult
	var wish := (global_transform.basis * Vector3(dir.x, 0, dir.y)).normalized() * speed if dir != Vector2.ZERO else Vector3.ZERO
	var accel := ACCEL / (1.0 + carried_kg * 0.12)
	var hv := Vector2(wish.x, wish.z)  # no inertia on the ground: velocity snaps to the input
	if not is_on_floor():
		hv = Vector2(velocity.x, velocity.z).move_toward(hv, accel * delta)
	velocity.x = hv.x
	velocity.z = hv.y
	velocity.y -= TacticalConfig.GRAVITY * delta
	if _jump and is_on_floor() and not crouching:
		velocity.y = JUMP_V
		Sfx.play("jump")
	_jump = false
	move_and_slide()
	if is_on_floor() and not _was_floor:
		Sfx.play("land")
	_was_floor = is_on_floor()
	_step_t -= delta * hv.length()
	if _step_t <= 0.0:
		_step_t = 1.7
		if is_on_floor() and hv.length() > 0.5:
			Sfx.play("step")
			BotNoise.emit(global_position, BotNoise.step_radius(sprinting, crouching), "step", self)


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Debug / screenshot hook: look toward a world point.
func look_at_point(p: Vector3) -> void:
	var d := p - (global_position + Vector3(0, _eye, 0))
	yaw = atan2(-d.x, -d.z)
	pitch = atan2(d.y, Vector2(d.x, d.z).length())
