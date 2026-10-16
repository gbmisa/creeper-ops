class_name RecoilEyeRoom
## How far the drawn gun may kick back along its bore at full ADS before any of its triangles comes within
## TacticalConfig.ADS_EYE_CLEAR (F58) of the eye (playtest 2026-10-16: the AK's top cover crossed the eye in a
## burst). Measured once per gun / fit from the mesh; the drawn kick back eases into that room (`soften`).
## Only the picture: the recoil model, the bullets and the view are untouched.

const NEAR := 0.08     # triangle search margin around the eye's kick-back path (> ADS_EYE_CLEAR)
const MAX_BACK := 0.40 # search limit (m); a gun with more room than this is never limited (F73: the Glock 18 kicks back 0.22 m)
const FREE := 1.0e9    # "no limit"
const STEP := 0.001    # search step (m)
const KNEE := 0.6      # kick back below this share of the room is drawn unchanged


## Room (m) for `model` posed by `pose` (model transform in the camera frame, eye at origin).
static func room(model: Node3D, pose: Transform3D) -> float:
	var eye := pose.affine_inverse() * Vector3.ZERO   # the eye in model space
	var tris := near_tris(model, eye)

	if tris.is_empty():
		return FREE
	var clear := TacticalConfig.ADS_EYE_CLEAR
	if clearance(tris, eye) <= clear:
		return 0.0
	var b := 0.0
	while b < MAX_BACK:   # kick back moves the gun +z in its own frame = the eye -z; not monotone, so walk it
		var nb := b + STEP
		if clearance(tris, eye - Vector3(0, 0, nb)) <= clear:
			return b
		b = nb
	return FREE


## Drawn kick back: unchanged up to KNEE x room, then eased so it never reaches the room.
static func soften(back: float, rm: float) -> float:
	var knee := rm * KNEE
	if back <= knee:
		return back
	var span := rm - knee
	return knee + span * tanhf((back - knee) / span) if span > 1e-6 else knee


static func tanhf(x: float) -> float:
	var e := exp(-2.0 * x)
	return (1.0 - e) / (1.0 + e)


## Visible triangles of `model` (model space) that can come within NEAR of the eye kicked back up to MAX_BACK
## (triangle box against the box swept by the eye, grown by NEAR).
static func near_tris(model: Node3D, eye: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	var reach := AABB(eye - Vector3(0, 0, MAX_BACK), Vector3(0, 0, MAX_BACK)).grow(NEAR)
	var inv := model.global_transform.affine_inverse()
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		var m := inv * mi.global_transform
		if not reach.intersects(m * mi.get_aabb()):
			continue
		var f := mi.mesh.get_faces()
		for i in range(0, f.size(), 3):
			var a := m * f[i]
			var b := m * f[i + 1]
			var c := m * f[i + 2]
			var box := AABB(a, Vector3.ZERO).expand(b).expand(c)
			if reach.intersects(box):
				out.append_array([a, b, c])
	return out


static func clearance(tris: PackedVector3Array, p: Vector3) -> float:
	var best := 1.0e9
	for i in range(0, tris.size(), 3):
		best = minf(best, closest(tris[i] - p, tris[i + 1] - p, tris[i + 2] - p).length())
	return best


## Closest point to the origin on triangle abc (Ericson, Real-Time Collision Detection 5.1.5).
static func closest(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var d1 := ab.dot(-a)
	var d2 := ac.dot(-a)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var d3 := ab.dot(-b)
	var d4 := ac.dot(-b)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var d5 := ab.dot(-c)
	var d6 := ac.dot(-c)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var den := 1.0 / (va + vb + vc)
	return a + ab * (vb * den) + ac * (vc * den)
