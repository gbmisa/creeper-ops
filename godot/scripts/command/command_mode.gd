class_name CommandMode
extends Node3D
## Top-down commander. Tools: a structure type (build; stays armed until right-click/Esc,
## like CW3), "@move" (relocate the selected
## structure), "@lance" (orbital strike), "@land" (Command Node landing at mission start).
## Selection: click / drag-box units, click structures. Orders: right-click moves units,
## relocates a selected movable structure, or sets a barracks rally point.

const DRAG_PX := 6.0

var world: World
var structures: StructureManager
var units: UnitManager
var orbital: Orbital
var level: Dictionary
var cam := CommandCamera.new()
var overlay: CommandOverlay
var tool := ""
var hover: Dictionary = {}        # { cell: Vector2i, point: Vector3 }
var reason := ""
var selected: Structure = null
var drag_rect := Rect2()          # for the HUD selection box (size 0 = hidden)
var on_land := Callable()         # GameFlow: func(cell: Vector2i)


func setup(w: World, sm: StructureManager, um: UnitManager, orb: Orbital, lvl: Dictionary) -> void:
	name = "Command"
	world = w
	structures = sm
	units = um
	orbital = orb
	level = lvl
	add_child(cam)
	cam.bounds = w.grid.world_size()
	overlay = CommandOverlay.new(w)
	Bus.structure_removed.connect(func(s): if s == selected: select_structure(null))


func set_tool(t: String) -> void:
	if tool == "@land" and t != "@land":
		return  # landing must finish first
	tool = t
	if t != "" and t != "@move":
		select_structure(null)
		units.select([])
	if t == "":
		overlay.hide_ghost()
	Bus.tool_changed.emit(t)


func select_structure(s: Structure) -> void:
	selected = s
	if s and s.type == "beacon":
		structures.selected_beacon = s
	Bus.selection_changed.emit()


func update(dt: float, input: InputState) -> void:
	if tool == "@move" and (selected == null or selected.is_flying()):
		set_tool("")
	_hotkeys(input)
	cam.update(dt, input, world.grid)
	Sfx.listener = cam.global_position
	_update_hover(input)
	overlay.show_selection(selected, tool != "")
	if input.right_clicked:
		_right_click()
	_left_mouse(input)


func _hotkeys(input: InputState) -> void:
	if input.was_pressed(KEY_ESCAPE):
		set_tool("")
		select_structure(null)
		units.select([])
	if selected:
		if input.act("recycle"): recycle_selected()
		if input.act("move"): begin_move()
		if input.act("supply"): toggle_supply()
		if input.act("hold_fire"): toggle_hold()
	if input.act("cam_home") and structures.command_node():
		cam.focus(structures.command_node().pos)
	for t in UnitDefs.ORDER:
		if input.act(UnitDefs.KEYS[t]):
			train(t)


func train(type: String) -> void:
	var b := selected if selected and selected.type == "barracks" else null
	if b == null:
		Bus.say("Select a Barracks first, then train units.", "warn")
		Sfx.play("deny")
	elif not b.is_built():
		Bus.say("Barracks is still under construction.", "warn")
	elif StructureBehaviors.queue_unit(b, type, units.living_for(b)):
		Sfx.play("click")
		Bus.selection_changed.emit()


func recycle_selected() -> void:
	if selected and selected.type != "node":
		Bus.say("%s recycled." % selected.def.label, "info")
		structures.recycle(selected)


func begin_move() -> void:
	if selected and selected.def.get("movable", false):
		set_tool("@move")
		Bus.say("Click (or right-click) where the %s should fly." % selected.def.label, "info")
	elif selected:
		Bus.say("%s can't be moved." % selected.def.label, "warn")
		Sfx.play("deny")


func toggle_supply() -> void:
	if selected and selected.has_ammo_store():
		selected.supply_on = not selected.supply_on
		Bus.selection_changed.emit()


func toggle_hold() -> void:
	if selected and selected.def.has("fire_rate"):
		selected.hold_fire = not selected.hold_fire
		Bus.selection_changed.emit()


func _update_hover(input: InputState) -> void:
	var p = cam.pick(input.mouse, world.grid)
	if p == null:
		hover = {}
		reason = ""
		overlay.hide_ghost()
		return
	hover = { "cell": world.grid.world_to_cell(p.x, p.z), "point": p }
	if tool == "":
		reason = ""
		return
	var c: Vector2i = hover.cell
	var at := world.grid.cell_ground(c.x, c.y)
	var res := _check(c)
	reason = res.reason if not res.ok else res.get("warn", "")
	match tool:
		"@lance":
			overlay.show_ghost("", p, res.ok, Config.LANCE_RADIUS * Config.CELL, Config.LANCE_RADIUS * Config.CELL, [])
		"@move":
			overlay.show_ghost(selected.type, at, res.ok, StructureDefs.radius_m(selected.type), selected.def.get("range", 0.0) * Config.CELL, [])
		"@land":
			overlay.show_ghost("node", at, res.ok, StructureDefs.radius_m("node"), StructureDefs.DEFS.node.link * Config.CELL, [])
		_:
			var def: Dictionary = StructureDefs.DEFS[tool]
			var r: float = def.get("range", def.link) * Config.CELL
			var cover: Array[Vector4] = structures.network.cover_discs(structures.list) if def.get("needs_network", true) else []
			overlay.show_ghost(tool, at, res.ok, StructureDefs.radius_m(tool), r, cover)


func _check(c: Vector2i) -> Dictionary:
	match tool:
		"@lance": return orbital.can_fire()
		"@move": return Placement.can_move(structures, selected, c.x, c.y) if selected else { "ok": false, "reason": "" }
		"@land": return Placement.can_land(structures, level, c.x, c.y)
		_: return Placement.can_place(structures, tool, c.x, c.y)


func _left_mouse(input: InputState) -> void:
	var dragging := input.left and tool == "" and input.mouse.distance_to(input.down_pos) > DRAG_PX
	drag_rect = Rect2(input.down_pos, input.mouse - input.down_pos).abs() if dragging else Rect2()
	if not input.left_released:
		return
	if tool == "" and input.mouse.distance_to(input.down_pos) > DRAG_PX:
		_box_select(Rect2(input.down_pos, input.mouse - input.down_pos).abs(), input.shift)
	elif input.left_pressed or input.mouse.distance_to(input.down_pos) <= DRAG_PX:
		if not hover.is_empty():
			_click(input.shift)


func _box_select(r: Rect2, additive: bool) -> void:
	var picked := []
	for u in units.list:
		var p := u.pos + Vector3.UP
		if not cam.is_position_behind(p) and r.has_point(cam.unproject_position(p)):
			picked.append(u)
	units.select(picked, additive)
	if not picked.is_empty():
		select_structure(null)
		Sfx.play("click")
	Bus.selection_changed.emit()


func _click(shift: bool) -> void:
	var c: Vector2i = hover.cell
	if tool != "":
		var res := _check(c)
		if not res.ok:
			Bus.say(res.reason, "warn")
			Sfx.play("deny")
			return
		match tool:
			"@land":
				tool = ""
				overlay.hide_ghost()
				on_land.call(c)
			"@lance":
				orbital.fire(hover.point)
				if not shift: set_tool("")
			"@move":
				structures.move(selected, c.x, c.y)
				set_tool("")
			_:
				structures.place(tool, c.x, c.y)
				Sfx.play("click")  # CW3: the tool stays armed; right-click or Esc to stop
		return
	var u := units.nearest(hover.point)
	if u:
		units.select([u], shift)
		select_structure(null)
		Sfx.play("click")
		Bus.selection_changed.emit()
		return
	units.select([])
	var s := structures.structure_at(c.x, c.y)
	select_structure(s)
	if s:
		Sfx.play("click")


func _right_click() -> void:
	if tool != "" and tool != "@land":
		set_tool("")
		return
	if hover.is_empty():
		return
	var p: Vector3 = hover.point
	var c: Vector2i = hover.cell
	if not units.selected.is_empty():
		units.order(units.selected, Vector2(p.x, p.z), true)
		world.effects.burst(p + Vector3(0, 0.3, 0), Color("9dff7a"), 1.2, 0.3)
	elif selected and selected.type == "barracks":
		selected.rally = p
		world.effects.burst(p + Vector3(0, 0.3, 0), Color("9dff7a"), 1.2, 0.3)
		Bus.say("Barracks rally point set.", "info")
	elif selected and selected.def.get("movable", false):
		var res := structures.move(selected, c.x, c.y)
		if not res.ok:
			Bus.say(res.reason, "warn")
			Sfx.play("deny")
		elif res.get("warn", "") != "":
			Bus.say(res.warn, "warn")
