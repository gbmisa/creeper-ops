class_name BotNoise
## Sound events the bots listen for. Per-session instance (MULTIPLAYER.md rule 1); listeners are
## Callables (pos, radius, kind, src). Shots carry 150 m, sprinting footsteps 20 m, walking 8 m,
## crouch-walking nothing.

const SHOT_R := 150.0
const SPRINT_R := 20.0
const WALK_R := 8.0

var listeners: Array = []


func reset() -> void:
	listeners.clear()


func listen(cb: Callable) -> void:
	listeners.append(cb)


func emit(pos: Vector3, radius: float, kind: String, src: Object = null) -> void:
	if radius <= 0.0:
		return
	listeners = listeners.filter(func(c): return c.is_valid())
	for c in listeners:
		c.call(pos, radius, kind, src)


static func step_radius(sprinting: bool, crouching: bool) -> float:
	if sprinting:
		return SPRINT_R
	return 0.0 if crouching else WALK_R
