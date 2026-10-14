class_name KillHouse
extends Node3D
## Walled 30x30 m kill house east of the booth: brick outer walls, plywood / brick interior walls, doorways,
## crates and cover markers. Geometry is local to the house centre (HOME is where it stands in the range).
## `bake()` builds the NavigationRegion3D from the house geometry (call once the node is in the tree).

const HOME := Vector3(46.0, 0.0, -8.0)
const H := 3.0
const BRICK := Color(0.55, 0.3, 0.24)
const PLY := Color(0.62, 0.5, 0.34)
const WOOD := Color(0.45, 0.33, 0.2)
## [axis, fixed coord, from, to, gap list, material, thickness]  axis "x": wall along x at z = fixed
const WALLS := [
	["z", -15.0, -15.0, 15.0, [[-1.0, 0.8]], "brick", 0.3],
	["z", 15.0, -15.0, 15.0, [[8.0, 9.6]], "brick", 0.3],
	["x", -15.0, -15.0, 15.0, [], "brick", 0.3],
	["x", 15.0, -15.0, 15.0, [], "brick", 0.3],
	["z", -5.0, -15.0, 15.0, [[-11.0, -9.4], [-1.0, 0.6], [10.0, 11.6]], "plywood", 0.1],
	["z", 5.0, -15.0, 15.0, [[-8.0, -6.4], [3.0, 4.6], [11.0, 12.6]], "brick", 0.2],
	["x", -6.0, 5.0, 15.0, [[9.0, 10.6]], "plywood", 0.1],
	["x", 6.0, -15.0, -5.0, [[-10.0, -8.4]], "plywood", 0.1],
	["x", 2.0, -5.0, 5.0, [[-2.6, -1.0], [2.0, 3.6]], "plywood", 0.1],
]
## [x, z, size, marker sides]
const CRATES := [[-10.0, -4.0, 1.2, true], [0.0, -10.0, 1.4, true], [10.0, 3.0, 1.2, true], [-1.0, 8.0, 1.4, true],
	[-9.0, -3.0, 1.0, false], [1.0, -9.0, 1.0, false], [11.0, 2.0, 1.0, false], [-11.0, 11.0, 1.2, false],
	[3.0, -4.0, 1.0, false], [9.0, -12.0, 1.2, false]]
const PATROL := [Vector2(-10, -10), Vector2(-10, 8), Vector2(0, -5), Vector2(0, 5), Vector2(10, -9), Vector2(10, 8), Vector2(-12, 0), Vector2(12, -2)]
const SPAWNS := [Vector2(10, -9), Vector2(10, 8)]
const TERMINAL := Vector2(-19.0, 3.0)

var covers: Array[Vector3] = []   # world positions
var patrol: Array[Vector3] = []
var spawns: Array[Vector3] = []
var region: NavigationRegion3D


func _init() -> void:
	name = "KillHouse"
	position = HOME


func build() -> void:
	RangeLayout.box(self, "yard", Vector3(-1.0, -0.5, -5.0), Vector3(50, 1.0, 42), "dirt_berm", 1.0, Color(0.22, 0.28, 0.14))
	RangeLayout.box(self, "floor", Vector3(0, -0.085, 0), Vector3(34, 0.2, 34), "concrete", 0.2, Color(0.42, 0.41, 0.39))
	for w in WALLS:
		_wall(w)
	for c in CRATES:
		RangeLayout.box(self, "crate", Vector3(c[0], c[2] * 0.5, c[1]), Vector3(c[2], c[2], c[2]), "wood_plank", c[2], WOOD)
		if c[3]:
			for s in [-1.0, 1.0]:
				covers.append(to_global(Vector3(c[0] + s * (c[2] * 0.5 + 0.7), 0, c[1])))
	for v in PATROL:
		patrol.append(to_global(Vector3(v.x, 0, v.y)))
	for v in SPAWNS:
		spawns.append(to_global(Vector3(v.x, 0, v.y)))
	for p in [Vector3(-9, 2.6, -9), Vector3(9, 2.6, 8)]:  # lamps (no roof)
		var l := OmniLight3D.new()
		l.position = p
		l.omni_range = 16.0
		l.light_energy = 1.4
		l.light_color = Color(1.0, 0.85, 0.65)
		add_child(l)


func terminal_pos() -> Vector3:
	return to_global(Vector3(TERMINAL.x, 0, TERMINAL.y))


func _wall(w: Array) -> void:
	var along_x: bool = w[0] == "x"  # wall runs along x, at z = fixed
	var edges := [w[2]]
	for g in w[4]:
		edges.append(g[0])
		edges.append(g[1])
	edges.append(w[3])
	var col: Color = BRICK if w[5] == "brick" else PLY
	for i in range(0, edges.size(), 2):
		var a: float = edges[i]
		var b: float = edges[i + 1]
		if b - a < 0.01:
			continue
		var mid := (a + b) * 0.5
		var size := Vector3(b - a, H, w[6]) if along_x else Vector3(w[6], H, b - a)
		var pos := Vector3(mid, H * 0.5, w[1]) if along_x else Vector3(w[1], H * 0.5, mid)
		RangeLayout.box(self, "wall_" + w[5], pos, size, w[5], w[6], col)


## NavigationRegion3D from the house colliders (static, world layer only).
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
