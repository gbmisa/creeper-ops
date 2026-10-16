class_name RangeTestRebind
## F112: the Controls page rebinds through Keybinds and Reset restores the shipped keys.

static func run(t) -> void:
	var m := RangeMenu.new()
	t.add_child(m)
	m.setup(RangeTestFbb.session)
	var page: KeybindMenu = m.controls
	page.open()
	page._capture("t_crouch", 0)
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = KEY_Z
	page._input(ev)
	var ok: bool = Keybinds.keys("t_crouch")[0] == KEY_Z
	Keybinds.reset_all()
	ok = ok and Keybinds.keys("t_crouch") == [KEY_C]
	t.check("F112 Controls page rebinds an action, Reset restores defaults", ok)
	page.close()
	m.queue_free()
