class_name TownLayout
## MAP-3 Town extras on top of SkirmishLayout: free-standing walls (courtyards, yard, FOB, ditch, cemetery) and flat
## road / square paving. Walls are world-layer boxes via SkirmishParts.wall; roads are visual only (no collider).


static func build_extras(parent: Node3D, data: GDScript) -> void:
	var holder := Node3D.new()
	holder.name = "TownWalls"
	parent.add_child(holder)
	for w in data.WALLS:
		var st: Array = data.WALL_STYLE[w[7]]
		SkirmishParts.wall(holder, w[0], w[1], w[2], w[3], 0.0, w[4], w[5], w[6], st[0], st[1])
	var roads := Node3D.new()
	roads.name = "Roads"
	parent.add_child(roads)
	var mat := RangeLayout.colour(data.ROAD_COL)
	for r in data.ROADS:
		var mi := MeshInstance3D.new()
		var qm := BoxMesh.new()
		qm.size = Vector3(r[2] - r[0], 0.04, r[3] - r[1])
		mi.mesh = qm
		mi.material_override = mat
		mi.position = Vector3((r[0] + r[2]) * 0.5, 0.02, (r[1] + r[3]) * 0.5)
		roads.add_child(mi)
	for l in data.LAMPS:
		_lamp(parent, l[0], l[1])


## Street lamp: dark post, emissive head, warm omni (no shadows, like the interior fixtures). Visual only.
static func _lamp(parent: Node3D, x: float, z: float) -> void:
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.07
	cm.bottom_radius = 0.1
	cm.height = 4.0
	post.mesh = cm
	post.material_override = RangeLayout.colour(Color(0.15, 0.15, 0.16))
	post.position = Vector3(x, 2.0, z)
	parent.add_child(post)
	var head := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.12, 0.5)
	head.mesh = bm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.9, 0.85, 0.7)
	hm.emission_enabled = true
	hm.emission = Color(1.0, 0.82, 0.55)
	hm.emission_energy_multiplier = 2.0
	head.material_override = hm
	head.position = Vector3(x, 4.0, z)
	parent.add_child(head)
	var l := OmniLight3D.new()
	l.position = Vector3(x, 3.8, z)
	l.omni_range = 14.0
	l.light_energy = 1.1
	l.light_color = Color(1.0, 0.82, 0.58)
	l.shadow_enabled = false
	parent.add_child(l)
