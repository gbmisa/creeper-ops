class_name BowSounds
## F146: procedural bow sounds (no recorded samples for them yet). RangeAudio.stream falls back to make() for a stem it
## has no file for, so these play through the normal RangeAudio paths (sample events, SoundDefs profiles). A recorded
## bow_twang.ogg / crossbow_thunk.ogg / arrow_thud.ogg in assets/audio/range/ replaces each one by name.

const RATE := 22050
static var _made := {}


static func make(stem: String) -> AudioStream:
	if not _made.has(stem):
		match stem:
			"bow_twang":
				_made[stem] = _wav(0.55, 3, func(t: float, n: float) -> float:
					return (sin(TAU * 196.0 * t) * 0.55 + sin(TAU * 392.0 * t) * 0.25 + sin(TAU * 588.0 * t) * 0.1) * exp(-t * 9.0) + n * exp(-t * 80.0) * 0.5)
			"crossbow_thunk":
				_made[stem] = _wav(0.35, 5, func(t: float, n: float) -> float:
					return sin(TAU * (120.0 - 60.0 * t) * t) * exp(-t * 18.0) * 0.8 + sin(TAU * 310.0 * t) * exp(-t * 14.0) * 0.3 + n * exp(-t * 60.0) * 0.5)
			"arrow_thud":
				_made[stem] = _wav(0.16, 9, func(t: float, n: float) -> float:
					return sin(TAU * 85.0 * t) * exp(-t * 30.0) * 0.8 + n * exp(-t * 45.0) * 0.3)
			_:
				return null
	return _made[stem]


## n = white noise sample for this instant; f(t, n) -> -1..1.
static func _wav(secs: float, seed_: int, f: Callable) -> AudioStreamWAV:
	var count := int(RATE * secs)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for i in count:
		var v: float = f.call(float(i) / RATE, rng.randf_range(-1.0, 1.0))
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 28000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
