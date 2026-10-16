class_name RecoilSpring
extends RefCounted
## Tarkov's position / camera recoil process (TRP spec "The position and camera processes", Apache-2.0).
## One fixed step, no dt in the formula:
##   if a force was added: Velocity += Force * Intensity; clear it
##   Velocity -= (Current - Offset) * ReturnSpeed;  Velocity *= Damping;  Current += Velocity

var return_speed := 0.0
var damping := 0.0
var intensity := 1.0
var offset := Vector3.ZERO
var current := Vector3.ZERO
var velocity := Vector3.ZERO
var _force := Vector3.ZERO
var _pending := false


## params = (return speed, damping, intensity)
func _init(params: Vector3 = Vector3.ZERO) -> void:
	return_speed = params.x
	damping = params.y
	intensity = params.z


func push(axis: int, value: float) -> void:
	_force[axis] += value
	_pending = true


func step() -> void:
	if _pending:
		velocity += _force * intensity
		_force = Vector3.ZERO
		_pending = false
	velocity -= (current - offset) * return_speed
	velocity *= damping
	current += velocity


func value() -> Vector3:
	return offset + current


## Piecewise-linear curve over [time, value] keys (the AKM's weapon curves); clamps past either end.
static func curve_at(keys: Array, t: float) -> float:
	if keys.is_empty():
		return 0.0
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		if t <= keys[i][0]:
			var a: Array = keys[i - 1]
			var b: Array = keys[i]
			return lerpf(a[1], b[1], (t - a[0]) / maxf(b[0] - a[0], 1e-6))
	return keys[keys.size() - 1][1]


## Unity's Mathf.Clamp, which accepts min > max (returns min first); the rotation process relies on it.
static func unity_clamp(v: float, lo: float, hi: float) -> float:
	if v < lo:
		return lo
	if v > hi:
		return hi
	return v
