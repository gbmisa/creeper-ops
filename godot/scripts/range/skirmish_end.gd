class_name SkirmishEnd
extends CanvasLayer
## EXTRACTED / KIA screen: time and kills, Restart / Level select / Back to Firing Range.


func _init(won: bool, time_s: float, kills: int, total: int, cheats_used := false) -> void:
	layer = 20
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := UiKit.panel(Color(0.05, 0.06, 0.08, 0.95))
	p.position = Vector2(640, 300)
	p.custom_minimum_size = Vector2(320, 0)
	add_child(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(UiKit.label("EXTRACTED" if won else "KIA", 34, Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.4, 0.35)))
	col.add_child(UiKit.label("Time %d:%02d   Kills %d / %d" % [int(time_s) / 60, int(time_s) % 60, kills, total], 18))
	if cheats_used:
		col.add_child(UiKit.label("CHEATS USED", 18, Color(1.0, 0.5, 0.4)))
	col.add_child(UiKit.button("Restart", func(): get_tree().reload_current_scene()))
	col.add_child(UiKit.button("Level select", func(): get_tree().change_scene_to_file("res://scenes/main.tscn")))
	col.add_child(UiKit.button("Back to Firing Range", func(): RangeMaps.go("range")))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
