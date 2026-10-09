class_name SmokeTowerForm
## Box-select prefers movable towers over units, and group moves land in a compact
## formation. Called from SmokeTest.run.


static func _screen_rect(cm: CommandMode, pts: Array) -> Rect2:
	var r := Rect2()
	for p in pts:
		var sp: Vector2 = cm.cam.unproject_position(p)
		if r.size == Vector2.ZERO:
			r = Rect2(sp - Vector2(8, 8), Vector2(16, 16))
		else:
			r = r.expand(sp + Vector2(8, 8)).expand(sp - Vector2(8, 8))
	return r


static func _max_pairwise(cells: Array) -> float:
	var m := 0.0
	for i in cells.size():
		for j in range(i + 1, cells.size()):
			m = maxf(m, Vector2(cells[i].x - cells[j].x, cells[i].y - cells[j].y).length())
	return m


static func run(g) -> void:
	var cm: CommandMode = g.command
	var sm = g.structures

	# --- box select: towers win over units ---
	var t1: Structure = sm.place("cannon", 44, 70, true)
	var t2: Structure = sm.place("cannon", 46, 70, true)
	var t3: Structure = sm.place("mortar", 48, 70, true)
	var u1: Unit = g.units.spawn("soldier", 44 * Config.CELL, 84 * Config.CELL)
	var u2: Unit = g.units.spawn("soldier", 45 * Config.CELL, 84 * Config.CELL)
	SmokeTest._check("towerform: fixtures placed", t1 != null and t2 != null and t3 != null and u1 != null and u2 != null)
	cm.cam.focus(Vector3(46 * Config.CELL, 0, 77 * Config.CELL))
	var pts := [
		cm.cam.unproject_position(t1.pos + Vector3.UP),
		cm.cam.unproject_position(t2.pos + Vector3.UP),
		cm.cam.unproject_position(t3.pos + Vector3.UP),
		cm.cam.unproject_position(u1.pos + Vector3.UP),
		cm.cam.unproject_position(u2.pos + Vector3.UP),
	]
	CommandSelect.box_select(cm, _screen_rect(cm, [t1.pos + Vector3.UP, t2.pos + Vector3.UP, t3.pos + Vector3.UP]), false)
	SmokeTest._check("box: towers selected over units in mixed box",
		cm.group.size() == 3 and cm.group.has(t1) and cm.group.has(t2) and cm.group.has(t3)
		and not cm.units.selected.has(u1) and not cm.units.selected.has(u2),
		"(group %d, unitsel %d)" % [cm.group.size(), cm.units.selected.size()])
	CommandSelect.box_select(cm, _screen_rect(cm, [u1.pos + Vector3.UP, u2.pos + Vector3.UP]), false)
	SmokeTest._check("box: units selected when no towers in box",
		cm.units.selected.has(u1) and cm.units.selected.has(u2) and cm.group.is_empty(),
		"(unitsel %d)" % [cm.units.selected.size()])
	# shift-drag adds towers to the existing tower group
	CommandSelect.box_select(cm, _screen_rect(cm, [t1.pos + Vector3.UP, t2.pos + Vector3.UP]), false)
	CommandSelect.box_select(cm, _screen_rect(cm, [t2.pos + Vector3.UP, t3.pos + Vector3.UP]), true)
	SmokeTest._check("box: shift-drag adds towers to the group",
		cm.group.size() == 3 and cm.group.has(t1) and cm.group.has(t2) and cm.group.has(t3)
		and cm.units.selected.is_empty())
	for u in [u1, u2]:
		g.units.kill(u)
	for s in [t1, t2, t3]:
		sm.remove(s)
	cm.select_structure(null)
	cm.units.select([], false)

	# --- formation group move: scattered group tightens up ---
	var a: Structure = sm.place("cannon", 40, 68, true)
	var b: Structure = sm.place("cannon", 50, 68, true)
	var c: Structure = sm.place("cannon", 40, 76, true)
	var d: Structure = sm.place("cannon", 50, 76, true)
	var before := _max_pairwise([Vector2i(a.x, a.z), Vector2i(b.x, b.z), Vector2i(c.x, c.z), Vector2i(d.x, d.z)])
	cm.select_structure(a)
	cm.group = [a, b, c, d] as Array[Structure]
	var res: Dictionary = CommandSelect.move_group(cm, Vector2i(44, 70))
	var after := _max_pairwise([Vector2i(a.x, a.z), Vector2i(b.x, b.z), Vector2i(c.x, c.z), Vector2i(d.x, d.z)])
	SmokeTest._check("formation: lead lands exactly on target", res.ok and a.x == 44 and a.z == 70,
		"(a %d,%d)" % [a.x, a.z])
	SmokeTest._check("formation: group tightens into compact grid", after < before,
		"(max pairwise %.1f -> %.1f)" % [before, after])
	SmokeTest._check("formation: slots are the 2x2 grid",
		Vector2i(b.x, b.z) == Vector2i(46, 70) and Vector2i(c.x, c.z) == Vector2i(44, 72)
		and Vector2i(d.x, d.z) == Vector2i(46, 72),
		"(b %d,%d c %d,%d d %d,%d)" % [b.x, b.z, c.x, c.z, d.x, d.z])
	for s in [a, b, c, d]:
		sm.remove(s)

	# --- blocked slot: member stays put ---
	var e: Structure = sm.place("cannon", 40, 68, true)
	var f: Structure = sm.place("cannon", 42, 68, true)
	var blocker: Structure = sm.place("collector", 46, 70, true)
	cm.select_structure(e)
	cm.group = [e, f] as Array[Structure]
	CommandSelect.move_group(cm, Vector2i(44, 70))
	SmokeTest._check("formation: blocked member stays put", e.x == 44 and e.z == 70 and f.x == 42 and f.z == 68,
		"(e %d,%d f %d,%d)" % [e.x, e.z, f.x, f.z])
	for s in [e, f, blocker]:
		sm.remove(s)

	# --- single move unchanged ---
	var h: Structure = sm.place("cannon", 40, 68, true)
	cm.select_structure(h)
	var r2: Dictionary = CommandSelect.move_group(cm, Vector2i(52, 62))
	SmokeTest._check("formation: single move lands on target", r2.ok and h.x == 52 and h.z == 62,
		"(h %d,%d)" % [h.x, h.z])
	sm.remove(h)
	cm.select_structure(null)
