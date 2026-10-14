class_name AttachmentRig
extends Node3D
## The fitted attachments of the held gun as nodes under the viewmodel (gun space, muzzle -Z): sight frame with a glass
## quad carrying the 1x reticle, muzzle device, grip, laser with its beam, extended mag. Uses attachments/<id>.glb when
## present, else placeholder boxes sized from AttachmentDefs. Mount points come from AttachmentMounts.

const LASER_RANGE := 60.0
const FRAME_T := 0.005
static var _tex := {}

var gun: Gun
var glass: MeshInstance3D
var beam: MeshInstance3D
var _beam_from := Vector3.ZERO
var _ver := -1


func build(g: Gun, half: float) -> void:
	gun = g
	_ver = g.fit_ver
	for c in get_children():
		c.queue_free()
		remove_child(c)
	glass = null
	beam = null
	for slot in g.fit:
		var id: String = g.fit[slot]
		var at := AttachmentMounts.mount(g.def, slot, half)
		var part := _load(id)
		if part == null:
			part = _placeholder(id, slot)
		part.position = at
		add_child(part)
		if slot == "sight" and AttachmentDefs.ROWS[id]["zoom"] <= 1.0:
			_add_glass(part, id)
		if id == "laser":
			_add_beam(at)


func stale() -> bool:
	return gun != null and gun.fit_ver != _ver


static func _load(id: String) -> Node3D:
	var path := "res://assets/models/attachments/%s.glb" % id
	if ResourceLoader.exists(path):
		return (load(path) as PackedScene).instantiate() as Node3D
	return null


static func _box(size: Vector3, at: Vector3, col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = at
	m.material_override = _mat(col)
	return m


static func _mat(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.4
	mat.roughness = 0.55
	return mat


## Dark placeholder at the mount: sight = open frame around the window, muzzle = tube forward, under = block down.
static func _placeholder(id: String, slot: String) -> Node3D:
	var r: Dictionary = AttachmentDefs.ROWS[id]
	var n := Node3D.new()
	var dark := Color(0.09, 0.09, 0.1)
	match slot:
		"sight":
			var depth: float = r["depth"]
			var win: float = r["win"]
			var ah: float = r["axis_h"]
			if r["zoom"] > 1.0:  # magnified: a tube along the sight line (the LPVO is open at 1x: the frame)
				var cm := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = win * 0.6
				cyl.bottom_radius = win * 0.6
				cyl.height = depth
				cm.mesh = cyl
				cm.rotation.x = PI * 0.5
				cm.position = Vector3(0, ah, 0)
				cm.material_override = _mat(dark)
				n.add_child(cm)
				n.add_child(_box(Vector3(0.02, ah - win * 0.6, 0.03), Vector3(0, (ah - win * 0.6) * 0.5, 0), dark))
			else:  # open frame so the world shows through the window
				var base_h := ah - win * 0.5
				n.add_child(_box(Vector3(win + 2 * FRAME_T, base_h, depth), Vector3(0, base_h * 0.5, 0), dark))
				for sx in [-1.0, 1.0]:
					n.add_child(_box(Vector3(FRAME_T, win, depth), Vector3(sx * (win * 0.5 + FRAME_T * 0.5), ah, 0), dark))
				n.add_child(_box(Vector3(win + 2 * FRAME_T, FRAME_T, depth), Vector3(0, ah + win * 0.5 + FRAME_T * 0.5, 0), dark))
		"muzzle":
			var len: float = r["len"]
			var gi: float = r["girth"]
			n.add_child(_box(Vector3(gi, gi, len), Vector3(0, 0, -len * 0.5), dark))
		"under":
			n.add_child(_box(Vector3(r["girth"], r["len"], r["girth"] * 1.4), Vector3(0, -r["len"] * 0.5, 0), dark))
		"mag":
			n.add_child(_box(Vector3(r["girth"], r["len"], 0.04), Vector3(0, -r["len"] * 0.5, 0), Color(0.12, 0.12, 0.12)))
	return n


## 1x sights: a small quad in the window, facing the eye, carrying the emissive reticle.
func _add_glass(sight: Node3D, id: String) -> void:
	var r: Dictionary = AttachmentDefs.ROWS[id]
	var q := QuadMesh.new()
	q.size = Vector2.ONE * float(r["win"])
	glass = MeshInstance3D.new()
	glass.mesh = q
	glass.position = Vector3(0, r["axis_h"], float(r["depth"]) * 0.5 - 0.002)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = reticle_tex(r["ret"])
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sight.add_child(glass)


static func reticle_tex(kind: String) -> ImageTexture:
	if _tex.has(kind):
		return _tex[kind]
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red := Color(1.0, 0.12, 0.08, 1.0)
	var c := Vector2(n * 0.5 - 0.5, n * 0.5 - 0.5)
	for y in n:
		for x in n:
			var d := Vector2(x, y).distance_to(c)
			var on := false
			match kind:
				"dot":
					on = d <= 2.6
				"ring":
					on = d <= 1.6 or (absf(d - 20.0) <= 1.8)
				"cross":
					on = d <= 1.6 or (absf(x - c.x) <= 0.8 and d < 26.0 and d > 5.0) or (absf(y - c.y) <= 0.8 and d < 26.0 and d > 5.0)
			if on:
				img.set_pixel(x, y, red)
	_tex[kind] = ImageTexture.create_from_image(img)
	return _tex[kind]


func _add_beam(at: Vector3) -> void:
	beam = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0015
	cm.bottom_radius = 0.0015
	cm.height = 1.0
	cm.radial_segments = 6
	beam.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.1, 0.08)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.1, 0.08)
	mat.emission_energy_multiplier = 3.0
	beam.material_override = mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam_from = at + Vector3(0, 0, -0.06)
	add_child(beam)
	beam.rotation.x = PI * 0.5  # cylinder axis Y -> Z


## Laser beam: from the laser out along the gun to the first world hit (or LASER_RANGE).
func update_beam() -> float:
	if beam == null or not is_inside_tree():
		return 0.0
	var from := global_transform * _beam_from
	var dir := -global_basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * LASER_RANGE, TacticalConfig.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var len := LASER_RANGE if hit.is_empty() else from.distance_to(hit["position"])
	beam.scale = Vector3(1, len, 1)
	beam.position = _beam_from + Vector3(0, 0, -len * 0.5)
	return len
