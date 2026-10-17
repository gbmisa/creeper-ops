class_name ArmTwist
## Viewmodel arms: the rig has no forearm twist bones, so a hand roll could only twist the skin at the elbow and the
## wrist, and linear-blend skinning pinches a ring where two bones differ by a large roll. build() adds two twist
## bones per forearm at runtime and moves the forearm skin's lowerarm weight onto them along the forearm's length;
## FpArms then spreads the roll over four rings (elbow, mid-forearm x2, wrist) instead of two.
## Only the viewmodel's own body.glb copy is changed (bots and the player body keep the asset as it is).

const AT := [0.5, 1.0]  # twist bones along the forearm (0 = elbow, 1 = wrist)
const SHARE := [0.15, 0.45, 0.75]  # share of the hand's roll on the lowerarm, twist 1, twist 2 (hand = all of it)


## Adds the bones, re-skins `mi` (the Arms mesh). Returns {side: [twist bone ids]}.
static func build(skel: Skeleton3D, mi: MeshInstance3D) -> Dictionary:
	var out := {}
	var skin := mi.skin.duplicate() as Skin
	var split := {}  # lowerarm bind -> [elbow (skeleton space), forearm vector, [bind per node: lowerarm, twist..]]
	for side in ["l", "r"]:
		var lo := skel.find_bone("lowerarm_" + side)
		var wrist: Vector3 = skel.get_bone_rest(skel.find_bone("hand_" + side)).origin  # (0, len, 0) in lowerarm space
		var nodes := [_bind(skin, "lowerarm_" + side)]
		var ids := []
		for k in AT.size():
			var b := skel.add_bone("lowerarm_twist_%02d_%s" % [k + 1, side])
			skel.set_bone_parent(b, lo)
			skel.set_bone_rest(b, Transform3D(Basis.IDENTITY, wrist * float(AT[k])))
			skel.reset_bone_pose(b)
			skin.add_named_bind(skel.get_bone_name(b), skel.get_bone_global_rest(b).affine_inverse())
			nodes.append(skin.get_bind_count() - 1)
			ids.append(b)
		var e := skel.get_bone_global_rest(lo)
		split[nodes[0]] = [e.origin, e.basis * wrist, nodes]
		out[side] = ids
	var old := mi.mesh
	var mesh := ArrayMesh.new()
	for s in old.get_surface_count():
		var arr := old.surface_get_arrays(s)
		_reweight(arr, split)
		mesh.add_surface_from_arrays(old.surface_get_primitive_type(s), arr)
		mesh.surface_set_material(s, old.surface_get_material(s))
	mi.mesh = mesh
	mi.skin = skin
	return out


static func _bind(skin: Skin, name: String) -> int:
	for i in skin.get_bind_count():
		if skin.get_bind_name(i) == name:
			return i
	return -1


## Each vertex's lowerarm weight is shared between the two forearm nodes around it (hat functions over 0, AT[0], AT[1]
## by its place along the forearm). The second share needs a free slot (weight 0), else the nearer node takes it all.
static func _reweight(arr: Array, split: Dictionary) -> void:
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var k: int = bones.size() / verts.size()
	var at := [0.0] + AT
	for v in verts.size():
		for j in k:
			var i := v * k + j
			if weights[i] <= 0.0 or not split.has(bones[i]):
				continue
			var sp: Array = split[bones[i]]
			var fv: Vector3 = sp[1]
			var t := clampf((verts[v] - (sp[0] as Vector3)).dot(fv) / fv.length_squared(), 0.0, 1.0)
			var n := 0
			while n < at.size() - 2 and t > at[n + 1]:
				n += 1
			var u := (t - float(at[n])) / (float(at[n + 1]) - float(at[n]))
			var w := weights[i]
			var free := -1
			for q in k:
				if weights[v * k + q] <= 0.0:
					free = v * k + q
			if free < 0 or u <= 0.0 or u >= 1.0:
				bones[i] = sp[2][n + (1 if u >= 0.5 else 0)]
				continue
			bones[i] = sp[2][n]
			weights[i] = w * (1.0 - u)
			bones[free] = sp[2][n + 1]
			weights[free] = w * u
	arr[Mesh.ARRAY_BONES] = bones
	arr[Mesh.ARRAY_WEIGHTS] = weights
