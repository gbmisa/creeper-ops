class_name PaperTarget
extends Node3D
## Paper silhouette: a thin "paper" world body that every bullet passes; hole marks stay until reset.
## Zone rings are drawn so the marks read as head / chest / stomach.

const HEIGHT := 1.8
var dist := 25
var marks: Array[Node3D] = []
var zone_hits := {}
var _body: StaticBody3D


func setup(d: int, x: float) -> void:
	dist = d
	position = Vector3(x, 0, -float(d))
	_body = RangeLayout.box(self, "paper", Vector3(0, 1.0, 0), Vector3(0.62, HEIGHT, 0.004), "paper", 0.004, Color(0.9, 0.88, 0.8))
	for z in ["head", "thorax", "stomach"]:
		var row: Array = HitboxRig.SHAPES[z]
		var r := MeshInstance3D.new()
		var q := QuadMesh.new()
		var sz: Vector2 = Vector2(0.24, 0.24) if row[1] is float else Vector2((row[1] as Vector3).x, (row[1] as Vector3).y)
		q.size = sz
		r.mesh = q
		r.material_override = RangeLayout.colour(Color(0.2, 0.2, 0.22) if z != "thorax" else Color(0.3, 0.3, 0.34))
		r.position = Vector3((row[0] as Vector3).x, (row[0] as Vector3).y - 1.0 + 0.0, 0.0035)
		r.scale = Vector3(0.9, 0.9, 1)
		_body.add_child(r)


func contains(p: Vector3) -> bool:
	var l := _body.to_local(p)
	return absf(l.x) <= 0.34 and absf(l.y) <= HEIGHT * 0.5 + 0.03 and absf(l.z) < 0.1


func zone_at(p: Vector3) -> String:
	var y := p.y - global_position.y
	var best := "outside"
	var bd := 0.0
	for z in ["head", "thorax", "stomach"]:
		var row: Array = HitboxRig.SHAPES[z]
		var c: Vector3 = row[0]
		var d := Vector2(p.x - global_position.x - c.x, y - c.y).length()
		var lim: float = row[1] if row[1] is float else maxf((row[1] as Vector3).x, (row[1] as Vector3).y) * 0.6
		if d <= lim and (best == "outside" or d < bd):
			best = z
			bd = d
	return best


func add_mark(p: Vector3) -> String:
	var z := zone_at(p)
	zone_hits[z] = zone_hits.get(z, 0) + 1
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	m.mesh = q
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.9, 0.2, 0.1) if z != "outside" else Color(0.1, 0.1, 0.1)
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mt
	add_child(m)
	m.global_position = p + Vector3(0, 0, 0.006)
	marks.append(m)
	return z


func reset() -> void:
	for m in marks:
		m.queue_free()
	marks.clear()
	zone_hits.clear()
