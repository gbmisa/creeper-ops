class_name LookWear
## Skirmish round 2 (visual only, no colliders, nothing on a bot route): wall wear (plaster patches, rust streaks, shutters,
## sector letters), roof clutter, wet asphalt strips, ground decals (leaf litter, stains) and decoration clusters beside the
## cover (sandbag nests, crate stacks). Cover colliders and positions are untouched. Headless skips it.

const ASPHALT := Color(0.09, 0.095, 0.1)
const RUST := Color(0.28, 0.14, 0.07, 1.0)
const SECTOR := {"hotel": "A-1", "barracks": "B-2", "cottage": "C-3", "warehouse": "D-4", "shack": "E-5"}
const YAW := {"s": 0.0, "n": 180.0, "w": -90.0, "e": 90.0}
## Cluster props near existing cover: [id, x, z, yaw, scale]. LookProps drops any that touch cover, buildings or routes.
const CLUSTERS := [
	["sandbags", -11.0, 28.0, 20, 0.8], ["sandbags", 9.0, 30.0, -10, 0.8], ["sandbags", -4.0, 12.0, 0, 0.8], ["sandbags", 5.0, 12.5, 0, 0.8],
	["sandbags", 22.0, 21.0, 70, 0.8], ["sandbags", -17.0, 25.0, 10, 0.8], ["sandbags", 50.0, 31.0, 0, 0.8], ["sandbags", -42.0, 18.0, 0, 0.8],
	["crate", 6.5, 28.5, 12, 0.9], ["crate", 22.5, 20.0, 40, 0.7], ["crate", -20.0, 13.0, 0, 0.8], ["crate", -20.8, 13.2, 25, 0.6],
	["crate", 10.0, 3.5, 0, 0.8], ["crate", -10.5, -19.0, 0, 0.8], ["crate", 13.5, -13.5, 10, 0.7], ["crate", 47.5, -11.0, 0, 0.8],
	["crate", -41.5, -11.5, 0, 0.7], ["crate", 12.0, -47.5, 0, 0.8], ["crate", 26.0, -45.5, 30, 0.7], ["crate", -6.5, -46.0, 0, 0.7],
	["pallets", 2.0, 30.0, 0, 0.9], ["pallets", -16.0, 27.0, 40, 0.9], ["drum", 48.5, -28.0, 0, 1.0], ["drum", -41.0, 41.5, 20, 1.0],
]


static func build(_layout: Node3D, n: Node3D) -> void:
	var w := Node3D.new()
	w.name = "Wear"
	n.add_child(w)
	_roads(w)
	_decals(w)
	for id in SkirmishData.BUILDINGS:
		_building(w, id, SkirmishData.BUILDINGS[id])
	LookProps.build(w, CLUSTERS, true)


## Wet asphalt: dark glossy strips (gate road, cross road, motor pool aprons). Flat boxes 2 cm proud of the ground.
static func _roads(n: Node3D) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = ASPHALT
	m.roughness = 0.42
	m.metallic = 0.0
	m.metallic_specular = 0.45
	for r in [[0.0, 38.0, 4.5, 20.0], [0.0, 17.0, 90.0, 3.4], [-10.0, 6.0, 5.6, 9.5], [6.0, -30.0, 5.6, 9.5], [0.0, -10.0, 3.0, 56.0]]:
		var mi := LookFacades.box(n, Vector3(r[0], 0.006, r[1]), Vector3(r[2], 0.012, r[3]), ASPHALT, 0.2)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if r[3] > 20.0 or r[2] > 20.0:   # roads get a faded centre line
			var vert: bool = r[3] > r[2]
			LookSigns.paint(n, Vector3(r[0], 0.0, r[1]), Vector2(0.12, r[3] * 0.9) if vert else Vector2(r[2] * 0.9, 0.12), Color(0.5, 0.45, 0.2))


## Leaf litter, stains and damp patches as projected decals (noise textures with alpha), scattered with a fixed seed.
static func _decals(n: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2209
	var tex := [_noise(Color(0.5, 0.26, 0.09), 0.5, 11), _noise(Color(0.12, 0.1, 0.08), 0.55, 23), _noise(Color(0.36, 0.3, 0.12), 0.5, 37)]
	var H: float = SkirmishData.HALF - 3.0
	for i in 70:
		var d := Decal.new()
		var s := rng.randf_range(3.0, 9.0)
		d.size = Vector3(s, 2.0, s * rng.randf_range(0.6, 1.4))
		d.position = Vector3(rng.randf_range(-H, H), 0.4, rng.randf_range(-H, H))
		d.rotation_degrees.y = rng.randf() * 360.0
		d.texture_albedo = tex[i % 3]
		d.modulate = Color(1, 1, 1, rng.randf_range(0.7, 1.0))
		d.upper_fade = 0.3
		n.add_child(d)


static func _noise(col: Color, cut: float, seed_: int) -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.seed = seed_
	fn.frequency = 0.02
	fn.fractal_octaves = 4
	nt.noise = fn
	nt.width = 256
	nt.height = 256
	nt.seamless = false
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, cut, minf(cut + 0.12, 0.99)])
	g.colors = PackedColorArray([Color(col, 0.0), Color(col, 0.0), Color(col, 0.9)])
	nt.color_ramp = g
	return nt


static func _building(n: Node3D, id: String, d: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var r := Rect2(d["rect"][0], d["rect"][1], d["rect"][2] - d["rect"][0], d["rect"][3] - d["rect"][1])
	var h: float = d["h"]
	var top: float = h * d["floors"]
	var pc: Array = LookFacades.PAINT[id]
	for side in YAW:
		var ops: Array = d["open"].get(side, [])
		var ops2: Array = d.get("open2", {}).get(side, [])
		var horiz: bool = side == "n" or side == "s"
		var a: float = r.position.x if horiz else r.position.y
		var b: float = r.end.x if horiz else r.end.y
		var fixed: float = (r.position.y if side == "n" else r.end.y) if horiz else (r.position.x if side == "w" else r.end.x)
		var o: float = LookFacades.OUT[side].x + LookFacades.OUT[side].y
		var f := [n, horiz, fixed, o]
		for lv in d["floors"]:
			var y0: float = lv * h
			var lops: Array = ops if lv == 0 else ops2
			_patches(f, rng, a, b, y0, h, lops, 4 if horiz else 3, pc[0])
			for op in lops:
				if op.size() > 2 and op[2] > 0.0:   # window: rust streaks off both lintel corners, shutter on the south / north faces
					var sill: float = op[2]
					for cx in [op[0] - 0.05, op[1] + 0.05, (op[0] + op[1]) * 0.5]:
						var hh := rng.randf_range(0.7, 1.5)
						LookFacades._quad(f, 0.07, cx - 0.04, cx + 0.04, maxf(y0 + sill - 0.1 - hh, y0 + 0.1), y0 + sill - 0.1, RUST, 0.02)
					if horiz:
						_shutter(n, side, fixed, o, op[0] - 0.12, op[1] - op[0], y0 + sill, pc[1])
		if lops_has_space(ops, a, b):
			var cx := (a + b) * 0.5
			var pos := Vector3(cx, 2.1, fixed + o * 0.2) if horiz else Vector3(fixed + o * 0.2, 2.1, cx)
			LookSigns.stencil(n, SECTOR[id], pos, YAW[side], 0.9, Color(0.82, 0.8, 0.7, 0.7))
	_roof_clutter(n, rng, r, top)


static func lops_has_space(ops: Array, a: float, b: float) -> bool:
	var c := (a + b) * 0.5
	for op in ops:
		if c > op[0] - 1.2 and c < op[1] + 1.2:
			return false
	return true


static func _patches(f: Array, rng: RandomNumberGenerator, a: float, b: float, y0: float, h: float, ops: Array, count: int, base: Color) -> void:
	for i in count:
		var w := rng.randf_range(0.8, 2.0)
		var c := rng.randf_range(a + 1.2, b - 1.2)
		var ok := true
		for op in ops:
			if c + w * 0.5 + 0.5 > op[0] and c - w * 0.5 - 0.5 < op[1]:
				ok = false
		if not ok:
			continue
		var y := y0 + rng.randf_range(0.9, h - 1.6)
		var col := base.lerp(Color(0.62, 0.58, 0.5), 0.5) if i % 2 == 0 else Color(0.2, 0.2, 0.19)
		LookFacades._quad(f, 0.09, c - w * 0.5, c + w * 0.5, y, y + rng.randf_range(0.5, 1.1), col, 0.02)


## A hanging shutter beside a window, swung outward on its jamb hinge.
static func _shutter(n: Node3D, side: String, fixed: float, o: float, hinge: float, w: float, sill: float, col: Color) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(hinge, sill + 0.55, fixed + o * 0.2)
	holder.rotation_degrees.y = (-55.0 if side == "s" else 125.0)
	n.add_child(holder)
	LookFacades.box(holder, Vector3(-w * 0.2, 0, 0), Vector3(w * 0.4, 1.1, 0.04), col.darkened(0.15), 0.9)


static func _roof_clutter(n: Node3D, rng: RandomNumberGenerator, r: Rect2, top: float) -> void:
	var y := top + 0.3
	var p := func() -> Vector3: return Vector3(rng.randf_range(r.position.x + 1.5, r.end.x - 1.5), y, rng.randf_range(r.position.y + 1.5, r.end.y - 1.5))
	for i in 2:
		var q: Vector3 = p.call()
		for k in 3:
			var t := LookFacades._cyl(n, q + Vector3(0, 0.15 + k * 0.3, 0), 0.38, 0.28, Color(0.07, 0.07, 0.07))
			t.position.x += (k % 2) * 0.05
	var tarp := LookFacades.box(n, p.call() + Vector3(0, 0.05, 0), Vector3(2.0, 0.1, 1.4), Color(0.2, 0.3, 0.4), 1.0)
	tarp.rotation_degrees.y = rng.randf() * 90.0
	var q2: Vector3 = p.call()
	LookFacades._cyl(n, q2 + Vector3(0, 1.0, 0), 0.025, 2.0, Color(0.25, 0.25, 0.25))
	var dish := LookFacades._cyl(n, q2 + Vector3(0.4, 1.6, 0), 0.5, 0.06, Color(0.65, 0.65, 0.62))
	dish.rotation_degrees.z = 55.0
	LookFacades.box(n, p.call() + Vector3(0, 0.6, 0), Vector3(0.9, 1.2, 0.9), Color(0.34, 0.2, 0.15), 0.9)   # chimney stack
