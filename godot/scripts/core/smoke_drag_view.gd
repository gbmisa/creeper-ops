class_name SmokeDragView
## Drag-build ghosts, collector outlines, and the Operative's own drag.


static func _preview(cm: CommandMode, span: Array) -> void:
	if span.is_empty():
		SmokeTest._check("drag ghosts", false, "no collector span")
		return
	cm.set_tool("collector")
	var items := DragBuild.plan(cm, span[0], span[1])
	cm.overlay.show_plan(items, "collector")
	var vis := 0
	var tint := true
	for i in items.size():
		vis += 1 if cm.overlay.plan_ghosts[i].visible else 0
		var col: Color = cm.overlay.plan_mats[i].albedo_color
		tint = tint and ((col.g > col.r) == items[i].ok)
	var fields := int(cm.overlay.mat.get_shader_parameter("field_plan_count"))
	SmokeTest._check("drag ghosts", vis == items.size() and tint, "visible %d" % vis)
	SmokeTest._check("collector field outlines", fields == items.size(), "fields %d" % fields)
	cm.set_tool("relay")
	cm.overlay.show_plan(DragBuild.plan(cm, span[0], span[0]), "relay")
	SmokeTest._check("relay chain has no field outline", int(cm.overlay.mat.get_shader_parameter("field_plan_count")) == 0)
	cm.overlay.hide_plan()
	var hidden := true
	for node in cm.overlay.plan_ghosts:
		hidden = hidden and not node.visible
	SmokeTest._check("hide plan hides ghosts", hidden)


static func _operative(g, span: Array) -> void:
	if span.is_empty():
		SmokeTest._check("operative drag places", false, "no collector span")
		return
	var sm = g.structures
	var grid: Grid = sm.world.grid
	var cam := Camera3D.new()
	g.add_child(cam)
	var bld: OperativeBuild = g.fps.builder
	bld.toggle(true)
	bld.tool = "collector"
	var had := SmokeDragbuild._had(sm)
	_hold(g, bld, cam, grid, span[0], span[1])
	var oks := 0
	for it in bld.drag_plan:
		oks += 1 if it.ok else 0
	var preview: bool = bld.drag_plan.size() >= 2 and "energy total" in bld.status
	g.input.left = false
	g.input.left_released = true
	bld.update(g.input, g.surface, cam)
	SmokeTest._check("operative drag places", preview and SmokeDragbuild._new(sm, had).size() == oks, bld.status)
	for s in SmokeDragbuild._new(sm, had):
		sm.remove(s)
	SmokeDragbuild._silence(g)
	bld.toggle(true)
	had = SmokeDragbuild._had(sm)
	_hold(g, bld, cam, grid, span[0], span[1])
	g.input.right_clicked = true
	g.input.left_released = true
	bld.update(g.input, g.surface, cam)
	SmokeTest._check("operative right-click during a drag places nothing", SmokeDragbuild._new(sm, had).is_empty() and not bld.active)
	SmokeDragbuild._silence(g)
	bld.toggle(true)
	had = SmokeDragbuild._had(sm)
	_hold(g, bld, cam, grid, span[0], span[1])
	g.input._pressed[KEY_ESCAPE] = true
	g.input.left_released = true
	bld.update(g.input, g.surface, cam)
	SmokeTest._check("operative esc during a drag places nothing", SmokeDragbuild._new(sm, had).is_empty() and bld.drag_plan.is_empty())
	bld.toggle(false)
	cam.queue_free()
	SmokeDragbuild._silence(g)


static func _hold(g, bld: OperativeBuild, cam: Camera3D, grid: Grid, a: Vector2i, b: Vector2i) -> void:
	SmokeDragbuild._silence(g)
	_aim(cam, grid, a)
	g.input.left = true
	g.input.left_pressed = true
	bld.update(g.input, g.surface, cam)
	g.input.left_pressed = false
	_aim(cam, grid, b)
	bld.update(g.input, g.surface, cam)


static func _aim(cam: Camera3D, grid: Grid, c: Vector2i) -> void:
	var p := grid.cell_ground(c.x, c.y)
	cam.global_transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), p + Vector3(0, 20, 0))


