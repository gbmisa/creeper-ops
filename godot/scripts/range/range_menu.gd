class_name RangeMenu
extends CanvasLayer
## Esc menu: Resume / Reset range / Quit. Opening frees the mouse; closing recaptures it.

signal resumed
signal reset_requested
signal deploy_requested


func _init() -> void:
	layer = 10
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := UiKit.panel(Color(0.05, 0.06, 0.08, 0.95))
	p.position = Vector2(680, 330)
	p.custom_minimum_size = Vector2(240, 0)
	add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(UiKit.label("PAUSED", 22))
	col.add_child(UiKit.button("Resume", close))
	col.add_child(UiKit.button("Reset range", func(): reset_requested.emit()))
	if RangeMaps.selected == "skirmish":
		col.add_child(UiKit.button("Back to Firing Range", func(): RangeMaps.go("range")))
	else:
		col.add_child(UiKit.button("Deploy to Skirmish", func(): deploy_requested.emit()))
	col.add_child(UiKit.button("Quit", func(): get_tree().quit()))


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()
