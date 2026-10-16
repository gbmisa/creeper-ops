class_name LookFacades
## Visual-only facades over the Skirmish building collision: trims round doors and windows, sills, plinth and eave bands,
## roof lips, drain pipes, conduits, wall lamps, roof units. No collision; nothing is placed inside an opening, so doors
## and windows stay exactly as wide as the collision says. Skirmish only.

const TRIM := Color(0.78, 0.77, 0.7)
const PLINTH := Color(0.2, 0.2, 0.19)
const PIPE := Color(0.33, 0.35, 0.33)
const PAINT := {   # per building: [paint band, door colour]
	"hotel": [Color(0.8, 0.74, 0.6), Color(0.22, 0.32, 0.28)],
	"barracks": [Color(0.46, 0.55, 0.48), Color(0.3, 0.36, 0.3)],
	"cottage": [Color(0.5, 0.58, 0.52), Color(0.4, 0.22, 0.18)],
	"warehouse": [Color(0.55, 0.3, 0.2), Color(0.3, 0.32, 0.3)],
	"shack": [Color(0.58, 0.58, 0.5), Color(0.28, 0.3, 0.26)],
	# MAP-2 west old town
	"garage": [Color(0.5, 0.48, 0.36), Color(0.3, 0.32, 0.3)],
	"storehouse": [Color(0.72, 0.66, 0.52), Color(0.36, 0.24, 0.18)],
	"pumphouse": [Color(0.55, 0.6, 0.62), Color(0.26, 0.3, 0.32)],
	"clinic": [Color(0.82, 0.82, 0.76), Color(0.55, 0.16, 0.14)],
	"bunkhouse": [Color(0.46, 0.55, 0.48), Color(0.3, 0.36, 0.3)],
	"row_a": [Color(0.75, 0.62, 0.48), Color(0.25, 0.3, 0.36)],
	"workshop": [Color(0.6, 0.45, 0.2), Color(0.3, 0.32, 0.3)],
	"office": [Color(0.66, 0.7, 0.66), Color(0.22, 0.32, 0.28)],
}
const OUT := {"n": Vector2(0, -1), "s": Vector2(0, 1), "w": Vector2(-1, 0), "e": Vector2(1, 0)}

static var _mi_mats := {}


static func build(parent: Node3D) -> void:
	for id in SkirmishData.BUILDINGS:
		var d: Dictionary = SkirmishData.BUILDINGS[id]
		var r := Rect2(d["rect"][0], d["rect"][1], d["rect"][2] - d["rect"][0], d["rect"][3] - d["rect"][1])
		var pc: Array = PAINT[id]
		var levels: Array = [[0.0, d["h"], d["open"]]]
		if d["floors"] == 2:
			levels.append([d["h"], d["h"], d["open2"]])
		var n := Node3D.new()
		n.name = "facade_" + id
		parent.add_child(n)
		for lv in levels:
			for side in OUT:
				_side(n, r, side, lv[0], lv[1], lv[2].get(side, []), pc)
		var top: float = d["h"] * levels.size()
		_roof(n, r, top, d["floors"] == 2)
		_details(n, r, id, top, pc)


## One wall face: plinth, paint band, eave strip and trims round every opening.
static func _side(n: Node3D, r: Rect2, side: String, y0: float, h: float, ops: Array, pc: Array) -> void:
	var horiz := side == "n" or side == "s"
	var a: float = r.position.x if horiz else r.position.y
	var b: float = r.end.x if horiz else r.end.y
	var fixed: float = (r.position.y if side == "n" else r.end.y) if horiz else (r.position.x if side == "w" else r.end.x)
	var o: float = OUT[side].x + OUT[side].y   # outward sign
	var f := [n, horiz, fixed, o]
	if y0 == 0.0:
		_strip(f, a, b, y0, 0.0, 0.5, 0.06, PLINTH, ops)
	_strip(f, a, b, y0, h - 0.45, 0.3, 0.05, pc[0], ops)    # eave band
	_strip(f, a, b, y0, 0.5, 0.12, 0.03, pc[0], ops)        # stencil stripe above the plinth
	for op in ops:
		var door: bool = op.size() < 3 or op[2] <= 0.0
		var sill: float = 0.0 if door else op[2]
		var top: float = SkirmishParts.DOOR_TOP if door else sill + SkirmishParts.WINDOW_H
		var t := 0.12
		var col: Color = pc[1] if door else TRIM
		_quad(f, 0.0, op[0] - t, op[0], y0 + sill, y0 + top + t, col, 0.07)    # left jamb
		_quad(f, 0.0, op[1], op[1] + t, y0 + sill, y0 + top + t, col, 0.07)    # right jamb
		_quad(f, 0.0, op[0] - t, op[1] + t, y0 + top, y0 + top + t, col, 0.07)  # lintel
		if not door:
			_quad(f, 0.0, op[0] - t, op[1] + t, y0 + sill - 0.1, y0 + sill, TRIM, 0.14)   # sill
		else:
			_quad(f, 0.0, op[0] - t, op[1] + t, y0 + top + t, y0 + top + t + 0.28, pc[0].darkened(0.3), 0.05)   # header board


## A horizontal strip along a wall face, split so it never crosses an opening that overlaps its height.
static func _strip(f: Array, a: float, b: float, y0: float, rel: float, hh: float, pro: float, col: Color, ops: Array) -> void:
	var cur := a - 0.15
	var spans: Array = []
	for op in ops:
		var sill: float = op[2] if op.size() > 2 else 0.0
		var top: float = SkirmishParts.DOOR_TOP if sill <= 0.0 else sill + SkirmishParts.WINDOW_H
		if rel < top + 0.12 and rel + hh > sill - 0.1:
			spans.append([op[0] - 0.12, op[1] + 0.12])
	spans.sort_custom(func(p, q): return p[0] < q[0])
	for s in spans:
		_quad(f, 0.0, cur, s[0], y0 + rel, y0 + rel + hh, col, pro)
		cur = s[1]
	_quad(f, 0.0, cur, b + 0.15, y0 + rel, y0 + rel + hh, col, pro)


## A flat slab on the outside of a wall: f = [parent, horizontal?, wall line, outward sign]; span a..b along the wall.
static func _quad(f: Array, start: float, a: float, b: float, y0: float, y1: float, col: Color, pro: float) -> void:
	if b - a < 0.02 or y1 - y0 < 0.02:
		return
	var horiz: bool = f[1]
	var d: float = f[2] + f[3] * (0.15 + start + pro * 0.5)
	var c := (a + b) * 0.5
	var size := Vector3(b - a, y1 - y0, pro) if horiz else Vector3(pro, y1 - y0, b - a)
	var pos := Vector3(c, (y0 + y1) * 0.5, d) if horiz else Vector3(d, (y0 + y1) * 0.5, c)
	box(f[0], pos, size, col)


static func box(n: Node3D, pos: Vector3, size: Vector3, col: Color, rough := 0.9, emit := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat(col, rough, emit)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if size.length() < 0.4 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	n.add_child(mi)
	return mi


static func mat(col: Color, rough := 0.9, emit := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [col.to_html(), rough, emit]
	if not _mi_mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = rough
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = emit
		_mi_mats[key] = m
	return _mi_mats[key]


## Roof lip round the slab edge (the slab sticks out 0.15 past the walls) and a stencilled cap.
static func _roof(n: Node3D, r: Rect2, top: float, _two: bool) -> void:
	var y := top + 0.2 + 0.12
	var x0 := r.position.x - 0.15
	var x1 := r.end.x + 0.15
	var z0 := r.position.y - 0.15
	var z1 := r.end.y + 0.15
	var c := Color(0.36, 0.36, 0.34)
	box(n, Vector3((x0 + x1) * 0.5, y, z0), Vector3(x1 - x0, 0.24, 0.12), c)
	box(n, Vector3((x0 + x1) * 0.5, y, z1), Vector3(x1 - x0, 0.24, 0.12), c)
	box(n, Vector3(x0, y, (z0 + z1) * 0.5), Vector3(0.12, 0.24, z1 - z0 - 0.12), c)
	box(n, Vector3(x1, y, (z0 + z1) * 0.5), Vector3(0.12, 0.24, z1 - z0 - 0.12), c)


static func _details(n: Node3D, r: Rect2, id: String, top: float, pc: Array) -> void:
	var sw := Vector3(r.end.x + 0.22, top * 0.5, r.end.y + 0.22)    # drain pipe, south-east corner
	var cyl := _cyl(n, Vector3(sw.x, sw.y, sw.z), 0.07, top, PIPE)
	cyl.name = "drain"
	var nw := Vector3(r.position.x - 0.22, top * 0.5, r.end.y + 0.22)
	_cyl(n, nw, 0.07, top, PIPE)
	# conduit run along the south wall below the eave, with brackets
	var cm := _cyl(n, Vector3(r.get_center().x, top - 0.65, r.end.y + 0.22), 0.04, r.size.x - 1.0, PIPE)
	cm.rotation_degrees = Vector3(0, 0, 90)
	# lamps beside the first south door (warm, small)
	var lamp_x := r.position.x + 1.0
	box(n, Vector3(lamp_x, 2.5, r.end.y + 0.3), Vector3(0.18, 0.12, 0.2), Color(1.0, 0.8, 0.5), 0.5)
	box(n, Vector3(lamp_x, 2.5, r.end.y + 0.3), Vector3(0.2, 0.14, 0.2), Color(1.0, 0.8, 0.5), 0.3)
	if id == "warehouse" or id == "barracks":   # roof vent boxes and a flue
		for i in 3:
			box(n, Vector3(r.position.x + r.size.x * (0.2 + 0.3 * i), top + 0.7, r.get_center().y), Vector3(1.0, 0.8, 0.8), Color(0.4, 0.42, 0.4))
		_cyl(n, Vector3(r.end.x - 1.5, top + 1.0, r.position.y + 1.5), 0.2, 1.6, Color(0.25, 0.22, 0.2))
	if id == "hotel":   # water tank on the roof
		_cyl(n, Vector3(r.position.x + 2.5, top + 1.2, r.position.y + 2.5), 0.9, 2.0, Color(0.35, 0.32, 0.28))


static func _cyl(n: Node3D, pos: Vector3, rad: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = h
	cm.radial_segments = 10
	cm.rings = 1
	mi.mesh = cm
	mi.position = pos
	mi.material_override = mat(col, 0.7)
	n.add_child(mi)
	return mi
