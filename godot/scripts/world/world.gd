class_name World
extends Node3D
## A self-contained playable space: terrain, creeper, lighting, effects and gameplay hooks.
## The surface and the cave are both Worlds. Both simulate every frame; only the active one
## is visible.

var grid: Grid
var cave := false
var creeper: CreeperSim
var creeper_mesh: CreeperMesh
var terrain: MeshInstance3D
var terrain_mat: ShaderMaterial
var effects: Effects
var env: WorldEnvironment

## Shootable things: { node: Node3D, radius: float, alive: Callable, on_hit: Callable(dmg, point) }
var targets: Array[Dictionary] = []
## Usable by the Operative: { pos: Vector3, radius, prompt: Callable -> String, use: Callable }
var interactables: Array[Dictionary] = []
## Per-frame hooks: Callable(dt)
var updaters: Array[Callable] = []
## On-screen markers: { pos: Vector3, label: String|Callable, color: Color, visible: Callable, minor: bool }
var markers: Array[Dictionary] = []


func setup(world_name: String, g: Grid, is_cave: bool, keep_clear := Callable()) -> void:
	name = world_name
	grid = g
	cave = is_cave
	var height_tex := TerrainMesh.height_texture(g)
	terrain_mat = ShaderMaterial.new()
	terrain_mat.shader = load("res://shaders/terrain.gdshader")
	terrain_mat.set_shader_parameter("grain", TerrainMesh.grain_texture())
	terrain_mat.set_shader_parameter("map_size", g.world_size())
	terrain = TerrainMesh.build(g, cave, terrain_mat)
	add_child(terrain)
	add_child(Props.scatter(g, cave, 11 if cave else 3, keep_clear))

	creeper = CreeperSim.create(g)
	creeper_mesh = CreeperMesh.new()
	creeper_mesh.setup(creeper, height_tex)
	add_child(creeper_mesh)

	effects = Effects.new()
	add_child(effects)
	env = WorldLook.make_environment(cave)
	add_child(env)
	WorldLook.add_lights(self, g, cave)


func add_target(t: Dictionary) -> void:
	targets.append(t)


func remove_target(t: Dictionary) -> void:
	targets.erase(t)


## Place a node on the smooth ground at a cell centre; returns the ground point.
func place_at(node: Node3D, x: int, z: int) -> Vector3:
	var p := grid.cell_ground(x, z)
	node.position = p
	add_child(node)
	return p


func update(dt: float) -> void:
	creeper.update(dt)
	for fn in updaters:
		fn.call(dt)
	effects.update(dt)


func refresh_visuals() -> void:
	creeper_mesh.refresh()


## Visible + environment on (only one World's environment may be active).
func set_active(on: bool) -> void:
	visible = on
	if on:
		if env.get_parent() != self:
			add_child(env)
	elif env.get_parent() == self:
		remove_child(env)
