class_name TitleMenu
extends Control
## Start screen of the tactical project: Firing Range / Skirmish / Quit. Skirmish's end screen
## ("Level select") comes back here.

const SCENE := "res://scenes/title.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplaySettings.apply()   # at launch, not when the first map loads
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var p := UiKit.panel()
	p.position = Vector2(680, 330)
	p.custom_minimum_size = Vector2(240, 0)
	add_child(p)
	UiKit.brackets(p)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(UiKit.label(ProjectSettings.get_setting("application/config/name").to_upper(), 22))
	col.add_child(UiKit.button("Firing Range", func(): RangeMaps.go("range")))
	col.add_child(UiKit.button("Skirmish", func(): RangeMaps.go("skirmish")))
	col.add_child(UiKit.button("Skirmish (large)", func(): RangeMaps.go("skirmish_large")))
	col.add_child(UiKit.button("Quit", func(): get_tree().quit()))
