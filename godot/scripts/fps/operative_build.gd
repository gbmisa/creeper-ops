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


func _init(sm: StructureManager, ov: CommandOverlay) -> void:
	structures = sm
	overlay = ov


func toggle(on: bool) -> void:
	active = on
	if not on:
		overlay.hide_ghost()
		status = ""
	elif tool == "":
		_pick_slot(0)


## Returns true while building (the caller then skips weapons).
func update(input: InputState, world: World, camera: Camera3D) -> bool:
	if input.act("op_build"):
		toggle(not active)
		Sfx.play("click")
	if not active:
		return false
	_keys(input)
	if input.right_clicked:
		toggle(false)
		return true
	var o := camera.global_position
	var hit = world.grid.raycast(o, -camera.global_transform.basis.z, REACH)
	if hit == null:
		overlay.hide_ghost()
		status = "BUILD %s: aim at the ground" % _label()
		return true
	var c := world.grid.world_to_cell(hit.x, hit.z)
	var res := Placement.can_place(structures, tool, c.x, c.y)
	var def: Dictionary = StructureDefs.DEFS[tool]
	var r: float = (WeaponLogic.def_range(def) if def.has("range") else def.link) * Config.CELL
	var cover: Array[Vector4] = structures.network.cover_discs(structures.list) if def.get("needs_network", true) else []
	overlay.show_ghost(tool, world.grid.cell_ground(c.x, c.y), res.ok, StructureDefs.radius_m(tool), r, cover)
	status = "BUILD %s (%d)  ·  %s" % [_label(), def.get("cost", 0), "click to place" if res.ok else res.reason]
	if input.left_pressed:
		if res.ok:
			structures.place(tool, c.x, c.y)
			Sfx.play("click")
		else:
			Bus.say(res.reason, "warn")
			Sfx.play("deny")
	return true


func _keys(input: InputState) -> void:
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
