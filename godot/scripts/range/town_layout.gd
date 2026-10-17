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
