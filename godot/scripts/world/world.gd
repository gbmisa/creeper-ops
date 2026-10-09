class_name World
extends Node3D
## A self-contained playable space: terrain, creeper, lighting, effects and gameplay hooks.
## The surface and the cave are both Worlds. Both simulate every frame; only the active one
## is visible.

var grid: Grid
var cave := false
var creeper: CreeperSim
var creeper_mesh: CreeperMesh
var terrain: TerrainChunks
var terrain_mat: ShaderMaterial
var height_tex: ImageTexture  # one texel per cell; terrain + creeper shaders read it
var props: Node3D
## Injected by the game: is a structure standing on this cell? TerrainEdit skips those.
var occupied := func(_x: int, _z: int) -> bool: return false
var effects: Effects
var env: WorldEnvironment

## Shootable things: { node: Node3D, radius: float, alive: Callable, on_hit: Callable(dmg, point) }
var targets: Array[Dictionary] = []
## Usable by the Operative: { pos: Vector3, radius, prompt: Callable -> String, use: Callable }
var interactables: Array[Dictionary] = []
## Per-frame hooks: Callable(dt)
var updaters: Array[Callable] = []
## On-screen markers: { pos: Vector3|Callable, label: String|Callable, color: Color, visible: Callable, minor: bool }
var markers: Array[Dictionary] = []


func setup(world_name: String, g: Grid, is_cave: bool, keep_clear := Callable()) -> void:
	name = world_name
	grid = g
	cave = is_cave
	g.snapshot_base()
	height_tex = TerrainMesh.height_texture(g)
	terrain_mat = ShaderMaterial.new()
	terrain_mat.shader = load("res://shaders/terrain.gdshader")
	terrain_mat.set_shader_parameter("grain", TerrainMesh.grain_texture())
	terrain_mat.set_shader_parameter("map_size", g.world_size())
	terrain_mat.set_shader_parameter("level_h", Config.LEVEL_H)
	terrain_mat.set_shader_parameter("is_cave", 1.0 if is_cave else 0.0)
	terrain = TerrainChunks.new()
	terrain.setup(g, cave, terrain_mat)
	add_child(terrain)
	props = Props.scatter(g, cave, 11 if cave else 3, keep_clear)
	add_child(props)

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
	terrain.update()
	for fn in updaters:
		fn.call(dt)
	effects.update(dt)


## Heights changed under `cells` (TerrainEdit.apply). Pushes the change to everything that
## caches heights, then tells the rest through Bus.terrain_changed.
func terrain_changed(cells: Array[Vector2i]) -> void:
	var img := height_tex.get_image()
	for c in cells:
		img.set_pixel(c.x, c.y, Color(grid.height_at(c.x, c.y), 0, 0))
	height_tex.update(img)
	terrain.mark(cells)
	creeper.terrain_changed(cells)
	var touched := {}
	for c in cells:
		touched[c] = true
	for p in props.get_children():
		var pc := grid.world_to_cell(p.position.x, p.position.z)
		if touched.has(pc):
			p.position.y = grid.smooth_y(p.position.x, p.position.z) + p.scale.y * 0.2
	Bus.terrain_changed.emit(self, cells)


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
