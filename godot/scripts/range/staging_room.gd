class_name StagingRoom
## F139: the loadout room geometry (hideout look): floor, four walls, ceiling, lamps. The stations on the back (+Z) wall
## keep the Firing Range's own positions (RangeWorkbench.POS, ammo bench, crate, rack), so the room spans z -5.2..10.2.

const HALF_W := 8.0
const Z_NORTH := -5.0   # inner face of the north wall (mannequins + deploy board)
const Z_SOUTH := 10.2   # inner face of the back wall (stations)
const HEIGHT := 3.6
const SPAWN := Vector3(0, 0.05, 4.5)
const WALL := Color(0.36, 0.34, 0.31)


static func build(p: Node3D) -> void:
	LookEnv.build(p, "range")
	var depth := Z_SOUTH - Z_NORTH
	var mid := (Z_SOUTH + Z_NORTH) * 0.5
	RangeLayout.box(p, "floor", Vector3(0, -0.15, mid), Vector3(HALF_W * 2 + 1, 0.3, depth + 1), "concrete", 0.3, Color(0.42, 0.41, 0.39))
	RangeLayout.box(p, "ceiling", Vector3(0, HEIGHT + 0.15, mid), Vector3(HALF_W * 2 + 1, 0.3, depth + 1), "concrete", 0.3, Color(0.3, 0.3, 0.3))
	RangeLayout.box(p, "wall_n", Vector3(0, HEIGHT * 0.5, Z_NORTH - 0.25), Vector3(HALF_W * 2 + 1, HEIGHT, 0.5), "concrete", 0.5, WALL)
	RangeLayout.box(p, "wall_s", Vector3(0, HEIGHT * 0.5, Z_SOUTH + 0.25), Vector3(HALF_W * 2 + 1, HEIGHT, 0.5), "concrete", 0.5, WALL)
	for sx in [-1.0, 1.0]:
		RangeLayout.box(p, "wall_x%d" % int(sx), Vector3(sx * (HALF_W + 0.25), HEIGHT * 0.5, mid), Vector3(0.5, HEIGHT, depth + 1), "concrete", 0.5, WALL)
	for x in [-5.0, 0.0, 5.0]:
		for z in [-2.0, 3.0, 8.0]:
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, HEIGHT - 0.4, z)
			lamp.omni_range = 9.0
			lamp.light_energy = 1.3
			lamp.light_color = Color(1.0, 0.92, 0.78)
			p.add_child(lamp)
