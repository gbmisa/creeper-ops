class_name UiKit
## Small helpers so every HUD file builds controls the same way. The look itself (fonts, button
## and panel boxes) is the root theme from UiTheme; these add per-widget accents.

const BG := Color(0.055, 0.062, 0.048, 0.95)
const BG_SOLID := Color(0.045, 0.05, 0.04, 0.97)
const EDGE := Color(0.46, 0.49, 0.33, 0.55)
const TEXT := Color("e6e4d2")
const DIM := Color("9a9c84")
const INK := Color("15160f")
const ACCENT := Color("e3b21c")
const ACCENT_HI := Color("ffd25a")
const BTN := Color(0.11, 0.125, 0.09, 0.95)
const BTN_HI := Color(0.17, 0.19, 0.13, 0.97)
const GOOD := Color("8ee05a")
const BAD := Color("ff5a3c")
const WARN := Color("ffc23d")
const ENERGY := Color("5fd4ff")
const KIND_COLORS := { "info": TEXT, "good": GOOD, "warn": WARN, "bad": BAD, "radio": Color("a8d8ff") }


static func style(bg := BG, edge := EDGE, _radius := 1, pad := 8) -> StyleBoxFlat:
	return UiTheme.box(bg, edge, 1, pad)


static func panel(bg := BG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg))
	return p


static func label(text := "", size := 16, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Numbers: monospace so readouts don't jitter as digits change.
static func mono(text := "", size := 16, color := TEXT) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_MONO))
	return l


## Section header: amber tick, spaced bold caps.
static func header(text: String, size := 14, color := ACCENT) -> HBoxContainer:
	var h := hbox(6)
	var tick := ColorRect.new()
	tick.color = color
	tick.custom_minimum_size = Vector2(3, size * 0.9)
	tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tick)
	var l := label(text.to_upper(), size, color)
	l.add_theme_font_override("font", UiTheme.header_font())
	l.name = "Text"
	h.add_child(l)
	return h


## Small caps caption above a value (top bar, info stats).
static func caption(text: String, size := 11) -> Label:
	var l := label(text.to_upper(), size, DIM)
	l.add_theme_font_override("font", UiTheme.header_font())
	return l


static func rich(size := 15) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("mono_font_size", size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func bar(width: float, height: float, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, height)
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.0
	b.add_theme_stylebox_override("fill", UiTheme.box(color, Color(0, 0, 0, 0), 0, 0))
	b.add_theme_stylebox_override("background", UiTheme.box(Color(0.02, 0.025, 0.02, 0.9), Color(1, 1, 1, 0.14), 1, 0))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


static func set_bar_color(b: ProgressBar, c: Color) -> void:
	(b.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = c


static func button(text: String, cb: Callable, size := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	return b


## Amber corner brackets drawn just outside a panel's content (tactical frame).
static func brackets(p: Control, color := ACCENT, arm := 10.0) -> void:
	p.draw.connect(func(): _draw_brackets(p, color, arm))


static func _draw_brackets(p: Control, color: Color, arm: float) -> void:
	var r := Rect2(Vector2.ZERO, p.size)
	var a := minf(arm, minf(r.size.x, r.size.y) * 0.4)
	for c: Vector2 in [r.position, Vector2(r.end.x, 0), r.end, Vector2(0, r.end.y)]:
		var sx := 1.0 if c.x <= 0.0 else -1.0
		var sy := 1.0 if c.y <= 0.0 else -1.0
		p.draw_line(c, c + Vector2(a * sx, 0), color, 2.0)
		p.draw_line(c, c + Vector2(0, a * sy), color, 2.0)


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
