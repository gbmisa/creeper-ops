class_name BotSteps
extends RefCounted
## F107: 3D footsteps for a bot. Same synthesized "step" voice and 1.7 m stride as the player's (TacticalPlayer), rate by
## actual ground speed, silent when still, quieter crouched. Heard out to BotNoise's walk / sprint radius. Sound only:
## nothing is emitted on the noise bus, so bots' hearing logic is unchanged.

const STRIDE := 1.7
const MIN_SPEED := 0.5
const SPRINT_SPEED := 3.8      # a bot at or above this is running (ScavBot.RUN 4.2 x its class speed)
const WALK_DB := -4.4
const SPRINT_DB := 0.0
const CROUCH_DB := -10.0
const CROUCH_R := 4.0

var _t := 0.0
var _snd: AudioStreamPlayer3D


## Call every physics frame with the bot's real horizontal speed. `crouched`: bots don't crouch yet; the hook is here.
func tick(bot: Node3D, dt: float, speed: float, on_floor: bool, crouched := false) -> void:
	if speed < MIN_SPEED or not on_floor:
		return
	_t -= dt * speed
	if _t > 0.0:
		return
	_t = STRIDE
	var sprint := speed >= SPRINT_SPEED
	if _snd == null:
		var stream = Sfx.get("_streams").get("step") if Sfx != null else null
		if stream == null:
			return
		_snd = AudioStreamPlayer3D.new()
		_snd.stream = stream
		_snd.unit_size = 4.0
		_snd.pitch_scale = 1.0
		bot.add_child(_snd)
	_snd.max_distance = CROUCH_R if crouched else (BotNoise.SPRINT_R if sprint else BotNoise.WALK_R)
	_snd.volume_db = CROUCH_DB if crouched else (SPRINT_DB if sprint else WALK_DB)
	_snd.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	_snd.play()
