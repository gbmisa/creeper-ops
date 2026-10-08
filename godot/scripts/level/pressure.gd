class_name Pressure
extends RefCounted
## Mission pressure, 0..1 (§4.1). Levels carry "pressure": { grace, cap } in seconds.
## Optional "pressure_points": [{ t, p }, ...] replaces the straight line with a piecewise
## curve so a level can hit old tier times. 0 until grace, 1 at and after cap.
## legacy_tier maps that curve back onto the old 0..3 band (Skitter / Brute / Ravager / Behemoth).


static func value(level: Dictionary, t: float) -> float:
	var spec: Dictionary = level.get("pressure", {})
	var grace := float(spec.get("grace", 300.0))
	var cap := float(spec.get("cap", 2400.0))
	if t <= grace:
		return 0.0
	if t >= cap:
		return 1.0
	var points: Array = level.get("pressure_points", [])
	if points.is_empty():
		return clampf((t - grace) / maxf(cap - grace, 0.001), 0.0, 1.0)
	return _piecewise(points, t)


## Piecewise linear through points sorted by t. Before the first point, that point's p.
static func _piecewise(points: Array, t: float) -> float:
	var pts := points.duplicate()
	pts.sort_custom(func(a, b): return float(a.t) < float(b.t))
	if t <= float(pts[0].t):
		return clampf(float(pts[0].p), 0.0, 1.0)
	for i in range(1, pts.size()):
		var a: Dictionary = pts[i - 1]
		var b: Dictionary = pts[i]
		var ta := float(a.t)
		var tb := float(b.t)
		if t <= tb:
			var k := (t - ta) / maxf(tb - ta, 0.001)
			return clampf(lerpf(float(a.p), float(b.p), k), 0.0, 1.0)
	return clampf(float(pts.back().p), 0.0, 1.0)


## Old nest tier index from pressure. Unlocks: Brute 0.20, Ravager 0.60, Behemoth 0.85.
static func legacy_tier(p: float) -> int:
	if p >= 0.85:
		return 3
	if p >= 0.60:
		return 2
	if p >= 0.20:
		return 1
	return 0
