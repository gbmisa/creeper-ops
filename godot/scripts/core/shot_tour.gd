class_name ShotTour
## --tour=PATH / --tour-orbit=id,N: many framed screenshots from one launch.
## Tour file: one shot per line, "#" comments and blank lines ignored:
##   out=/abs/a.png look=40,74,22,0.9 wait=1.5
##   out=/abs/b.png look=88,30,14 wait=0.5 select=cannon
##   out=/abs/c.png fps=60,62,yaw=1.2,pitch=-0.2 wait=1.0
##   out=/abs/d.png gallery=anim:wyvern clip=attack t=0.5
## Level setup comes from the normal flags (--demo, --sim=N, --level=N, ...) and
## runs once. Then each line runs in order: frame the shot, wait `wait` seconds
## of game time (default 1.0), wait for a drawn frame, save the PNG, print
## "[tour] saved PATH". Quits after the last line. Bad lines print
## "[tour] skip LINE: reason" and the tour goes on.

const KNOWN_KEYS := ["out", "look", "fps", "select", "gallery", "clip", "t", "wait"]
# Flattened pad for gallery= lines. Kept clear of the --gallery=anim strip
# (CreatureGallery lays out z 82..91), so the tour's model never overlaps it.
const GALLERY_PAD := Vector2i(43, 74)
const GALLERY_PAD_R := 4
const ORBIT_WAIT := 0.5  # game seconds between orbit shots

static var _prev_gallery: Node3D = null
static var _reframe_g = null  # game object while a gallery shot is tracked
static var _reframe_node: Node3D = null  # gallery model being re-aimed at


## Parse tour text into shot dicts. Each dict has "line", "wait", "out" and the
## keys from its line; parse problems land in "error" (the runner skips those).
static func parse_text(text: String) -> Array:
	var shots: Array = []
	for raw in text.split("\n"):
		var s := raw.strip_edges()
		if s.is_empty() or s.begins_with("#"):
			continue
		var shot := { "line": s, "wait": 1.0, "out": "", "error": "" }
		for tok in s.split(" ", false):
			var kv := tok.split("=", true, 1)
			if kv.size() != 2:
				shot["error"] = "bad token '%s'" % tok
				break
			var key := kv[0].strip_edges()
			if not key in KNOWN_KEYS:
				shot["error"] = "unknown key '%s'" % key
				break
			shot[key] = kv[1].strip_edges()
		for num_key in ["wait", "t"]:
			if str(shot["error"]) == "" and shot.has(num_key) and not str(shot[num_key]).is_valid_float():
				shot["error"] = "bad %s=" % num_key
		if str(shot["error"]) == "" and str(shot["out"]) == "":
			shot["error"] = "missing out="
		shots.append(shot)
	return shots


static func start_file(g, path: String) -> void:
	if not FileAccess.file_exists(path):
		print("[tour] no tour file: ", path)
		g.get_tree().quit()
		return
	_run(g, parse_text(FileAccess.get_file_as_string(path)))


static func start_orbit(g, spec: String, shot_arg: String) -> void:
	_orbit(g, spec, shot_arg)


static func _run(g, shots: Array) -> void:
	for shot in shots:
		if str(shot["error"]) != "":
			print("[tour] skip %s: %s" % [shot["line"], shot["error"]])
			continue
		var reason := _frame(g, shot)
		if reason != "":
			print("[tour] skip %s: %s" % [shot["line"], reason])
			continue
		await g.get_tree().create_timer(float(shot["wait"])).timeout
		await _draw_sync(g)
		_save(g, str(shot["out"]))
		print("[tour] saved ", shot["out"])
	_untrack_gallery()
	g.get_tree().quit()


## Frame one shot (move cameras, spawn/pose the gallery model). "" or a skip reason.
static func _frame(g, shot: Dictionary) -> String:
	if not shot.has("gallery"):
		_untrack_gallery()  # a later look=/fps= shot must not fight the gallery re-aim
	if shot.has("look") or shot.has("select") or shot.has("gallery"):
		g.flow.set_mode("command")
	if shot.has("look"):
		var xz: PackedStringArray = str(shot["look"]).split(",")
		if xz.size() < 2 or not xz[0].is_valid_int() or not xz[1].is_valid_int():
			return "bad look= coords"
		g.command.cam.focus(g.level.grid.cell_ground(int(xz[0]), int(xz[1])))
		g.command.cam.dist = float(xz[2]) if xz.size() > 2 else 55.0
		if xz.size() > 3:
			g.command.cam.pitch = float(xz[3])
	if shot.has("fps"):
		var r := _apply_fps(g, str(shot["fps"]))
		if r != "":
			return r
	if shot.has("select"):
		var want := str(shot["select"])
		var s: Structure = g.structures.nearest_to(0, 0, func(x): return x.type == want)
		g.command.select_structure(s)
	if shot.has("gallery"):
		return _apply_gallery(g, str(shot["gallery"]), str(shot.get("clip", "idle")), float(shot.get("t", "0.0")))
	return ""


## fps=x,z[,yaw=..,pitch=..]: Operative camera there, standing on the ground.
static func _apply_fps(g, spec: String) -> String:
	var toks := spec.split(",")
	if toks.size() < 2 or not toks[0].is_valid_int() or not toks[1].is_valid_int():
		return "bad fps= coords"
	var yaw := PI
	var pitch := 0.0
	for i in range(2, toks.size()):
		var kv := toks[i].split("=", true, 1)
		if kv.size() != 2:
			return "bad fps= token '%s'" % toks[i]
		match kv[0].strip_edges():
			"yaw":
				yaw = float(kv[1])
			"pitch":
				pitch = float(kv[1])
			_:
				return "unknown fps= token '%s'" % toks[i]
	g.fps.enter(g.surface, Vector2i(int(toks[0]), int(toks[1])), yaw)
	g.fps.controller.pitch = pitch
	g.flow.set_mode("surface")
	return ""


## gallery=anim:<id> with clip=/t=: pose that model's clip at t (0-1, exact frame)
## on a flattened pad and frame its AABB with the command camera.
static func _apply_gallery(g, spec: String, clip: String, t: float) -> String:
	if not spec.begins_with("anim:"):
		return "gallery must be anim:<id>"
	var id := spec.trim_prefix("anim:").strip_edges()
	var info: Dictionary = CreatureGallery._spec(id)
	if info.is_empty():
		return "unknown gallery id '%s'" % id
	var node: Node3D = CreatureAnim.make(id, float(info.scale), info.glow)
	if node == null:
		return "no model for '%s'" % id
	var w: World = g.surface
	var grid: Grid = w.grid
	_flatten_pad(grid, w)
	if is_instance_valid(_prev_gallery):
		_prev_gallery.queue_free()
	_prev_gallery = node
	node.position = grid.cell_ground(GALLERY_PAD.x, GALLERY_PAD.y)
	node.rotation.y = -PI / 2.0 + 0.7  # three-quarter view, like the gallery rows
	w.add_child(node)
	var p := node.get_meta("_anim_player") as AnimationPlayer
	if p == null or not p.has_animation(clip):
		return "no clip '%s' for '%s'" % [clip, id]
	var length := (p.get_animation(clip) as Animation).length
	p.play(clip)
	p.seek(clampf(t, 0.0, 1.0) * length, true)
	p.pause()
	var box := _world_aabb(node)
	if box.size.length() <= 0.01:
		return "empty AABB for '%s'" % id
	_aim_gallery(g, box)
	_track_gallery(g, node)
	return ""


## Aim the command camera at a gallery model's box: the AABB centre (flyers
## hover — never the base), distance fitting the box diagonal.
static func _aim_gallery(g, box: AABB) -> void:
	g.command.cam.focus(box.get_center())
	g.command.cam.dist = clampf(box.size.length() * 2.2, 12.0, 90.0)
	g.command.cam.pitch = 0.55


## Keep re-aiming at the gallery model's live AABB centre every process frame.
## CommandCamera.update lerps target.y back to the terrain height each frame,
## which drags the aim off hovering flyers during the wait before the shot;
## process_frame fires before the camera's _process, so the re-aim wins.
static func _track_gallery(g, node: Node3D) -> void:
	_untrack_gallery()
	_reframe_g = g
	_reframe_node = node
	g.get_tree().process_frame.connect(_reframe_tick)


static func _untrack_gallery() -> void:
	if _reframe_g != null:
		var tree: SceneTree = _reframe_g.get_tree()
		if tree != null and tree.process_frame.is_connected(_reframe_tick):
			tree.process_frame.disconnect(_reframe_tick)
	_reframe_g = null
	_reframe_node = null


static func _reframe_tick() -> void:
	if _reframe_g == null or _reframe_node == null or not is_instance_valid(_reframe_node):
		_untrack_gallery()
		return
	var box := _world_aabb(_reframe_node)
	if box.size.length() > 0.01:
		_aim_gallery(_reframe_g, box)


static func _flatten_pad(grid: Grid, w: World) -> void:
	var level: float = grid.height_at(GALLERY_PAD.x, GALLERY_PAD.y)
	var edits := []
	for z in range(GALLERY_PAD.y - GALLERY_PAD_R, GALLERY_PAD.y + GALLERY_PAD_R + 1):
		for x in range(GALLERY_PAD.x - GALLERY_PAD_R, GALLERY_PAD.x + GALLERY_PAD_R + 1):
			edits.append({ "x": x, "z": z, "height": level })
	TerrainEdit.apply(w, edits)


static func _world_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var xform := _xform_to(mi as Node3D, n)
		var b: AABB = xform * (mi as MeshInstance3D).get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box


## World transform of `node` built from local transforms up to `root`, so it holds
## even before `root` enters the tree (global_transform is identity then).
static func _xform_to(node: Node3D, root: Node3D) -> Transform3D:
	var base := root.global_transform if root.is_inside_tree() else root.transform
	if node == root:
		return base
	var t := node.transform
	var p := node.get_parent() as Node3D
	while p != null and p != root:
		t = p.transform * t
		p = p.get_parent() as Node3D
	return base * t


## Wait for a drawn frame. frame_post_draw never fires on some headless GL
## drivers (seen on Xvfb/llvmpipe); the process-frame cap keeps a tour from
## hanging there, at the cost of a possibly one-frame-stale shot.
static func _draw_sync(g) -> void:
	var tree: SceneTree = g.get_tree()
	var drawn := false
	var on_draw := func() -> void: drawn = true
	RenderingServer.frame_post_draw.connect(on_draw)
	var frames := 0
	while not drawn and frames < 120:
		await tree.process_frame
		frames += 1
	if RenderingServer.frame_post_draw.is_connected(on_draw):
		RenderingServer.frame_post_draw.disconnect(on_draw)


static func _save(g, out: String) -> void:
	var dir := out.get_base_dir()
	if dir.begins_with("/") and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	g.get_viewport().get_texture().get_image().save_png(out)


## --tour-orbit=id,N: N shots orbiting the gallery model id at 360/N degree
## steps, named <dir>/<id>_<k>.png; --shot gives the directory.
static func _orbit(g, spec: String, shot_arg: String) -> void:
	var p := spec.split(",")
	var id := p[0].strip_edges()
	var n := 8
	if p.size() > 1:
		if not p[1].is_valid_int() or int(p[1]) < 1:
			print("[tour] skip orbit: bad count in '%s'" % spec)
			g.get_tree().quit()
			return
		n = int(p[1])
	var reason := _frame(g, { "gallery": "anim:" + id, "clip": "idle", "t": "0.0" })
	if reason != "":
		print("[tour] skip orbit %s: %s" % [id, reason])
		g.get_tree().quit()
		return
	var dir := shot_arg
	if dir.ends_with(".png"):
		dir = dir.get_base_dir()
	if dir.is_empty():
		dir = "/tmp/tour_orbit"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	for k in n:
		g.command.cam.yaw = TAU * float(k) / float(n)
		g.command.cam.focus(g.command.cam.target)  # re-apply after the yaw change
		await g.get_tree().create_timer(ORBIT_WAIT).timeout
		await _draw_sync(g)
		var out := "%s/%s_%d.png" % [dir, id, k]
		_save(g, out)
		print("[tour] saved ", out)
	_untrack_gallery()
	g.get_tree().quit()
