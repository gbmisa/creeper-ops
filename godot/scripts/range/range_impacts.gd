class_name RangeImpacts
extends Node3D
## Simple impact puffs + bullet-hole discs for Ballistics.impact (phase 3 adds per-target marks).

const MAX_HOLES := 120
var _holes: Array[Node3D] = []
var _hole_mesh := QuadMesh.new()


func _init() -> void:
	_hole_mesh.size = Vector2(0.07, 0.07)


func on_impact(info: Dictionary) -> void:
	var mat := MaterialDefs.of(info.get("mat", "dirt_berm"))
	var pos: Vector3 = info["pos"]
	var n: Vector3 = info.get("normal", Vector3.UP)
	var col: Color = mat["color"]
	_puff(pos, n, col, info.get("kind", "stop"))
	if info.get("kind", "stop") != "pass":
		_hole(pos, n, col.darkened(0.6))


func _puff(pos: Vector3, n: Vector3, col: Color, kind: String) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.06
	s.height = 0.12
	s.radial_segments = 8
	s.rings = 4
	m.mesh = s
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(1.0, 0.8, 0.4, 0.9) if kind == "ricochet" else Color(col.lightened(0.3), 0.7)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mt
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = pos + n * 0.03
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * 3.0, 0.35)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(m.queue_free)


func _hole(pos: Vector3, n: Vector3, col: Color) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _hole_mesh
	var mt := StandardMaterial3D.new()
	mt.albedo_color = col
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mt
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = pos + n * 0.01
	var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	m.global_basis = Basis.looking_at(-n, up)
	_holes.append(m)
	if _holes.size() > MAX_HOLES:
		_holes.pop_front().queue_free()
