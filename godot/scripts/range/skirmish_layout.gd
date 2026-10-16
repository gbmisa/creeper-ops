class_name SkirmishLayout
extends Node3D
## The Skirmish map: 120 x 120 m walled compound with five enterable buildings (the hotel has a second floor
## reached by a ramp), a watchtower, vehicles / crates / barriers as cover and a whole-map navmesh.
## Duck-types KillHouse for ScavBot: `covers` and `patrol` are world positions.

var covers: Array[Vector3] = []
var patrol: Array[Vector3] = []
var loot_crates: Array[Dictionary] = []   # {pos, loot: Array, taken}
var region: NavigationRegion3D


func _init() -> void:
	name = "Skirmish"


func build() -> void:
	var H := SkirmishData.HALF
	RangeLayout.box(self, "ground", Vector3(0, -0.5, 0), Vector3(H * 2, 1.0, H * 2), "dirt_berm", 1.0, Color(0.26, 0.3, 0.16))
	for s in [-1.0, 1.0]:
		RangeLayout.box(self, "perimeter", Vector3(0, SkirmishData.WALL_H * 0.5, s * (H + 0.5)), Vector3(H * 2 + 2, SkirmishData.WALL_H, 1.0), "concrete", 1.0, SkirmishData.CONCRETE)
		RangeLayout.box(self, "perimeter", Vector3(s * (H + 0.5), SkirmishData.WALL_H * 0.5, 0), Vector3(1.0, SkirmishData.WALL_H, H * 2), "concrete", 1.0, SkirmishData.CONCRETE)
	for id in SkirmishData.BUILDINGS:
		_building(SkirmishData.BUILDINGS[id], id)
	_tower()
	for c in SkirmishData.COVER:
		_cover(c)
	for l in SkirmishData.LOOT:
		_loot(l)
	_extract_marker()
	for p in [Vector2(0, 40), Vector2(-20, 20), Vector2(20, 20), Vector2(0, 0), Vector2(-40, 0), Vector2(40, -10), Vector2(0, -30)]:
		patrol.append(Vector3(p.x, 0, p.y))
	LookKestrel.build(self)
	LookKestrel.gate_collider(self)
	LookScatter.tree_colliders(self)


func _building(d: Dictionary, id: String) -> void:
	var r := Rect2(d["rect"][0], d["rect"][1], d["rect"][2] - d["rect"][0], d["rect"][3] - d["rect"][1])
	var h: float = d["h"]
	SkirmishParts.building(self, r, 0.0, h, d["open"], d["mat"], d["col"])
	for w in d.get("inner", []):
		SkirmishParts.wall(self, "z" if w[0] == "z" else "x", w[1], w[2] + r.position.y, w[3] + r.position.y, 0.0, h, 0.15, w[4], "plywood", SkirmishData.PLASTER)
	if d["floors"] == 2:
		_second_floor(r, h, d)
	else:
		SkirmishParts.slab(self, Rect2(r.position - Vector2(0.15, 0.15), r.size + Vector2(0.3, 0.3)), h + 0.2, 0.2, "concrete", Color(0.3, 0.3, 0.32))
	_ceiling_light(r.get_center().x, h, r.get_center().y)
	if d["floors"] == 2:
		_ceiling_light(r.get_center().x, h * 2.0, r.get_center().y)


## F26: ceiling light fixture (emissive mesh + OmniLight3D, shadows off) for a building interior.
## Replaces the old bare floating light; `ceil_y` is the ceiling height the fixture hangs from.
func _ceiling_light(x: float, ceil_y: float, z: float) -> void:
	var fix := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 0.12, 0.6)
	fix.mesh = bm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.85, 0.82, 0.7)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.85, 0.6)
	fm.emission_energy_multiplier = 2.0
	fix.material_override = fm
	fix.position = Vector3(x, ceil_y - 0.12, z)
	add_child(fix)
	var l := OmniLight3D.new()
	l.position = Vector3(x, ceil_y - 0.35, z)
	l.omni_range = 11.0
	l.light_energy = 1.2
	l.light_color = Color(1.0, 0.85, 0.65)
	l.shadow_enabled = false
	add_child(l)


## Hotel upper storey: slab with a lane for the ramp along the west wall, walls with windows, a roof.
func _second_floor(r: Rect2, h: float, d: Dictionary) -> void:
	var lane_x := r.position.x + 0.2 + 2.0   # ramp lane is 2 m wide beside the west wall
	var top_z := r.position.y + 6.0          # ramp top edge
	SkirmishParts.slab(self, Rect2(r.position.x, r.position.y, r.size.x, top_z - r.position.y), h, 0.2, "concrete", Color(0.4, 0.4, 0.38))
	SkirmishParts.slab(self, Rect2(lane_x, top_z, r.end.x - lane_x, r.end.y - top_z), h, 0.2, "concrete", Color(0.4, 0.4, 0.38))
	SkirmishParts.ramp(self, Vector3(lane_x - 1.0, 0.0, r.end.y - 1.5), Vector3(lane_x - 1.0, h, top_z), 2.0, Color(0.45, 0.45, 0.42))
	SkirmishParts.building(self, r, h, h, d["open2"], d["mat"], d["col"])
	SkirmishParts.slab(self, Rect2(r.position - Vector2(0.15, 0.15), r.size + Vector2(0.3, 0.3)), h * 2.0 + 0.2, 0.2, "concrete", Color(0.3, 0.3, 0.32))


func _tower() -> void:
	var t := SkirmishData.TOWER
	var r := Rect2(t["rect"][0], t["rect"][1], t["rect"][2] - t["rect"][0], t["rect"][3] - t["rect"][1])
	var top: float = t["top"]
	SkirmishParts.slab(self, r, top, 0.3, "wood_plank", SkirmishData.WOOD)
	for cx in [r.position.x + 0.3, r.end.x - 0.3]:
		for cz in [r.position.y + 0.3, r.end.y - 0.3]:
			RangeLayout.box(self, "post", Vector3(cx, top * 0.5, cz), Vector3(0.4, top, 0.4), "wood_plank", 0.4, SkirmishData.WOOD)
	var lx: Array = t["lane_x"]
	var z0: float = t["ramp_z0"]
	SkirmishParts.ramp(self, Vector3((lx[0] + lx[1]) * 0.5, 0.0, z0), Vector3((lx[0] + lx[1]) * 0.5, top, r.end.y), lx[1] - lx[0], Color(0.45, 0.36, 0.24))
	var col := Color(0.4, 0.3, 0.2)
	var e := 0.1
	SkirmishParts.wall(self, "x", r.position.y, r.position.x, r.end.x, top, 1.1, 0.2, [], "wood_plank", col)
	SkirmishParts.wall(self, "z", r.position.x, r.position.y, r.end.y, top, 1.1, 0.2, [], "wood_plank", col)
	SkirmishParts.wall(self, "z", r.end.x - e, r.position.y, r.end.y, top, 1.1, 0.2, [], "wood_plank", col)
	SkirmishParts.wall(self, "x", r.end.y - e, r.position.x, lx[0], top, 1.1, 0.2, [], "wood_plank", col)


func _cover(c: Array) -> void:
	var st: Array = SkirmishData.COVER_STYLE[c[0]]
	var size := Vector3(c[3], c[5], c[4])
	RangeLayout.box(self, str(c[0]), Vector3(c[1], c[5] * 0.5, c[2]), size, st[0], minf(c[3], c[4]), st[1])
	var o := 0.9
	var pts := [Vector3(0, 0, size.z * 0.5 + o), Vector3(0, 0, -size.z * 0.5 - o)]
	if c[0] != "barrier":
		pts += [Vector3(size.x * 0.5 + o, 0, 0), Vector3(-size.x * 0.5 - o, 0, 0)]
	for p in pts:
		covers.append(Vector3(c[1], 0, c[2]) + p)


func _loot(l: Array) -> void:
	var pos := Vector3(l[0], 0, l[1])
	RangeLayout.box(self, "loot", pos + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.6), "wood_plank", 0.6, Color(0.2, 0.42, 0.25))
	var sign := Label3D.new()
	sign.text = " + ".join((l[2] as Array).map(func(k): return str(k).to_upper()))
	sign.font_size = 40
	sign.pixel_size = 0.004
	sign.outline_size = 8
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color(0.6, 1.0, 0.65)
	sign.position = pos + Vector3(0, 1.0, 0)
	add_child(sign)
	loot_crates.append({"pos": pos, "loot": l[2].duplicate(), "taken": false})


func _extract_marker() -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = SkirmishData.EXTRACT_R
	cm.bottom_radius = SkirmishData.EXTRACT_R
	cm.height = 0.06
	m.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.4, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = SkirmishData.EXTRACT + Vector3(0, 0.04, 0)
	add_child(m)
	var l := Label3D.new()
	l.text = "EXTRACT"
	l.font_size = 120
	l.pixel_size = 0.01
	l.outline_size = 16
	l.modulate = Color(0.5, 1.0, 0.6)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = SkirmishData.EXTRACT + Vector3(0, 4.5, 0)
	add_child(l)
	var beam := OmniLight3D.new()
	beam.position = SkirmishData.EXTRACT + Vector3(0, 3.0, 0)
	beam.light_color = Color(0.4, 1.0, 0.5)
	beam.omni_range = 14.0
	add_child(beam)


## NavigationRegion3D over every world collider on the map (call once the node is in the tree).
func bake() -> void:
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5
	nm.agent_height = 2.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_max_climb = 0.5
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = TacticalConfig.LAYER_WORLD
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, self)
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	region = NavigationRegion3D.new()
	region.navigation_mesh = nm
	add_child(region)
	NavigationServer3D.map_force_update(region.get_navigation_map())
