class_name SmokeCastles2bStone
## Stage 21b P1: castle stonework — ashlar slab shader + beams, parapet merlons on
## open-air roof edges, stone arches over interior doors, wall trim. Fresh level
## builds only; touches no running-game state.


static func run(_g) -> void:
	for lvl in [Level01.build(), Level02.build()]:
		var grid: Grid = lvl.grid
		for row in lvl.castles.filter(func(c): return c.layout.get("plan", "") == "concentric"):
			_one(grid, row.id, row.layout)


static func _one(grid: Grid, id: String, lay: Dictionary) -> void:
	var doors_ok := true
	for tw in lay.towers:
		var ds: Array = tw.get("doors", [])
		if ds.is_empty():
			doors_ok = false
			continue
		var cells := {}
		for c in tw.cells:
			cells[c] = true
		if ds.any(func(d): return not cells.has(d)):
			doors_ok = false
	SmokeTest._check("castles2b %s: tower dicts record their door cells" % id, doors_ok)
	SmokeTest._check("castles2b %s: keep door cells recorded" % id,
		not (lay.get("keep", {}) as Dictionary).get("door", []).is_empty())
	var root := Node3D.new()
	SmokeTest._check("castles2b %s: parapet merlons on open-air roof edges" % id,
		CastleStonework.parapets(root, grid, lay) > 0)
	SmokeTest._check("castles2b %s: stone arches over interior doors" % id,
		CastleStonework.door_arches(root, grid, lay) > 0)
	root.free()
	# Slab material + beams: build the interiors on a scratch root.
	var r2 := Node3D.new()
	var banners: Array = []
	var nodes: Array = CastleInteriorMeshes.build(r2, grid, lay, banners)
	var shader_ok := true
	var mesh_n := 0
	for n in nodes:
		for mi in _find_meshes(n):
			mesh_n += 1
			if mi.mesh != null and mi.mesh.get_surface_count() == 2 \
					and not (mi.get_surface_override_material(0) is ShaderMaterial):
				shader_ok = false
	SmokeTest._check("castles2b %s: slabs use the ashlar ShaderMaterial" % id,
		shader_ok and not nodes.is_empty())
	SmokeTest._check("castles2b %s: slabs carry beams under them" % id, mesh_n > nodes.size())
	r2.free()
	# Wall trim on a scratch segment node (no World needed).
	var a := Node3D.new()
	var seg: Dictionary = lay.segments[0]
	CastleStonework.wall_trim(a, grid, lay.segments.filter(func(s): return s.ring == "inner")[0],
		lay, Vector3(0, 0, -1))
	var inner_n := a.get_child_count()
	CastleStonework.wall_trim(a, grid, seg, lay, Vector3(0, 0, -1))
	SmokeTest._check("castles2b %s: wall trim builds (inner ring richer)" % id,
		a.get_child_count() > 0 and inner_n > 0)
	a.free()


static func _find_meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D:
		out.append(n)
	for ch in n.get_children():
		out.append_array(_find_meshes(ch))
	return out
