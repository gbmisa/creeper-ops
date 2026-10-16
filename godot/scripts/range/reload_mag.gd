class_name ReloadMag
## FB-R: makes the magazine its own node so a reload can take it out of the gun. Triangles whose `Magazine` bone
## weight is >= 0.5 move from the skinned gun mesh into a static `Mag` MeshInstance3D, a child of the Skeleton3D
## with an identity transform (at rest a skinned vertex renders at skeleton * vertex, so the mag stays put). The gun
## gets a new ArrayMesh for this instance only, with custom_aabb = the original AABB, so size and sight code read the
## same numbers. The glb on disk and every other instance of it are untouched.

const BONE := "Magazine"
const MIN_W := 0.5


## The new Mag node, or null if the glb has no skinned mesh weighted to a `Magazine` bone.
static func split(glb: Node) -> MeshInstance3D:
	for node in glb.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sk := mi.get_parent() as Skeleton3D
		if sk == null or mi.skin == null or not mi.mesh is ArrayMesh:
			continue
		var bind := -1
		for i in mi.skin.get_bind_count():
			if mi.skin.get_bind_name(i) == BONE or (mi.skin.get_bind_bone(i) >= 0 and sk.get_bone_name(mi.skin.get_bind_bone(i)) == BONE):
				bind = i
		if bind < 0:
			continue
		var mag := _cut(mi, bind)
		if mag == null:
			continue
		mag.name = "Mag"
		mag.cast_shadow = mi.cast_shadow
		sk.add_child(mag)
		return mag
	return null


static func _cut(mi: MeshInstance3D, bind: int) -> MeshInstance3D:
	var src := mi.mesh as ArrayMesh
	var gun := ArrayMesh.new()
	var mag := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var n: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(n))
		var on_mag := _mag_verts(arr, n, bind)
		var keep := PackedInt32Array()
		var cut := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var m := on_mag[idx[t]] and on_mag[idx[t + 1]] and on_mag[idx[t + 2]]
			(cut if m else keep).append_array([idx[t], idx[t + 1], idx[t + 2]])
		var flags := src.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		var mat := src.surface_get_material(s)
		if not keep.is_empty():
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
