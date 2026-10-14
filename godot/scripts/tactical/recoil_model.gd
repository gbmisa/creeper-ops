class_name RecoilModel
extends RefCounted
## Camera / viewmodel recoil offset (degrees: x = pitch up, y = yaw) plus idle sway.

## Classic (default): instant offset, bullets follow the camera. Tarkov (static flag, Esc menu): each shot is an
## impulse into a critically damped spring on the BARREL; the camera only follows by `cam_share`, the viewmodel and
## the bullets use the full barrel angle. `conv` pulls the barrel target back, so auto fire plateaus.
static var tarkov := false

var offset := Vector2.ZERO  # camera offset (deg): x = pitch up, y = yaw
var barrel := Vector2.ZERO  # Tarkov only: bore angle from the un-recoiled aim (deg)
var _tgt := Vector2.ZERO
var _vel := Vector2.ZERO
var _drift := 0.0


## The one place that reads a gun's kick numbers (attachments will scale them here): x = up, y = side.
static func kick_stats(def: Dictionary) -> Vector2:
	return Vector2(def["up"], def["side"])


func shoot(def: Dictionary, rng: RandomNumberGenerator) -> void:
	var ks := kick_stats(def)
	if tarkov:
		_drift = lerpf(_drift, rng.randf_range(-1.0, 1.0), TacticalConfig.RECOIL_T_DRIFT)
		var ang := deg_to_rad(def.get("angle", 90.0))
		var mag := ks.x * TacticalConfig.RECOIL_T_UP_MULT
		_tgt += Vector2(sin(ang) * mag, cos(ang) * mag + _drift * ks.y * TacticalConfig.RECOIL_T_SIDE_MULT)
		return
	var cap: float = ks.x * TacticalConfig.RECOIL_CAP_SHOTS
	offset.x += ks.x * clampf(1.0 - offset.x / cap, 0.0, 1.0)
	var side_cap: float = ks.y * TacticalConfig.RECOIL_CAP_SHOTS
	offset.y = clampf(offset.y + rng.randf_range(-ks.y, ks.y), -side_cap, side_cap)


## Classic: converges back to zero faster with higher ergonomics. Tarkov: spring + convergence (def gives conv, cam_share).
func update(dt: float, ergo: float, def: Dictionary = {}) -> void:
	if tarkov:
		_update_barrel(dt, def.get("conv", 6.0), def.get("cam_share", 0.35))
		return
	var rate := lerpf(TacticalConfig.RECOIL_RATE_LOW, TacticalConfig.RECOIL_RATE_HIGH, ergo / 100.0)
	offset *= exp(-rate * dt)


func _update_barrel(dt: float, conv: float, cam_share: float) -> void:
	var w := TacticalConfig.RECOIL_T_OMEGA
	var steps := maxi(1, ceili(dt / 0.004))
	var h := dt / float(steps)
	for i in steps:
		_tgt *= exp(-conv * h)
		_vel += ((_tgt - barrel) * w * w - _vel * 2.0 * w) * h
		barrel += _vel * h
	offset = barrel * cam_share


## Where the bullets go: the camera basis turned by the part of the barrel angle the camera did not follow.
func aim_basis(cam: Basis) -> Basis:
	if not tarkov:
		return cam
	var rest := barrel - offset
	var b := cam.rotated(cam.x, deg_to_rad(rest.x))
	return b.rotated(b.y, deg_to_rad(rest.y))


## Breathing sway in degrees. hold = breath held; tired = arm stamina empty.
static func sway(t: float, def: Dictionary, hold: bool, tired: bool, arm_fracture: float = 0.0) -> Vector2:
	var amp: float = TacticalConfig.SWAY_BASE_DEG * def["kg"] / (def["ergo"] / 100.0 + 0.3) + arm_fracture * TacticalConfig.SWAY_BASE_DEG
	if hold:
		amp *= TacticalConfig.SWAY_HOLD_MULT
	if tired:
		amp *= TacticalConfig.SWAY_TIRED_MULT
	return Vector2(sin(t * 1.7) * 0.6, sin(t * 1.1 + 1.3)) * amp * def.get("sway_mult", 1.0)


static func ads_time(ergo: float) -> float:
	return lerpf(TacticalConfig.ADS_TIME_SLOW, TacticalConfig.ADS_TIME_FAST, ergo / 100.0)
