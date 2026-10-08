extends Node3D
## Top-level orchestrator: builds both Worlds and every subsystem, then runs the frame loop.
## Rules live in subsystems; mode transitions live in GameFlow. Wiring only.

const SPEEDS := [1, 2, 3]

var input: InputState
var hud: Hud
var economy: Economy
var stockpile: Stockpile
var deploy: OperativeDeploy
var level: Dictionary
var surface: World
var structures: StructureManager
var hazards: SurfaceHazards
var units: UnitManager
var cave_data: Dictionary
var cave: World
var cave_hazards: CaveHazards
var castles: Strongholds
var castle_raids: CastleRaids
var guards: CastleGuards
var orbital: Orbital
var command: CommandMode
var fps: FpsMode
var flow: GameFlow

var mode := "command"       # command | surface | cave
var paused := true          # until the briefing is dismissed
var landing := true         # Command Node still in orbit
var fps_paused := false     # Esc in Operative mode
var over := false
var time := 0.0
var teleport_cooldown := 0.0
var speed := 1
var time_scale := 1.0       # debug multiplier on top of speed
var ignore_capture := false # debug: run the Operative without mouse capture


func _ready() -> void:
	input = InputState.new()
	add_child(input)
	economy = Economy.new()
	stockpile = Stockpile.new()
	level = Levels.build(Levels.current())
	surface = World.new()
	surface.setup("Surface", level.grid, false)
	add_child(surface)
	structures = StructureManager.new()
	structures.setup(surface, economy)
	surface.add_child(structures)
	hazards = SurfaceHazards.new(surface, level, structures)
	structures.hazards = hazards
	units = UnitManager.new()
	units.setup(surface, structures)
	surface.add_child(units)

	cave_data = Levels.cave(Levels.current())
	cave = World.new()
	cave.setup("Cave", cave_data.grid, true)
	add_child(cave)
	cave_hazards = CaveHazards.new(cave, cave_data)
	castles = Strongholds.new(surface, level.castles, hazards.nests)
	castle_raids = CastleRaids.new(castles, level.get("castle_rules", {}))
	guards = CastleGuards.new(surface, castles, level.castles)
	hazards.guards = guards

	orbital = Orbital.new(surface, economy)
	orbital.hazards = hazards
	command = CommandMode.new()
	command.setup(surface, structures, units, orbital, level)
	add_child(command)
	var hint: Vector2i = level.landing_hint
	command.cam.focus(level.grid.cell_ground(hint.x, hint.y))
	fps = FpsMode.new()
	add_child(fps)
	fps.beacons = func(w): return structures.beacons() if w == surface else []
	deploy = OperativeDeploy.new(self)
	command.deploy = deploy
	fps.builder = OperativeBuild.new(structures, command.overlay)
	fps.commit_recall = deploy.commit_recall
	fps.preview_recall = deploy.preview_recall
	hazards.nests.prey = surface_prey
	guards.prey = surface_prey
	hazards.nests.goal_cells = raider_goals
	castles.op = func(): return fps.controller if fps.world == surface else null
	castles.stockpile = stockpile
	command.castles = castles
	castles.on_lost = func(cells: Array):
		for cell in cells:
			var s = structures.occupied.get(surface.grid.idx(cell.x, cell.y))
			if s != null and not s.dead:
				structures.remove(s, "destroyed")

	hud = Hud.new()
	add_child(hud)
	hud.setup(command, units)
	hud.build.on_pick = func(item): flow.pick(item)
	input.on_key = func(k): flow.on_key(k)
	flow = GameFlow.new(self)
	cave.set_active(false)
	command.cam.current = true
	flow.show_briefing()
	Debug.apply(self)


## Cells nest raiders march toward: every grounded structure's footprint.
func raider_goals() -> Array:
	var out := []
	for s in structures.list:
		if not s.is_flying() and not s.def.get("flying", false):
			out.append_array(Placement.footprint_cells(s.type, s.x, s.z))
	return out


## Everything nest raiders may attack: { node, radius, alive, hit }.
func surface_prey() -> Array:
	var prey := []
	for u in units.list:
		prey.append(u.prey)
	for s in structures.list:
		prey.append(s.prey)
	prey.append_array(castles.prey())
	if mode == "surface":
		prey.append(fps.prey)
	return prey


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	var menu := hud.keys.visible
	if mode == "command" and not menu:
		command.update(dt, input)  # camera + planning work while paused too
	var frozen := menu or mode != "command" and fps_paused
	var scale: float = (speed if mode == "command" else 1) * time_scale
	if not paused and not over and not frozen and not landing:
		update(dt * scale)
	render(dt)
	input.end_frame()


func update(dt: float) -> void:
	time += dt
	teleport_cooldown = maxf(0.0, teleport_cooldown - dt)
	stockpile.tick(dt)
	deploy.update(dt)
	flow.update(dt)
	if mode != "command":
		fps.update(dt, input)
	surface.update(dt)
	cave.update(dt)
	structures.update(dt, time)
	units.update(dt, hazards.nests.enemies() + castles.enemies() + guards.enemies())
	orbital.update(dt)


func render(dt: float) -> void:
	(cave if mode == "cave" else surface).refresh_visuals()
	hud.refresh(self, dt)


func cycle_speed(dir: int) -> void:
	var i := SPEEDS.find(speed)
	speed = SPEEDS[clampi(i + dir, 0, SPEEDS.size() - 1)]
