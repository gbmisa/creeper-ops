class_name KeybindMenu
extends ColorRect
## Controls screen: every Keybinds action with a primary and an alternate key. Click a slot,
## then press a key (Esc cancels). Right-click a slot to clear it. Changes save at once to
## user://keybinds.cfg and survive game updates. The game is frozen while this is open.

var on_close := Callable()
var _rows: VBoxContainer
var _note: Label
var _slots := {}          # id -> [Button, Button]
var _waiting: Array = []  # [id, slot] while capturing a key


func _init() -> void:
	color = Color(0, 0, 0, 0.6)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p := UiKit.panel(Color(0.05, 0.07, 0.1, 0.97))
	c.add_child(p)
	var v := UiKit.vbox(8)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(v)
	v.add_child(UiKit.label("CONTROLS", 22))
	v.add_child(UiKit.label("Click a key to rebind it, then press the new key (Esc cancels). Right-click clears. Saved automatically and kept across updates.", 13, UiKit.DIM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_rows = UiKit.vbox(3)
	_rows.mouse_filter = Control.MOUSE_FILTER_PASS
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	_note = UiKit.label("", 14, UiKit.WARN)
	v.add_child(_note)
	var bottom := UiKit.hbox(10)
	bottom.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(bottom)
	bottom.add_child(UiKit.button("Reset all to defaults", func():
		Keybinds.reset_all()
		_note.text = "Defaults restored."
		_refresh(), 16))
	bottom.add_child(UiKit.button("Close", close, 16))
	_build_rows()


func _build_rows() -> void:
	for grp in Keybinds.GROUPS:
		var head := UiKit.label(grp.to_upper(), 15, UiKit.ENERGY)
		_rows.add_child(head)
		for id in Keybinds.DEFAULTS:
			if Keybinds.group(id) != grp:
				continue
			var row := UiKit.hbox(8)
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			var l := UiKit.label(Keybinds.label(id), 14)
			l.custom_minimum_size.x = 260
			row.add_child(l)
			var pair := []
			for slot in Keybinds.SLOTS:
				var b := UiKit.button("", func(): _capture(id, slot), 14)
				b.custom_minimum_size.x = 150
				b.gui_input.connect(func(e):
					if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
						Keybinds.bind(id, slot, 0)
						_refresh())
				row.add_child(b)
				pair.append(b)
			_slots[id] = pair
			_rows.add_child(row)


func open() -> void:
	_waiting = []
	_note.text = ""
	_refresh()
	visible = true


func close() -> void:
	_waiting = []
	visible = false
	if on_close.is_valid():
		on_close.call()


func _capture(id: String, slot: int) -> void:
	_waiting = [id, slot]
	_note.text = "Press a key for \"%s\"  (Esc cancels)" % Keybinds.label(id)
	_refresh()


func _input(e: InputEvent) -> void:
	if not visible or not (e is InputEventKey and e.pressed and not e.echo):
		return
	get_viewport().set_input_as_handled()
	if _waiting.is_empty():
		if e.physical_keycode == KEY_ESCAPE:
			close()
		return
	var id: String = _waiting[0]
	var slot: int = _waiting[1]
	_waiting = []
	if e.physical_keycode == KEY_ESCAPE:
		_note.text = ""
	else:
		var lost := Keybinds.bind(id, slot, e.physical_keycode)
		_note.text = "%s unbound from: %s" % [OS.get_keycode_string(e.physical_keycode), ", ".join(PackedStringArray(lost))] if not lost.is_empty() else ""
	_refresh()


func _refresh() -> void:
	for id in _slots:
		var k := Keybinds.keys(id)
		for slot in Keybinds.SLOTS:
			var b: Button = _slots[id][slot]
			if _waiting.size() == 2 and _waiting[0] == id and _waiting[1] == slot:
				b.text = "press a key..."
			else:
				b.text = Keybinds.key_name(k[slot]) if slot < k.size() else "-"
