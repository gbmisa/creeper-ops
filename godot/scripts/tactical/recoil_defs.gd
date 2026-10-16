class_name TacRecoilDefs
## Per-gun Tarkov recoil rows (`recoil` settings, F63) and the player prefab's fixed numbers.
##
## Port of TRP's read-out of Tarkov's `NewRecoilShotEffect` (github.com/JuanFNQ/TRP,
## TRP/docs/spec/weapon-handling.md "Recoil" and crates/trp-sim/src/recoil.rs, Apache-2.0).
## Names follow the template fields: force_up = RecoilForceUp, force_back = RecoilForceBack, angle /
## dispersion = RecoilAngle / RecolDispersion, camera = RecoilCamera, convergence = RecoilReturnSpeedHandRotation
## x RecoilConvergenceMult, damping = RecoilDampingHandRotation, category_mult =
## RecoilCategoryMultiplierHandRotation, stable_shot = RecoilStableIndexShot, hip_* = HipInnaccuracyGain /
## HipAccuracyRestorationDelay / HipAccuracyRestorationSpeed, post_v / post_h = PostRecoil{Vertical,Horizontal}
## RangeHandRotation, return_offset / return_damping = RecoilReturnPath{Offset,Damping}HandRotation.
## The AK47 row is the stock AKM. Where the spec gives no AKM figure (force_up, force_back, camera) the
## value is worked back from the spec's measured shots (see docs/tasks/FB_I_tarkov_recoil_progress.md);
## the return path / stable widening use TRP's assault-rifle test settings; curves are unmeasured.

# --- prefab (player) values, the same for every gun ---
const STEP := 1.0 / 60.0                     # physics step: springs never see a frame dt
const ROT_STRENGTH := Vector2(0.9, 1.15)     # BasicRecoilRotationStrengthRange
const POS_STRENGTH := Vector2(0.65, 1.05)    # BasicRecoilPositionStrengthRange
const FORCE_K := 0.1399
const VERT_BONUS := 20.0                     # Aiming.RecoilVertBonus
const BACK_BONUS := 20.0                     # Aiming.RecoilBackBonus
const PROGRESS_POWER_SHOT := 2
const AIM_INTENSITY := 0.75                  # Aiming.AimProceduralIntensity
## Stance factors per axis [x, y, z], index 0 prone, 1 crouched, 2 standing.
const POSE := [Vector3(0.6, 0.7, 0.7), Vector3(0.7, 0.7, 0.7), Vector3(1.0, 1.0, 1.0)]
## ShotRecoilProcessValues: x -> rot x, y -> rot z, z -> pos y (m), x -> cam x (x camera), y -> cam y (x -camera).
const TO_ROT := 0.15
const TO_POS := 0.0007
const POS_SPRING := Vector3(0.08, 0.5, 1.0)  # return speed, damping, intensity
const CAM_SPRING := Vector3(0.05, 0.5, 1.0)
const NEXT_STABLE := Vector2(0.1, 8.0)       # NextStablePointDistanceRange
const STABLE_LIMIT := 0.95                   # ToNextStablePointDistanceLimit
const TO_NEXT_SPEED := 0.2                   # ToNextCurrentSpeed
const RETURN_CURVE := 0.008                  # ReturnSpeedCurve (flat on the prefab)
# hip wander (breath effector). Deviation from TRP (brief FB-I): base amplitude 0, not 1, so a rested
# hip shot leaves exactly along the hip dot ray. hip_penalty / throw / hardness_speed are not in the spec.
const HIP_BASE_AMP := 0.0
const HIP_DELAY := Vector2(0.2, 0.7)
const HIP_PENALTY := 1.0
const HIP_THROW := Vector2(0.2, 0.7)         # _randomBetween
const HIP_SHOT_HARDNESS := 0.15
const HIP_REST_HARDNESS := 0.1
const HIP_HARDNESS_SPEED := 0.1
const HIP_AMP_MAX := 3.0

## Curve shape every AKM curve uses: [time, value] keys, linear between keys.
const KICK_CURVE := [[0.0, 0.0], [0.1, 2.0], [0.3, -0.75], [1.0, 0.0]]

const AK := {
	"force_up": 104.0, "force_back": 270.0, "angle": 85.0, "dispersion": 11.0,
	"groups": [{"from": 1, "to": 200, "rot": Vector2.ZERO, "pos": Vector2.ZERO, "angle": Vector2(6.0, -6.0)}],
	"camera": 0.05, "convergence": 2.4, "damping": 0.86, "category_mult": 0.19, "stable_shot": 5,
	"stable_step": 2.5, "stable_angle": Vector2(0.0, 28.0),
	"post_v": Vector2(-1.5, 0.0), "post_h": Vector2(-1.5, 1.5),
	"return_offset": 0.01, "return_damping": 0.48, "reset_after_shot": false,
	"hip_gain": 0.16, "hip_delay": 0.2, "hip_speed": 7.0,
	"camera_snap": 3.5, "cam_to_weapon": Vector2(0.1, 0.2), "cam_to_weapon_step": 0.1,
	"pivot": Vector3(0.0, -0.25, 0.0),
	# [target (0 camera rot, 1 weapon pos, 2 weapon rot), axis, time mult, value mult, aiming value mult]
	"curves": [[2, 1, 1.0, 1.0, 0.5], [1, 1, 1.0, 0.001, 0.0005], [0, 2, 1.0, 0.25, 0.125]],
}

## Tuning-panel overrides by gun id (phase 2 writes here); merged over the scaled row.
static var overrides := {}


## The recoil row for a gun id: the AK row with force_up / force_back scaled by the def's `up`, and
## dispersion (and the group's narrowing with it) by `side`, both relative to the AK47's.
static func row(id: String) -> Dictionary:
	var r: Dictionary = AK.duplicate(true)
	if id != "ak47" and WeaponDefs.ROWS.has(id):
		var d: Dictionary = WeaponDefs.ROWS[id]
		var ak: Dictionary = WeaponDefs.ROWS["ak47"]
		var up: float = d["up"] / ak["up"]
		var side: float = d["side"] / ak["side"]
		r["force_up"] = AK["force_up"] * up
		r["force_back"] = AK["force_back"] * up
		r["dispersion"] = AK["dispersion"] * side
		r["groups"][0]["angle"] = AK["groups"][0]["angle"] * side
	if overrides.has(id):
		r.merge(overrides[id], true)
	return r


## Resolved shot ranges for a fitted gun (`eff` = Gun.eff_def()): parts = stat(up) / def up.
static func resolve(eff: Dictionary) -> Dictionary:
	var id: String = eff.get("id", "ak47")
	var r := row(id)
	var base: Dictionary = WeaponDefs.ROWS.get(id, WeaponDefs.ROWS["ak47"])
	var parts := maxf(0.0, float(eff.get("up", base["up"])) / float(base["up"]))
	var spread := float(eff.get("side", base["side"])) / float(base["side"])
	r["rot_range"] = ROT_STRENGTH * (r["force_up"] * parts + VERT_BONUS) * FORCE_K
	r["pos_range"] = POS_STRENGTH * (r["force_back"] * parts + BACK_BONUS) * FORCE_K
	var disp: float = r["dispersion"] * spread
	r["angle_range"] = Vector2(r["angle"] - disp, r["angle"] + disp)
	for g in r["groups"]:   # the group narrows the range by the same share
		g["angle"] = g["angle"] * spread
	return r
