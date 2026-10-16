class_name RangeLayout
## Range geometry: floor, berms, booth, distance boards, dusk sky and sun. World colliders carry
## meta "mat" and "thick" (see TacticalConfig / MaterialDefs). Shooting direction is -Z; firing line z = 0.

const HALF_W := 20.0
const LENGTH := 320.0
const BACK_Z := 14.0
const DISTANCES := [10, 25, 50, 100, 200, 300]
const SPAWN := Vector3(0, 0.05, 4.5)
const RACK_POS := Vector3(-5.0, 0, 9.7)  # wall-mounted, faces -Z
const BENCH_POS := Vector3(5.0, 0, 9.5)  # F9: ammo bench against the back wall

static var _mats := {}


static func build(parent: Node3D) -> void:
	_environment(parent)
	box(parent, "grass", Vector3(0, -0.5, -LENGTH * 0.5 + BACK_Z * 0.5), Vector3(HALF_W * 2, 1.0, LENGTH + BACK_Z), "dirt_berm", 1.0, Color(0.22, 0.28, 0.14))
	box(parent, "slab", Vector3(0, -0.15, 3.5), Vector3(16, 0.3, 14), "concrete", 0.3, Color(0.5, 0.5, 0.48), Vector3(0, 0.001, 0))
	# berms: far end, both sides, behind the booth
	box(parent, "berm_far", Vector3(0, 1.75, -LENGTH - 3), Vector3(HALF_W * 2 + 12, 3.5, 6), "dirt_berm", 3.0, Color(0.3, 0.22, 0.14))
	var berm_col := Color(0.3, 0.22, 0.14)
	box(parent, "berm_side", Vector3(-(HALF_W + 3), 1.75, -LENGTH * 0.5 + BACK_Z * 0.5), Vector3(6, 3.5, LENGTH + BACK_Z), "dirt_berm", 3.0, berm_col)
	# east berm has a gap (z -12..-2) leading to the kill house yard
	box(parent, "berm_east_far", Vector3(HALF_W + 3, 1.75, (-LENGTH - 12.0) * 0.5), Vector3(6, 3.5, LENGTH - 12.0), "dirt_berm", 3.0, berm_col)
	box(parent, "berm_east_near", Vector3(HALF_W + 3, 1.75, (-2.0 + BACK_Z) * 0.5), Vector3(6, 3.5, BACK_Z + 2.0), "dirt_berm", 3.0, berm_col)
	box(parent, "berm_back", Vector3(0, 1.75, BACK_Z + 3), Vector3(HALF_W * 2 + 12, 3.5, 6), "dirt_berm", 3.0, Color(0.3, 0.22, 0.14))
	_booth(parent)
	for d in DISTANCES:
		_board(parent, d)
	LookHub.build(parent)


static func box(parent: Node3D, nm: String, pos: Vector3, size: Vector3, mat: String, thick: float, col: Color, lift := Vector3.ZERO) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = nm
	sb.position = pos + lift
	sb.collision_layer = TacticalConfig.LAYER_WORLD
	sb.collision_mask = 0
	sb.set_meta("mat", mat)
	sb.set_meta("thick", thick)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = LookMaterials.get_mat(mat, col, nm)
	sb.add_child(mi)
	parent.add_child(sb)
	return sb


static func colour(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.95
		_mats[key] = m
	return _mats[key]


static func _booth(p: Node3D) -> void:
	var wall := Color(0.42, 0.4, 0.38)
	box(p, "roof", Vector3(0, 3.35, 8.5), Vector3(16.6, 0.3, 4.0), "concrete", 0.3, Color(0.3, 0.3, 0.32))
	box(p, "back_wall", Vector3(0, 1.6, 10.15), Vector3(16.6, 3.2, 0.3), "concrete", 0.3, wall)
	for sx in [-1.0, 1.0]:
		box(p, "side_wall", Vector3(sx * 8.15, 1.6, 4.0), Vector3(0.3, 3.2, 12.0), "concrete", 0.3, wall)
	# shooting counter (low, so the muzzle clears it) and the bench
	box(p, "counter", Vector3(0, 0.5, 0.4), Vector3(9.0, 1.0, 0.5), "concrete", 0.5, Color(0.36, 0.34, 0.32))
	box(p, "bench", BENCH_POS + Vector3(0, 0.45, 0), Vector3(2.6, 0.9, 0.9), "wood_plank", 0.9, Color(0.5, 0.36, 0.2))


static func _board(p: Node3D, d: int) -> void:
	var z := -float(d)
	var line := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(HALF_W * 2, 0.02, 0.25)
	line.mesh = bm
	line.material_override = colour(Color(0.85, 0.85, 0.8))
	line.position = Vector3(0, 0.011, z)
	p.add_child(line)
	var s := 1.0 + d / 80.0
	for sx in [-1.0, 1.0]:
		var post := box(p, "board_post", Vector3(sx * 14.0, 1.2 * s, z), Vector3(0.12, 2.4 * s, 0.12), "wood_plank", 0.12, Color(0.4, 0.3, 0.2))
		var l := Label3D.new()
		l.text = "%d m" % d
		l.font_size = 96
		l.pixel_size = 0.008 * s
		l.modulate = Color(1, 0.95, 0.75)
		l.outline_size = 16
		l.position = Vector3(0, 1.4 * s, 0.1)
		post.add_child(l)


static func _environment(p: Node3D) -> void:
	LookEnv.build(p, "skirmish" if RangeMaps.pending == "skirmish" else "range")
	for x in [-4.0, 4.0]:  # booth lamps
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 3.0, 5.5)
		lamp.omni_range = 12.0
		lamp.light_energy = 1.6
		lamp.light_color = Color(1.0, 0.9, 0.75)
		p.add_child(lamp)
