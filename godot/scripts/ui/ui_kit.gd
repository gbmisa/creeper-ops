class_name UiKit
## Small helpers so every HUD file builds controls the same way.

const BG := Color(0.04, 0.06, 0.09, 0.88)
const EDGE := Color(0.37, 0.83, 1.0, 0.35)
const TEXT := Color("dce8f2")
const DIM := Color("8899aa")
const GOOD := Color("5dff8a")
const BAD := Color("ff5a4a")
const WARN := Color("ffc857")
const ENERGY := Color("5fd4ff")
const KIND_COLORS := { "info": TEXT, "good": GOOD, "warn": WARN, "bad": BAD, "radio": Color("9fd4ff") }


static func style(bg := BG, edge := EDGE, radius := 6, pad := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s


static func panel(bg := BG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg))
	return p


static func label(text := "", size := 14, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func rich(size := 14) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func bar(width: float, height: float, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, height)
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.0
	var fill := style(color, Color(0, 0, 0, 0), 3, 0)
	var bg := style(Color(0.1, 0.12, 0.15, 0.9), Color(1, 1, 1, 0.15), 3, 0)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


static func set_bar_color(b: ProgressBar, c: Color) -> void:
	(b.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = c


static func button(text: String, cb: Callable, size := 14) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color("eaf6ff"))
	b.add_theme_color_override("font_pressed_color", Color("ffffff"))
	b.add_theme_color_override("font_disabled_color", DIM)
	b.add_theme_stylebox_override("normal", _btn_box(Color(0.10, 0.14, 0.19, 0.95), Color(0.37, 0.83, 1.0, 0.35)))
	b.add_theme_stylebox_override("hover", _btn_box(Color(0.14, 0.20, 0.27, 0.97), Color(0.37, 0.83, 1.0, 0.7)))
	b.add_theme_stylebox_override("pressed", _btn_box(Color(0.13, 0.32, 0.45, 0.97), Color(0.37, 0.83, 1.0, 1.0)))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(0.06, 0.08, 0.11, 0.9), Color(1, 1, 1, 0.08)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	return b


static func _btn_box(bg: Color, edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


static func vbox(sep := 4) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v
