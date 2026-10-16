class_name BotPerception
extends RefCounted
## What one bot sees and hears: view cone + range + LOS rays to the player's head and thorax, a reaction delay
## before it is *aware*, the last known position, and the latest noise.

const FOV_DEG := 110.0
const RANGE := 120.0
const REACT_MIN := 0.35
const REACT_MAX := 1.0
const STILL_MULT := 1.4
const ALERT_TIME := 30.0       # F87: seconds a heard gunshot keeps a bot alert
const ALERT_REACT_MULT := 0.35 # alert bots react this much faster (sight delay and first shot)
const ALERT_AIM_HEAD := 1.5    # alert bots start the aim warm-up this many seconds in

var range_m := RANGE   # per bot (BotDefs sight)
var seeing := false       # raw cone + LOS this frame
var aware := false        # seeing for longer than the reaction delay
var react_left := -1.0
var sight_t := 0.0        # continuous time aware, drives the aim warm-up
var since_seen := 99.0
var last_known := Vector3.ZERO   # mirrors contact.pos (kept for callers)
var has_last := false            # mirrors contact.has()
var contact := BotContact.new()  # F97: the enemy as a memory, not a live fix
var noise_pos := Vector3.ZERO
var noise_new := false
var shot_new := false     # the latest noise was a gunshot (cleared with noise_new)
var alert_t := 0.0
var _was_seeing := false


static func in_view(eye: Vector3, fwd: Vector3, point: Vector3, max_range := RANGE) -> bool:
	var to := point - eye
	var d := to.length()
	if d > max_range or d < 0.01:
		return d < 0.01
	return rad_to_deg(fwd.angle_to(to)) <= FOV_DEG * 0.5


## True when any ray from `from` to a point reaches it without touching world geometry.
static func los(space: PhysicsDirectSpaceState3D, from: Vector3, points: Array) -> bool:
	for p in points:
		var q := PhysicsRayQueryParameters3D.create(from, p, TacticalConfig.LAYER_WORLD)
		if space.intersect_ray(q).is_empty():
			return true
	return false


## 0.35..1.0 s random, longer with distance, longer when the target is still or crouched.
static func reaction_delay(dist: float, still: bool, roll: float) -> float:
	var d := lerpf(REACT_MIN, REACT_MAX, clampf(roll, 0.0, 1.0)) * (1.0 + clampf(dist / RANGE, 0.0, 1.0))
	return d * (STILL_MULT if still else 1.0)


func update(dt: float, eye: Vector3, fwd: Vector3, space: PhysicsDirectSpaceState3D, pts: Array, still: bool, rng: RandomNumberGenerator, spot_mult := 1.0) -> void:
	alert_t = maxf(0.0, alert_t - dt)
	seeing = false
	for p in pts:
		if in_view(eye, fwd, p, range_m * spot_mult):
			seeing = true
			break
	seeing = seeing and los(space, eye, pts)
	if seeing:
		if not aware and react_left < 0.0:
			react_left = reaction_delay(eye.distance_to(pts[1] if pts.size() > 1 else pts[0]), still, rng.randf())
			if alerted():
				react_left *= ALERT_REACT_MULT
		if not aware:
			react_left -= dt
			if react_left <= 0.0:
				aware = true
		if aware:
			sight_t += dt
			contact.sight(pts[1] if pts.size() > 1 else pts[0])
			since_seen = 0.0
	else:
		react_left = -1.0
		since_seen += dt
		if since_seen > 0.5:
			sight_t = 0.0
		if since_seen > 2.0:
			aware = false
	if _was_seeing and not seeing:
		contact.lose_sight()
	_was_seeing = seeing
	tick(dt)


## Ages the contact even when there is no player to sense (dead, missing). Called every think.
func tick(dt: float) -> void:
	contact.tick(dt)
	last_known = contact.pos
	has_last = contact.has()


## Hit from `from`, or told by the squad: instantly aware of that spot.
func alert(from: Vector3) -> void:
	contact.hit(from)
	aware = true
	react_left = 0.0
	since_seen = 0.0
	tick(0.0)


## F87: a gunshot also makes the bot alert. F97: the shot contact is fuzzy, never the exact spot.
func hear(pos: Vector3, shot: bool, dist: float, rng: RandomNumberGenerator) -> void:
	noise_pos = pos
	noise_new = true
	if shot:
		shot_new = true
		alert_t = ALERT_TIME
		contact.shot(pos, dist, rng)
		tick(0.0)


func alerted() -> bool:
	return alert_t > 0.0
