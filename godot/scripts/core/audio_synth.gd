extends Node
## Autoload "Sfx": procedural sound effects, no asset files. Voices (SfxVoices) are synthesised
## by SfxRender on a worker thread at startup; play() before they are ready is silent.
## play(name, pos) throttles repeats per voice, jitters pitch, and attenuates by distance from
## the listener (set by the active mode). One-shots go through the "Sfx" bus (short reverb,
## compressor, limiter); looping ambience beds (set_bed) go through "Amb".

const POOL := 16
const BED_SMOOTH := 1.5  # bed volume follows its target at this rate per second

var listener := Vector3.ZERO
var muted := false
var _streams := {}
var _last := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _beds := {}  # name -> AudioStreamPlayer
var _bed_target := {}
var _bed_now := {}
var _task := -1


func _ready() -> void:
	_make_buses()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		_players.append(p)
	if DisplayServer.get_name() == "headless":
		_streams = _render_voices()  # tests check _last right away; no beds headless
	else:
		_task = WorkerThreadPool.add_task(_render_all)


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)


func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Amb"), muted)
	return muted


func play(voice: String, pos: Variant = null) -> void:
	if muted or not _streams.has(voice):
		return
	var v: Array = SfxVoices.VOICES[voice]
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last.get(voice, -99.0) < v[0]:
		return
	var vol := 1.0
	if pos != null and v[1] > 0.0:
		vol = pow(maxf(0.0, 1.0 - (pos as Vector3).distance_to(listener) / v[1]), 1.5)
		if vol < 0.03:
			return
	_last[voice] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL
	var jitter: float = v[3] if v.size() > 3 else 0.03
	p.stream = _streams[voice]
	p.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	p.volume_db = linear_to_db(vol * 0.6)
	p.play()


## Target loudness (0..1) of a looping ambience bed ("wind", "cave", "creeper").
func set_bed(bed: String, vol: float) -> void:
	_bed_target[bed] = clampf(vol, 0.0, 1.0)


## Every bed off at once, no fade (leaving the command game for the Firing Range / Skirmish).
func silence_beds() -> void:
	for bed in _beds:
		_bed_target[bed] = 0.0
		_bed_now[bed] = 0.0
		(_beds[bed] as AudioStreamPlayer).stop()


func _process(delta: float) -> void:
	for bed in _beds:
		var p: AudioStreamPlayer = _beds[bed]
		var now: float = _bed_now.get(bed, 0.0)
		now = move_toward(now, _bed_target.get(bed, 0.0), delta * BED_SMOOTH)
		_bed_now[bed] = now
		p.volume_db = linear_to_db(maxf(now, 0.0001))
		if now > 0.001 and not p.playing:
			p.play(randf() * 3.0)
		elif now <= 0.001 and p.playing:
			p.stop()


func _render_voices() -> Dictionary:
	var out := {}
	for n in SfxVoices.VOICES:
		out[n] = SfxRender.render(SfxVoices.VOICES[n][2])
	return out


func _render_all() -> void:
	_set_streams.call_deferred(_render_voices())
	var loops := {}
	var defs := SfxVoices.beds()
	for n in defs:
		loops[n] = SfxRender.render(defs[n][1], defs[n][0])
	_set_beds.call_deferred(loops)


func _set_streams(out: Dictionary) -> void:
	_streams = out


func _set_beds(loops: Dictionary) -> void:
	for n in loops:
		var p := AudioStreamPlayer.new()
		p.bus = "Amb"
		p.stream = loops[n]
		p.volume_db = -80.0
		add_child(p)
		_beds[n] = p


func _make_buses() -> void:
	if AudioServer.get_bus_index("Sfx") >= 0:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, "Sfx")
	var rev := AudioEffectReverb.new()
	rev.room_size = 0.35
	rev.damping = 0.6
	rev.wet = 0.1
	AudioServer.add_bus_effect(i, rev)
	var comp := AudioEffectCompressor.new()
	comp.threshold = -14.0
	comp.ratio = 3.0
	AudioServer.add_bus_effect(i, comp)
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -1.0
	AudioServer.add_bus_effect(i, lim)
	AudioServer.add_bus(i + 1)
	AudioServer.set_bus_name(i + 1, "Amb")
	AudioServer.set_bus_volume_db(i + 1, -6.0)
