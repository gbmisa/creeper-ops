class_name HipWander
extends RefCounted
## The muzzle's wander from the hip and the gain hip shots add to it (Tarkov's breath effector, hip part).
## Port of TRP crates/trp-sim/src/breath.rs `SmoothRandom` / `Breath::on_shot` (github.com/JuanFNQ/TRP,
## Apache-2.0). Deviation (brief FB-I): base amplitude is TacRecoilDefs.HIP_BASE_AMP (0), not 1, so with no
## recent hip shots the offset is exactly zero and the first shot leaves along the hip dot ray.
## `offset` (deg, rotation-process axes: x pitch, z aside) is the rotation process's rest point.

var offset := Vector3.ZERO
var _x := _Smooth.new()
var _z := _Smooth.new()
var _gain := _Blend.new(0.0, 1.0)
var _hard := _Blend.new(0.0, TacRecoilDefs.HIP_HARDNESS_SPEED)
var _per_shot := 0.16
var _delay := 0.2


class _Smooth:
	var amplitude := TacRecoilDefs.HIP_BASE_AMP
	var hardness := TacRecoilDefs.HIP_REST_HARDNESS
	var count := 0.0
	var current := 0.0
	var increase := 0.0

	func value(dt: float, rng: RandomNumberGenerator) -> float:
		count -= dt
		if count < 0.0:
			count = rng.randf_range(TacRecoilDefs.HIP_DELAY.x, TacRecoilDefs.HIP_DELAY.y)
			var wanted := (rng.randf_range(-amplitude, amplitude) - current) / count
			increase += (wanted - increase) * hardness
		current += increase * dt
		if amplitude <= 0.0:   # FB-I: no gain left, nothing to wander about: back on the dot (same draws as TRP)
			current = 0.0
			increase = 0.0
		return current


## A value that moves toward its target at a fixed rate, after an optional hold (read off the clock).
class _Blend:
	var start_v := 0.0
	var start_t := 0.0
	var target := 0.0
	var speed := 0.0

	func _init(v: float, spd: float) -> void:
		start_v = v
		target = v
		speed = spd

	func value(now: float) -> float:
		var moved := start_v + maxf(now - start_t, 0.0) * speed * signf(target - start_v)
		return clampf(moved, minf(target, start_v), maxf(target, start_v))

	func set_target(t: float, now: float) -> void:
		if target != t:
			start_v = value(now)
			start_t = now
			target = t

	func jump(v: float, hold: float, now: float) -> void:
		start_t = now + hold
		start_v = v


func _init() -> void:
	_hard.set_target(TacRecoilDefs.HIP_REST_HARDNESS, 0.0)


## gain per hip shot, hold before it falls (s), fall rate (/s): the weapon's hip_gain / hip_delay / hip_speed.
func configure(row: Dictionary) -> void:
	_per_shot = row["hip_gain"]
	_delay = row["hip_delay"]
	_gain.speed = row["hip_speed"]


func gain(now: float) -> float:
	return _gain.value(now)


## A shot was fired (after its bullet left). From the hip it widens the wander and throws the rest point.
func on_shot(now: float, intensity: float, aiming: bool, rng: RandomNumberGenerator) -> void:
	if aiming:
		return
	var g := _gain.value(now)
	g += maxf(0.0, _per_shot - 0.2 * (sqrt(g) - 1.0))
	_gain.jump(g, _delay, now)
	_hard.jump(TacRecoilDefs.HIP_SHOT_HARDNESS, 0.0, now)
	for sm in [_x, _z]:
		sm.amplitude = clampf(TacRecoilDefs.HIP_BASE_AMP + g, 0.0, TacRecoilDefs.HIP_AMP_MAX)
		sm.hardness = TacRecoilDefs.HIP_SHOT_HARDNESS
	var up := _x.value(rng.randf_range(TacRecoilDefs.HIP_THROW.x, TacRecoilDefs.HIP_THROW.y), rng)
	var aside := _z.value(rng.randf_range(TacRecoilDefs.HIP_THROW.x, TacRecoilDefs.HIP_THROW.y), rng)
	var k := intensity * TacRecoilDefs.HIP_PENALTY
	offset = Vector3(minf(offset.x, up) * k, 0.0, aside / 2.0 * k)


## One physics step; returns the rotation process's rest point.
func step(dt: float, now: float, intensity: float, aiming: bool, rng: RandomNumberGenerator) -> Vector3:
	var widened := sqrt(_gain.value(now))
	var hard := _hard.value(now)
	for sm in [_x, _z]:
		sm.amplitude = clampf(TacRecoilDefs.HIP_BASE_AMP + widened, 0.0, TacRecoilDefs.HIP_AMP_MAX)
		sm.hardness = hard
	var want := Vector3.ZERO
	if not aiming:
		var k := intensity * TacRecoilDefs.HIP_PENALTY
		want = Vector3(_x.value(dt, rng) * k, 0.0, _z.value(dt, rng) * k)
	if (want - offset).length_squared() > 0.01:
		offset += (want - offset) * 0.1
	else:
		offset = want
	return offset
