class_name RangeMenu
extends CanvasLayer
## Esc menu: Resume / Reset range / Quit. Opening frees the mouse; closing recaptures it.

signal resumed
signal reset_requested
signal deploy_requested

var session: RangeSession
var _col: VBoxContainer
var _rec: Button


func _init() -> void:
	layer = 10
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # F19: the menu must work while the tree is paused
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := UiKit.panel(Color(0.05, 0.06, 0.08, 0.95))
	p.position = Vector2(680, 330)
	p.custom_minimum_size = Vector2(240, 0)
	add_child(p)
	_col = VBoxContainer.new()
	p.add_child(_col)
	_col.add_child(UiKit.label("PAUSED", 22))
	_col.add_child(UiKit.button("Resume", close))


## Session-dependent rows (recoil toggle, map buttons). Called once by FiringRange.
func setup(s: RangeSession) -> void:
	session = s
	_rec = UiKit.button("", func(): pass)
	_rec.pressed.connect(func():
		if session.local != null:
			session.set_local_recoil(not session.local.recoil_mode)
			# the weapons read the flag at setup; live toggle applies on next select
		_refresh_recoil_text())
	_rec.text = _recoil_text()
	_col.add_child(_rec)
	_col.add_child(UiKit.button("Reset range", func(): reset_requested.emit()))
	if session.maps.selected == "skirmish":
		_col.add_child(UiKit.button("Back to Firing Range", func(): session.maps.go("range")))
	else:
		_col.add_child(UiKit.button("Deploy to Skirmish", func(): deploy_requested.emit()))
	_col.add_child(UiKit.button("Quit", func(): get_tree().quit()))


func _refresh_recoil_text() -> void:
	if _rec != null:
		_rec.text = _recoil_text()


func _recoil_text() -> String:
	var t := session != null and session.local != null and session.local.recoil_mode
	return "Recoil: %s" % ("Tarkov" if t else "Classic")


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true   # F19: freeze bots, shots, ballistics, bleeding, timers


func close() -> void:
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
