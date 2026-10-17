class_name GunsmithPreview
extends SubViewportContainer
## F141: live 3D preview of one gun with its fitted parts. Same glb + AttachmentRig placement as the viewmodel
## (TacticalViewmodel._on_switched), in its own World3D. Drag to rotate (the view calls turn()).

var _vp := SubViewport.new()
var _pivot := Node3D.new()
var _rig: AttachmentRig
var _gun: Gun
var yaw := -0.6
var pitch := 0.15
var _dist := 0.8


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 1.0)
	cam.fov = 35.0
	_vp.add_child(cam)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.75)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_energy = 1.4
	_vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, 150, 0)
	fill.light_energy = 0.5
	_vp.add_child(fill)
	_vp.add_child(_pivot)


func _process(_dt: float) -> void:
	_pivot.rotation = Vector3(pitch, yaw, 0)
	if _rig != null and _rig.stale():
		_rig.build(_gun, _half)


var _half := 0.2


## Show `g` (null clears). Rebuilds the model; parts are rebuilt by _process when the gun's fit changes.
func show_gun(g: Gun) -> void:
	for c in _pivot.get_children():
		c.queue_free()
	_rig = null
	_gun = g
	if g == null:
		return
	var def := g.eff_def()
	var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
	var model := Node3D.new()
	model.add_child(glb)
	if def.get("flip", false):
		glb.rotation.y = PI
	_pivot.add_child(model)
	var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_half = mi.get_aabb().size.z * 0.5
	var ctr := mi.get_aabb().get_center()
	model.position = -(glb.transform * ctr)
	_rig = AttachmentRig.new()
	model.add_child(_rig)
	_rig.build(g, _half)
	_dist = clampf(_half * 2.0 / tan(deg_to_rad(35.0) * 0.5) * 0.7, 0.5, 2.5)
	(_vp.get_child(0) as Camera3D).position = Vector3(0, 0, _dist)


func turn(d: Vector2) -> void:
	yaw += d.x * 0.01
	pitch = clampf(pitch + d.y * 0.01, -1.2, 1.2)
