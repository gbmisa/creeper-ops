extends SceneTree
## Ortho silhouettes of each gun in gun space (as TacticalViewmodel loads it). 2000 px per metre, centre y = 0.05.
const PPM := 2000.0
var out := ""
var ids := []
var step := 0
var vp: SubViewport
var cam: Camera3D
var holder: Node3D
var queue := []

func _initialize():
	var a := OS.get_cmdline_user_args()
	out = a[0]; ids = a.slice(1)
	vp = SubViewport.new(); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color.WHITE
	vp.add_child(env)
	cam = Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; vp.add_child(cam)
	var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0, 1); mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for id in ids:
		var def := WeaponDefs.of(id)
		var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
		var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var half := mi.get_aabb().size.z * 0.5
		queue.append([id, def, half, "side"]); queue.append([id, def, half, "rear"]); queue.append([id, def, half, "top"])
		glb.free()
	holder = Node3D.new(); vp.add_child(holder)
	set_meta("mat", mat)

var wait := 0
var cur
func _process(_d):
	if cur != null:
		wait += 1
		if wait < 4: return false
		var img := vp.get_texture().get_image()
		img.save_png("%s/%s_%s.png" % [out, cur[0], cur[3]])
		print("@@ ", cur[0], " ", cur[3], " half=%.3f iron_y=%.3f" % [cur[2], AttachmentMounts.iron_y(cur[1])])
		cur = null
	if queue.is_empty():
		quit(); return true
	cur = queue.pop_front(); wait = 0
	for c in holder.get_children(): c.free()
	var def: Dictionary = cur[1]; var half: float = cur[2]
	var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
	holder.add_child(glb)
	if def.get("flip", false): glb.rotation.y = PI
	for m in glb.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = get_meta("mat")
	if cur[3] == "side":
		vp.size = Vector2i(int(half * 2.0 * PPM) + 100, 600)
		cam.size = 600.0 / PPM  # keep_aspect height
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.transform = Transform3D(Basis.looking_at(Vector3(-1, 0, 0)), Vector3(2, 0.05, 0))
		cam.near = 0.01; cam.far = 10.0
	elif cur[3] == "top":
		vp.size = Vector2i(int(half * 2.0 * PPM) + 100, 600)
		cam.size = 600.0 / PPM
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.transform = Transform3D(Basis.looking_at(Vector3(0, -1, 0), Vector3(-1, 0, 0)), Vector3(0, 2, 0.05))
		cam.near = 0.01; cam.far = 10.0
	else:
		vp.size = Vector2i(600, 600)
		cam.size = 600.0 / PPM
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0, -1)), Vector3(0, 0.05, 2))
		cam.near = 2.0 + half * 0.25  # cut away the rear quarter-plus: shows the front half (front post over the barrel)
		cam.far = 10.0
	return false
