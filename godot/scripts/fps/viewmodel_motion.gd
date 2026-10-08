class_name ViewmodelMotion
extends RefCounted
## Moves the first-person weapon node: recoil spring (kick), idle breathing, walk bob, sprint
## lower-and-tilt, landing dip and mouse-look lag. One scalar spring `k` carries every shot:
## the gun goes back by k * VM_KICK_BACK, pitches up by k * VM_KICK_PITCH and the camera by
## k * VM_CAM_KICK. k is set instantly on a shot, then rings out with a small overshoot, so
## nothing is ever permanent. FpsMode calls update() once per frame after the controller.

const BASE := Vector3(0.18, -0.16, -0.5)

var gun: Node3D
var k := 0.0            # recoil spring displacement (1.0 = one full shot)
var kv := 0.0
var dip := 0.0          # landing dip spring
var dipv := 0.0
var _t := 0.0
var _bob := 0.0
var _sprint := 0.0      # 0..1 blend
var _lag := Vector2.ZERO
var _last_pos := Vector3.ZERO
var _fall := 0.0        # downward speed while airborne (for the landing dip)
var _was_air := false
var _speed := 0.0
var _dt := 0.016


func _init(g: Node3D) -> void:
	gun = g


## A shot: strength 1.0 = crossbow. Rapid fire stacks up to VM_KICK_MAX.
func kick(strength: float) -> void:
	k = minf(k + strength, Config.VM_KICK_MAX)
	kv = 0.0


func cam_pitch() -> float:
	return k * Config.VM_CAM_KICK


## True when every spring has settled (smoke test and idle checks).
func at_rest() -> bool:
	return absf(k) < 0.01 and absf(kv) < 0.05 and absf(dip) < 0.01


func update(dt: float, ctrl: PlayerController, input: InputState) -> void:
	_dt = dt
	_springs(dt)
	_t += dt
	var flat := Vector2(ctrl.pos.x - _last_pos.x, ctrl.pos.z - _last_pos.z).length()
	_last_pos = ctrl.pos
	_speed = lerpf(_speed, minf(flat / maxf(dt, 0.0001), 12.0), minf(1.0, dt * 10.0))
	var air := not ctrl.on_ground
	if air:
		_fall = maxf(_fall, -ctrl.vel_y)
	elif _was_air:
		dip = minf(dip + _fall * Config.VM_LAND_DIP, 0.14)
		dipv = 0.0
		_fall = 0.0
	_was_air = air
	var moving := ctrl.moving and ctrl.on_ground and _speed > 0.3
	var sprinting := moving and input.held("sprint")
	_sprint = move_toward(_sprint, 1.0 if sprinting else 0.0, dt * 6.0)
	var mouse := input.mouse_delta * 0.001
	_lag = _lag.lerp(mouse, minf(1.0, dt * 14.0)) if mouse.length() > 0.0 else _lag.lerp(Vector2.ZERO, minf(1.0, dt * 7.0))
	_apply(moving)


func _springs(dt: float) -> void:
	var left := dt
	while left > 0.0:  # substep: the spring is stiff
		var h := minf(left, 1.0 / 180.0)
		left -= h
		kv += (-Config.VM_SPRING_K * k - Config.VM_SPRING_DAMP * kv) * h
		k += kv * h
		dipv += (-Config.VM_SPRING_K * 0.25 * dip - Config.VM_SPRING_DAMP * 0.5 * dipv) * h
		dip += dipv * h


func _apply(moving: bool) -> void:
	var p := BASE
	var rot := Vector3.ZERO
	# Breathing: slow figure of eight, a little stronger when standing still.
	var still := 1.0 - minf(1.0, _speed / 2.0)
	p.y += sin(_t * 1.7) * Config.VM_BREATH * (0.6 + still)
	p.x += sin(_t * 0.85) * Config.VM_BREATH * 0.6 * (0.6 + still)
	rot.z += sin(_t * 0.85) * 0.004
	if moving:
		_bob += _dt * _speed * 1.45
		var amp := Config.VM_BOB * minf(1.0, _speed / 5.0) * (1.0 + _sprint * 0.8)
		p.x += sin(_bob) * amp
		p.y += absf(sin(_bob)) * amp * 0.9 - amp * 0.4
		rot.z += sin(_bob) * amp * 0.9
	# Sprint: lower the weapon and tilt it across the body.
	p.y -= Config.VM_SPRINT_DROP * _sprint
	p.x -= 0.04 * _sprint
	rot.x -= Config.VM_SPRINT_TILT * 0.6 * _sprint
	rot.z -= Config.VM_SPRINT_TILT * _sprint
	rot.y += Config.VM_SPRINT_TILT * 0.8 * _sprint
	# Recoil, landing dip, look lag.
	p.z += k * Config.VM_KICK_BACK
	p.y += k * 0.012 - dip
	rot.x += k * Config.VM_KICK_PITCH
	rot.y += _lag.x * Config.VM_LAG * 0.2
	rot.x += _lag.y * Config.VM_LAG * 0.2
	p.x += _lag.x * 0.03
	p.y -= _lag.y * 0.03
	gun.position = p
	gun.rotation = rot
