class_name Grid
extends RefCounted
## Heightfield shared by terrain rendering, creeper sim, structures, units and the Operative.
## Cell (x, z) has its centre at world ((x+.5)*CELL, height*LEVEL_H, (z+.5)*CELL).
## The rendered terrain is a terraced bilinear surface through every cell centre, so
## smooth_y() matches what you see (and the creeper shader uses the same weights).

enum Zone { NONE = 0, BLIGHT = 1 }  # BLIGHT = agent-only: nothing can be built there

var w: int
var h: int
var height := PackedFloat32Array()  # terrain level per cell (fractional is fine)
var blocked := PackedByteArray()    # 1 = no building here (hazard footprint)
var zone := PackedByteArray()       # Zone per cell


func _init(width: int, depth: int) -> void:
	w = width
	h = depth
	height.resize(w * h)
	blocked.resize(w * h)
	zone.resize(w * h)


func idx(x: int, z: int) -> int:
	return z * w + x


func in_bounds(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < w and z < h


func height_at(x: int, z: int) -> float:
	if not in_bounds(x, z):
		return 99.0  # map edge acts as a wall
	return height[z * w + x]


func set_height(x: int, z: int, v: float) -> void:
	if in_bounds(x, z):
		height[z * w + x] = v


func zone_at(x: int, z: int) -> int:
	return zone[z * w + x] if in_bounds(x, z) else Zone.NONE


func world_to_cell(wx: float, wz: float) -> Vector2i:
	return Vector2i(floori(wx / Config.CELL), floori(wz / Config.CELL))


func cell_center(x: int, z: int) -> Vector3:
	return Vector3((x + 0.5) * Config.CELL, height_at(x, z) * Config.LEVEL_H, (z + 0.5) * Config.CELL)


## Ground point (on the smooth surface) at a cell centre.
func cell_ground(x: int, z: int) -> Vector3:
	var c := Vector3((x + 0.5) * Config.CELL, 0.0, (z + 0.5) * Config.CELL)
	c.y = smooth_y(c.x, c.z)
	return c


func h_clamped(x: int, z: int) -> float:
	return height[clampi(z, 0, h - 1) * w + clampi(x, 0, w - 1)]


## CW3 terraces: between two cell centres the ground stays flat, then ramps across a band
## around the shared edge (Config.TERRACE_BAND of the gap). Same formula as creeper.gdshader.
static func terrace(t: float) -> float:
	var b := Config.TERRACE_BAND
	return clampf((t - 0.5 + b * 0.5) / b, 0.0, 1.0)


## Ground height in world units: bilinear between cell centres with terraced weights
## (flat tops, steep walls). Matches the mesh vertices exactly.
func smooth_y(wx: float, wz: float) -> float:
	var fx := wx / Config.CELL - 0.5
	var fz := wz / Config.CELL - 0.5
	var x0 := floori(fx)
	var z0 := floori(fz)
	var tx := terrace(fx - x0)
	var tz := terrace(fz - z0)
	var a := h_clamped(x0, z0)
	var b := h_clamped(x0 + 1, z0)
	var c := h_clamped(x0, z0 + 1)
	var d := h_clamped(x0 + 1, z0 + 1)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz) * Config.LEVEL_H


## Stepped ground height (cell under the point).
func ground_y(wx: float, wz: float) -> float:
	var c := world_to_cell(wx, wz)
	return height_at(c.x, c.y) * Config.LEVEL_H


## Cells within a radius (in cells) of a centre cell: Array of Vector3i(x, z, dist*1000).
## Callers that need the distance use cells_in_radius_d.
func cells_in_radius(cx: int, cz: int, r: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var ri := ceili(r)
	var r2 := r * r
	for dz in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			if dx * dx + dz * dz > r2:
				continue
			var x := cx + dx
			var z := cz + dz
			if in_bounds(x, z):
				out.append(Vector2i(x, z))
	return out


## March a ray across the heightfield; returns the hit point or null. Cheaper than physics.
func raycast(origin: Vector3, dir: Vector3, max_dist := 600.0) -> Variant:
	var prev := 0.0
	var t := 0.0
	var ww := w * Config.CELL
	var dd := h * Config.CELL
	while t < max_dist:
		var p := origin + dir * t
		var inside := p.x >= 0.0 and p.z >= 0.0 and p.x <= ww and p.z <= dd
		if inside and p.y <= smooth_y(p.x, p.z):
			var lo := prev
			var hi := t
			for i in 10:
				var mid := (lo + hi) * 0.5
				var q := origin + dir * mid
				if q.y <= smooth_y(q.x, q.z):
					hi = mid
				else:
					lo = mid
			return origin + dir * hi
		prev = t
		t += 0.5
	return null


func world_size() -> Vector2:
	return Vector2(w * Config.CELL, h * Config.CELL)
