class_name FpsMode
extends Node3D
## Operative mode: movement + weapons + suit + interaction + recall. Works in any World
## (surface or cave); GameFlow decides which. `body` is a proxy node that mites and the
## marker system treat as the Operative's position.

var camera := Camera3D.new()
var controller: PlayerController
var weapons: OperativeWeapons
var body := Node3D.new()
var suit := Config.SUIT_MAX
var recall_hold := 0.0
var recall_cd := 0.0
var commit_recall: Callable = func() -> void: pass
var preview_recall: Callable = func() -> float: return 0.0
var world: World = null
var prompt := ""
var in_creeper := false
var creeper_depth := 0.0
var hurt_flash := 0.0
var since_hurt := 99.0
var beacons := func(_w) -> Array: return []  # injected: built beacons when on the surface
var mites: CaveMites = null
var prey: Dictionary


func _init() -> void:
	name = "Operative"
	camera.fov = 75.0
	camera.near = 0.05
	camera.far = 1200.0
	add_child(camera)
	add_child(body)
	controller = PlayerController.new(camera)
	weapons = OperativeWeapons.new(camera)
	prey = { "node": body, "radius": 0.5, "alive": func(): return world != null, "hit": func(d): damage(d) }


func enter(w: World, cell: Vector2i, facing: float, cave_mites: CaveMites = null) -> void:
	leave()
	world = w
	controller.spawn(w.grid, cell.x, cell.y, facing)
	body.position = controller.pos
	recall_hold = 0.0
	mites = cave_mites
	if mites:
		mites.target = body
		mites.on_player_hit = damage
	camera.current = true
	Sfx.play("teleport")


func leave() -> void:
	if world == null:
		return
	if mites:
		mites.target = null
	mites = null
	world = null


func reset_suit() -> void:
	suit = Config.SUIT_MAX
	weapons.tank = Config.TANK_MAX


func damage(amount: float) -> void:
	suit -= amount
	hurt_flash = 0.3
	since_hurt = 0.0
	Sfx.play("hurt")


func update(dt: float, input: InputState) -> void:
	var g := world.grid
	var feet := controller.pos
	var depth := world.creeper.depth_world(feet)
	var surface_y := g.ground_y(feet.x, feet.z) + depth * Config.LEVEL_H
	in_creeper = depth > 0.04 and feet.y < surface_y + 0.15
	creeper_depth = depth if in_creeper else 0.0
	controller.update(dt, input, g, Config.CREEPER_SLOW if in_creeper else 1.0)
	body.position = controller.pos
	weapons.update(dt, input, world, controller.pos)
	Sfx.listener = camera.global_position
	since_hurt += dt
	if in_creeper:  # suit burns, faster the deeper you wade
		suit -= (Config.OP_CREEPER_BASE_DPS + depth * Config.OP_CREEPER_DPS) * dt
		since_hurt = 0.0
		Sfx.play("sizzle")
	elif since_hurt > Config.REGEN_DELAY:
		suit = minf(Config.SUIT_MAX, suit + Config.SUIT_REGEN * dt)
	hurt_flash = maxf(0.0, hurt_flash - dt)
	if suit <= 0.0:
		Bus.operative_down.emit()
		return
	_interact(input)
	_recall(dt, input)


func _interact(input: InputState) -> void:
	var feet := controller.pos
	var best: Dictionary = {}
	var bd := INF
	var candidates: Array = world.interactables.duplicate()
	for b in beacons.call(world):
		candidates.append({ "pos": b.pos, "radius": 1.8, "prompt": func(): return "[E] Recall to the Command Node (free)",
			"use": func(): commit_recall.call() })
	for it in candidates:
		var d := Vector2(it.pos.x - feet.x, it.pos.z - feet.z).length()
		if d <= it.radius and d < bd and it.prompt.call() != "":
			best = it
			bd = d
	prompt = best.prompt.call() if not best.is_empty() else ""
	if not best.is_empty() and input.act("use"):
		best.use.call()


func _recall(dt: float, input: InputState) -> void:
	if input.held("recall") and world != null:
		recall_hold += dt
		recall_cd = preview_recall.call()
		if recall_hold >= Config.RECALL_HOLD:
			recall_hold = 0.0
			commit_recall.call()
	else:
		recall_hold = 0.0
		recall_cd = 0.0
