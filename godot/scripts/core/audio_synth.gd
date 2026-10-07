extends Node
## Autoload "Sfx": procedural sound effects, no asset files. Each voice is synthesised once
## into an AudioStreamWAV at startup. play(name, pos) throttles repeats per voice and
## attenuates by distance from the listener (the active camera).

const RATE := 22050
## name: [min seconds between plays, falloff distance m (0 = no falloff), recipe]
## recipe: list of [kind, start s, dur s, f0, f1, vol]; kind "sin"/"sq"/"saw"/"tri"/"noise"
const VOICES := {
	"blaster": [0.07, 70.0, [["sq", 0.0, 0.06, 1400, 500, 0.10]]],
	"mortar": [0.15, 90.0, [["sin", 0.0, 0.2, 160, 60, 0.5]]],
	"boom": [0.1, 110.0, [["noise", 0.0, 0.45, 600, 0, 0.6]]],
	"rifle": [0.04, 60.0, [["saw", 0.0, 0.09, 900, 120, 0.25], ["noise", 0.0, 0.06, 3000, 0, 0.2]]],
	"beam": [0.08, 70.0, [["saw", 0.0, 0.1, 2200, 1800, 0.12]]],
	"spray": [0.12, 0.0, [["noise", 0.0, 0.14, 1800, 0, 0.12]]],
	"hit": [0.05, 0.0, [["tri", 0.0, 0.05, 1800, 1200, 0.25]]],
	"hurt": [0.25, 0.0, [["saw", 0.0, 0.18, 220, 90, 0.3]]],
	"sizzle": [0.3, 0.0, [["noise", 0.0, 0.3, 4000, 0, 0.15]]],
	"build": [0.2, 120.0, [["sin", 0.0, 0.08, 520, 520, 0.2], ["sin", 0.08, 0.12, 780, 780, 0.2]]],
	"lift": [0.2, 120.0, [["sin", 0.0, 0.5, 220, 520, 0.25]]],
	"lost": [0.3, 200.0, [["sq", 0.0, 0.3, 330, 160, 0.2], ["noise", 0.0, 0.3, 800, 0, 0.3]]],
	"alarm": [2.5, 0.0, [["sq", 0.0, 0.12, 880, 880, 0.15], ["sq", 0.2, 0.12, 660, 660, 0.15]]],
	"teleport": [0.5, 0.0, [["sin", 0.0, 0.6, 200, 1600, 0.35]]],
	"good": [0.4, 0.0, [["tri", 0.0, 0.25, 523, 523, 0.25], ["tri", 0.09, 0.25, 659, 659, 0.25], ["tri", 0.18, 0.25, 784, 784, 0.25]]],
	"click": [0.03, 0.0, [["sin", 0.0, 0.03, 900, 700, 0.15]]],
	"deny": [0.15, 0.0, [["sq", 0.0, 0.12, 180, 150, 0.18]]],
	"unit": [0.1, 0.0, [["tri", 0.0, 0.08, 600, 900, 0.2]]],
	"pop": [0.05, 60.0, [["sin", 0.0, 0.1, 700, 200, 0.3]]],
	"lance": [1.0, 0.0, [["saw", 0.0, 1.2, 80, 1200, 0.25], ["noise", 0.9, 0.6, 1500, 0, 0.5]]],
}
const POOL := 12

var listener := Vector3.ZERO
var muted := false
var _streams := {}
var _last := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for n in VOICES:
		_streams[n] = _render(VOICES[n][2])
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func toggle_mute() -> bool:
	muted = not muted
	return muted


func play(voice: String, pos: Variant = null) -> void:
	if muted or not VOICES.has(voice):
		return
	var v: Array = VOICES[voice]
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last.get(voice, -99.0) < v[0]:
		return
	var vol := 1.0
	if pos != null and v[1] > 0.0:
		vol = 1.0 - (pos as Vector3).distance_to(listener) / v[1]
		if vol < 0.05:
			return
	_last[voice] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[voice]
	p.volume_db = linear_to_db(vol * 0.6)
	p.play()


func _render(recipe: Array) -> AudioStreamWAV:
	var total := 0.0
	for part in recipe:
		total = maxf(total, part[1] + part[2])
	var n := int((total + 0.02) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for part in recipe:
		_voice(buf, part)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = bytes
	return s


func _voice(buf: PackedFloat32Array, part: Array) -> void:
	var kind: String = part[0]
	var start := int(part[1] * RATE)
	var len := int(part[2] * RATE)
	var phase := 0.0
	var lp := 0.0
	for i in len:
		var t := float(i) / len
		var env: float = pow(0.001, t) * part[5]  # exponential decay like the WebAudio version
		var s := 0.0
		if kind == "noise":
			var a := clampf(part[3] / RATE * TAU, 0.0, 1.0)  # one-pole low-pass at cutoff
			lp += (randf() * 2.0 - 1.0 - lp) * a
			s = lp * 2.0
		else:
			var f: float = part[3] * pow(maxf(20.0, part[4]) / part[3], t)
			phase = fmod(phase + f / RATE, 1.0)
			match kind:
				"sin": s = sin(phase * TAU)
				"sq": s = 1.0 if phase < 0.5 else -1.0
				"saw": s = phase * 2.0 - 1.0
				"tri": s = 4.0 * absf(phase - 0.5) - 1.0
		if start + i < buf.size():
			buf[start + i] += s * env
