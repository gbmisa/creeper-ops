class_name CommandSelect
## Orders on the current selection: train, recycle, relocate, supply, hold fire,
## and drag-box unit picks. CommandMode keeps the public entry points.


static func train(cm: CommandMode, type: String) -> void:
	var b := cm.selected if cm.selected and cm.selected.type == "barracks" else null
	if b == null:
		Bus.say("Select a Barracks first, then train units.", "warn")
		Sfx.play("deny")
	elif not b.is_built():
		Bus.say("Barracks is still under construction.", "warn")
	elif StructureBehaviors.queue_unit(b, type, cm.units.living_for(b)):
		Sfx.play("click")
		Bus.selection_changed.emit()


static func recycle(cm: CommandMode) -> void:
	if cm.selected and cm.selected.type != "node":
		Bus.say("%s recycled." % cm.selected.def.label, "info")
		cm.structures.recycle(cm.selected)


static func begin_move(cm: CommandMode) -> void:
	if cm.selected and cm.selected.def.get("movable", false):
		cm.set_tool("@move")
		Bus.say("Click (or right-click) where the %s should fly." % cm.selected.def.label, "info")
	elif cm.selected:
		Bus.say("%s can't be moved." % cm.selected.def.label, "warn")
		Sfx.play("deny")


static func toggle_supply(cm: CommandMode) -> void:
	if cm.selected and cm.selected.has_ammo_store():
		cm.selected.supply_on = not cm.selected.supply_on
		Bus.selection_changed.emit()


static func toggle_hold(cm: CommandMode) -> void:
	if cm.selected and cm.selected.def.has("fire_rate"):
		cm.selected.hold_fire = not cm.selected.hold_fire
		Bus.selection_changed.emit()


static func box_select(cm: CommandMode, r: Rect2, additive: bool) -> void:
	var picked := []
	for u in cm.units.list:
		var p := u.pos + Vector3.UP
		if not cm.cam.is_position_behind(p) and r.has_point(cm.cam.unproject_position(p)):
			picked.append(u)
	cm.units.select(picked, additive)
	if not picked.is_empty():
		cm.select_structure(null)
		Sfx.play("click")
	Bus.selection_changed.emit()
