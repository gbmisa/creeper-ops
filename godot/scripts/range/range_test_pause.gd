class_name RangeTestPause
extends RefCounted
## FB-B: a mouse release while the pause menu has the tree paused must still end held fire / aim.


static func run(t: RangeTest) -> void:
	var inp := InputState.new()
	t.add_child(inp)
	inp.left = true
	inp.right = true
	t.get_tree().paused = true
	for b in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var ev := InputEventMouseButton.new()
		ev.button_index = b
		ev.pressed = false
		Input.parse_input_event(ev)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var l := inp.left
	var r := inp.right
	t.get_tree().paused = false
	t.check("pause: left release is seen while paused (hold fire, pause, release, resume stops)", not l and inp.left_released)
	t.check("pause: right release is seen while paused", not r)
	inp.queue_free()
