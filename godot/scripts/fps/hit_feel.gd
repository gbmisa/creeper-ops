class_name HitFeel
extends RefCounted
## State for the Operative's felt feedback: hit marker, kill confirm, red arcs toward whatever
## hurt you and a screen-edge vignette on big hits. HitOverlay draws it. Enemy code that knows
## where a blow came from calls HitFeel.note_source(pos) just before it hits the Operative.

static var _src := Vector3.ZERO
static var _src_at := -99.0

var marker_t := 0.0
var kill_t := 0.0
var arcs: Array[Dictionary] = []   # { src: Vector3, t: float }
var vignette_t := 0.0
var camera: Camera3D


static func note_source(pos: Vector3) -> void:
	_src = pos
	_src_at = Time.get_ticks_msec() / 1000.0


func update(dt: float) -> void:
	marker_t = maxf(0.0, marker_t - dt)
	kill_t = maxf(0.0, kill_t - dt)
	vignette_t = maxf(0.0, vignette_t - dt)
	for i in range(arcs.size() - 1, -1, -1):
		arcs[i].t -= dt
		if arcs[i].t <= 0.0:
			arcs.remove_at(i)


## A shot landed on an enemy. `killed` turns the marker red with a crunch.
func confirm(killed: bool) -> void:
	marker_t = Config.HIT_MARKER_TIME
	if killed:
		kill_t = Config.KILL_MARKER_TIME
		Sfx.play("crunch")
	else:
		Sfx.play("tick")


func hurt(amount: float) -> void:
	if amount >= Config.BIG_HIT:
		vignette_t = Config.VIGNETTE_TIME
	if Time.get_ticks_msec() / 1000.0 - _src_at > 0.25:
		return  # the attacker is unknown: vignette only
	for a in arcs:
		if (a.src as Vector3).distance_to(_src) < 3.0:
			a.t = Config.HURT_ARC_TIME
			return
	if arcs.size() >= 4:
		arcs.remove_at(0)
	arcs.append({ "src": _src, "t": Config.HURT_ARC_TIME })


## Clockwise angle from straight ahead to the direction of `src` (radians), 0 if unknown.
func arc_angle(src: Vector3) -> float:
	if camera == null:
		return 0.0
	var b := camera.global_transform.basis
	var d := src - camera.global_position
	return atan2(d.dot(b.x), -d.dot(b.z))
