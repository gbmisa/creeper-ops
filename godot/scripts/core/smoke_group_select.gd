class_name SmokeGroupSelect
## CW3 group orders: hold fire and move apply to every box-selected weapon, and the group
## keeps its shape when it flies. Called from SmokeTest.run.


static func run(g) -> void:
	var cm: CommandMode = g.command
	var sm = g.structures
	var a: Structure = sm.place("cannon", 44, 72, true)
	var b: Structure = sm.place("cannon", 46, 72, true)
	cm.select_structure(a)
	cm.group = [a, b] as Array[Structure]
	cm.toggle_hold()
	SmokeTest._check("group: hold fire applies to every selected weapon", a.hold_fire and b.hold_fire)
	CommandSelect.move_group(cm, Vector2i(44, 70))
	SmokeTest._check("group: move keeps the formation", a.x == 44 and a.z == 70 and b.x == 46 and b.z == 70,
		"(a %d,%d b %d,%d)" % [a.x, a.z, b.x, b.z])
	cm.select_structure(null)
	sm.remove(a)
	sm.remove(b)
