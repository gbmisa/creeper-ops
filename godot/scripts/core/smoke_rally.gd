class_name SmokeRally
extends RefCounted
## Barracks rally-point marker: right-clicking with a barracks selected sets its rally
## point, and the command overlay must show a persistent flag + line at that point while
## the barracks stays selected. Called from SmokeTest.run and --smoke=rally.


static func run(g) -> void:
	var sm = g.structures
	var grid = g.level.grid
	var cm: CommandMode = g.command
	g.economy.energy = 200.0
	var b: Structure = sm.place("barracks", 44, 72, true)
	var c: Structure = sm.place("cannon", 48, 72, true)
	SmokeTest._check("rally: barracks placed", b != null and b.type == "barracks")

	# Set the rally point through the real input path (right-click with barracks selected).
	cm.select_structure(b)
	var p1: Vector3 = grid.cell_ground(44, 66)
	cm.hover = { "cell": Vector2i(44, 66), "point": p1 }
	CommandInput.right_click(cm)
	SmokeTest._check("rally: right-click sets the point", b.rally != null
		and (b.rally as Vector3).distance_to(p1) < 0.01)

	cm.overlay.show_selection(b, [b] as Array[Structure], false)
	SmokeTest._check("rally: marker appears at the rally point",
		cm.overlay.rally_root.visible
		and cm.overlay.rally_root.position.distance_to(Vector3(p1.x, p1.y + 0.05, p1.z)) < 0.05,
		"(flag at %s)" % str(cm.overlay.rally_root.position))

	# Moving the rally point moves the marker (show_selection runs every frame in game).
	var p2: Vector3 = grid.cell_ground(50, 66)
	cm.hover = { "cell": Vector2i(50, 66), "point": p2 }
	CommandInput.right_click(cm)
	cm.overlay.show_selection(b, [b] as Array[Structure], false)
	SmokeTest._check("rally: marker tracks the moved point",
		cm.overlay.rally_root.visible
		and cm.overlay.rally_root.position.distance_to(Vector3(p2.x, p2.y + 0.05, p2.z)) < 0.05)

	# Deselecting hides it.
	cm.overlay.show_selection(null, [] as Array[Structure], false)
	SmokeTest._check("rally: marker hides on deselect", not cm.overlay.rally_root.visible)

	# Group selection hides it too (single-selection marker only).
	cm.overlay.show_selection(b, [b, c] as Array[Structure], false)
	SmokeTest._check("rally: marker hides for group selection", not cm.overlay.rally_root.visible)

	# A barracks with no rally set shows nothing.
	var b2: Structure = sm.place("barracks", 44, 78, true)
	cm.select_structure(b2)
	cm.overlay.show_selection(b2, [b2] as Array[Structure], false)
	SmokeTest._check("rally: no marker when unset", not cm.overlay.rally_root.visible)

	# Non-barracks selection shows nothing.
	cm.select_structure(c)
	cm.overlay.show_selection(c, [c] as Array[Structure], false)
	SmokeTest._check("rally: no marker for non-barracks", not cm.overlay.rally_root.visible)

	cm.select_structure(null)
	sm.remove(b)
	sm.remove(b2)
	sm.remove(c)
