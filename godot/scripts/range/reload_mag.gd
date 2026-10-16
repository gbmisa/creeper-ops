class_name ReloadMag
## FB-R: makes the magazine its own node so a reload can take it out of the gun. Triangles whose `Magazine` bone
## weight is >= MIN_W move from the skinned gun mesh into a static `Mag` MeshInstance3D, a child of the Skeleton3D
## at the bone's rest * bind pose (where the skinned vertex renders at rest, so the mag stays put; the importer
## leaves the mesh in gun-model space, so that pose is not the identity). Guns without that bone (single static
## mesh) name a region instead (ReloadRigs `mag_box`, gun-model space): triangles wholly inside it move into the
## part, which sits beside the mesh with the mesh's transform; `mag_body` adds a box hidden inside the grip
## (the glb has no mag body there). `cut_box` also makes other moving parts (a slide). The gun gets a new
## ArrayMesh for this instance only, with custom_aabb = the original AABB, so size and sight code read the same
## numbers. The glb on disk and every other instance of it are untouched.

const BONE := "Magazine"
const MIN_W := 0.45  # m1911 mag: 0.5 Control + 0.5 Magazine, stored as 0.49999


## The new Mag node, or null if nothing could be split out.
static func split(glb: Node, rig: Dictionary = {}) -> MeshInstance3D:
	if rig.has("mag_box"):
		var m := cut_box(glb, rig["mag_box"], "Mag")
		if m != null and rig.has("mag_body"):
			_add_body(glb, m, rig["mag_body"])
		return m
	for node in glb.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sk := mi.get_parent() as Skeleton3D
		if sk == null or mi.skin == null or not mi.mesh is ArrayMesh:
			continue
		var bind := -1
		var bone := -1
		for i in mi.skin.get_bind_count():
			var b := mi.skin.get_bind_bone(i)
			if b < 0:
				b = sk.find_bone(mi.skin.get_bind_name(i))
			if b >= 0 and sk.get_bone_name(b) == BONE:
				bind = i
				bone = b
		if bind < 0:
			continue
		var mag := _cut(mi, func(arr: Array, n: int) -> Array[bool]: return _mag_verts(arr, n, bind))
		if mag == null:
			continue
		mag.name = "Mag"
		mag.transform = sk.get_bone_global_rest(bone) * mi.skin.get_bind_pose(bind)
		mag.cast_shadow = mi.cast_shadow
		sk.add_child(mag)
		return mag
	return null


## Moves the triangles of the first static mesh that lie wholly inside `box` (gun-model space: the glb's parent)
## into a new node beside that mesh. Null if none do.
static func cut_box(glb: Node, box: AABB, part_name: String) -> MeshInstance3D:
	for node in glb.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.skin != null or not mi.mesh is ArrayMesh or mi.name == "Mag":
			continue
		var k := to_gun(mi, glb)
		var part := _cut(mi, func(arr: Array, n: int) -> Array[bool]: return _box_verts(arr, n, k, box))
		if part == null:
			continue
		part.name = part_name
		part.transform = mi.transform
		part.cast_shadow = mi.cast_shadow
		mi.get_parent().add_child(part)
		return part
	return null


## Node space -> gun-model space (the glb's parent).
static func to_gun(n: Node, glb: Node) -> Transform3D:
	var k := Transform3D.IDENTITY
	while n != glb.get_parent():
		k = (n as Node3D).transform * k
		n = n.get_parent()
	return k


## body = [centre, size, rotation (rad)] in gun-model space; material of the part's first surface.
static func _add_body(glb: Node, mag: MeshInstance3D, body: Array) -> void:
	var box := BoxMesh.new()
	box.size = body[1]
	box.material = mag.mesh.surface_get_material(0)
	var b := MeshInstance3D.new()
	b.name = "Body"
	b.mesh = box
	b.transform = to_gun(mag, glb).affine_inverse() * Transform3D(Basis.from_euler(body[2]), body[0])
	mag.add_child(b)


static func _cut(mi: MeshInstance3D, select: Callable) -> MeshInstance3D:
	var src := mi.mesh as ArrayMesh
	var gun := ArrayMesh.new()
	var mag := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var n: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(n))
		var on_mag: Array[bool] = select.call(arr, n)
		var keep := PackedInt32Array()
		var cut := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var m := on_mag[idx[t]] and on_mag[idx[t + 1]] and on_mag[idx[t + 2]]
			(cut if m else keep).append_array([idx[t], idx[t + 1], idx[t + 2]])
		var flags := src.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		var mat := src.surface_get_material(s)
		if keep.is_empty():  # all mag: keep the surface (same indices, same AABB) as one degenerate triangle
			keep = PackedInt32Array([0, 0, 0])
		arr[Mesh.ARRAY_INDEX] = keep
		gun.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		gun.surface_set_material(gun.get_surface_count() - 1, mat)
		if not cut.is_empty():
			arr[Mesh.ARRAY_INDEX] = cut
			arr[Mesh.ARRAY_BONES] = null
			arr[Mesh.ARRAY_WEIGHTS] = null
			mag.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mag.surface_set_material(mag.get_surface_count() - 1, mat)
	if mag.get_surface_count() == 0:
		return null
	gun.custom_aabb = src.get_aabb()
	mi.mesh = gun
	var out := MeshInstance3D.new()
	out.mesh = mag
	return out


static func _mag_verts(arr: Array, n: int, bind: int) -> Array[bool]:
	var out: Array[bool] = []
	out.resize(n)
	out.fill(false)
	var bones = arr[Mesh.ARRAY_BONES]
	var w = arr[Mesh.ARRAY_WEIGHTS]
	if bones == null or w == null or n == 0:
		return out
	var per: int = bones.size() / n
	for i in n:
		for k in per:
			if int(bones[i * per + k]) == bind and float(w[i * per + k]) >= MIN_W:
				out[i] = true
	return out


static func _box_verts(arr: Array, n: int, k: Transform3D, box: AABB) -> Array[bool]:
	var out: Array[bool] = []
	out.resize(n)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in n:
		out[i] = box.has_point(k * v[i])
	return out
