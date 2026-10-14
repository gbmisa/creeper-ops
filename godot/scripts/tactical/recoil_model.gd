class_name RecoilModel
extends RefCounted
## Camera / viewmodel recoil offset (degrees: x = pitch up, y = yaw) plus idle sway.

var offset := Vector2.ZERO


func shoot(def: Dictionary, rng: RandomNumberGenerator) -> void:
	var cap: float = def["up"] * TacticalConfig.RECOIL_CAP_SHOTS
	offset.x += def["up"] * clampf(1.0 - offset.x / cap, 0.0, 1.0)
	var side_cap: float = def["side"] * TacticalConfig.RECOIL_CAP_SHOTS
	offset.y = clampf(offset.y + rng.randf_range(-def["side"], def["side"]), -side_cap, side_cap)


## Converges back to zero faster with higher ergonomics.
func update(dt: float, ergo: float) -> void:
	var rate := lerpf(TacticalConfig.RECOIL_RATE_LOW, TacticalConfig.RECOIL_RATE_HIGH, ergo / 100.0)
	offset *= exp(-rate * dt)


## Breathing sway in degrees. hold = breath held; tired = arm stamina empty.
static func sway(t: float, def: Dictionary, hold: bool, tired: bool, arm_fracture: float = 0.0) -> Vector2:
	var amp: float = TacticalConfig.SWAY_BASE_DEG * def["kg"] / (def["ergo"] / 100.0 + 0.3) + arm_fracture * TacticalConfig.SWAY_BASE_DEG
	if hold:
		amp *= TacticalConfig.SWAY_HOLD_MULT
	if tired:
		amp *= TacticalConfig.SWAY_TIRED_MULT
	return Vector2(sin(t * 1.7) * 0.6, sin(t * 1.1 + 1.3)) * amp


static func ads_time(ergo: float) -> float:
	return lerpf(TacticalConfig.ADS_TIME_SLOW, TacticalConfig.ADS_TIME_FAST, ergo / 100.0)
