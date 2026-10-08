class_name OperativeBuild
extends RefCounted
## Building from first person (surface only). The build key toggles it; the tab keys and
## slot keys pick a structure the same way as in command mode; the crosshair aims the ghost
## (drawn by CommandOverlay on the terrain shader, with network cover and range); left click
## places it under the normal rules (Placement.can_place), right click or the build key ends
## it. Weapons are holstered while building.

const REACH := 60.0  # metres the crosshair can place at

var structures: StructureManager
var overlay: CommandOverlay
var active := false
var tab := 0
var tool := ""
var status := ""  # HUD line: what is armed, where, and why it can't go there
var drag_from := Vector2i(-1, -1)
var drag_plan: Array[Dictionary] = []


func _init(sm: StructureManager, ov: CommandOverlay) -> void:
	structures = sm
	overlay = ov


func toggle(on: bool) -> void:
	active = on
	_end_drag()
	if not on:
		overlay.hide_ghost()
		status = ""
	elif tool == "":
		_pick_slot(0)


func _end_drag() -> void:
	drag_from = Vector2i(-1, -1)
	drag_plan.clear()
	overlay.hide_plan()


## Returns true while building (the caller then skips weapons).
## A click places one structure on release. Holding the button and aiming at another cell
## drags a chain or row, same rules as command mode; release places it.
func update(input: InputState, world: World, camera: Camera3D) -> bool:
	if input.act("op_build"):
		toggle(not active)
		Sfx.play("click")
	if not active:
		return false
	if _keys(input):
		_end_drag()
	if input.right_clicked or input.was_pressed(KEY_ESCAPE):
		_end_drag()
		if input.right_clicked:
			toggle(false)
		return true
	var hit = world.grid.raycast(camera.global_position, -camera.global_transform.basis.z, REACH)
	if hit == null:
		overlay.hide_ghost()
		if input.left_released:
			_end_drag()
		status = "BUILD %s: aim at the ground" % _label()
		return true
	var c := world.grid.world_to_cell(hit.x, hit.z)
	if input.left_pressed:
		drag_from = c
	var dragging := drag_from.x >= 0 and (input.left or input.left_released) and c != drag_from
	if dragging:
		drag_plan = DragBuild.plan_at(structures, tool, drag_from, c)
		overlay.show_plan(drag_plan, tool)
		status = "BUILD %s  ·  %s" % [_label(), DragBuild.summary(drag_plan)]
	else:
		if not drag_plan.is_empty():
			drag_plan.clear()
			overlay.hide_plan()
		var res := Placement.can_place(structures, tool, c.x, c.y)
		var def: Dictionary = StructureDefs.DEFS[tool]
		var reach: float = (WeaponLogic.def_range(def) if def.has("range") else def.link) * Config.CELL
		var cover: Array[Vector4] = structures.network.cover_discs(structures.list) if def.get("needs_network", true) else []
		overlay.show_ghost(tool, world.grid.cell_ground(c.x, c.y), res.ok, StructureDefs.radius_m(tool), reach, cover)
		status = "BUILD %s (%d)  ·  %s" % [_label(), def.get("cost", 0), "click to place" if res.ok else res.reason]
	if input.left_released:
		if not drag_plan.is_empty():
			DragBuild.commit_at(structures, tool, drag_plan)
		elif drag_from == c:
			var placed := Placement.can_place(structures, tool, c.x, c.y)
			if placed.ok:
				structures.place(tool, c.x, c.y)
				Sfx.play("click")
			else:
				Bus.say(placed.reason, "warn")
				Sfx.play("deny")
		_end_drag()
	return true


## True when the armed structure changed, so a drag in progress is dropped.
func _keys(input: InputState) -> bool:
	var before := tool
	for i in StructureDefs.TABS.size():
		if input.act("tab_%d" % (i + 1)):
			tab = i
			_pick_slot(0)
	if input.act("tab_next"):
		tab = (tab + 1) % StructureDefs.TABS.size()
		_pick_slot(0)
	for n in 9:
		if input.act("build_%d" % (n + 1)):
			_pick_slot(n)
	return tool != before


## Picks slot n of the current tab (same numbers as the command-mode menu). "@" actions
## (Lance, drop pods) are command-mode only; slot 0 of a tab falls to its first structure.
func _pick_slot(n: int) -> void:
	var list: Array = StructureDefs.MENU[StructureDefs.TABS[tab]]
	if n < list.size() and not String(list[n]).begins_with("@"):
		tool = list[n]
		return
	if n == 0:
		for t in list:
			if not String(t).begins_with("@"):
				tool = t
				return
	if tool == "":
		tool = StructureDefs.MENU[StructureDefs.TABS[0]][0]


func _label() -> String:
	return "[%s] %s" % [StructureDefs.TABS[tab], StructureDefs.DEFS[tool].label]
