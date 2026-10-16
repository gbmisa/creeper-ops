class_name BuildCard
extends Button
## One build-menu item: icon (res://assets/icons/<id>.png, else a stencil glyph), hotkey badge,
## name, cost line, and a lock/up-front note. `summary` holds the plain text (tests read it).

const ICON_DIR := "res://assets/icons/"
const SIZE := Vector2(158, 60)
const LOCKED_W := 250.0

var item := ""
var summary := ""
var _key: Label
var _name: Label
var _cost: Label
var _note: Label


var _glyph := ""


## `glyph`: two-letter stencil for items that are not structures (the Range quick-use bar); "" = from StructureDefs.
func _init(id: String, slot: int, glyph := "") -> void:
	item = id
	_glyph = glyph
	set_meta("slot", slot)
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	custom_minimum_size = SIZE
	clip_contents = true
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		add_theme_stylebox_override(st, _box(st))
	var row := UiKit.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.offset_top = 5
	row.offset_bottom = -5
	add_child(row)
	row.add_child(_icon(id))
	var v := UiKit.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := UiKit.hbox(5)
	_key = UiKit.mono("", 14, UiKit.ACCENT)
	top.add_child(_key)
	_name = UiKit.label("", 17)
	_name.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_BOLD))
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name)
	v.add_child(top)
	_cost = UiKit.mono("", 14, UiKit.ENERGY)
	_cost.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_cost)
	_note = UiKit.label("", 13, UiKit.WARN)
	_note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_note)


func _box(st: String) -> StyleBoxFlat:
	match st:
		"hover":
			return UiTheme.box(UiKit.BTN_HI, UiKit.ACCENT, 1, 0)
		"pressed", "hover_pressed":
			var b := UiTheme.box(Color(UiKit.ACCENT, 0.2), UiKit.ACCENT, 2, 0)
			b.border_width_bottom = 4
			return b
		"disabled":
			return UiTheme.box(Color(0.05, 0.055, 0.045, 0.85), Color(1, 1, 1, 0.06), 1, 0)
	return UiTheme.box(UiKit.BTN, UiKit.EDGE, 1, 0)


func _icon(id: String) -> Control:
	var path := ICON_DIR + id.trim_prefix("@") + ".png"
	if ResourceLoader.exists(path):
		var t := TextureRect.new()
		t.texture = load(path)
		t.custom_minimum_size = Vector2(50, 50)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	var p := PanelContainer.new()  # stencil glyph: two letters on a dark plate
	p.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0.35), Color(UiKit.EDGE, 0.4), 1, 0))
	p.custom_minimum_size = Vector2(40, 52)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiKit.label(_glyph if _glyph != "" else StructureDefs.label(id).left(2).to_upper(), 18, UiKit.DIM)
	l.add_theme_font_override("font", UiTheme.header_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func show_info(key: String, title: String, cost: String, note: String, locked: bool) -> void:
	_key.text = key
	_name.text = title
	_cost.text = "" if locked else cost
	_cost.visible = not locked
	_note.text = note
	_note.visible = locked
	disabled = locked
	custom_minimum_size.x = LOCKED_W if locked else SIZE.x
	summary = "%s  %s\n%s" % [key, title, note if locked else cost]
