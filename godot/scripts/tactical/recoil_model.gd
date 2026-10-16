class_name RecoilModel
extends RefCounted
## Camera / viewmodel recoil offset (degrees: x = pitch up, y = yaw) plus idle sway.
##
## Single recoil model (FB-H, from the EFT community reverse-engineering research): two
## separately-parameterized channels:
##   (1) BARREL (bore angle, aim-affecting): each shot is an impulse into a critically-damped spring
##       (`_tgt`/`_vel`, OMEGA). Per-gun `conv` decays the target so auto fire plateaus. A compensation
##       ramp scales the added impulse 1.0 -> RECOIL_T_COMP_MIN over the first RECOIL_T_COMP_SHOTS shots,
##       so the first shots kick hardest and sustained fire self-limits vertically. Horizontal is per-shot
##       pseudo-random (`side * disp`) plus a low-passed drift wander. Compensation only scales the ADDED
##       impulse — it never subtracts, and pitch impulses are never negative, so the model can never drag
##       the aim low by itself; the player's manual pull-down stacks additively and is never fought.
##   (2) CAMERA (view pitch/yaw, `offset`): its own impulse channel with per-gun `cam_up` (magnitude) and
##       `cam_snap` (return rate). A critically-damped spring drives the camera toward
##       `_cam_tgt + _climb`; `_climb` keeps RECOIL_T_CLIMB_FRAC of every impulse, capped at
##       RECOIL_T_CLIMB_MAX, and never recenters — the view stays displaced until the player re-aims or
##       switches weapons (`reset()`).
## Bullets use `aim_basis()`: the camera rotated by `barrel - offset` (the bore the camera didn't follow).
## The viewmodel follows the same `barrel - offset` term (visual). A separate random shake spring in
## TacticalViewmodel is visual-only and never touches this model.
##
## Model notes (TRP spec, TRP/docs/spec/weapon-handling.md, Apache-2.0 — numbers used, no code copied):
## - "Recoil / The position and camera processes": a shot adds force to a spring, then per step
##   `Velocity += Force * Intensity; Velocity -= (Current - Offset) * ReturnSpeed; Velocity *= Damping`.
##   Ours is the same shape with an explicit dt and critical damping (OMEGA), so it is
##   frame-rate independent where TRP's runs at the physics step.
## - "Recoil / The rotation process": TRP enters stable mode on the weapon's RecoilStableIndexShot
##   (5 for the AKM) and the muzzle stops climbing from there. Ours plateaus via per-gun `conv`
##   pulling the spring target back; `conv` values are tuned so the plateau sets in around shot 5.
## - "Recoil / What a shot does": recoil angle about 90 deg = straight up (AKM 80..90). Our per-gun
##   `angle` column follows the same convention (80..100).
## - "Recoil / Onto the camera": the camera blends toward the weapon's climb by a per-frame fraction
##   (AKM CameraToWeaponAngleSpeedRange 0.1..0.2). FB-H replaces the old fixed `cam_share` with the
##   camera's own impulse channel (`cam_up`, `cam_snap`) plus permanent climb.
## - "Recoil / Measured" (stock AKM, standing): one shot raises the muzzle 1.6 deg from the hip,
##   1.2 deg aiming; full auto sits 7..8 deg from the 5th shot, never above 10.3. Our `up` column
##   keeps the game's existing tuning (smaller, game-feel scaled); the plateau SHAPE matches.
## FB-H judgment calls (not datamined; tuned approximations): the 1.0 -> 0.45 compensation ramp, the
## per-gun `cam_up` / `cam_snap` / `disp` values, CLIMB_FRAC 0.35 and CLIMB_MAX 6.0. BSG's exact per-shot
## constants were never published — no faithful open-source reimplementation of them exists.
var offset := Vector2.ZERO  # camera offset (deg): x = pitch up, y = yaw
var barrel := Vector2.ZERO  # bore angle from the un-recoiled aim (deg)
var _tgt := Vector2.ZERO
var _vel := Vector2.ZERO
var _drift := 0.0
# Camera channel (FB-H): _cam springs toward _cam_tgt + _climb; offset always mirrors _cam.
var _cam := Vector2.ZERO
var _cam_tgt := Vector2.ZERO
var _cam_vel := Vector2.ZERO
var _climb := Vector2.ZERO  # permanent camera climb; cleared by reset()
var _shots := 0  # consecutive shots in the current burst
var _since_shot := 99.0


## The one place that reads a gun's kick numbers (attachments will scale them here): x = up, y = side.
static func kick_stats(def: Dictionary) -> Vector2:
	return Vector2(def["up"], def["side"])


## Permanent (non-recentering) camera climb, for tests.
func climb() -> Vector2:
	return _climb


## Clears bore, camera, climb and burst state. Called on weapon switch so climb never leaks between guns.
func reset() -> void:
	offset = Vector2.ZERO
	barrel = Vector2.ZERO
	_tgt = Vector2.ZERO
	_vel = Vector2.ZERO
	_drift = 0.0
	_cam = Vector2.ZERO
	_cam_tgt = Vector2.ZERO
	_cam_vel = Vector2.ZERO
	_climb = Vector2.ZERO
	_shots = 0
	_since_shot = 99.0


func shoot(def: Dictionary, rng: RandomNumberGenerator) -> void:
	var ks := kick_stats(def)
	_shots += 1
	_since_shot = 0.0
	# Automatic recoil compensation: the first shots kick hardest, sustained fire self-limits.
	var comp := lerpf(1.0, TacticalConfig.RECOIL_T_COMP_MIN,
		clampf(float(_shots - 1) / (TacticalConfig.RECOIL_T_COMP_SHOTS - 1.0), 0.0, 1.0))
	_drift = lerpf(_drift, rng.randf_range(-1.0, 1.0), TacticalConfig.RECOIL_T_DRIFT)
	var ang := deg_to_rad(def.get("angle", 90.0))
	var disp: float = def.get("disp", 1.0)
	var mag := ks.x * comp * TacticalConfig.RECOIL_T_UP_MULT
	var h := rng.randf_range(-1.0, 1.0) * ks.y * disp * TacticalConfig.RECOIL_T_SIDE_MULT
	_tgt += Vector2(sin(ang) * mag, cos(ang) * mag + _drift * ks.y * TacticalConfig.RECOIL_T_SIDE_MULT + h)
	# Camera channel: its own impulse with its own scalars; a share becomes permanent climb.
	var cam_up: float = def.get("cam_up", 0.6)
	var cimp := Vector2(ks.x * cam_up * comp, rng.randf_range(-1.0, 1.0) * ks.y * cam_up * disp)
	_cam_tgt += cimp
	_climb += cimp * TacticalConfig.RECOIL_T_CLIMB_FRAC
	var cm := TacticalConfig.RECOIL_T_CLIMB_MAX
	if _climb.length() > cm:
		_climb = _climb.normalized() * cm


## Bore spring + convergence (def gives conv); camera spring at cam_snap toward its target plus the
## permanent climb.
func update(dt: float, def: Dictionary) -> void:
	_since_shot += dt
	if _since_shot >= TacticalConfig.RECOIL_T_BURST_GAP:
		_shots = 0  # burst over: tapping re-triggers the full first-shot kick
	_update_barrel(dt, def.get("conv", 6.0))
	_update_camera(dt, def.get("cam_snap", TacticalConfig.RECOIL_T_CAM_SNAP))
	offset = _cam


func _update_barrel(dt: float, conv: float) -> void:
	var w := TacticalConfig.RECOIL_T_OMEGA
	var steps := maxi(1, ceili(dt / 0.004))
	var h := dt / float(steps)
	for i in steps:
		_tgt *= exp(-conv * h)
		_vel += ((_tgt - barrel) * w * w - _vel * 2.0 * w) * h
		barrel += _vel * h


func _update_camera(dt: float, snap: float) -> void:
	var steps := maxi(1, ceili(dt / 0.004))
	var h := dt / float(steps)
	for i in steps:
		_cam_tgt *= exp(-snap * h)
		_cam_vel += (((_cam_tgt + _climb) - _cam) * snap * snap - _cam_vel * 2.0 * snap) * h
		_cam += _cam_vel * h


## Where the bullets go: the camera basis turned by the part of the barrel angle the camera did not follow.
func aim_basis(cam: Basis) -> Basis:
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
