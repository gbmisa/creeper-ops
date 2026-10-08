class_name ShapeKit
## Shapes the primitive meshes can't make: lathes from a 2D profile, struts between two
## points, axles, cones, arches and cloth banners. Meshes are cached by their parameters,
## so a hundred raiders share one ArrayMesh per part.

static var _cache := {}


## Surface of revolution round +Y. `profile` is (radius, y) pairs from bottom to top.
## Few sides give the faceted, hand-cut look the stone parts want.
static func lathe_mesh(profile: PackedVector2Array, sides := 8) -> ArrayMesh:
	var key := "lathe%s/%d" % [profile, sides]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in profile.size() - 1:
		var a := profile[i]
		var b := profile[i + 1]
		for s in sides:
			var t0 := TAU * s / sides
			var t1 := TAU * (s + 1) / sides
			var p00 := Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x)
			var p01 := Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x)
			var p10 := Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)
			var p11 := Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)
			for p in [p00, p11, p10, p00, p01, p11]:
				st.add_vertex(p)
	st.generate_normals()
	var m := st.commit()
	_cache[key] = m
	return m


static func lathe(parent: Node3D, profile: PackedVector2Array, m: Material, at := Vector3.ZERO, sides := 8) -> MeshInstance3D:
	return StructureMeshes._add(parent, lathe_mesh(profile, sides), m, at)


## Box beam from a to b (parent-local), `w` thick across and `d` deep along Z of the beam.
static func strut(parent: Node3D, a: Vector3, b: Vector3, w: float, m: Material, d := -1.0) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = Vector3(w, a.distance_to(b), d if d > 0.0 else w)
	var mi := StructureMeshes._add(parent, bm, m, (a + b) * 0.5)
	var up := (b - a).normalized()
	var side := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := up.cross(side).normalized()
	mi.basis = Basis(x, up, x.cross(up)).orthonormalized()
	return mi


## Round rod from a to b.
static func rod(parent: Node3D, a: Vector3, b: Vector3, r: float, m: Material, sides := 8) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = a.distance_to(b)
	c.radial_segments = sides
	c.rings = 1
	var mi := StructureMeshes._add(parent, c, m, (a + b) * 0.5)
	var up := (b - a).normalized()
	var side := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := up.cross(side).normalized()
	mi.basis = Basis(x, up, x.cross(up)).orthonormalized()
	return mi


## Tapered horn/rib from a (radius r0) to b (radius r1): bone spikes, ribs, bow limbs.
static func taper(parent: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, m: Material, sides := 6) -> MeshInstance3D:
	var l := a.distance_to(b)
	var mi := StructureMeshes._add(parent, lathe_mesh(PackedVector2Array([Vector2(r0, 0.0), Vector2(r1, l), Vector2(0.0, l)]), sides), m, a)
	var up := (b - a).normalized()
	var side := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := up.cross(side).normalized()
	mi.basis = Basis(x, up, x.cross(up)).orthonormalized()
	return mi


## Curved horn: two tapered segments a -> bend -> b.
static func horn(parent: Node3D, a: Vector3, bend: Vector3, b: Vector3, r: float, m: Material) -> void:
	taper(parent, a, bend, r, r * 0.6, m)
	taper(parent, bend, b, r * 0.6, r * 0.12, m)


## Hinge pin along Z (the joint axis of a pitching arm).
static func axle(parent: Node3D, at: Vector3, r: float, length: float, m: Material) -> MeshInstance3D:
	return rod(parent, at - Vector3(0, 0, length * 0.5), at + Vector3(0, 0, length * 0.5), r, m, 10)


static func cone(parent: Node3D, r: float, h: float, m: Material, at := Vector3.ZERO, sides := 10) -> MeshInstance3D:
	return lathe(parent, PackedVector2Array([Vector2(r, 0), Vector2(0, h)]), m, at, sides)


## Round arch in the XY plane (span along X), `n` voussoir blocks, standing on `at`.
static func arch(parent: Node3D, span: float, rise: float, thick: float, depth: float, m: Material, at := Vector3.ZERO, n := 7) -> void:
	var rx := span * 0.5
	for i in n:
		var t0 := PI * i / n
		var t1 := PI * (i + 1) / n
		var a := at + Vector3(cos(t0) * rx, sin(t0) * rise, 0)
		var b := at + Vector3(cos(t1) * rx, sin(t1) * rise, 0)
		var ext := (b - a) * 0.12  # overlap neighbours so the outer joints don't gap
		strut(parent, a - ext, b + ext, thick, m, depth)


## Hanging cloth banner: a thin panel with a notched (swallowtail) foot, facing +Z.
static func banner(parent: Node3D, w: float, h: float, m: Material, top := Vector3.ZERO) -> Node3D:
	var b := Node3D.new()
	b.position = top
	parent.add_child(b)
	StructureMeshes.box(b, Vector3(w, h * 0.8, 0.04), m, Vector3(0, -h * 0.4, 0))
	for sx in [-1.0, 1.0]:
		var tail := StructureMeshes.box(b, Vector3(w * 0.5, h * 0.25, 0.04), m, Vector3(sx * w * 0.25, -h * 0.85, 0))
		tail.rotation.z = sx * 0.25
	return b
