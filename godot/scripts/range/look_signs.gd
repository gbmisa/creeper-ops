class_name LookSigns
## Shared builders for decorative signs and paint on the ground / walls: faded stencil text, ground stripes, lit panels.

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	return _font


## Faded stencil label. `yaw` turns it (0 faces +Z). `flat` lays it on the ground facing up.
static func stencil(parent: Node3D, text: String, pos: Vector3, yaw: float, size_m: float, col: Color, flat := false) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font()
	l.font_size = 128
	l.pixel_size = size_m / 128.0
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.double_sided = false
	l.position = pos
	l.rotation_degrees = Vector3(-90.0 if flat else 0.0, yaw, 0.0)
	parent.add_child(l)
	return l


## Ground paint: a flat box of colour (visual only).
static func paint(parent: Node3D, pos: Vector3, size: Vector2, col: Color, yaw := 0.0) -> void:
	var m: MeshInstance3D = LookFacades.box(parent, Vector3(pos.x, pos.y + 0.012, pos.z), Vector3(size.x, 0.02, size.y), col, 0.8)
	m.rotation_degrees.y = yaw
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Rectangle outline of paint stripes centred on `c` (x width, z depth), line width `w`.
static func outline(parent: Node3D, c: Vector3, w: float, d: float, line: float, col: Color) -> void:
	paint(parent, c + Vector3(0, 0, d * 0.5), Vector2(w, line), col)
	paint(parent, c - Vector3(0, 0, d * 0.5), Vector2(w, line), col)
	paint(parent, c + Vector3(w * 0.5, 0, 0), Vector2(line, d), col)
	paint(parent, c - Vector3(w * 0.5, 0, 0), Vector2(line, d), col)


## A lit panel: dark backing and an emissive face with text.
static func lit_panel(parent: Node3D, text: String, pos: Vector3, yaw: float, w: float, h: float, col: Color) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw
	parent.add_child(n)
	LookFacades.box(n, Vector3.ZERO, Vector3(w, h, 0.1), Color(0.08, 0.1, 0.1), 0.5)
	LookFacades.box(n, Vector3(0, 0, 0.055), Vector3(w - 0.12, h - 0.12, 0.01), col.darkened(0.55), 0.4, 0.6)
	var l := stencil(n, text, Vector3(0, 0, 0.065), 0.0, h * 0.6, Color(1, 1, 1))
	l.shaded = false
