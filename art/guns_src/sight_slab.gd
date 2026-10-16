extends SceneTree
## Rear-view ortho render of one z slab of a gun (gun space, as TacticalViewmodel loads it), to measure sight points.
## xvfb-run -a godot --path godot --rendering-driver opengl3 -s ../art/guns_src/sight_slab.gd -- OUTDIR id:z0:z1:tag ...
## z0 > z1 in metres (+Z is the butt). Image: 4000 px/m, 1000 px square, centre x 0, y CY. Prints "@@ tag file".
const PPM := 4000.0
const CY := 0.10
var out := ""
var queue := []
var vp: SubViewport
var cam: Camera3D
var holder: Node3D
var mat: StandardMaterial3D
var cur = null
var wait := 0


func _initialize():
	var a := OS.get_cmdline_user_args()
	out = a[0]
	for s in a.slice(1):
		queue.append(s.split(":"))
	vp = SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1000, 1000)
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color.WHITE
	vp.add_child(env)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = 1000.0 / PPM
	vp.add_child(cam)
	mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0, 1)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	holder = Node3D.new()
	vp.add_child(holder)


func _process(_d):
	if cur != null:
		wait += 1
		if wait < 4:
			return false
		var f := "%s/%s.png" % [out, cur[3]]
		vp.get_texture().get_image().save_png(f)
		print("@@ %s %s" % [cur[3], f])
		cur = null
	if queue.is_empty():
		quit()
		return true
	cur = queue.pop_front()
	wait = 0
	for c in holder.get_children():
		c.free()
	var def := WeaponDefs.of(cur[0])
	var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
	holder.add_child(glb)
	if def.get("flip", false):
		glb.rotation.y = PI
	for m in glb.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
	var z0 := float(cur[1])
	var z1 := float(cur[2])
	cam.transform = Transform3D(Basis.IDENTITY, Vector3(0, CY, 2.0))  # looks down -Z from behind
	cam.near = 2.0 - z0
	cam.far = 2.0 - z1
	return false
