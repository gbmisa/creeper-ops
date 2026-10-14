class_name FiringRange
extends Node3D
## Scene root for the Firing Range. Wiring only. Phase 1: runs the logic tests when asked.

var args := {}


func _ready() -> void:
	Keybinds.persist = false
	args = RangeArgs.parse()
	if args.has("range-test"):
		var t := RangeTest.new()
		add_child(t)
		await t.run()
		get_tree().quit(1 if t.failed > 0 else 0)
		return
	var label := Label.new()
	label.text = "Firing Range (phase 1: core module only). Run with -- --range-test"
	add_child(label)
