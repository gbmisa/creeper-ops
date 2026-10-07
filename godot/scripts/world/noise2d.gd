class_name Noise2D
extends RefCounted
## Deterministic 2D value noise (fractal sum, ~0..1). Seeded so levels are reproducible.
## Same algorithm as the JS prototype so ported levels keep their shape.

var perm := PackedInt32Array()


func _init(seed_value := 1) -> void:
	var s := seed_value & 0xffffffff
	var p := []
	for i in 256:
		p.append(i)
	for i in range(255, 0, -1):
		s = (s * 1664525 + 1013904223) & 0xffffffff
		var j := int(floor(float(s) / 4294967296.0 * (i + 1)))
		var t: int = p[i]
		p[i] = p[j]
		p[j] = t
	perm.resize(512)
	for i in 512:
		perm[i] = p[i & 255]


func _hash(x: int, z: int) -> float:
	return perm[(perm[x & 255] + z) & 511] / 255.0


func _value(x: float, z: float) -> float:
	var x0 := floori(x)
	var z0 := floori(z)
	var tx := x - x0
	var tz := z - z0
	tx = tx * tx * (3.0 - 2.0 * tx)
	tz = tz * tz * (3.0 - 2.0 * tz)
	var a := _hash(x0, z0)
	var b := _hash(x0 + 1, z0)
	var c := _hash(x0, z0 + 1)
	var d := _hash(x0 + 1, z0 + 1)
	var top := a + (b - a) * tx
	return top + ((c + (d - c) * tx) - top) * tz


func fbm(x: float, z: float, octaves := 3) -> float:
	var amp := 1.0
	var freq := 1.0
	var sum := 0.0
	var norm := 0.0
	for o in octaves:
		sum += _value(x * freq, z * freq) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return sum / norm
