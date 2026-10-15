class_name CheatMenu
extends CanvasLayer
## Debug cheat panel (Ctrl+KP5). Mouse visible while open; the game keeps running.
## Same chord closes it. Every button routes through RangeCheats.request().

var cheats: RangeCheats
var _panel: PanelContainer
var _rows := {}  # cheat name -> Button


func _init() -> void:
	layer = 15
	visible = false


func setup(c: RangeCheats) -> void:
	cheats = c
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = UiKit.panel(Color(0.08, 0.05, 0.05, 0.97))
	_panel.position = Vector2(560, 120)
	_panel.custom_minimum_size = Vector2(400, 0)
	add_child(_panel)
	var col := VBoxContainer.new()
	_panel.add_child(col)
	col.add_child(UiKit.label("CHEATS (debug)", 22, Color(1.0, 0.5, 0.4)))
	col.add_child(UiKit.caption("Ctrl+Numpad 5 to close. Any use marks CHEATS USED."))
	var grid := GridContainer.new()
	grid.columns = 2
	col.add_child(grid)
	for n in RangeCheats.ORDER:
		var b := UiKit.button("", func(): cheats.request(n))
		b.custom_minimum_size = Vector2(190, 0)
		grid.add_child(b)
		_rows[n] = b
	refresh()


func refresh() -> void:
	if cheats == null:
		return
	for n in _rows:
		var b: Button = _rows[n]
		var skirmish_only: bool = n in ["tp_extract", "instant_extract"]
		var usable: bool = not skirmish_only or cheats.fr.skirmish != null
		b.disabled = not usable
		b.text = "%s [%s]%s" % [RangeCheats.DEFS[n]["label"], cheats.state_text(n),
			"" if usable else " (N/A)"]


func toggle() -> void:
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	if visible:
		refresh()
