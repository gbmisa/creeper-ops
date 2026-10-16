class_name RangeTestF92
## F92: the EXTRACTED / KIA screen keeps its buttons off the screen centre (crosshair) and ignores clicks for
## TacticalConfig.END_CLICK_GRACE s.


static func run(t: RangeTest) -> void:
	var end := SkirmishEnd.new(false, 75.0, 3, 12, RangeSession.new(92))
	t.add_child(end)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	t.check("f92: end screen has its 3 buttons", end.buttons.size() == 3)
	var all_off := true
	for b in end.buttons:
		all_off = all_off and b.disabled
	t.check("f92: buttons ignore clicks right after death", all_off)
	# headless windows are tiny, so check the layout rule: bottom-left anchored, right edge + 40 px left of the
	# centre of the narrowest supported screen (1280 px wide)
	var p := end.find_children("*", "PanelContainer", true, false)[0] as Control
	var right := p.offset_left + maxf(p.size.x, p.custom_minimum_size.x)
	t.check("f92: end panel anchored bottom-left, clear of the crosshair at 1280 px (right edge %d)" % right,
		p.anchor_left == 0.0 and p.anchor_top == 1.0 and right + 40.0 < 640.0)
	await t.get_tree().create_timer(TacticalConfig.END_CLICK_GRACE + 0.2, true).timeout
	var all_on := true
	for b in end.buttons:
		all_on = all_on and not b.disabled
	t.check("f92: buttons work after %.1f s" % TacticalConfig.END_CLICK_GRACE, all_on)
	end.free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
