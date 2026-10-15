class_name LookKestrel
## Outpost Kestrel dressing for Skirmish: facades, checkpoint gate + barrier arm at the spawn, radar mast, motor pool paint,
## perimeter stencils, wall signs, props and foliage. Visual only, except the guard-hut collider (see gate_collider):
## nothing else collides, nothing sits on a bot route.
const STENCIL := Color(0.78, 0.76, 0.66, 0.72)
const WALL_H := 4.0


static func build(parent: Node3D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var n := Node3D.new()
	n.name = "Kestrel"
	parent.add_child(n)
	LookFacades.build(n)
	_gate(n)
	_radar_mast(n)
	_motor_pool(n, Vector3(-10, 0, 6), 0.0)
	_motor_pool(n, Vector3(6, 0, -30), 0.0)
	_perimeter(n)
	_wall_signs(n)
	_covers(parent, n)
	LookProps.build(n, LookPropDefs.SKIRMISH, true, true)
	LookScatter.skirmish(n)


## F25: collision for the guard hut beside the checkpoint lane. The hut itself is built visual-only in
## _gate (skipped when headless), so this runs separately from SkirmishLayout.build and always applies.
## Simple box matching the hut body: 2.2 x 2.6 x 2.2 at (8.0, 1.3, 47.0).
static func gate_collider(parent: Node3D) -> void:
	var sb := StaticBody3D.new()
	sb.name = "GuardHut"
	sb.collision_layer = TacticalConfig.LAYER_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.2, 2.6, 2.2)
	cs.shape = b
	sb.add_child(cs)
	sb.position = Vector3(8.0, 1.3, 47.0)
	sb.set_meta("mat", "plywood")
	sb.set_meta("thick", 0.15)
	parent.add_child(sb)


## Checkpoint: two posts and an overhead beam at z 47, barrier arm raised beside the booth, guard hut, stripes.
static func _gate(n: Node3D) -> void:
	var z := 47.0
	var red := Color(0.7, 0.18, 0.14)
	var white := Color(0.82, 0.8, 0.74)
	for sx in [-1.0, 1.0]:
		LookFacades.box(n, Vector3(sx * 4.6, 2.2, z), Vector3(0.35, 4.4, 0.35), Color(0.4, 0.4, 0.38), 0.8)
		for i in 4:   # red / white hazard bands on the posts
			LookFacades.box(n, Vector3(sx * 4.6, 0.4 + i * 0.7, z), Vector3(0.39, 0.3, 0.39), red if i % 2 == 0 else white, 0.8)
	LookFacades.box(n, Vector3(0, 4.55, z), Vector3(9.8, 0.4, 0.45), Color(0.32, 0.36, 0.33), 0.8)
	LookSigns.stencil(n, "KESTREL", Vector3(0, 4.55, z + 0.24), 0.0, 0.3, STENCIL)
	LookSigns.stencil(n, "CHECKPOINT 1", Vector3(0, 4.55, z - 0.24), 180.0, 0.3, STENCIL)
	# barrier arm, raised at 75 degrees from the east post so the lane stays open
	var arm := Node3D.new()
	arm.position = Vector3(4.2, 1.1, z)
	arm.rotation_degrees.z = -75.0
	n.add_child(arm)
	for i in 8:
		LookFacades.box(arm, Vector3(-(i + 0.5) * 0.92, 0, 0), Vector3(0.9, 0.12, 0.1), red if i % 2 == 0 else white, 0.7)
	# guard hut beside the lane
	var hx := 8.0
	LookFacades.box(n, Vector3(hx, 1.3, z), Vector3(2.2, 2.6, 2.2), Color(0.42, 0.5, 0.45), 0.9)
	LookFacades.box(n, Vector3(hx, 2.7, z), Vector3(2.6, 0.18, 2.6), Color(0.3, 0.3, 0.29), 0.9)
	LookFacades.box(n, Vector3(hx - 1.12, 1.6, z), Vector3(0.05, 0.8, 1.4), Color(0.16, 0.2, 0.22), 0.1)
	LookFacades.box(n, Vector3(hx, 1.6, z + 1.12), Vector3(1.4, 0.8, 0.05), Color(0.16, 0.2, 0.22), 0.1)
	LookSigns.stencil(n, "STOP", Vector3(0, 0.012, z + 1.5), 0.0, 1.2, Color(0.9, 0.85, 0.5, 0.7), true)
	LookSigns.paint(n, Vector3(0, 0, z + 1.0), Vector2(9.0, 0.25), Color(0.85, 0.82, 0.7))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(hx - 1.4, 3.2, z + 1.4)
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.omni_range = 9.0
	lamp.light_energy = 1.4
	n.add_child(lamp)


## Lattice mast beside the radar dome, with a red obstruction light.
static func _radar_mast(n: Node3D) -> void:
	var c := Vector3(-55.5, 0, -39.0)
	var steel := Color(0.52, 0.54, 0.52)
	for i in 4:
		var a := float(i) * TAU / 4.0 + PI * 0.25
		var foot := c + Vector3(cos(a), 0, sin(a)) * 1.2
		var top := c + Vector3(cos(a), 0, sin(a)) * 0.2 + Vector3(0, 16, 0)
		_beam(n, foot, top, 0.07, steel)
	for k in 6:   # cross braces
		var y := 1.5 + k * 2.4
		var r := lerpf(1.2, 0.2, y / 16.0)
		for i in 4:
			var a0 := float(i) * TAU / 4.0 + PI * 0.25
			var a1 := float(i + 1) * TAU / 4.0 + PI * 0.25
			_beam(n, c + Vector3(cos(a0), 0, sin(a0)) * r + Vector3(0, y, 0), c + Vector3(cos(a1), 0, sin(a1)) * r + Vector3(0, y, 0), 0.04, steel)
	LookFacades.box(n, c + Vector3(0, 16.2, 0), Vector3(0.3, 0.3, 0.3), Color(1.0, 0.1, 0.05), 0.4, 3.0)
	var l := OmniLight3D.new()
	l.position = c + Vector3(0, 16.6, 0)
	l.light_color = Color(1.0, 0.15, 0.1)
	l.omni_range = 12.0
	l.light_energy = 1.5
	n.add_child(l)
	LookFacades.box(n, c + Vector3(0, 0.15, 0), Vector3(3.2, 0.3, 3.2), Color(0.34, 0.34, 0.32), 0.9)


static func _beam(n: Node3D, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var mi := LookFacades._cyl(n, (a + b) * 0.5, r, a.distance_to(b), col)
	mi.look_at_from_position((a + b) * 0.5, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)


## Painted bay: yellow outline round a truck, a bay number, a wheel-chock tick.
static func _motor_pool(n: Node3D, c: Vector3, yaw: float) -> void:
	var y := Color(0.82, 0.68, 0.2, 1.0).darkened(0.25)
	LookSigns.outline(n, c + Vector3(0, 0, 0), 4.0, 8.4, 0.15, y)
	LookSigns.stencil(n, "MP-%d" % (1 if c.x < 0 else 2), c + Vector3(0, 0.014, 4.9), yaw, 0.9, Color(0.9, 0.85, 0.5, 0.65), true)


static func _perimeter(n: Node3D) -> void:
	var H := SkirmishData.HALF
	var c := STENCIL
	LookSigns.stencil(n, "KESTREL", Vector3(0, 2.3, -H + 0.54), 0.0, 1.6, c)
	LookSigns.stencil(n, "KESTREL", Vector3(0, 2.3, H - 0.54), 180.0, 1.6, c)
	LookSigns.stencil(n, "SECTOR A", Vector3(-H + 0.54, 2.2, -30.0), 90.0, 0.9, c)
	LookSigns.stencil(n, "SECTOR B", Vector3(-H + 0.54, 2.2, 30.0), 90.0, 0.9, c)
	LookSigns.stencil(n, "SECTOR C", Vector3(H - 0.54, 2.2, -30.0), -90.0, 0.9, c)
	LookSigns.stencil(n, "SECTOR D", Vector3(H - 0.54, 2.2, 30.0), -90.0, 0.9, c)
	# painted wall stripes and a base band so the 4 m walls are not plain slabs
	for s in [-1.0, 1.0]:
		LookFacades.box(n, Vector3(0, 0.35, s * (H - 0.52)), Vector3(H * 2, 0.7, 0.04), Color(0.16, 0.16, 0.15), 0.9)
		LookFacades.box(n, Vector3(0, 3.7, s * (H - 0.52)), Vector3(H * 2, 0.2, 0.04), Color(0.55, 0.5, 0.3), 0.9)
		LookFacades.box(n, Vector3(s * (H - 0.52), 0.35, 0), Vector3(0.04, 0.7, H * 2), Color(0.16, 0.16, 0.15), 0.9)
		LookFacades.box(n, Vector3(s * (H - 0.52), 3.7, 0), Vector3(0.04, 0.2, H * 2), Color(0.55, 0.5, 0.3), 0.9)


## Small stencils on buildings and covers.
static func _wall_signs(n: Node3D) -> void:
	var c := STENCIL
	LookSigns.stencil(n, "BLOCK B", Vector3(26.5, 2.0, 10.2), 0.0, 0.5, c)
	LookSigns.stencil(n, "BLOCK B", Vector3(26.5, 2.0, -0.2), 180.0, 0.5, c)
	LookSigns.stencil(n, "ADMIN", Vector3(-22.0, 3.45, -0.82), 0.0, 0.45, c)
	LookSigns.stencil(n, "WH-1", Vector3(28.0, 2.9, -25.8), 0.0, 0.6, c)
	for cv in SkirmishData.COVER:
		if cv[0] == "barrier":
			var k := 1 + int(absf(cv[1] + cv[2])) % 9
			LookSigns.stencil(n, "K-%d" % k, Vector3(cv[1], 0.62, cv[2] + cv[4] * 0.5 + 0.02), 0.0, 0.35, Color(0.9, 0.85, 0.6, 0.75))


## Re-skin cover pieces: the StaticBody (collision) stays, its box mesh is hidden and a prop fitted to the same box shows instead.
static func _covers(layout: Node3D, n: Node3D) -> void:
	var skin := {"crate": "crate", "barrier": "jersey", "car": "wreck"}
	var bodies: Array = layout.get_children().filter(func(c): return c is StaticBody3D)
	for c in SkirmishData.COVER:
		var id: String = c[0]
		var size := Vector3(c[3], c[5], c[4])
		var centre := Vector3(c[1], c[5] * 0.5, c[2])
		var body: StaticBody3D = null
		for b in bodies:
			if (b as StaticBody3D).position.distance_to(centre) < 0.01 and str(b.name).begins_with(id):
				body = b
				break
		if body == null:
			continue
		var yaw := 0.0
		if id == "car":   # wreck model is long along X; the car box is long along Z
			yaw = 90.0
		var got: Node3D = null
		if skin.has(id):
			got = LookProps.fit(n, skin[id], Vector3(c[1], 0.0, c[2]), Vector3(size.z, size.y, size.x) if id == "car" else size, yaw)
		elif id == "truck":
			got = _truck(n, Vector3(c[1], 0.0, c[2]), size)
		if got != null:
			for m in body.get_children():
				if m is MeshInstance3D:
					(m as MeshInstance3D).visible = false


## Truck dressing over its box: wheels, cab with windscreen, canvas ribs, bumper. The box mesh underneath is hidden, so this
## builds the whole visible truck inside the same footprint.
static func _truck(n: Node3D, p: Vector3, size: Vector3) -> Node3D:
	var t := Node3D.new()
	t.position = p
	n.add_child(t)
	var green := Color(0.3, 0.36, 0.28)
	var cab_len := 1.9
	var hz := size.z * 0.5
	LookFacades.box(t, Vector3(0, 0.55, 0), Vector3(size.x, 0.22, size.z), Color(0.16, 0.17, 0.16), 0.9)   # chassis
	LookFacades.box(t, Vector3(0, 1.5, -hz + cab_len * 0.5), Vector3(size.x, 1.8, cab_len), green, 0.7)
	LookFacades.box(t, Vector3(0, 1.85, -hz + 0.02), Vector3(size.x - 0.3, 0.8, 0.06), Color(0.1, 0.14, 0.16), 0.1)
	LookFacades.box(t, Vector3(0, 0.95, -hz - 0.1), Vector3(size.x, 0.35, 0.2), Color(0.2, 0.2, 0.2), 0.8)
	for sx in [-1.0, 1.0]:
		LookFacades.box(t, Vector3(sx * (size.x * 0.5 + 0.01), 1.85, -hz + cab_len * 0.5), Vector3(0.05, 0.7, 1.0), Color(0.1, 0.14, 0.16), 0.1)
	var bed_len := size.z - cab_len - 0.1
	LookFacades.box(t, Vector3(0, 1.0, hz - bed_len * 0.5), Vector3(size.x, 0.2, bed_len), Color(0.28, 0.22, 0.14), 0.9)
	LookFacades.box(t, Vector3(0, 1.9, hz - bed_len * 0.5), Vector3(size.x - 0.1, 1.2, bed_len - 0.1), Color(0.36, 0.38, 0.28), 0.95)   # canvas
	LookFacades.box(t, Vector3(0, 2.4, hz - bed_len * 0.5), Vector3(size.x - 0.5, 0.2, bed_len - 0.3), Color(0.36, 0.38, 0.28), 0.95)
	for i in 4:
		LookFacades.box(t, Vector3(0, 1.9, hz - 0.8 - i * (bed_len - 1.2) / 3.0), Vector3(size.x, 1.25, 0.08), Color(0.25, 0.26, 0.2), 0.9)
	for sx in [-1.0, 1.0]:
		for z in [-hz + 1.0, hz - 1.0, hz - 2.4]:
			var w := LookFacades._cyl(t, Vector3(sx * (size.x * 0.5 - 0.05), 0.5, z), 0.5, 0.4, Color(0.07, 0.07, 0.07))
			w.rotation_degrees.z = 90.0
	LookSigns.stencil(t, "KS-%d" % (int(p.z) % 90 + 10), Vector3(size.x * 0.5 + 0.03, 1.4, -hz + 0.9), 90.0, 0.3, Color(0.85, 0.85, 0.75, 0.8))
	return t
