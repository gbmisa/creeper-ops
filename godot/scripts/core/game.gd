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
var builder: EnemyBuilder
var castle_raids: CastleRaids
var keeps: CastleKeeps
var guards: CastleGuards
var engines: SalvageEngines
var cave_engines: SalvageEngines
var orbital: Orbital
var command: CommandMode
var fps: FpsMode
var flow: GameFlow
var metrics: PlayMetrics

var mode := "command"       # command | surface | cave
var paused := true          # until the briefing is dismissed
var landing := true         # Command Node still in orbit
var fps_paused := false     # Esc in Operative mode
var over := false
var time := 0.0
var win_time := -1.0         # game seconds when the last required objective completed
var objective_times := {}    # objective id -> game seconds it completed (sim report)
var teleport_cooldown := 0.0
var speed := 1
var time_scale := 1.0       # debug multiplier on top of speed
var ignore_capture := false # debug: run the Operative without mouse capture
var ambience := SfxAmbience.new()
var _anims_frozen := false  # tracks CreatureAnim freeze state vs the sim gate below


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
	structures.level = level
	structures.stockpile = stockpile
	structures.packets.stockpile = stockpile
	var deposits := Deposits.new()
	var ore_rows: Array = level.get("ores", [])
	deposits.setup(surface, ore_rows)
	structures.deposits = deposits
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
	cave_engines = SalvageEngines.new(cave, cave_data.get("engines", []), structures, stockpile)
	cave_engines.cash_mode = true
	castles = Strongholds.new(surface, level.castles, hazards.nests)
	units.castles = castles
	castle_raids = CastleRaids.new(castles, level.get("castle_rules", {}))
	guards = CastleGuards.new(surface, castles, level.castles)
	hazards.guards = guards

	engines = SalvageEngines.new(surface, level.get("engines", []), structures, stockpile)
	engines.nests = hazards.nests
	engines.castles = castles

	orbital = Orbital.new(surface, economy)
	orbital.hazards = hazards
	TerpPaint.attach(surface)
	TerpPaint.attach(cave)
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
	fps.stockpile = stockpile
	fps.weapons.advanced.stockpile = stockpile
	fps.node_pos = func():
		if mode == "cave":
			return null
		var n: Structure = structures.command_node()
		if n == null or n.is_flying():
			return null
		return n.pos
	hazards.nests.prey = surface_prey
	guards.prey = surface_prey
	castles.engine_prey = surface_prey  # Stage 21 trebuchets
	CastlePerks.attach(castles)  # Stage 21: weapons reach further near held castles
	hazards.nests.goal_cells = raider_goals
	hazards.nests.node_pos = func() -> Vector3:
		var n := structures.command_node()
		return n.pos if n else Vector3.ZERO
	castles.op = func(): return fps.controller if fps.world == surface else null
	castles.stockpile = stockpile
	hazards.nests.stockpile = stockpile
	hazards.nests.operative = func(): return fps if fps.world == surface else null
	builder = EnemyBuilder.new(surface, castles, hazards.nests, structures, stockpile)
	structures.enemy_build = builder
	hazards.nests.builder = builder
	hazards.nests.hub_mortars = builder.mortars
	deploy.drop_blocked = func(cell: Vector2i) -> bool: return builder.shields(cell)
	command.castles = castles
	keeps = CastleKeeps.new(castles, structures)
	castles.on_lost = func(cells: Array):
		for cell in cells:
			var s = structures.occupied.get(surface.grid.idx(cell.x, cell.y))
			if s != null and not s.dead:
				structures.remove(s, "destroyed")

	AmmoGrades.reset(level)
	Bus.objective_done.connect(func(id: String): objective_times[id] = roundi(time))
	Bus.victory.connect(func(): win_time = time if win_time < 0.0 else win_time)
	hud = Hud.new()
	add_child(hud)
	hud.setup(command, units)
	hud.info.stockpile = stockpile
	ArmouryMenu.bind(self)
	hud.wheel_view.wheel = fps.builder.wheel
	fps.builder.wheel.host = self
	hud.build.on_pick = func(item): flow.pick(item)
	input.on_key = func(k): flow.on_key(k)
	flow = GameFlow.new(self)
	cave.set_active(false)
	command.cam.current = true
	flow.show_briefing()
	metrics = PlayMetrics.new(self)
	Debug.apply(self)


func _exit_tree() -> void:
	metrics.finish("quit")


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
		var row := s.prey.duplicate() as Dictionary
		row["type"] = s.type
		row["weapon"] = bool(s.def.get("weapon", false))
		prey.append(row)
	prey.append_array(castles.prey())
	prey.append_array(engines.prey())
	if mode == "surface":
		prey.append(fps.prey)
	return prey


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	var menu := hud.keys.visible or flow.pause_open
	if mode == "command" and not menu:
		command.update(dt, input)  # camera + planning work while paused too
	var frozen := menu or mode != "command" and fps_paused
	var scale: float = (speed if mode == "command" else 1) * time_scale
	var running := not paused and not over and not frozen and not landing
	# Freeze creature clips exactly when the sim gate closes, resume when it
	# opens. Same condition as the update() gate, so NPCs never walk in place
	# while the game is paused.
	var want_frozen := not running
	if want_frozen != _anims_frozen:
		_anims_frozen = want_frozen
		CreatureAnim.set_all_paused(get_tree(), _anims_frozen)
	if running:
		update(dt * scale)
	render(dt)
	input.end_frame()


func update(dt: float) -> void:
	time += dt
	metrics.tick(dt)
	teleport_cooldown = maxf(0.0, teleport_cooldown - dt)
	stockpile.tick(dt)
	AmmoGrades.tick(dt)
	deploy.update(dt)
	flow.update(dt)
	if mode != "command":
		fps.update(dt, input)
	surface.update(dt)
	cave.update(dt)
	keeps.update()
	structures.update(dt, time)
	units.update(dt, hazards.nests.enemies() + castles.enemies() + guards.enemies() + builder.enemies())
	var due: Array[Vector3] = []
	for i in orbital._pending.size():
		var strike: Dictionary = orbital._pending[i]
		if float(strike.t) + dt >= Config.LANCE_DELAY:
			due.append(strike.at as Vector3)
	orbital.update(dt)
	if not due.is_empty():
		hazards.nests.on_lance(due)


func render(dt: float) -> void:
	(cave if mode == "cave" else surface).refresh_visuals()
	ambience.update(self, dt)
	CreatureLod.tick(get_tree(), get_viewport().get_camera_3d(), dt)
	hud.refresh(self, dt)


func cycle_speed(dir: int) -> void:
	var i := SPEEDS.find(speed)
	speed = SPEEDS[clampi(i + dir, 0, SPEEDS.size() - 1)]
