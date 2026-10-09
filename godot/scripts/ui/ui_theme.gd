class_name UiTheme
## Project-wide military HUD theme (olive/charcoal panels, khaki edges, amber accents, square
## corners, Barlow Condensed + Share Tech Mono). Hud.setup() puts it on the root Window, so every
## Control (menus, overlays, tooltips) inherits it; UiKit helpers only add per-widget accents.

const FONT := "res://assets/fonts/BarlowCondensed-Medium.ttf"
const FONT_BOLD := "res://assets/fonts/BarlowCondensed-SemiBold.ttf"
const FONT_MONO := "res://assets/fonts/ShareTechMono-Regular.ttf"

static var _fonts := {}


static func font(path := FONT) -> Font:
	if not _fonts.has(path):
		_fonts[path] = load(path) if ResourceLoader.exists(path) else ThemeDB.fallback_font
	return _fonts[path]


## Header font: the bold face with a little letter spacing (stencil feel).
static func header_font() -> Font:
	if not _fonts.has("header"):
		var f := FontVariation.new()
		f.base_font = font(FONT_BOLD)
		f.spacing_glyph = 1
		_fonts["header"] = f
	return _fonts["header"]


static func box(bg: Color, edge: Color, width := 1, pad := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(width)
	s.set_corner_radius_all(1)
	s.set_content_margin_all(pad)
	s.anti_aliasing = false
	return s


static func _button_box(bg: Color, edge: Color, accent := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := box(bg, edge, 1, 0)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	if accent.a > 0.0:  # thicker amber edge along the bottom
		s.border_color = accent
		s.border_width_bottom = 3
	return s


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 17
	t.set_font("bold_font", "RichTextLabel", font(FONT_BOLD))
	t.set_font("mono_font", "RichTextLabel", font(FONT_MONO))
	for c in ["Label", "Button", "RichTextLabel", "LineEdit", "CheckBox", "OptionButton", "TooltipLabel", "PopupMenu"]:
		t.set_color("font_color" if c != "RichTextLabel" else "default_color", c, UiKit.TEXT)
	t.set_color("font_hover_color", "Button", UiKit.ACCENT_HI)
	t.set_color("font_pressed_color", "Button", UiKit.INK)
	t.set_color("font_hover_pressed_color", "Button", UiKit.INK)
	t.set_color("font_focus_color", "Button", UiKit.TEXT)
	t.set_color("font_disabled_color", "Button", UiKit.DIM)
	t.set_stylebox("normal", "Button", _button_box(UiKit.BTN, UiKit.EDGE))
	t.set_stylebox("hover", "Button", _button_box(UiKit.BTN_HI, UiKit.ACCENT, UiKit.ACCENT))
	t.set_stylebox("pressed", "Button", _button_box(UiKit.ACCENT, UiKit.ACCENT_HI))
	t.set_stylebox("hover_pressed", "Button", _button_box(UiKit.ACCENT_HI, UiKit.ACCENT_HI))
	t.set_stylebox("disabled", "Button", _button_box(Color(0.05, 0.055, 0.045, 0.85), Color(1, 1, 1, 0.07)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", box(UiKit.BG, UiKit.EDGE))
	t.set_stylebox("panel", "Panel", box(UiKit.BG, UiKit.EDGE))
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.06, 0.065, 0.05, 0.97), UiKit.ACCENT, 1, 8))
	t.set_font_size("font_size", "TooltipLabel", 15)
	t.set_stylebox("background", "ProgressBar", box(Color(0.03, 0.035, 0.03, 0.9), Color(1, 1, 1, 0.12), 1, 0))
	t.set_stylebox("fill", "ProgressBar", box(UiKit.GOOD, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("normal", "LineEdit", box(Color(0.03, 0.035, 0.03, 0.9), UiKit.EDGE, 1, 6))
	t.set_stylebox("focus", "LineEdit", box(Color(0.03, 0.035, 0.03, 0.9), UiKit.ACCENT, 1, 6))
	t.set_stylebox("panel", "PopupMenu", box(Color(0.06, 0.065, 0.05, 0.98), UiKit.EDGE, 1, 6))
	t.set_stylebox("hover", "PopupMenu", box(UiKit.ACCENT, UiKit.ACCENT, 0, 4))
	t.set_color("font_hover_color", "PopupMenu", UiKit.INK)
	for c in ["HSeparator", "VSeparator"]:
		var line := StyleBoxLine.new()
		line.color = Color(UiKit.EDGE, 0.5)
		line.vertical = c == "VSeparator"
		line.thickness = 1
		t.set_stylebox("separator", c, line)
	var grab := box(UiKit.EDGE, UiKit.EDGE, 0, 0)
	for c in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", c, box(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 0, 0))
		t.set_stylebox("grabber", c, grab)
		t.set_stylebox("grabber_highlight", c, box(UiKit.ACCENT, UiKit.ACCENT, 0, 0))
		t.set_stylebox("grabber_pressed", c, box(UiKit.ACCENT_HI, UiKit.ACCENT_HI, 0, 0))
	return t
