class_name RangeMenu
extends CanvasLayer
## Esc menu: Resume / Reset range / Quit. Opening frees the mouse; closing recaptures it.

signal resumed
signal reset_requested
signal deploy_requested

var session: RangeSession
var _col: VBoxContainer
var _panel: PanelContainer
var controls: KeybindMenu   # F112: rebinding page (same screen as command mode's F10 menu)
var report := BugReport.new()   # Report a bug: voice note + screenshot + log


func _init() -> void:
	layer = 10
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # F19: the menu must work while the tree is paused
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := UiKit.panel(Color(0.05, 0.06, 0.08, 0.95))
	p.set_anchors_preset(Control.PRESET_CENTER)   # centred at any size (the settings rows made it taller)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.custom_minimum_size = Vector2(240, 0)
	add_child(p)
	_panel = p
	_col = VBoxContainer.new()
	p.add_child(_col)
	_col.add_child(UiKit.label("PAUSED", 22))
	_col.add_child(UiKit.button("Resume", close))


## Session-dependent rows (map buttons). Called once by FiringRange. (FB-I: no recoil toggle, Tarkov only.)
func setup(s: RangeSession) -> void:
	session = s
	_col.add_child(UiKit.button("Reset range", func(): reset_requested.emit()))
	if RangeMaps.is_skirmish(session.maps.selected):
		_col.add_child(UiKit.button("Back to Firing Range", func(): session.maps.go("range")))
	else:
		_col.add_child(UiKit.button("Deploy to Skirmish", func(): deploy_requested.emit()))
	controls = KeybindMenu.new()
	add_child(controls)
	_col.add_child(UiKit.button("Controls", func(): controls.open()))
	_add_sensitivity()
	_add_display()
	_add_safe_zone()
	report.set_anchors_preset(Control.PRESET_CENTER)
	report.grow_horizontal = Control.GROW_DIRECTION_BOTH
	report.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(report)
	report.closed.connect(func(): _panel.visible = true)
	_col.add_child(UiKit.button("Report a bug", func():
		_panel.visible = false
		report.open()))
	_col.add_child(UiKit.button("Quit", func(): get_tree().quit()))


func open() -> void:
	_panel.visible = true
	report.shot = get_viewport().get_texture().get_image()   # the last game frame, before the menu draws
	report.context = _context()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true   # F19: freeze bots, shots, ballistics, bleeding, timers


func close() -> void:
	report.close()
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false   # F19: resume exactly where the world stopped
	resumed.emit()


## F19: firing_range._process is pausable, so Esc-to-close while paused is handled here.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


## Mouse sensitivity: typed number (MouseSettings, x0.2 .. x3, saved). Enter or clicking away applies it.
func _add_sensitivity() -> void:
	var line := HBoxContainer.new()
	line.add_child(UiKit.label("Mouse sensitivity", 14))
	var box := SpinBox.new()
	box.min_value = MouseSettings.MIN
	box.max_value = MouseSettings.MAX
	box.step = 0.01
	box.value = MouseSettings.mult()
	box.suffix = "x"
	box.select_all_on_focus = true
	box.custom_minimum_size = Vector2(100, 0)
	box.value_changed.connect(func(v: float): MouseSettings.set_mult(v))
	line.add_child(box)
	_col.add_child(line)


## Where the player was, for the bug report's info.txt.
func _context() -> Dictionary:
	var sc := get_parent() as TacticalScene
	if sc == null or sc.player == null:
		return {}
	var gun: Gun = sc.weapons.gun if sc.weapons != null else null
	return {"map": sc.map_id(), "gun": gun.def["id"] if gun != null else "none",
		"pos": sc.player.global_position.snapped(Vector3.ONE * 0.1)}


## Windowed / Borderless / Fullscreen (DisplaySettings, saved).
func _add_display() -> void:
	var line := HBoxContainer.new()
	line.add_child(UiKit.label("Display", 14))
	var pick := OptionButton.new()
	for m in DisplaySettings.MODES:
		pick.add_item(m)
	pick.selected = DisplaySettings.current()
	pick.item_selected.connect(func(i: int): DisplaySettings.choose(i))
	line.add_child(pick)
	_col.add_child(line)


## HUD safe zone: typed width / height in percent of the window (SafeZone; 100 = full screen, e.g. 60 on ultra-wide).
func _add_safe_zone() -> void:
	for axis in 2:
		var line := HBoxContainer.new()
		line.add_child(UiKit.label("HUD width" if axis == 0 else "HUD height", 14))
		var box := SpinBox.new()
		box.min_value = SafeZone.MIN
		box.max_value = SafeZone.MAX
		box.step = 1.0
		box.suffix = "%"
		box.value = SafeZone.pct()[axis]
		box.select_all_on_focus = true
		box.custom_minimum_size = Vector2(100, 0)
		box.value_changed.connect(func(v: float): SafeZone.set_pct(axis, v))
		line.add_child(box)
		_col.add_child(line)
