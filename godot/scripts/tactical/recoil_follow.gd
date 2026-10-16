class_name RecoilFollow
extends RefCounted
## The camera following the muzzle while aiming (Tarkov's `AddHandRecoilRotateToCamera`, TRP spec
## "Onto the camera"). `value` (deg, game terms: x = pitch up, y = yaw left) is added to the view.
## Spec gaps filled here (FB-I phase 2): the blend runs once per 60 Hz recoil step rather than per rendered
## frame (the spec notes the game's is frame-rate dependent); "the built rotation with y zeroed, times
## Euler(c)" is read as "the view turned by the muzzle's pitch and aside angles" (barrel in game terms).
## Port source: github.com/JuanFNQ/TRP TRP/docs/spec/weapon-handling.md (Apache-2.0).

var value := Vector2.ZERO
var speed := 0.2
var _held := Vector2.ZERO   # the kept target in stable automatic fire


## One step. c = the rotation process's current angles in game terms (no hip wander).
func step(row: Dictionary, dt: float, aiming: bool, auto: bool, stable: bool, c: Vector2) -> void:
	var lim: Vector2 = row["cam_to_weapon"]
	if not aiming:
		value = value.lerp(Vector2.ZERO, lim.y)   # only smooths: the view is not turned by the muzzle
		_held = value
		return
	var rate: float = row["cam_to_weapon_step"] * dt
	if auto and stable:
		value = value.lerp(_held, speed)
		return
	if auto:
		if c == Vector2.ZERO:
			return
		speed = minf(lim.y, speed + rate)
	else:
		speed = maxf(lim.x, speed - rate)
	_held = c
	value = value.lerp(c, speed)


## The view took `d` of the muzzle's settled residual: keep the camera where it is.
func folded(d: Vector2) -> void:
	value -= d
	_held -= d
