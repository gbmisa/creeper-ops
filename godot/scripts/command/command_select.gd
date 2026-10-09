class_name CommandSelect
## Orders on the current selection: train, recycle, relocate, supply, hold fire, and
## drag-box picks (movable weapons win over units in the box, so towers can be grabbed
## next to your army; with no towers in the box, units). Orders apply to every
## structure in `cm.group`. CommandMode keeps the public entry points.


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


## Moves every movable structure in the group into a compact formation centred on
## `c`: the primary (cm.selected) takes the centre slot and lands exactly on `c`,
## the rest fill a tight footprint-aware grid around it. Members whose slot is
## blocked stay put (counted in the warning). Returns the primary's result (for the
## warning/deny message).
static func move_group(cm: CommandMode, c: Vector2i) -> Dictionary:
	var members: Array[Structure] = []
	var lead := cm.selected
	if lead != null and lead.def.get("movable", false):
		members.append(lead)
	for s in cm.group:
		if s != lead and s.def.get("movable", false):
			members.append(s)
	var slots := _formation_slots(members)
	var failed := 0
	var res := { "ok": false, "reason": "Nothing to move" }
	for i in members.size():
		var t := Vector2i(c.x + slots[i].x, c.y + slots[i].y)
		var r: Dictionary = cm.structures.move(members[i], t.x, t.y)
		if i == 0:
			res = r
		elif not r.ok:
			failed += 1
	if failed > 0:
		Bus.say("%d of the group can't land there (blocked ground). They stay put." % failed, "warn")
	return res


## Compact grid slots for a group move: row-major, footprint-aware spacing, slot 0
## at the origin so the primary lands exactly on the target cell.
static func _formation_slots(members: Array[Structure]) -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	var n := members.size()
	if n <= 0:
		return slots
	var spacing := 2
	for m in members:
		spacing = maxi(spacing, 2 + int(m.def.get("footprint", 0)))
	var cols := int(ceil(sqrt(float(n))))
	var rows := int(ceil(float(n) / float(cols)))
	var bx := 0 * spacing - (cols - 1) * spacing / 2
	var by := 0 * spacing - (rows - 1) * spacing / 2
	for i in n:
		var col := i % cols
		var row := i / cols
		slots.append(Vector2i(col * spacing - (cols - 1) * spacing / 2 - bx,
			row * spacing - (rows - 1) * spacing / 2 - by))
	return slots


static func toggle_supply(cm: CommandMode) -> void:
	if cm.selected and cm.selected.has_ammo_store():
		var on := not cm.selected.supply_on
		for s in cm.group:
			if s.has_ammo_store():
				s.supply_on = on
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
	var weapons: Array[Structure] = []
	for s in cm.structures.list:
		if s.def.get("movable", false) and s.type != "node" and not s.dead and _in_box(cm, r, s.pos + Vector3.UP):
			weapons.append(s)
	if weapons.is_empty() and not picked.is_empty():
		cm.units.select(picked, additive)
		cm.select_structure(null)
		Sfx.play("click")
		Bus.selection_changed.emit()
		return
	if weapons.is_empty() and not additive:
		cm.units.select([])
		cm.select_structure(null)
		return
	# Movable towers win over units: right-click can only order one kind, and the old
	# units-always-win rule made towers unselectable next to your army.
	var keep: Array[Structure] = []
	if additive:
		keep.assign(cm.group)
	for s in weapons:
		if not keep.has(s):
			keep.append(s)
	cm.units.select([], false)
	cm.select_structure(null if keep.is_empty() else keep[0])
	cm.group = keep
	Sfx.play("click")
	Bus.selection_changed.emit()


static func _in_box(cm: CommandMode, r: Rect2, p: Vector3) -> bool:
	return not cm.cam.is_position_behind(p) and r.has_point(cm.cam.unproject_position(p))
