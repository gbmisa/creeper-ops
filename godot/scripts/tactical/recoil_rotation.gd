class_name RecoilRotation
extends RefCounted
## Tarkov's weapon-rotation recoil process (`NewRotationRecoilProcess`): stable mode in automatic fire,
## the progress multiplier and the return path with its settle point.
## Port of TRP crates/trp-sim/src/recoil.rs `RotationProcess` (github.com/JuanFNQ/TRP, Apache-2.0).
## Degrees in the weapon bone's axes: negative x raises the muzzle, z turns it sideways.

enum Side { LEFT, RIGHT, NONE }

var s := {}                 # the resolved recoil row (TacRecoilDefs.resolve)
var intensity := 1.0
var offset := Vector3.ZERO  # rest point (the hip wander moves it)
var current := Vector3.ZERO
var velocity := Vector3.ZERO
var stable_on := false
var auto_fire_on := false
var multiplier := 1.0       # multiplier by shot index
var angle_add := 0.0        # stable-mode widening of the angle range (deg)
var _force := Vector3.ZERO
var _pending := false
var _prev := Vector3.ZERO
var _rest := Vector2.ZERO   # settle point (x, z)
var _stable_cur := Vector3.ZERO
var _next := Vector3.ZERO
var _curve_t := 0.0
var _speed := 0.0
var _impulse := 0.01
var _peak_x := 0.01
var _path_on := false
var _side := Side.NONE


func _init(row: Dictionary) -> void:
	s = row


func reset() -> void:
	var keep := [intensity, stable_on, auto_fire_on, multiplier, angle_add, _pending, _side]
	offset = Vector3.ZERO
	current = Vector3.ZERO
	velocity = Vector3.ZERO
	_force = Vector3.ZERO
	_prev = Vector3.ZERO
	_rest = Vector2.ZERO
	_stable_cur = Vector3.ZERO
	_next = Vector3.ZERO
	_curve_t = 0.0
	_speed = 0.0
	_impulse = 0.01
	_peak_x = 0.01
	_path_on = false
	intensity = keep[0]; stable_on = keep[1]; auto_fire_on = keep[2]; multiplier = keep[3]
	angle_add = keep[4]; _pending = keep[5]; _side = keep[6]


func push(axis: int, value: float) -> void:
	_path_on = true
	if stable_on:
		velocity = Vector3.ZERO
	_force[axis] += value * s["category_mult"] * multiplier
	_pending = true


func set_stable(on: bool) -> void:
	if on and not stable_on:
		stable_on = true
		_stable_cur = current
	elif not on and stable_on:
		angle_add = 0.0
		stable_on = false


func set_auto_fire(on: bool) -> void:
	if on:
		auto_fire_on = true
	elif auto_fire_on:
		_curve_t = minf(current.length_squared(), _curve_t)
		auto_fire_on = false


func step(dt: float, rng: RandomNumberGenerator) -> void:
	if _pending:
		velocity += _force * intensity
		_force = Vector3.ZERO
		_curve_t = minf(current.length_squared(), _curve_t)
		if stable_on:
			_next = _stable_cur + velocity * rng.randf_range(TacRecoilDefs.NEXT_STABLE.x, TacRecoilDefs.NEXT_STABLE.y)
			var dir := _next - current
			if dir.length() > TacRecoilDefs.STABLE_LIMIT:
				_next = current + dir * TacRecoilDefs.STABLE_LIMIT   # scaled by the limit, not cut to it
	if not auto_fire_on:
		_speed = s["convergence"] * TacRecoilDefs.RETURN_CURVE
	if _pending and auto_fire_on and not stable_on:
		_speed *= multiplier
	_curve_t += dt
	velocity *= s["damping"]
	if stable_on:
		current += (_next - current) * TacRecoilDefs.TO_NEXT_SPEED
	else:
		velocity -= current * _speed
		current += velocity
	_return_path(rng)
	if not auto_fire_on and _peak_x != 0.0:
		var remaining := absf(RecoilSpring.unity_clamp(current.x, _peak_x, -0.01) / _peak_x)
		var k := clampf(1.0 - remaining, 0.01, 1.0) * 0.01
		current.x += (_rest.x - current.x) * k
		current.z += (_rest.y - current.z) * k
	_prev = current
	_pending = false


func _return_path(rng: RandomNumberGenerator) -> void:
	if current.x < _prev.x and _path_on:
		var h: Vector2 = s["post_h"]
		var aside := 0.0
		if _side == Side.RIGHT:
			aside = rng.randf_range(current.z, h.y)
		elif _side == Side.LEFT:
			aside = rng.randf_range(h.x, current.z)
		var v: Vector2 = s["post_v"]
		_rest = Vector2(rng.randf_range(v.x, v.y), aside)
		_peak_x = current.x
		_impulse = absf(current.x * s["convergence"]) * s["return_offset"]
		if current.z > 0.0:
			_side = Side.RIGHT
		elif current.z < 0.0:
			_side = Side.LEFT
		else:
			_side = Side.RIGHT if rng.randf_range(-1.0, 1.0) >= 0.0 else Side.LEFT
		return
	if auto_fire_on or not _path_on:
		return
	_impulse *= s["return_damping"]
	if _impulse < 0.001:
		if s["reset_after_shot"]:
			reset()
		else:
			_path_on = false
	else:
		velocity.z += _impulse * (1.0 if _side == Side.RIGHT else -1.0)


func value() -> Vector3:
	return offset + current
