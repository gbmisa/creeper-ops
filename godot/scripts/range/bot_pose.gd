class_name BotPose
extends RefCounted
## ScavBot stance. Crouch: in cover (TakeCover / Heal, once there), crouch-walking while Investigating, Searching or
## Flanking, and crouch-firing from a standstill beyond BOT_CROUCH_FIRE_M. Lean: a bot in cover that can't see the
## threat from where it crouches leans out the side that can, shoots (BotEngage.peek), and leans back when it can't.
## Like the player's crouch/lean, the pose moves the eye (sight and shot origin) and the hitboxes, not just the mesh.

const CROUCH_MOVE := [BotBrain.INVESTIGATE, BotBrain.SEARCH, BotBrain.FLANK]
const IN_COVER := [BotBrain.COVER, BotBrain.HEAL]

var crouch := false
var k := 0.0          # 0 standing .. 1 crouched (smoothed)
var lean := 0.0       # -1 left .. 1 right, toward the bot's +X (smoothed)
var lean_want := 0.0
var _peek_t := 0.0


## Once per physics tick, after think(): pick the stance, ease toward it, move hitboxes and the mesh pose.
func update(b: ScavBot, dt: float) -> void:
	var s := b.brain.state
	var covered := s in IN_COVER and b._arrived()
	var still := Vector2(b.velocity.x, b.velocity.z).length() < 0.3
	var far := b.percept.has_last and b._flat(b.percept.last_known - b.global_position).length() > TacticalConfig.BOT_CROUCH_FIRE_M
	crouch = covered or s in CROUCH_MOVE or (s == BotBrain.ENGAGE and b.percept.seeing and still and far)
	_peek_t -= dt
	if not (covered and s == BotBrain.COVER and b.percept.has_last) or b.gun.busy():
		lean_want = 0.0
	elif _peek_t <= 0.0:
		_peek_t = TacticalConfig.BOT_PEEK_CHECK
		lean_want = _peek_side(b)
	k = move_toward(k, 1.0 if crouch else 0.0, dt * TacticalConfig.BOT_STANCE_RATE)
	lean = move_toward(lean, lean_want, dt * TacticalConfig.BOT_LEAN_RATE)
	for z in b.rig:
		var n := b.rig[z] as Node3D
		n.position = point(HitboxRig.SHAPES[z][0])
		n.rotation.z = -lean * TacticalConfig.BOT_LEAN_RAD if (HitboxRig.SHAPES[z][0] as Vector3).y > TacticalConfig.BOT_LEAN_PIVOT else 0.0
	b.mesh.crouch = crouch
	b.mesh.lean = lean * lerpf(1.0, TacticalConfig.BOT_CROUCH_K, k)  # crouched hitboxes lean less far; so does the mesh


## True while leaned most of the way out (BotEngage.peek only shoots then).
func peeking() -> bool:
	return lean_want != 0.0 and absf(lean) > 0.9


## A standing-pose point (bot local, feet at 0) moved by the current crouch and lean.
func point(p: Vector3, lean_k := INF) -> Vector3:
	var l := lean if lean_k == INF else lean_k
	var hk := lerpf(1.0, TacticalConfig.BOT_CROUCH_K, k)
	var y := p.y * hk
	var pivot := TacticalConfig.BOT_LEAN_PIVOT * hk
	var rel := y - pivot
	if l == 0.0 or rel <= 0.0:
		return Vector3(p.x, y, p.z)
	var a := l * TacticalConfig.BOT_LEAN_RAD
	return Vector3(p.x * cos(a) + rel * sin(a), pivot - p.x * sin(a) + rel * cos(a), p.z)


## The eye in world space (sight checks and the shot origin).
func eye(b: ScavBot, lean_k := INF) -> Vector3:
	return b.global_transform * point(Vector3(0, ScavBot.EYE, 0), lean_k)


## 0 if the threat is in sight from the crouch (or from neither side), else the side (+1 right, -1 left) whose leaned
## eye sees it; right first. The side is taken facing the threat, which BotMotion turns the bot toward.
func _peek_side(b: ScavBot) -> float:
	var threat := b.percept.last_known + Vector3(0, 1.4, 0)
	var space := b.get_world_3d().direct_space_state
	if BotPerception.los(space, eye(b, 0.0), [threat]):
		return 0.0
	var d := b._flat(threat - b.global_position)
	if d.length() < 0.05:
		return 0.0
	var right := d.normalized().cross(Vector3.UP)
	var e := eye(b, 0.0)
	var out := point(Vector3(0, ScavBot.EYE, 0), 1.0) - point(Vector3(0, ScavBot.EYE, 0), 0.0)  # +x out, -y down
	for side in [1.0, -1.0]:
		if BotPerception.los(space, e + right * side * out.x + Vector3.UP * out.y, [threat]):
			return side
	return 0.0
