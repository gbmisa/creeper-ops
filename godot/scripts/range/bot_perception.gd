class_name BotPerception
extends RefCounted
## What one bot sees and hears: view cone + range + LOS rays to the player's head and thorax, a reaction delay
## before it is *aware*, the last known position, and the latest noise.

const FOV_DEG := 110.0
const RANGE := 120.0
const REACT_MIN := 0.35
const REACT_MAX := 1.0
const STILL_MULT := 1.4

var range_m := RANGE   # per bot (BotDefs sight)
var seeing := false       # raw cone + LOS this frame
var aware := false        # seeing for longer than the reaction delay
var react_left := -1.0
var sight_t := 0.0        # continuous time aware, drives the aim warm-up
var since_seen := 99.0
var last_known := Vector3.ZERO
var has_last := false
var noise_pos := Vector3.ZERO
var noise_new := false


static func in_view(eye: Vector3, fwd: Vector3, point: Vector3, max_range := RANGE) -> bool:
	var to := point - eye
	var d := to.length()
	if d > max_range or d < 0.01:
		return d < 0.01
	return rad_to_deg(fwd.angle_to(to)) <= FOV_DEG * 0.5


## True when any ray from `from` to a point reaches it without touching world geometry
## or a smoke volume.
static func los(space: PhysicsDirectSpaceState3D, from: Vector3, points: Array, smoke: Array = []) -> bool:
	for p in points:
		if _smoked(from, p, smoke):
			continue
		var q := PhysicsRayQueryParameters3D.create(from, p, TacticalConfig.LAYER_WORLD)
		if space.intersect_ray(q).is_empty():
			return true
	return false


static func _smoked(a: Vector3, b: Vector3, smoke: Array) -> bool:
	for s in smoke:
		if s.blocks(a, b):
			return true
	return false


## 0.35..1.0 s random, longer with distance, longer when the target is still or crouched.
static func reaction_delay(dist: float, still: bool, roll: float) -> float:
	var d := lerpf(REACT_MIN, REACT_MAX, clampf(roll, 0.0, 1.0)) * (1.0 + clampf(dist / RANGE, 0.0, 1.0))
	return d * (STILL_MULT if still else 1.0)


func update(dt: float, eye: Vector3, fwd: Vector3, space: PhysicsDirectSpaceState3D, pts: Array, still: bool, rng: RandomNumberGenerator, spot_mult := 1.0, smoke: Array = []) -> void:
	seeing = false
	for p in pts:
		if in_view(eye, fwd, p, range_m * spot_mult):
			seeing = true
			break
	seeing = seeing and los(space, eye, pts, smoke)
	if seeing:
		if not aware and react_left < 0.0:
			react_left = reaction_delay(eye.distance_to(pts[1] if pts.size() > 1 else pts[0]), still, rng.randf())
		if not aware:
			react_left -= dt
			if react_left <= 0.0:
				aware = true
		if aware:
			sight_t += dt
			last_known = pts[1] if pts.size() > 1 else pts[0]
			has_last = true
			since_seen = 0.0
	else:
		react_left = -1.0
		since_seen += dt
		if since_seen > 0.5:
			sight_t = 0.0
		if since_seen > 2.0:
			aware = false


## Hit from `from`, or told by the squad: instantly aware of that spot.
func alert(from: Vector3) -> void:
	last_known = from
	has_last = true
	aware = true
	react_left = 0.0
	since_seen = 0.0


func hear(pos: Vector3) -> void:
	noise_pos = pos
	noise_new = true
