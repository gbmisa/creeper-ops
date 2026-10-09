class_name HudOverlay
extends ColorRect
## Modal overlay (briefing, pause, end screen): a dimmed screen with a bracketed panel holding
## BBCode text and a wrapping row of buttons. The first button is the primary action (amber).

var _box: VBoxContainer


func _init() -> void:
	color = Color(0.02, 0.025, 0.015, 0.62)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p := UiKit.panel(UiKit.BG_SOLID)
	(p.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(22)
	(p.get_theme_stylebox("panel") as StyleBoxFlat).border_width_top = 3
	(p.get_theme_stylebox("panel") as StyleBoxFlat).border_color = UiKit.EDGE
	UiKit.brackets(p, UiKit.ACCENT, 18.0)
	c.add_child(p)
	_box = UiKit.vbox(12)
	_box.custom_minimum_size.x = 680
	_box.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(_box)
	visible = false


## buttons: [{ label, on_click }]
func open(bbcode: String, buttons: Array) -> void:
	for c in _box.get_children():
		c.queue_free()
	var t := UiKit.rich(17)
	t.text = bbcode
	_box.add_child(t)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	_box.add_child(row)
	for i in buttons.size():
		var b := UiKit.button(buttons[i].label, buttons[i].on_click, 18)
		if i == 0:
			_primary(b)
		row.add_child(b)
	visible = true


func _primary(b: Button) -> void:
	for st in ["normal", "hover"]:
		var s := UiTheme.box(UiKit.ACCENT if st == "normal" else UiKit.ACCENT_HI, UiKit.ACCENT_HI, 1, 0)
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 6
		s.content_margin_bottom = 6
		b.add_theme_stylebox_override(st, s)
	b.add_theme_color_override("font_color", UiKit.INK)
	b.add_theme_color_override("font_hover_color", UiKit.INK)
	b.add_theme_font_override("font", UiTheme.header_font())
