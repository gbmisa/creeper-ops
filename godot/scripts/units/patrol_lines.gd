class_name PatrolLines
extends MeshInstance3D
## Thin lines over the ground: the patrol routes of selected units plus the route being laid
## out (`pending`). Rebuilt every frame only while something is shown.

const MAX_ROUTES := 8

var mgr: UnitManager
var pending: Array[Vector2] = []
var _im := ImmediateMesh.new()


func _init() -> void:
	name = "PatrolLines"
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("5fe6ff")
	material_override = m


func _process(_dt: float) -> void:
	_im.clear_surfaces()
	if mgr == null:
		return
	var routes: Array = []
	var seen := {}
	for u in mgr.selected:
		if not u.patrol.is_empty() and not seen.has(u.patrol):
			seen[u.patrol] = true
			routes.append(u.patrol)
	if routes.size() > MAX_ROUTES:
		routes.resize(MAX_ROUTES)
	if pending.size() >= 1:
		routes.append(pending)
	if routes.is_empty():
		return
	_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for r in routes:
		var loop: bool = not is_same(r, pending) and r.size() > 2
		for i in r.size():
			_tick(r[i])
			if i + 1 < r.size():
				_seg(r[i], r[i + 1])
		if loop:
			_seg(r.back(), r[0])
	_im.surface_end()


func _tick(p: Vector2) -> void:
	var y := _y(p)
	_im.surface_add_vertex(Vector3(p.x, y, p.y))
	_im.surface_add_vertex(Vector3(p.x, y + 1.6, p.y))


func _seg(a: Vector2, b: Vector2) -> void:
	var n := maxi(1, ceili(a.distance_to(b) / Config.PATROL_LINE_STEP))
	for i in n:
		for t in [float(i) / n, float(i + 1) / n]:
			var p: Vector2 = a.lerp(b, t)
			_im.surface_add_vertex(Vector3(p.x, _y(p) + 0.35, p.y))


func _y(p: Vector2) -> float:
	return mgr.world.grid.stand_y(p.x, p.y, Grid.Faction.PLAYER)
