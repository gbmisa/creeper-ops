class_name SkirmishParts
## Skirmish building blocks: walls with doors / windows, slabs, ramps. All colliders are world-layer boxes via RangeLayout.box.

const DOOR_TOP := 2.3
const WINDOW_H := 1.2


## Wall along `axis` ("x": runs along x at z = fixed; "z": along z at x = fixed) from a to b. Openings are
## [from, to] doors or [from, to, sill] windows, in absolute coordinates.
static func wall(parent: Node3D, axis: String, fixed: float, a: float, b: float, y0: float, h: float, thick: float,
		openings: Array, mat: String, col: Color) -> void:
	var ops := openings.duplicate()
	ops.sort_custom(func(p, q): return p[0] < q[0])
	var cur := a
	for o in ops:
		_piece(parent, axis, fixed, cur, o[0], y0, h, thick, mat, col)
		var sill: float = o[2] if o.size() > 2 else 0.0
		if sill > 0.0:
			_piece(parent, axis, fixed, o[0], o[1], y0, sill, thick, mat, col)
		var top := DOOR_TOP if sill <= 0.0 else sill + WINDOW_H
		if top < h:
			_piece(parent, axis, fixed, o[0], o[1], y0 + top, h - top, thick, mat, col)
		cur = o[1]
	_piece(parent, axis, fixed, cur, b, y0, h, thick, mat, col)


static func _piece(parent: Node3D, axis: String, fixed: float, a: float, b: float, y0: float, h: float, thick: float,
		mat: String, col: Color) -> void:
	if b - a < 0.01 or h < 0.01:
		return
	var mid := (a + b) * 0.5
	if axis == "x":
		RangeLayout.box(parent, "wall_" + mat, Vector3(mid, y0 + h * 0.5, fixed), Vector3(b - a, h, thick), mat, thick, col)
	else:
		RangeLayout.box(parent, "wall_" + mat, Vector3(fixed, y0 + h * 0.5, mid), Vector3(thick, h, b - a), mat, thick, col)


## Four walls round rect (x0, z0, x1, z1). openings: {"n","s","e","w"} -> list (n/s use x coords, e/w use z coords).
static func building(parent: Node3D, r: Rect2, y0: float, h: float, openings: Dictionary, mat: String, col: Color, thick := 0.3) -> void:
	var e := thick * 0.5
	wall(parent, "x", r.position.y, r.position.x - e, r.end.x + e, y0, h, thick, openings.get("n", []), mat, col)
	wall(parent, "x", r.end.y, r.position.x - e, r.end.x + e, y0, h, thick, openings.get("s", []), mat, col)
	wall(parent, "z", r.position.x, r.position.y + e, r.end.y - e, y0, h, thick, openings.get("w", []), mat, col)
	wall(parent, "z", r.end.x, r.position.y + e, r.end.y - e, y0, h, thick, openings.get("e", []), mat, col)


## Horizontal slab whose top face is at y_top.
static func slab(parent: Node3D, r: Rect2, y_top: float, thick: float, mat: String, col: Color) -> void:
	RangeLayout.box(parent, "slab_" + mat, Vector3(r.get_center().x, y_top - thick * 0.5, r.get_center().y),
		Vector3(r.size.x, thick, r.size.y), mat, thick, col)


## Vertical cylinder collider + mesh (fuel tanks, water towers).
static func cylinder(parent: Node3D, pos: Vector3, r: float, h: float, mat: String, col: Color) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = "cyl_" + mat
	sb.position = pos
	sb.collision_layer = TacticalConfig.LAYER_WORLD
	sb.collision_mask = 0
	sb.set_meta("mat", mat)
	sb.set_meta("thick", r)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r
	shape.height = h
	cs.shape = shape
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = LookMaterials.get_mat(mat, col, sb.name)
	sb.add_child(mi)
	parent.add_child(sb)
	return sb


## Walkable ramp (the stairs): top surface runs from `lo` (bottom centre) to `hi` (top centre), with tread strips.
static func ramp(parent: Node3D, lo: Vector3, hi: Vector3, width: float, col: Color) -> void:
	var dir := hi - lo
	var len := dir.length()
	var sb := RangeLayout.box(parent, "stairs", Vector3.ZERO, Vector3(width, 0.3, len), "concrete", 0.3, col)
	var basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	sb.transform = Transform3D(basis, (lo + hi) * 0.5 - basis.y * 0.15)
	var n := int(len / 0.45)
	for i in n:
		var tread := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(width, 0.03, 0.08)
		tread.mesh = bm
		tread.material_override = RangeLayout.colour(col.darkened(0.45))
		tread.position = Vector3(0, 0.16, -len * 0.5 + (i + 0.5) * len / n)
		sb.add_child(tread)
