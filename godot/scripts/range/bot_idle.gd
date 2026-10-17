class_name BotIdle
extends RefCounted
## The small life in an enemy's body (BotBody): breathing in the chest, a slow sway, weight moving from leg to leg
## and glances around while it isn't shooting. Seeded per bot (its own RNG, never the global one) so no two bots move
## in step. Look only: hitboxes, the eye and the shot origin are BotPose's and don't follow any of this.

const BREATH_HZ := Vector2(0.21, 0.3)    # breaths per second (each bot picks one in this range)
const BREATH_RAD := 0.022                # chest pitch at the top of a breath (spine_02 + spine_03)
const SWAY_HZ := Vector2(0.07, 0.12)
const SWAY_RAD := 0.022                  # upper-body roll / yaw drift while standing
const SHIFT_HOLD := Vector2(3.5, 8.0)    # s standing on one leg before moving onto the other
const SHIFT_RATE := 1.4                  # 1/s: how fast the weight moves across (exponential)
const GLANCE_YAW := 0.6                  # widest head turn (rad), each way
const GLANCE_PITCH := Vector2(-0.08, 0.14)  # look up .. down (rad)
const GLANCE_HOLD := Vector2(1.0, 3.0)   # s looking at something
const GLANCE_GAP := Vector2(2.5, 6.5)    # s between glances; alert (not calm) bots look round twice as often
const GLANCE_RATE := 3.5                 # 1/s: head turn speed (exponential)
const STILL_RATE := 5.0                  # 1/s: standing-still blend in / out (~0.2 s, the clip crossfade)
const SHIFT_M := 0.035                   # pelvis sideways onto the standing leg (feet stay planted: BotLegs)
const SHIFT_DROP := 0.0                 # pelvis drop while on one leg (0: the head stays on its hitbox)
const SHIFT_ROLL := 0.06                 # hip drop on the relaxed leg's side (rad); the spine rolls it back
const SOFT_KNEE_M := 0.0                # pelvis drop in the aiming stance (0: the head stays on its hitbox)
const GAIT_STEADY := 0.6                 # share of the clip's pelvis roll the spine takes back while moving
const RUN_FROM := Vector2(3.0, 4.2)      # m/s: running blend 0 .. 1 (gun tucked in, BotHold run_at)

var rng := RandomNumberGenerator.new()
var breath := 0.0               # chest pitch now (rad, + = forward)
var sway := Vector2.ZERO        # x: roll toward the bot's +X, y: yaw toward -X (rad)
var shift := 0.0                # -1 on the left leg .. +1 on the right leg (eased)
var glance := Vector2.ZERO      # x: head yaw toward the bot's -X (left), y: head pitch down (rad)
var still := 1.0                # 0 moving or crouched .. 1 standing still (eased)
var gait := 0.0                 # 0 still .. 1 moving (eased)
var run := 0.0                  # 0 walking .. 1 running (eased)
var _t := 0.0
var _hz := 0.25
var _sway_hz := 0.1
var _phase := 0.0
var _shift_want := 1.0
var _shift_t := 0.0
var _glance_want := Vector2.ZERO
var _glance_t := 0.0


func _init(seed_v: int) -> void:
	rng.seed = seed_v
	_hz = rng.randf_range(BREATH_HZ.x, BREATH_HZ.y)
	_sway_hz = rng.randf_range(SWAY_HZ.x, SWAY_HZ.y)
	_phase = rng.randf() * TAU
	_t = rng.randf() * 60.0
	_shift_want = 1.0 if rng.randf() < 0.5 else -1.0
	shift = _shift_want
	_shift_t = rng.randf_range(0.0, SHIFT_HOLD.y)
	_glance_t = rng.randf_range(0.0, GLANCE_GAP.y)


## speed: ground speed (m/s). busy: aiming (no glances, weight centred). calm: unalerted (patrol).
func tick(dt: float, speed: float, crouch: bool, busy: float, calm: bool) -> void:
	_t += dt
	still = move_toward(still, 1.0 if speed < 0.3 and not crouch else 0.0, dt * STILL_RATE)
	gait = move_toward(gait, 1.0 if speed >= 0.3 else 0.0, dt * STILL_RATE)
	run = move_toward(run, clampf((speed - RUN_FROM.x) / (RUN_FROM.y - RUN_FROM.x), 0.0, 1.0), dt * STILL_RATE)
	var deep := 1.0 + 0.5 * (1.0 - still)  # breathing harder on the move
	breath = (sin(_t * TAU * _hz * deep) * 0.5 + 0.5) * BREATH_RAD * deep
	sway = Vector2(sin(_t * TAU * _sway_hz + _phase), sin(_t * TAU * _sway_hz * 0.73 + _phase * 1.7)) * SWAY_RAD * still * (1.0 - busy)
	_shift_t -= dt
	if _shift_t <= 0.0:
		_shift_want = -_shift_want
		_shift_t = rng.randf_range(SHIFT_HOLD.x, SHIFT_HOLD.y)
	shift = lerpf(shift, _shift_want, 1.0 - exp(-dt * SHIFT_RATE))
	_glance_t -= dt * (1.0 if calm else 2.0)
	if _glance_t <= 0.0:
		if _glance_want != Vector2.ZERO or rng.randf() < 0.25:
			_glance_want = Vector2.ZERO
			_glance_t = rng.randf_range(GLANCE_GAP.x, GLANCE_GAP.y)
		else:
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			_glance_want = Vector2(side * rng.randf_range(0.3, 1.0) * GLANCE_YAW, rng.randf_range(GLANCE_PITCH.x, GLANCE_PITCH.y))
			_glance_t = rng.randf_range(GLANCE_HOLD.x, GLANCE_HOLD.y)
	glance = glance.lerp(_glance_want * (1.0 - busy), 1.0 - exp(-dt * GLANCE_RATE))
