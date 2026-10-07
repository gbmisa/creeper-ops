class_name CommandInput
## Keyboard and pointer while commanding. Tool ghosts live in CommandHover;
## selection orders live in CommandSelect.

const DRAG_PX := 6.0


static func hotkeys(cm: CommandMode, input: InputState) -> void:
	if input.was_pressed(KEY_ESCAPE):
		cm.set_tool("")
		cm.select_structure(null)
		cm.units.select([])
	if cm.selected:
		if input.act("recycle"): cm.recycle_selected()
		if input.act("move"): cm.begin_move()
		if input.act("supply"): cm.toggle_supply()
		if input.act("hold_fire"): cm.toggle_hold()
	if input.act("select_units"):
		CommandSelect.select_units(cm, null)
	if input.act("cam_home") and cm.structures.command_node():
		cm.cam.focus(cm.structures.command_node().pos)
	for t in UnitDefs.ORDER:
		if input.act(UnitDefs.KEYS[t]):
			cm.train(t)


static func left_mouse(cm: CommandMode, input: InputState) -> void:
	var dragging := input.left and cm.tool == "" and input.mouse.distance_to(input.down_pos) > DRAG_PX
	cm.drag_rect = Rect2(input.down_pos, input.mouse - input.down_pos).abs() if dragging else Rect2()
	if not input.left_released:
		return
	if cm.tool == "" and input.mouse.distance_to(input.down_pos) > DRAG_PX:
		CommandSelect.box_select(cm, Rect2(input.down_pos, input.mouse - input.down_pos).abs(), input.shift)
	elif input.left_pressed or input.mouse.distance_to(input.down_pos) <= DRAG_PX:
		if not cm.hover.is_empty():
			cm._click(input.shift)


static func click(cm: CommandMode, shift: bool) -> void:
	var c: Vector2i = cm.hover.cell
	if cm.tool != "":
		var res := CommandHover.check(cm, c)
		if not res.ok:
			Bus.say(res.reason, "warn")
			Sfx.play("deny")
			return
		match cm.tool:
			"@land":
				cm.tool = ""
				cm.overlay.hide_ghost()
				cm.on_land.call(c)
			"@lance":
				cm.orbital.fire(cm.hover.point)
				if not shift: cm.set_tool("")
			"@drop":
				cm.deploy.start_drop(c)
				if not shift: cm.set_tool("")
			"@move":
				CommandSelect.move_group(cm, c)
			"@repeater", "@lobber", "@flak":
				var t := CommandHover.turret_check(cm, c)
				CastleTurrets.buy(t.castle, t.i, cm.tool.substr(1), cm.castles.stockpile)
				Sfx.play("good")
				cm.set_tool("")
			_:
				cm.structures.place(cm.tool, c.x, c.y)
				Sfx.play("click")  # CW3: the tool stays armed; right-click or Esc to stop
		return
	var u := cm.units.nearest(cm.hover.point)
	if u:
		cm.units.select([u], shift)
		cm.select_structure(null)
		Sfx.play("click")
		Bus.selection_changed.emit()
		return
	cm.units.select([])
	var s := cm.structures.structure_at(c.x, c.y)
	cm.select_structure(s)
	if s:
		Sfx.play("click")


static func right_click(cm: CommandMode) -> void:
	if cm.tool != "" and cm.tool != "@land":
		cm.set_tool("")
		return
	if cm.hover.is_empty():
		return
	var p: Vector3 = cm.hover.point
	var c: Vector2i = cm.hover.cell
	if not cm.units.selected.is_empty():
		cm.units.order(cm.units.selected, Vector2(p.x, p.z), true)
		cm.world.effects.burst(p + Vector3(0, 0.3, 0), Color("9dff7a"), 1.2, 0.3)
	elif cm.selected and cm.selected.type == "barracks":
		cm.selected.rally = p
		cm.world.effects.burst(p + Vector3(0, 0.3, 0), Color("9dff7a"), 1.2, 0.3)
		Bus.say("Barracks rally point set.", "info")
	elif cm.selected and cm.selected.def.get("movable", false):
		var res := CommandSelect.move_group(cm, c)
		if not res.ok:
			Bus.say(res.reason, "warn")
			Sfx.play("deny")
		elif res.get("warn", "") != "":
			Bus.say(res.warn, "warn")
