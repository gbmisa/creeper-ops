class_name RecoilModel
extends RefCounted
## Tarkov recoil, the only model (F63): `Shoot(strength)` pushes three springs (weapon rotation,
## weapon position, camera rotation), the weapon's own curves play from each shot, and the hip
## wander moves the rotation's rest point. Springs step at a fixed 60 Hz (TacRecoilDefs.STEP) from an
## accumulator; read values are blended between the last two steps for drawing.
##
## Port of TRP's read-out of Tarkov's `NewRecoilShotEffect`: github.com/JuanFNQ/TRP,
## TRP/docs/spec/weapon-handling.md "Recoil" and crates/trp-sim/src/recoil.rs (Apache-2.0).
## Axes: weapon_rot() / camera_rot() are degrees in Tarkov's axes (x < 0 raises, weapon z / camera -y
## turn aside, weapon y and camera z roll); weapon_pos().y is metres back along the bore.
## `barrel` / `offset` are the same in game terms: x = pitch up, y = yaw (+ = left, Godot +Y).

var tarkov: bool:   # kept for old callers; there is no other model
	get: return true
	set(_v): pass

var aiming := false
var pose := 2              # 0 prone, 1 crouched, 2 standing
var auto_fire := false     # in a run of automatic fire (trigger held, auto mode)
var barrel := Vector2.ZERO
var offset := Vector2.ZERO
var shot_index := 0
var last_kick := Vector3.ZERO   # the last shot's direction vector (before routing) and angle (deg)
var last_angle := 0.0
var rng := RandomNumberGenerator.new()

var rot: RecoilRotation
var pos := RecoilSpring.new(TacRecoilDefs.POS_SPRING)
var cam := RecoilSpring.new(TacRecoilDefs.CAM_SPRING)
var hip := HipWander.new()
var row := {}
var _id := ""
var _seeded := false
var _now := 0.0
var _acc := 0.0
var _curves := []          # per curve: [clock, value]
var _prev := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _cur := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]


func _init() -> void:
	_use(TacRecoilDefs.resolve({"id": "ak47"}), "ak47")


func set_seed(s: int) -> void:
	rng.seed = s
	_seeded = true


## Switches to a gun's row; a different gun starts from rest (Tarkov builds the effector per weapon).
func _use(r: Dictionary, id: String) -> void:
	row = r
	if id != _id or rot == null:
		_id = id
		rot = RecoilRotation.new(r)
		pos = RecoilSpring.new(TacRecoilDefs.POS_SPRING)
		cam = RecoilSpring.new(TacRecoilDefs.CAM_SPRING)
		_curves = []
		for c in r["curves"]:
			_curves.append([1.0e9, 0.0])   # TRP: curves start finished
	rot.s = r
	hip.configure(r)


## One shot of the fitted gun (`def` = Gun.eff_def()). Call after the bullet left. strength = 1 + ammo rec / 100.
func shoot(def: Dictionary, src: RandomNumberGenerator = null, strength := 1.0) -> void:
	if not _seeded and src != null:
		set_seed(src.seed)
	_use(TacRecoilDefs.resolve(def), def.get("id", "ak47"))
	rot.intensity = TacRecoilDefs.AIM_INTENSITY if aiming else 1.0
	shot_index += 1
	var stable: int = row["stable_shot"]
	if shot_index == stable:
		rot.set_stable(true)
	rot.multiplier = clampf(shot_index, 1, stable) / float(stable) \
		if shot_index >= TacRecoilDefs.PROGRESS_POWER_SHOT and stable > 0 else 1.0
	var r_rng: Vector2 = row["rot_range"]
	var p_rng: Vector2 = row["pos_range"]
	var ang: Vector2 = row["angle_range"]
	for g in row["groups"]:
		if shot_index >= g["from"] and shot_index <= g["to"]:
			r_rng += g["rot"]
			p_rng += g["pos"]
			ang += g["angle"]
	var rp := rng.randf_range(r_rng.x, r_rng.y) * strength
	var pp := rng.randf_range(p_rng.x, p_rng.y) * strength
	if rot.stable_on:
		var lim: Vector2 = row["stable_angle"]
		rot.angle_add = RecoilSpring.unity_clamp(rot.angle_add + row["stable_step"], lim.x, lim.y)
		ang += Vector2(-rot.angle_add, rot.angle_add)
	last_angle = rng.randf_range(ang.x, ang.y)
	var a := deg_to_rad(last_angle)
	var f: Vector3 = TacRecoilDefs.POSE[clampi(pose, 0, 2)]
	var kick := Vector3(-sin(a) * rp * f.x, cos(a) * rp * f.y, pp * f.z) * TacRecoilDefs.POS_SPRING.z
	last_kick = kick
	rot.push(0, kick.x * TacRecoilDefs.TO_ROT)
	rot.push(2, kick.y * TacRecoilDefs.TO_ROT)
	pos.push(1, kick.z * TacRecoilDefs.TO_POS)
	cam.push(0, kick.x * row["camera"])
	cam.push(1, -kick.y * row["camera"])
	for c in _curves:
		c[0] = 0.0
		c[1] = 0.0
	hip.on_shot(_now, _hip_intensity(), aiming, rng)


func _hip_intensity() -> float:
	return (TacRecoilDefs.POSE[clampi(pose, 0, 2)] as Vector3).y


## Advances the springs by `dt` of real time in fixed steps. ergo / def are unused (old signature).
func update(dt: float, _ergo := 0.0, _def := {}) -> void:
	_acc += dt
	while _acc >= TacRecoilDefs.STEP - 1e-7:
		_acc -= TacRecoilDefs.STEP
		_step()
	var t := clampf(_acc / TacRecoilDefs.STEP, 0.0, 1.0)
	var w: Vector3 = (_prev[0] as Vector3).lerp(_cur[0], t)
	var c: Vector3 = (_prev[2] as Vector3).lerp(_cur[2], t)
	barrel = Vector2(-w.x, w.z)
	offset = Vector2(-c.x, -c.y)


func _step() -> void:
	var h := TacRecoilDefs.STEP
	_now += h
	rot.set_auto_fire(auto_fire)
	if not auto_fire:
		shot_index = 0
		rot.set_stable(false)
	rot.offset = hip.step(h, _now, _hip_intensity(), aiming, rng)
	pos.step()
	cam.step()
	rot.step(h, rng)
	var defs: Array = row["curves"]
	for i in _curves.size():
		var cd: Array = defs[i]
		_curves[i][1] = (cd[4] if aiming else cd[3]) * RecoilSpring.curve_at(TacRecoilDefs.KICK_CURVE, _curves[i][0])
		_curves[i][0] += h * cd[2]
	_prev = _cur
	_cur = [rot.value() + _curve_sum(2), pos.value() + _curve_sum(1), cam.current + _curve_sum(0)]


func _curve_sum(target: int) -> Vector3:
	var v := Vector3.ZERO
	var defs: Array = row["curves"]
	for i in _curves.size():
		if defs[i][0] == target:
			v[defs[i][1]] += _curves[i][1]
	return v


## The last step's values unblended [weapon rot, weapon pos, camera rot] (checks and probes).
func stepped() -> Array:
	return _cur


## Drawn (blended) values: weapon rotation (deg), weapon position (m), camera rotation (deg), Tarkov axes.
func weapon_rot() -> Vector3:
	return (_prev[0] as Vector3).lerp(_cur[0], clampf(_acc / TacRecoilDefs.STEP, 0.0, 1.0))


func weapon_pos() -> Vector3:
	return (_prev[1] as Vector3).lerp(_cur[1], clampf(_acc / TacRecoilDefs.STEP, 0.0, 1.0))


func camera_rot() -> Vector3:
	return (_prev[2] as Vector3).lerp(_cur[2], clampf(_acc / TacRecoilDefs.STEP, 0.0, 1.0))


## Where the bullets go: the camera basis turned by the part of the barrel angle the camera did not follow.
func aim_basis(cam_basis: Basis) -> Basis:
	var rest := barrel - offset
	var b := cam_basis.rotated(cam_basis.x, deg_to_rad(rest.x))
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
