class_name ReloadHinge
extends RefCounted
## FB-R2: a part that turns about a hinge during a reload (PKM feed cover, revolver cylinder + crane). Rig key
## "hinge" = {box: AABB (gun-model space, cut by region like ReloadMag.cut_box), whole: only whole parts,
## pivot: Vector3, axis: Vector3, angle: rad at open = 1}. ReloadTimeline drives `open` 0..1 from its phases ("open").

var node: MeshInstance3D
var pivot := Vector3.ZERO
var axis := Vector3.RIGHT
var angle := 0.0
var _base := Transform3D.IDENTITY
var _k := Transform3D.IDENTITY


## Null unless the rig names a hinge and its region holds geometry.
static func make(glb: Node, rig: Dictionary) -> ReloadHinge:
	if not rig.has("hinge"):
		return null
	var h: Dictionary = rig["hinge"]
	var n := ReloadMag.cut_box(glb, h["box"], "Hinge", h.get("whole", false))
	if n == null:
		return null
	var out := ReloadHinge.new()
	out.node = n
	out.pivot = h["pivot"]
	out.axis = (h["axis"] as Vector3).normalized()
	out.angle = float(h["angle"])
	out._base = n.transform
	out._k = ReloadMag.to_gun(n.get_parent(), glb)
	return out


## Gun-model transform of the hinged part at `open` (0 = home).
func xf(open: float) -> Transform3D:
	return Transform3D(Basis(axis, angle * open), pivot) * Transform3D(Basis.IDENTITY, -pivot)


func apply(open: float) -> void:
	node.transform = _k.affine_inverse() * xf(open) * _k * _base


## True when the part sits exactly where the glb put it.
func home() -> bool:
	return node.transform.is_equal_approx(_base)
