class_name BotSteps
extends RefCounted
## F107: 3D footsteps for a bot. Same synthesized "step" voice and 1.7 m stride as the player's (TacticalPlayer), rate by
## actual ground speed, silent when still, quieter crouched. Heard out to WALK_HEAR_R / SPRINT_HEAR_R. Sound only:
## nothing is emitted on the noise bus, so bots' hearing logic is unchanged.

const STRIDE := 1.7
const MIN_SPEED := 0.5
const SPRINT_SPEED := 3.8      # a bot at or above this is running (ScavBot.RUN 4.2 x its class speed)
const WALK_DB := 0.0           # F118: was -4.4 (Gregory couldn't hear bots coming up behind him)
const SPRINT_DB := 3.0         # F118: was 0.0
const WALK_HEAR_R := 15.0      # F118: heard out to 15 m walking / 30 m running (was BotNoise 8 / 20; bots' hearing unchanged)
const SPRINT_HEAR_R := 30.0
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
		_snd.unit_size = 6.0  # F118: was 4
		_snd.attenuation_filter_db = 0.0  # F118: no distance low-pass on steps (room muffling still applies)
		_snd.pitch_scale = 1.0
		bot.add_child(_snd)
	_snd.max_distance = CROUCH_R if crouched else (SPRINT_HEAR_R if sprint else WALK_HEAR_R)
	_snd.volume_db = CROUCH_DB if crouched else (SPRINT_DB if sprint else WALK_DB)
	_snd.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	var sp := RangeSpace.treat(RangeAudio._listener(), bot.global_position)
	RangeSpace.ensure_buses()
	_snd.bus = sp["bus"]
	_snd.volume_db += sp["db"]
	_snd.play()
