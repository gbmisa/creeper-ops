class_name SkirmishEnd
extends CanvasLayer
## EXTRACTED / KIA screen: time and kills, Restart / Level select / Back to Firing Range.
## F92: the panel sits in the bottom-left corner, away from the crosshair, and its buttons ignore clicks for
## TacticalConfig.END_CLICK_GRACE s, so the clicks of a firefight don't press Level select after a death.

var buttons: Array[Button] = []


func _init(won: bool, time_s: float, kills: int, total: int, session: RangeSession) -> void:
	layer = 20
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := UiKit.panel(Color(0.05, 0.06, 0.08, 0.95))
	p.custom_minimum_size = Vector2(320, 0)
	p.anchor_left = 0.0
	p.anchor_right = 0.0
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = 80.0
	p.offset_bottom = -80.0
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(UiKit.label("EXTRACTED" if won else "KIA", 34, Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.4, 0.35)))
	col.add_child(UiKit.label("Time %d:%02d   Kills %d / %d" % [int(time_s) / 60, int(time_s) % 60, kills, total], 18))
	buttons = [UiKit.button("Restart", func():
			session.restore_walk_in()
			session.maps.change(session.maps.selected)),
		UiKit.button("Level select", func(): get_tree().change_scene_to_file("res://scenes/main.tscn")),
		UiKit.button("Back to Firing Range", func(): session.maps.change("range"))]
	for b in buttons:
		b.disabled = true
		col.add_child(b)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	await get_tree().create_timer(TacticalConfig.END_CLICK_GRACE, true).timeout
	for b in buttons:
		if is_instance_valid(b):
			b.disabled = false
