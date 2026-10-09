class_name SfxRender
## Offline synthesis for the Sfx autoload: turns a recipe (list of parts) into an AudioStreamWAV.
## part: [kind, start s, dur s, f0, f1, vol, opts?]
##   kind: "sin" / "sq" / "saw" / "tri" (pitch sweeps f0 -> f1) or "noise" (low-pass sweeps
##   f0 -> f1; f1 = 0 keeps f0).
##   opts: a (attack s, default 0.003), env ("exp" | "lin" | "flat"), hp (noise high-pass Hz),
##   drive (tanh saturation), vib ([rate Hz, depth as a pitch fraction]),
##   trem ([rate Hz, depth 0..1]).

const RATE := 22050
const XFADE := 0.25  # loop crossfade, seconds


## loop > 0 renders a seamless loop of that many seconds (beds); parts should be "flat".
static func render(recipe: Array, loop := 0.0) -> AudioStreamWAV:
	var total := loop
	if loop <= 0.0:
		for part in recipe:
			total = maxf(total, part[1] + part[2])
		total += 0.02
	var n := int(total * RATE)
	var fade := int(XFADE * RATE) if loop > 0.0 else 0
	var buf := PackedFloat32Array()
	buf.resize(n + fade)
	for part in recipe:
		_part(buf, part)
	if fade > 0:
		for i in fade:  # fold the tail over the head so the seam is inaudible
			var k := float(i) / fade
			buf[i] = buf[i] * k + buf[n + i] * (1.0 - k)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(tanh(buf[i] * 1.2) * 30000.0))  # soft clip the mix
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = bytes
	if loop > 0.0:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
	return s


static func _part(buf: PackedFloat32Array, part: Array) -> void:
	var kind: String = part[0]
	var start := int(part[1] * RATE)
	var len := maxi(1, int(part[2] * RATE))
	var f0: float = part[3]
	var f1: float = part[4]
	var vol: float = part[5]
	var o: Dictionary = part[6] if part.size() > 6 else {}
	var atk := maxf(1.0, o.get("a", 0.003) * RATE)
	var env_kind: String = o.get("env", "exp")
	var hp: float = o.get("hp", 0.0)
	var drive: float = o.get("drive", 0.0)
	var vib: Array = o.get("vib", [0.0, 0.0])
	var trem: Array = o.get("trem", [0.0, 0.0])
	var phase := 0.0
	var lp := 0.0
	var lp2 := 0.0
	for i in len:
		var j := start + i
		if j >= buf.size():
			break
		var t := float(i) / len
		var sec := float(i) / RATE
		var env := 1.0
		match env_kind:
			"exp": env = pow(0.001, t)
			"lin": env = 1.0 - t
		env *= minf(1.0, i / atk)
		if trem[0] > 0.0:
			env *= 1.0 - trem[1] * (0.5 + 0.5 * sin(sec * TAU * trem[0]))
		var s := 0.0
		if kind == "noise":
			var cut := f0 if f1 <= 0.0 else f0 * pow(f1 / f0, t)
			lp += (randf() * 2.0 - 1.0 - lp) * clampf(cut / RATE * TAU, 0.0, 1.0)
			s = lp * 2.0
			if hp > 0.0:  # band-pass: remove what a lower low-pass keeps
				lp2 += (lp - lp2) * clampf(hp / RATE * TAU, 0.0, 1.0)
				s = (lp - lp2) * 2.5
		else:
			var f := f0 * pow(maxf(20.0, f1) / f0, t)
			if vib[0] > 0.0:
				f *= 1.0 + vib[1] * sin(sec * TAU * vib[0])
			phase = fmod(phase + f / RATE, 1.0)
			match kind:
				"sin": s = sin(phase * TAU)
				"sq": s = 1.0 if phase < 0.5 else -1.0
				"saw": s = phase * 2.0 - 1.0
				"tri": s = 4.0 * absf(phase - 0.5) - 1.0
		if drive > 0.0:
			s = tanh(s * (1.0 + drive))
		buf[j] += s * env * vol
