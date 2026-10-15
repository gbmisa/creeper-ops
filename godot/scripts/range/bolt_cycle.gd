class_name BoltCycle
extends RefCounted
## Procedural bolt-action cycle for a gun glb rigged with `Bolt` + `BoltHandle` bones (Mosin-Nagant). Handle lifts
## about the bore axis (rest: pointing right; local bone Y = -Z gun, so a -angle local-Y turn lifts it), both bones
## slide back along +Z, return, handle drops. Measured on mosin.glb: bore axis at gun-space x=-0.0077, y=0.0646
## (the handle pivot); knob at rest (0.0241, 0.0644, 0.1985) = def["bolt_knob"]. Handle clears the stock (stock top
## y<=0.063 behind z=0.2, handle tip y<=0.101 raised). Guns with a FireWBullet clip keep their baked animation.

const AXIS_XY := Vector2(-0.0077, 0.0646)  # bore axis in gun space (x, y)

var skel: Skeleton3D
var bolt := -1
var handle := -1
var knob := Vector3.ZERO  # gun space, at rest
var t := 1.0  # 0..1 through the cycle; 1 = idle
var len := 1.0
var _rest_b: Transform3D
var _rest_h: Transform3D


## Null unless the model is rigged for it and has no baked cycle clip.
static func make(glb: Node, def: Dictionary) -> BoltCycle:
	if not def.has("bolt_knob"):
		return null
	var sk := glb.find_children("*", "Skeleton3D", true, false)
	if sk.is_empty() or sk[0].find_bone("Bolt") < 0 or sk[0].find_bone("BoltHandle") < 0:
		return null
	for ap in glb.find_children("*", "AnimationPlayer", true, false):
		if (ap as AnimationPlayer).has_animation("FireWBullet"):
			return null
	var b := BoltCycle.new()
	b.skel = sk[0]
	b.bolt = b.skel.find_bone("Bolt")
	b.handle = b.skel.find_bone("BoltHandle")
	b.knob = def["bolt_knob"]
	b._rest_b = b.skel.get_bone_rest(b.bolt)
	b._rest_h = b.skel.get_bone_rest(b.handle)
	return b


func start(secs: float) -> void:
	len = maxf(secs, 0.1)
	t = 0.0


func playing() -> bool:
	return t < 1.0


## (handle lift 0..1, slide 0..1) at cycle fraction f, each leg eased.
static func profile(f: float) -> Vector2:
	var s: Array = TacticalConfig.BOLT_SPLIT
	var a: float = s[0]
	var b: float = a + float(s[1])
	var c: float = b + float(s[2])
	if f < a:
		return Vector2(smoothstep(0.0, a, f), 0.0)
	if f < b:
		return Vector2(1.0, smoothstep(a, b, f))
	if f < c:
		return Vector2(1.0, 1.0 - smoothstep(b, c, f))
	return Vector2(1.0 - smoothstep(c, 1.0, f), 0.0)


func lift() -> float:
	return profile(t).x


func slide() -> float:
	return profile(t).y


func angle() -> float:
	return deg_to_rad(TacticalConfig.BOLT_ANGLE_DEG) * lift()


func travel() -> float:
	return TacticalConfig.BOLT_TRAVEL * slide()


func update(delta: float) -> void:
	if t >= 1.0:
		return
	t = minf(1.0, t + delta / len)
	_pose()


func _pose() -> void:
	var tr := travel()
	var q := Quaternion(Vector3(0, 1, 0), -angle())  # local Y = -Z gun
	skel.set_bone_pose_position(bolt, _rest_b.origin + Vector3(0, 0, tr))
	skel.set_bone_pose_position(handle, _rest_h.origin + Vector3(0, 0, tr))
	skel.set_bone_pose_rotation(handle, _rest_h.basis.get_rotation_quaternion() * q)


## The knob in gun space with the current bone poses applied.
func knob_now() -> Vector3:
	var rel := Vector3(knob.x - AXIS_XY.x, knob.y - AXIS_XY.y, 0.0).rotated(Vector3(0, 0, 1), angle())
	return Vector3(AXIS_XY.x + rel.x, AXIS_XY.y + rel.y, knob.z + travel())


## Right-hand target (gun space): the grip, leaving it for the knob and returning.
func hand_r(grip: Vector3) -> Vector3:
	if t >= 1.0:
		return grip
	var e := TacticalConfig.BOLT_HAND_BLEND
	return grip.lerp(knob_now(), smoothstep(0.0, e, t) * (1.0 - smoothstep(1.0 - e, 1.0, t)))


## Roll about the bore (radians, for the viewmodel) toward the hand: peaks mid-stroke.
func roll() -> float:
	if t >= 1.0:
		return 0.0
	return deg_to_rad(TacticalConfig.BOLT_ROLL_DEG) * sin(t * PI)
