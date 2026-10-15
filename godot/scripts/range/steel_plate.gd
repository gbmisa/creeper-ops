class_name SteelPlate
extends Node3D
## Hinged steel plate: swings and rings when a bullet lands on it, then settles. Collider is a steel_target world body.

const SWING_DEG := 22.0

var dist := 10
var size := Vector2(0.3, 0.4)
var rest := 0.0
var swinging := false
var _body: StaticBody3D
var _mat := StandardMaterial3D.new()
var _tw: Tween


func setup(d: int, x: float) -> void:
	dist = d
	var s := 0.3 + d / 200.0
	size = Vector2(s, s * 1.25)
	position = Vector3(x, 0.9 + size.y, -float(d))  # hinge at the plate's top edge
	_mat.albedo_color = Color(0.55, 0.12, 0.1)
	_mat.metallic = 0.7
	_mat.roughness = 0.4
	_body = RangeLayout.box(self, "plate", Vector3(0, -size.y * 0.5, 0), Vector3(size.x, size.y, 0.03), "steel_target", 0.03, Color.WHITE)
	(_body.get_child(1) as MeshInstance3D).material_override = _mat
	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.05, 0.9 + size.y, 0.05)
	post.mesh = pm
	post.material_override = RangeLayout.colour(Color(0.3, 0.3, 0.32))
	post.position = Vector3(0, -(0.9 + size.y) * 0.5 - size.y, -0.1)
	add_child(post)


func contains(p: Vector3) -> bool:
	var local := _body.to_local(p)
	return absf(local.x) <= size.x * 0.5 + 0.06 and absf(local.y) <= size.y * 0.5 + 0.06 and absf(local.z) < 0.12


func hit() -> void:
	swinging = true
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.7, 0.3)
	if _tw != null:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "rotation_degrees:x", SWING_DEG, 0.12)
	_tw.tween_property(self, "rotation_degrees:x", -SWING_DEG * 0.5, 0.25)
	_tw.tween_property(self, "rotation_degrees:x", SWING_DEG * 0.25, 0.25)
	_tw.tween_property(self, "rotation_degrees:x", 0.0, 0.3)
	_tw.tween_callback(reset)


func reset() -> void:
	if _tw != null:
		_tw.kill()
	rotation_degrees.x = 0.0
	swinging = false
	_mat.emission_enabled = false
