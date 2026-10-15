class_name LookProps
## Places the Hunyuan props (assets/models/props) and a MultiMesh of dead grass, leaves and stones. Visual only.
## Repeats of one prop share a MultiMesh; singles are plain instances. Skipped when headless.

static var _scenes := {}


static func build(parent: Node3D, defs: Array, filter := false) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var root := Node3D.new()
	root.name = "LookProps"
	parent.add_child(root)
	for d in defs:
		var pos := Vector3(d[1], 0.0, d[2])
		if filter and not _free(pos, d[0]):
			continue
		var sc := _scene(d[0])
		if sc == null:
			continue
		var n: Node3D = sc.instantiate()
		n.position = pos
		n.rotation_degrees.y = d[3]
		n.scale = Vector3.ONE * float(d[4])
		_tint(n, LookPropDefs.TINT.get(d[0], Color.WHITE))
		root.add_child(n)


static func _scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		var p := "%s%s.glb" % [LookPropDefs.DIR, id]
		_scenes[id] = load(p) if ResourceLoader.exists(p) else null
	return _scenes[id]


static func _tint(n: Node, col: Color) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			var m: Material = c.get_active_material(0)
			if m is StandardMaterial3D:
				var mm: StandardMaterial3D = m.duplicate()
				mm.albedo_color *= col
				mm.roughness = 0.85
				mm.metallic = 0.0
				c.material_override = mm
		_tint(c, col)


## True when a prop footprint (~1.5 m) clears every building, cover piece, route point and the spawn.
static func _free(p: Vector3, id: String) -> bool:
	var rad := 3.0 if id in ["radar", "fueltank", "wreck", "camonet", "lightmast"] else 1.2
	for b in SkirmishData.BUILDINGS.values():
		var r: Array = b["rect"]
		if p.x > r[0] - rad and p.x < r[2] + rad and p.z > r[1] - rad and p.z < r[3] + rad:
			return false
	for c in SkirmishData.COVER:
		if absf(p.x - c[1]) < c[3] * 0.5 + rad and absf(p.z - c[2]) < c[4] * 0.5 + rad:
			return false
	for e in SkirmishData.ENEMIES:
		for q in e["route"]:
			if Vector2(q[0], q[1]).distance_to(Vector2(p.x, p.z)) < rad + 1.5:
				return false
	var t: Dictionary = SkirmishData.TOWER
	var tr: Array = t["rect"]
	if p.x > tr[0] - rad and p.x < tr[2] + rad and p.z > tr[1] - rad and p.z < tr[3] + rad:
		return false
	var lx: Array = t["lane_x"]
	if p.x > lx[0] - rad and p.x < lx[1] + rad and p.z > tr[3] and p.z < t["ramp_z0"] + rad:
		return false
	if p.distance_to(SkirmishData.SPAWNS[0]) < 4.0 or p.distance_to(SkirmishData.SPAWNS[1]) < 4.0 or p.distance_to(SkirmishData.SPAWNS[2]) < 4.0:
		return false
	for e in SkirmishData.EXTRACTS:
		if p.distance_to(e["pos"]) < 6.0:
			return false
	return true


## Fit a prop's bounding box to `size` (bottom centre at `pos`) and add it to `parent`. Used to re-skin cover boxes: the
## collider stays the box, only the look changes. Returns null when the model is missing.
static func fit(parent: Node3D, id: String, pos: Vector3, size: Vector3, yaw := 0.0) -> Node3D:
	var sc := _scene(id)
	if sc == null:
		return null
	var n: Node3D = sc.instantiate()
	var bb := _aabb(n)
	if bb.size.x < 0.01 or bb.size.y < 0.01 or bb.size.z < 0.01:
		n.free()
		return null
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = yaw
	n.scale = Vector3(size.x / bb.size.x, size.y / bb.size.y, size.z / bb.size.z)
	n.position = Vector3(-(bb.position.x + bb.size.x * 0.5) * n.scale.x, -bb.position.y * n.scale.y, -(bb.position.z + bb.size.z * 0.5) * n.scale.z)
	holder.add_child(n)
	_tint(n, LookPropDefs.TINT.get(id, Color.WHITE))
	parent.add_child(holder)
	return holder


static func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		var bb := mi.transform * mi.get_aabb() if mi.get_parent() == n else mi.get_aabb()
		out = bb if first else out.merge(bb)
		first = false
	return out
