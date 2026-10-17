class_name RangeStationProps
## F141: low-poly prop shapes for the range stations (workbench, ammo bench, armor rack, truck extras) and their small
## signs. Boxes through RangeLayout.box (same collision / material path as the rest of the range), no floating text.

const WOOD := Color(0.45, 0.33, 0.2)
const DARK_WOOD := Color(0.32, 0.23, 0.14)
const STEEL := Color(0.3, 0.32, 0.34)
const SIGN_BG := Color(0.1, 0.12, 0.1)


## Small plaque on two posts-free board: `pos` is its centre, it faces -Z (toward the range) like the old labels.
static func sign_board(parent: Node3D, pos: Vector3, text: String, width := 1.1) -> Label3D:
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.3, 0.04)
	board.mesh = bm
	board.material_override = RangeLayout.colour(SIGN_BG)
	board.position = pos
	parent.add_child(board)
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = 0.0045
	l.outline_size = 6
	l.rotation_degrees.y = 180.0
	l.position = pos + Vector3(0, 0, -0.025)
	l.modulate = Color(0.85, 1.0, 0.8)
	l.double_sided = false
	parent.add_child(l)
	return l


static func _b(parent: Node3D, nm: String, pos: Vector3, size: Vector3, col: Color, mat := "wood_plank") -> void:
	RangeLayout.box(parent, nm, pos, size, mat, 0.1, col)


## Workbench: planked top, four legs, lower shelf, back panel with hung tools, a vise and a parts tray.
static func workbench(parent: Node3D, c: Vector3) -> void:
	_b(parent, "wb_top", c + Vector3(0, 0.9, 0), Vector3(1.8, 0.08, 0.8), WOOD)
	for sx in [-0.85, 0.85]:
		for sz in [-0.33, 0.33]:
			_b(parent, "wb_leg", c + Vector3(sx, 0.43, sz), Vector3(0.08, 0.86, 0.08), DARK_WOOD)
	_b(parent, "wb_shelf", c + Vector3(0, 0.25, 0), Vector3(1.7, 0.05, 0.7), DARK_WOOD)
	_b(parent, "wb_back", c + Vector3(0, 1.45, 0.4), Vector3(1.8, 1.0, 0.04), DARK_WOOD)
	_b(parent, "wb_vise", c + Vector3(-0.65, 1.0, -0.2), Vector3(0.2, 0.12, 0.16), STEEL, "sheet_metal")
	_b(parent, "wb_vise_jaw", c + Vector3(-0.65, 1.08, -0.31), Vector3(0.16, 0.06, 0.04), STEEL, "sheet_metal")
	_b(parent, "wb_tray", c + Vector3(0.45, 0.96, -0.05), Vector3(0.5, 0.04, 0.3), STEEL, "sheet_metal")
	for i in 4:  # hung tools on the back panel
		_b(parent, "wb_tool", c + Vector3(-0.6 + i * 0.4, 1.55, 0.36), Vector3(0.05, 0.4 - i * 0.05, 0.03), STEEL, "sheet_metal")
	_b(parent, "wb_lamp", c + Vector3(0.6, 1.95, 0.25), Vector3(0.4, 0.06, 0.2), Color(0.8, 0.75, 0.5), "sheet_metal")
	sign_board(parent, c + Vector3(0, 2.25, 0.3), "WORKBENCH")


## Ammo bench: low bench with stacked crate shapes and ammo cans along the back wall.
static func ammo_bench(parent: Node3D, c: Vector3) -> void:
	_b(parent, "ab_top", c + Vector3(0, 0.85, 0), Vector3(1.5, 0.08, 0.7), WOOD)
	for sx in [-0.65, 0.65]:
		_b(parent, "ab_leg", c + Vector3(sx, 0.4, 0), Vector3(0.1, 0.8, 0.6), DARK_WOOD)
	for i in 3:
		_b(parent, "ab_can", c + Vector3(-0.45 + i * 0.35, 0.99, 0.1), Vector3(0.28, 0.2, 0.16), Color(0.28, 0.33, 0.22), "sheet_metal")
	_b(parent, "ab_crate_a", c + Vector3(1.05, 0.25, 0.1), Vector3(0.5, 0.5, 0.5), Color(0.36, 0.3, 0.2))
	_b(parent, "ab_crate_b", c + Vector3(1.05, 0.7, 0.1), Vector3(0.4, 0.4, 0.4), Color(0.4, 0.33, 0.22))
	_b(parent, "ab_shelf", c + Vector3(0, 1.5, 0.4), Vector3(1.5, 0.05, 0.25), DARK_WOOD)
	sign_board(parent, c + Vector3(0, 1.95, 0.4), "AMMO BENCH")


## Armor rack: two uprights and a crossbar, a stand pole with shoulder bar and a helmet block on top.
static func armor_rack(parent: Node3D, c: Vector3) -> Node3D:
	for sx in [-0.5, 0.5]:
		_b(parent, "ar_post", c + Vector3(sx, 1.0, 0.25), Vector3(0.1, 2.0, 0.1), STEEL, "sheet_metal")
	_b(parent, "ar_bar", c + Vector3(0, 1.95, 0.25), Vector3(1.1, 0.08, 0.1), STEEL, "sheet_metal")
	_b(parent, "ar_base", c + Vector3(0, 0.04, 0.1), Vector3(1.2, 0.08, 0.5), STEEL, "sheet_metal")
	_b(parent, "ar_pole", c + Vector3(0, 0.9, 0.1), Vector3(0.08, 1.7, 0.08), STEEL, "sheet_metal")
	_b(parent, "ar_shoulders", c + Vector3(0, 1.5, 0.1), Vector3(0.7, 0.08, 0.12), STEEL, "sheet_metal")
	_b(parent, "ar_helmet", c + Vector3(0, 1.68, 0.1), Vector3(0.24, 0.2, 0.26), Color(0.24, 0.3, 0.22), "sheet_metal")
	var vest := MeshInstance3D.new()  # F10: the armour itself, mounted on the stand
	var vm := BoxMesh.new()
	vm.size = Vector3(0.55, 0.7, 0.28)
	vest.mesh = vm
	vest.material_override = RangeLayout.colour(Color(0.3, 0.38, 0.3))
	vest.position = c + Vector3(0, 1.15, 0.02)
	parent.add_child(vest)
	return vest


## Truck extras: headlights, bumper, canopy hoops, tail lights and a sign on the bed side (truck faces -Z).
static func truck_extras(parent: Node3D, c: Vector3) -> void:
	for sx in [-0.8, 0.8]:
		_b(parent, "tk_light", c + Vector3(sx, 0.95, -2.62), Vector3(0.3, 0.2, 0.06), Color(0.9, 0.85, 0.6), "sheet_metal")
		_b(parent, "tk_tail", c + Vector3(sx, 0.9, 3.03), Vector3(0.3, 0.2, 0.06), Color(0.6, 0.1, 0.08), "sheet_metal")
	_b(parent, "tk_bumper", c + Vector3(0, 0.55, -2.65), Vector3(2.5, 0.2, 0.12), STEEL, "sheet_metal")
	for z in [0.0, 1.0, 2.0]:
		_b(parent, "tk_hoop", c + Vector3(0, 1.9, z), Vector3(2.3, 0.05, 0.05), STEEL, "sheet_metal")
	for sx in [-1.15, 1.15]:
		for z in [0.0, 2.0]:
			_b(parent, "tk_hoop_post", c + Vector3(sx, 1.75, z), Vector3(0.05, 0.3, 0.05), STEEL, "sheet_metal")
