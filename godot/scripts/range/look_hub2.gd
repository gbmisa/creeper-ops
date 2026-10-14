class_name LookHub2
## Firing Range hub round 2 (visual only, no colliders): painted lane numbers and dividers, slab joints and edge wear,
## target stands, lane work lights, gear benches off the fire lanes, booth side-wall dressing. Headless skips it.

const WHITE := Color(0.84, 0.84, 0.8)
const YELLOW := Color(0.85, 0.7, 0.2)
const DARK := Color(0.12, 0.13, 0.13)
const OLIVE := Color(0.27, 0.3, 0.2)
const WOOD := Color(0.42, 0.3, 0.18)


static func build(n: Node3D) -> void:
	_lanes(n)
	_slab(n)
	_stands(n)
	_lamps(n)
	_gear(n)
	_booth_sides(n)


## Lane dividers (dashed), lane numbers at the firing line, distance numerals on the ground and long edge lines.
static func _lanes(n: Node3D) -> void:
	var lx := [-16.0, -8.0, 0.0, 8.0, 16.0]
	for i in 5:
		LookSigns.stencil(n, "LANE %d" % (i + 1), Vector3(lx[i], 0.03, -5.2), 0.0, 1.0, Color(0.95, 0.92, 0.8, 0.9), true)
		LookSigns.stencil(n, "%d" % (i + 1), Vector3(lx[i], 0.03, -9.0), 0.0, 2.6, Color(0.95, 0.92, 0.8, 0.85), true)
	for x in [-12.0, -4.0, 4.0, 12.0]:   # dashed dividers 4 m dash / 4 m gap out to 60 m
		for k in 14:
			LookSigns.paint(n, Vector3(x, 0.0, -4.0 - k * 4.0), Vector2(0.14, 2.0), WHITE)
	for x in [-19.2, 19.2]:   # edge lines, whole length
		LookSigns.paint(n, Vector3(x, 0.0, -RangeLayout.LENGTH * 0.5 + 7.0), Vector2(0.2, RangeLayout.LENGTH - 6.0), YELLOW)
	for d in RangeLayout.DISTANCES:
		var s: float = 1.2 + d / 70.0
		for x in [-12.0, 0.0, 12.0]:
			LookSigns.stencil(n, "%d M" % d, Vector3(x, 0.03, -float(d) + 2.6 * s), 0.0, 1.6 * s, Color(0.95, 0.92, 0.8, 0.8), true)


## Slab: dark expansion joints (grout), darker edge band for wear / AO, scuffed worn patch in front of the counter.
static func _slab(n: Node3D) -> void:
	var grout := Color(0.1, 0.1, 0.1)
	for i in 5:   # joints every 3 m across x (slab spans -8..8, z -3.5..10.5)
		LookSigns.paint(n, Vector3(-6.0 + i * 3.0, 0.0, 3.5), Vector2(0.06, 14.0), grout)
	for k in 5:
		LookSigns.paint(n, Vector3(0, 0.0, -2.0 + k * 3.0), Vector2(16.0, 0.06), grout)
	for sx in [-1.0, 1.0]:   # edge wear bands
		LookSigns.paint(n, Vector3(sx * 7.85, 0.0, 3.5), Vector2(0.3, 14.0), Color(0.16, 0.15, 0.14))
	LookSigns.paint(n, Vector3(0, 0.0, -3.35), Vector2(16.0, 0.3), Color(0.16, 0.15, 0.14))
	LookSigns.paint(n, Vector3(0, 0.0, 1.8), Vector2(9.0, 1.4), Color(0.4, 0.38, 0.35).darkened(0.1))   # worn standing area
	for sx in [-1.0, 1.0]:   # hazard stripes at the slab corners
		for k in 5:
			LookSigns.paint(n, Vector3(sx * 7.4, 0.0, -3.0 + k * 0.3), Vector2(1.0, 0.14), YELLOW if k % 2 == 0 else DARK, 0.0)


## Target stands: two posts, a crossbeam, a sandbag foot and a paper target, in pairs just inside the berms.
static func _stands(n: Node3D) -> void:
	for d in RangeLayout.DISTANCES:
		var s: float = 1.0 + d / 100.0
		for sx in [-1.0, 1.0]:
			var p := Vector3(sx * 18.2, 0.0, -float(d) - 1.2)
			for k in [-0.55, 0.55]:
				LookFacades.box(n, p + Vector3(k * s, 0.9 * s, 0), Vector3(0.08 * s, 1.8 * s, 0.08 * s), WOOD, 0.9)
			LookFacades.box(n, p + Vector3(0, 1.7 * s, 0), Vector3(1.3 * s, 0.08 * s, 0.08 * s), WOOD, 0.9)
			LookFacades.box(n, p + Vector3(0, 1.1 * s, 0.05), Vector3(0.6 * s, 0.8 * s, 0.02), Color(0.8, 0.76, 0.62), 0.9)
			LookFacades.box(n, p + Vector3(0, 1.2 * s, 0.065), Vector3(0.3 * s, 0.3 * s, 0.01), Color(0.1, 0.1, 0.1), 0.9)
			LookFacades.box(n, p + Vector3(0, 0.12 * s, 0), Vector3(1.4 * s, 0.24 * s, 0.4 * s), Color(0.5, 0.45, 0.32), 1.0)


## Pole lamps down both sides: emissive heads everywhere, a few real warm omni lights near the booth that pool on the ground.
static func _lamps(n: Node3D) -> void:
	var zs := [-14.0, -40.0, -70.0, -110.0, -160.0, -220.0, -290.0]
	for z in zs:
		for sx in [-1.0, 1.0]:
			var x: float = sx * 19.6
			LookFacades._cyl(n, Vector3(x, 2.4, z), 0.07, 4.8, Color(0.2, 0.2, 0.2))
			LookFacades.box(n, Vector3(x - sx * 0.5, 4.8, z), Vector3(1.1, 0.08, 0.1), Color(0.2, 0.2, 0.2), 0.7)
			LookFacades.box(n, Vector3(x - sx * 1.0, 4.74, z), Vector3(0.5, 0.12, 0.25), Color(1.0, 0.82, 0.5), 0.4, 5.0)
	for z in [-14.0, -40.0, -70.0]:
		for sx in [-1.0, 1.0]:
			var l := OmniLight3D.new()
			l.position = Vector3(sx * 17.0, 4.2, z)
			l.omni_range = 18.0
			l.light_energy = 2.4
			l.light_color = Color(1.0, 0.78, 0.48)
			l.light_specular = 0.3
			n.add_child(l)


## Gear off the fire lanes: ammo cans and a spotting scope on side tables against the booth walls, rifle stand, cleaning bench.
static func _gear(n: Node3D) -> void:
	for sx in [-1.0, 1.0]:
		var t := Vector3(sx * 7.4, 0.0, 2.0)
		LookFacades.box(n, t + Vector3(0, 0.88, 0), Vector3(1.0, 0.06, 1.8), WOOD, 0.8)
		for dz in [-0.8, 0.8]:
			LookFacades.box(n, t + Vector3(0, 0.43, dz), Vector3(0.9, 0.86, 0.06), Color(0.2, 0.22, 0.22), 0.7)
		for i in 4:   # ammo cans
			LookFacades.box(n, t + Vector3(-0.2 + (i % 2) * 0.4, 0.96 + (i / 2) * 0.0, -0.6 + (i / 2) * 0.4), Vector3(0.32, 0.18, 0.16), OLIVE, 0.6)
			LookFacades.box(n, t + Vector3(-0.2 + (i % 2) * 0.4, 1.0, -0.6 + (i / 2) * 0.4), Vector3(0.12, 0.02, 0.04), YELLOW, 0.8)
	# spotting scope on a tripod (left table)
	var sc := Vector3(-7.4, 0.9, 2.9)
	for k in 3:
		var a := k * TAU / 3.0
		var leg := LookFacades._cyl(n, sc + Vector3(cos(a) * 0.15, 0.2, sin(a) * 0.15), 0.012, 0.45, DARK)
		leg.rotation_degrees = Vector3(sin(a) * 18.0, 0, -cos(a) * 18.0)
	var tube := LookFacades._cyl(n, sc + Vector3(0, 0.52, 0), 0.05, 0.4, Color(0.1, 0.16, 0.14))
	tube.rotation_degrees.x = 90.0
	# rifle stand against the right wall: rails with five dark rifle shapes
	var r := Vector3(7.6, 0.0, 5.5)
	LookFacades.box(n, r + Vector3(0, 0.15, 0), Vector3(0.4, 0.3, 2.0), DARK, 0.7)
	LookFacades.box(n, r + Vector3(0.05, 1.0, 0), Vector3(0.1, 0.06, 2.0), DARK, 0.7)
	for i in 5:
		var z := -0.8 + i * 0.4
		LookFacades.box(n, r + Vector3(-0.05, 0.6, z), Vector3(0.06, 1.1, 0.07), Color(0.08, 0.08, 0.09), 0.5)
		LookFacades.box(n, r + Vector3(-0.05, 0.12, z), Vector3(0.1, 0.24, 0.1), Color(0.28, 0.2, 0.12), 0.7)
	# gear on the existing bench top (y 0.9): cans, a cleaning mat
	LookFacades.box(n, Vector3(5.0, 0.93, 8.0), Vector3(1.2, 0.02, 0.6), Color(0.12, 0.18, 0.12), 0.9)
	for i in 3:
		LookFacades.box(n, Vector3(4.5 + i * 0.35, 1.03, 8.2), Vector3(0.3, 0.18, 0.15), OLIVE, 0.6)


## Booth side walls (x = +/-8.3 outside face): windows with dark glass and warm interior glow, a door, posters, pipes, vents.
static func _booth_sides(n: Node3D) -> void:
	for sx in [-1.0, 1.0]:
		var xo: float = sx * 8.33
		for z in [1.2, 4.0, 6.8, 9.2]:   # windows: frame, dark glass, sill
			LookFacades.box(n, Vector3(xo, 1.95, z), Vector3(0.1, 1.25, 1.65), Color(0.78, 0.77, 0.7), 0.7)
			LookFacades.box(n, Vector3(xo + sx * 0.03, 1.95, z), Vector3(0.1, 1.05, 1.45), Color(0.05, 0.08, 0.09), 0.08, 0.35)
			LookFacades.box(n, Vector3(xo + sx * 0.06, 1.95, z), Vector3(0.04, 1.05, 0.05), Color(0.78, 0.77, 0.7), 0.7)
			LookFacades.box(n, Vector3(xo + sx * 0.1, 1.28, z), Vector3(0.22, 0.08, 1.8), Color(0.6, 0.6, 0.56), 0.7)
		var posters := [[2.6, Color(0.7, 0.2, 0.15)], [5.4, Color(0.2, 0.4, 0.6)], [8.0, Color(0.8, 0.7, 0.3)]]
		for p in posters:
			LookFacades.box(n, Vector3(xo + sx * 0.02, 1.35, p[0]), Vector3(0.06, 0.5, 0.36), p[1], 0.9)
		LookFacades.box(n, Vector3(xo + sx * 0.02, 0.8, -0.3), Vector3(0.05, 0.7, 0.2), Color(0.7, 0.12, 0.1), 0.5)   # extinguisher
		LookFacades._cyl(n, Vector3(xo + sx * 0.18, 1.1, 5.4), 0.06, 1.8, Color(0.33, 0.35, 0.33))   # vertical pipe
		var conduit := LookFacades._cyl(n, Vector3(xo + sx * 0.14, 2.75, 4.0), 0.045, 11.0, Color(0.33, 0.35, 0.33))
		conduit.rotation_degrees.x = 90.0
		for i in 5:   # louvre vents high up
			LookFacades.box(n, Vector3(xo + sx * 0.05, 2.5 + i * 0.07, 9.4), Vector3(0.05, 0.03, 0.8), Color(0.2, 0.22, 0.22), 0.6)
		LookSigns.lit_panel(n, "RANGE OFFICE", Vector3(xo + sx * 0.05, 2.95, 1.0), 90.0 * sx, 1.8, 0.3, Color(0.9, 0.75, 0.4))
		for k in 6:   # hazard stripes on the lower corner
			LookFacades.box(n, Vector3(xo + sx * 0.03, 0.25 + k * 0.0, -1.75 + k * 0.14), Vector3(0.04, 0.5, 0.07), YELLOW if k % 2 == 0 else DARK, 0.8)
		LookFacades.box(n, Vector3(xo, 0.2, 4.0), Vector3(0.14, 0.4, 12.2), Color(0.18, 0.18, 0.17), 0.9)   # plinth
