class_name LookHub
## Firing Range hub dressing: clean, well-kept base. Booth fascia and warm work lights, lit lane signage, painted firing line and
## deploy bay, armoury wall behind the rack, flags, props. Visual only (no colliders); headless skips it.

const WHITE := Color(0.82, 0.82, 0.78)
const BLUE := Color(0.18, 0.28, 0.4)
const YELLOW := Color(0.85, 0.7, 0.2)


static func build(p: Node3D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var n := Node3D.new()
	n.name = "Hub"
	p.add_child(n)
	_booth(n)
	_floor_paint(n)
	_armoury(n)
	_flags(n)
	_work_lights(n)
	LookProps.build(n, LookPropDefs.RANGE)
	LookScatter.range_hub(n)


static func _booth(n: Node3D) -> void:
	# roof fascia, gutter and a blue stripe along the front edge; posts' base band; wall stripes
	LookFacades.box(n, Vector3(0, 3.35, 6.45), Vector3(16.8, 0.42, 0.1), BLUE, 0.6)
	LookFacades.box(n, Vector3(0, 3.62, 6.5), Vector3(16.9, 0.08, 0.2), WHITE, 0.5)
	for sx in [-1.0, 1.0]:
		LookFacades.box(n, Vector3(sx * 8.33, 3.4, 4.0), Vector3(0.08, 0.4, 12.3), BLUE, 0.6)
		LookFacades.box(n, Vector3(sx * 8.0, 0.3, 4.0), Vector3(0.04, 0.6, 12.0), Color(0.2, 0.22, 0.24), 0.8)
		LookFacades.box(n, Vector3(sx * 8.0, 2.9, 4.0), Vector3(0.04, 0.25, 12.0), BLUE, 0.7)
	LookFacades.box(n, Vector3(0, 0.3, 9.97), Vector3(16.5, 0.6, 0.04), Color(0.2, 0.22, 0.24), 0.8)
	LookFacades.box(n, Vector3(0, 2.9, 9.97), Vector3(16.5, 0.25, 0.04), BLUE, 0.7)
	# counter top lip and bench edge trim
	LookFacades.box(n, Vector3(0, 1.015, 0.4), Vector3(9.2, 0.05, 0.62), Color(0.55, 0.55, 0.52), 0.5)
	LookFacades.box(n, Vector3(5, 0.92, 8.0), Vector3(2.7, 0.05, 1.0), Color(0.6, 0.45, 0.28), 0.6)
	LookSigns.lit_panel(n, "FIRING LINE", Vector3(0, 3.0, 6.42), 0.0, 4.2, 0.55, Color(0.9, 0.7, 0.3))
	LookSigns.lit_panel(n, "FIRING LINE", Vector3(0, 3.0, 6.38), 180.0, 4.2, 0.55, Color(0.9, 0.7, 0.3))
	LookSigns.lit_panel(n, "RANGE 01", Vector3(-6.0, 3.0, 6.42), 0.0, 2.4, 0.55, Color(0.4, 0.8, 1.0))
	LookSigns.lit_panel(n, "SKIRMISH >", Vector3(6.0, 3.0, 6.42), 0.0, 2.8, 0.55, Color(0.5, 1.0, 0.6))
	# lit distance board at the counter: lane tags
	for i in 6:
		LookSigns.lit_panel(n, "%d M" % RangeLayout.DISTANCES[i], Vector3(-3.75 + i * 1.5, 0.55, 0.68), 0.0, 1.0, 0.28, Color(1.0, 0.85, 0.5))


static func _floor_paint(n: Node3D) -> void:
	LookSigns.paint(n, Vector3(0, 0, -0.9), Vector2(16.0, 0.22), YELLOW)
	LookSigns.stencil(n, "FIRING LINE", Vector3(-6.5, 0.014, -1.5), 0.0, 0.5, Color(0.9, 0.85, 0.5, 0.8), true)
	for i in 7:   # lane ticks on the slab
		LookSigns.paint(n, Vector3(-7.2 + i * 2.4, 0, -2.3), Vector2(0.12, 1.1), WHITE)
	# deploy bay round the truck at (-6.4, 3)
	var c := Vector3(-6.4, 0, 3.0)
	LookSigns.outline(n, c + Vector3(0, 0, 0.0), 3.4, 7.2, 0.15, YELLOW)
	for i in 4:
		LookSigns.paint(n, c + Vector3(1.9, 0, -2.5 + i * 1.6), Vector2(0.14, 0.9), YELLOW, 30.0)
	LookSigns.stencil(n, "DEPLOY BAY", c + Vector3(0, 0.014, 4.4), 0.0, 0.55, Color(0.9, 0.85, 0.5, 0.8), true)
	LookSigns.lit_panel(n, "DEPLOY", c + Vector3(-1.9, 2.6, 4.2), 0.0, 1.8, 0.45, Color(0.4, 1.0, 0.6))
	LookFacades.box(n, c + Vector3(-1.9, 1.3, 4.2), Vector3(0.1, 2.6, 0.1), Color(0.25, 0.27, 0.28), 0.6)


static func _armoury(n: Node3D) -> void:
	var c := Vector3(-5.0, 0, 9.96)   # behind the rack (rack board z 9.8)
	LookFacades.box(n, c + Vector3(0, 1.6, 0), Vector3(9.4, 3.0, 0.05), Color(0.17, 0.2, 0.2), 0.7)
	for i in 10:   # pegboard slats
		LookFacades.box(n, c + Vector3(-4.2 + i * 0.93, 1.6, -0.03), Vector3(0.04, 2.9, 0.02), Color(0.28, 0.3, 0.3), 0.6)
	LookFacades.box(n, c + Vector3(0, 3.2, -0.05), Vector3(9.6, 0.2, 0.15), BLUE, 0.6)
	LookSigns.lit_panel(n, "ARMOURY", c + Vector3(0, 3.0, -0.12), 180.0, 3.0, 0.5, Color(1.0, 0.78, 0.4))
	LookFacades.box(n, c + Vector3(-4.9, 0.4, -0.2), Vector3(0.3, 0.8, 0.4), Color(0.3, 0.32, 0.3), 0.7)   # ammo lockers
	LookFacades.box(n, c + Vector3(4.9, 0.4, -0.2), Vector3(0.3, 0.8, 0.4), Color(0.3, 0.32, 0.3), 0.7)


static func _flags(n: Node3D) -> void:
	for sx in [-1.0, 1.0]:
		var base := Vector3(sx * 7.8, 3.5, 6.6)
		LookFacades._cyl(n, base + Vector3(0, 1.4, 0), 0.04, 2.8, Color(0.75, 0.75, 0.72))
		var col: Color = Color(0.2, 0.32, 0.5) if sx < 0 else Color(0.55, 0.15, 0.12)
		var f := LookFacades.box(n, base + Vector3(-sx * 0.0, 2.4, 0.5), Vector3(0.02, 0.6, 1.0), col, 0.9)
		f.name = "flag"
	LookSigns.stencil(n, "KESTREL RANGE", Vector3(0, 4.2, 6.4), 0.0, 0.6, Color(0.9, 0.9, 0.85, 0.9)).modulate = Color(0.9, 0.9, 0.85)


static func _work_lights(n: Node3D) -> void:
	for x in [-6.0, -2.0, 2.0, 6.0]:   # caged lamps under the roof, warm spot over the counter
		LookFacades.box(n, Vector3(x, 3.15, 6.7), Vector3(0.5, 0.16, 0.2), Color(1.0, 0.85, 0.55), 0.4, 4.0)
		var s := SpotLight3D.new()
		s.position = Vector3(x, 3.1, 6.7)
		s.rotation_degrees = Vector3(-80, 0, 0)
		s.spot_angle = 55.0
		s.spot_range = 9.0
		s.light_energy = 3.0
		s.light_color = Color(1.0, 0.82, 0.55)
		n.add_child(s)
