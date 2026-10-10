class_name CommandSelect
## Orders on the current selection: train, recycle, relocate, supply, hold fire, and
## drag-box picks (units first; with no units in the box, your weapons, CW3 style). Orders
## apply to every structure in `cm.group`. CommandMode keeps the public entry points.


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


## Selects units (a barracks' own, or all when `b` is null) and centres the camera on them.
static func select_units(cm: CommandMode, b: Structure) -> void:
	var pick := cm.units.list.filter(func(u): return u.alive and (b == null or u.home == b))
	if pick.is_empty():
		Bus.say("No units to select.", "info")
		return
	var c := Vector3.ZERO
	for u in pick:
		c += u.pos
	cm.select_structure(null)
	cm.units.select(pick)
	cm.cam.focus(c / pick.size())
	Sfx.play("click")
	Bus.selection_changed.emit()


static func recycle(cm: CommandMode) -> void:
	var gone := cm.group.filter(func(s): return s.type != "node")
	if gone.is_empty():
		return
	Bus.say("%s recycled." % (gone[0].def.label if gone.size() == 1 else "%d structures" % gone.size()), "info")
	for s in gone:
		cm.structures.recycle(s)


static func begin_move(cm: CommandMode) -> void:
	if cm.selected and cm.selected.def.get("movable", false):
		cm.set_tool("@move")
		var what: String = cm.selected.def.label if cm.group.size() == 1 else "group"
		Bus.say("Click (or right-click) where the %s should fly." % what, "info")
	elif cm.selected:
		Bus.say("%s can't be moved." % cm.selected.def.label, "warn")
		Sfx.play("deny")


## Moves every movable structure in the group: the primary to `c`, the rest keep their
## offsets from it. Returns the primary's result (for the warning/deny message).
static func move_group(cm: CommandMode, c: Vector2i) -> Dictionary:
	var lead := cm.selected
	var from := Vector2i(lead.x, lead.z)  # read before the lead lifts off (move updates x/z)
	var res: Dictionary = cm.structures.move(lead, c.x, c.y)
	var failed := 0
	for s in cm.group:
		if s == lead or not s.def.get("movable", false):
			continue
		var r: Dictionary = cm.structures.move(s, c.x + s.x - from.x, c.y + s.z - from.y)
		if not r.ok:
			failed += 1
	if failed > 0:
		Bus.say("%d of the group can't land there (blocked ground). They stay put." % failed, "warn")
	return res


static func toggle_supply(cm: CommandMode) -> void:
	if cm.selected and cm.selected.type != "node":
		var on := not cm.selected.active
		for s in cm.group:
			if s.type != "node":
				s.active = on
		Bus.say("%s %s." % [cm.selected.def.label, "activated" if on else "deactivated"])
		Bus.selection_changed.emit()


static func toggle_hold(cm: CommandMode) -> void:
	if cm.selected and cm.selected.def.has("fire_rate"):
		var on := not cm.selected.hold_fire
		for s in cm.group:
			if s.def.has("fire_rate"):
				s.hold_fire = on
		Bus.selection_changed.emit()


static func box_select(cm: CommandMode, r: Rect2, additive: bool) -> void:
	var picked := []
	for u in cm.units.list:
		if _in_box(cm, r, u.pos + Vector3.UP):
			picked.append(u)
	if not picked.is_empty():
		cm.units.select(picked, additive)
		cm.select_structure(null)
		Sfx.play("click")
		Bus.selection_changed.emit()
		return
	var weapons: Array[Structure] = []
	for s in cm.structures.list:
		if s.def.get("movable", false) and s.type != "node" and not s.dead and _in_box(cm, r, s.pos + Vector3.UP):
			weapons.append(s)
	if weapons.is_empty() and not additive:
		cm.units.select([])
		cm.select_structure(null)
		return
	var keep: Array[Structure] = cm.group.duplicate() if additive else []
	for s in weapons:
		if not keep.has(s):
			keep.append(s)
	cm.units.select([])
	cm.select_structure(null if keep.is_empty() else keep[0])
	cm.group = keep
	Sfx.play("click")
	Bus.selection_changed.emit()


static func _in_box(cm: CommandMode, r: Rect2, p: Vector3) -> bool:
	return not cm.cam.is_position_behind(p) and r.has_point(cm.cam.unproject_position(p))
