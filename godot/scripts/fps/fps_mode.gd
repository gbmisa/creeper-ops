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
var shield := 0.0
var stockpile: Stockpile
var node_pos: Callable = func(): return null  # Vector3 of the Command Node, or null
var recall_hold := 0.0
var recall_cd := 0.0
var hold_label := ""   # HoldBar: what hold action is in progress ("" = none)
var hold_frac := -1.0  # HoldBar: 0..1 progress, -1 = hidden
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
var builder: OperativeBuild = null  # injected: first-person building (surface only)
var prey: Dictionary
var hold_t := 0.0  # seconds the use key has been held on a hold interactable


func _init() -> void:
	name = "Operative"
	camera.fov = 75.0
	camera.near = 0.05
	camera.far = 1200.0
	add_child(camera)
	add_child(body)
	controller = PlayerController.new(camera)
	weapons = OperativeWeapons.new(camera)
	prey = { "kind": "operative", "node": body, "radius": 0.5, "alive": func(): return world != null, "hit": func(d): damage(d) }


func enter(w: World, cell: Vector2i, facing: float, cave_mites: CaveMites = null) -> void:
	leave()
	world = w
	controller.spawn(w.grid, cell.x, cell.y, facing)
	body.position = controller.pos
	recall_hold = 0.0
	weapons.rifle.bloom = 0.0
	weapons.climb = 0.0
	weapons.climb_yaw = 0.0
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
	if builder:
		builder.toggle(false)
	world = null
	ArmouryMenu.close_menu()


func reset_suit() -> void:
	suit = OperativeUpgrades.suit_max()
	shield = OperativeUpgrades.shield_max()
	weapons.tank = Config.TANK_MAX
	weapons.rifle.bloom = 0.0
	weapons.climb = 0.0
	weapons.climb_yaw = 0.0


## Shield (Armour tier 3) soaks first. What remains hits the suit.
func absorb(amount: float) -> void:
	var left := amount
	if shield > 0.0:
		var soak := minf(shield, left)
		shield -= soak
		left -= soak
	if left > 0.0:
		suit -= left


func damage(amount: float) -> void:
	absorb(amount)
	weapons.feel.hurt(amount)
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
	hold_label = ""
	hold_frac = -1.0
	if ArmouryMenu.is_open():
		prompt = ""
		_vitals(dt, depth)
		return
	controller.kick_pitch = weapons.motion.cam_pitch() + weapons.climb
	controller.kick_yaw = weapons.motion.cam_yaw() + weapons.climb_yaw
	if builder != null and builder.wheel_open():
		input.mouse_delta = Vector2.ZERO  # wheel drives the mouse: suspend FPS look
	controller.update(dt, input, g, Config.CREEPER_SLOW if in_creeper else 1.0)
	body.position = controller.pos
	var building := builder != null and world == builder.structures.world and builder.update(input, world, camera, dt)
	_drive_wheel_holdbar()
	weapons.gun.visible = not building
	if not building:
		weapons.update(dt, input, world, controller.pos)
	weapons.motion.update(dt, controller, input)
	Sfx.listener = camera.global_position
	_vitals(dt, depth)
	if suit <= 0.0:
		return
	_interact(input, dt)
	if building:
		prompt = builder.status
	_recall(dt, input)


## B hold-to-open progress for the build wheel (the wheel itself opens at 1.0).
func _drive_wheel_holdbar() -> void:
	if builder == null:
		return
	var f := builder.wheel.hold_frac()
	if f >= 0.0:
		hold_label = "BUILD WHEEL [%s]" % Keybinds.short("op_build")
		hold_frac = f


## Suit/shield regen and hurt-flash decay.
func _vitals(dt: float, depth: float) -> void:
	since_hurt += dt
	if in_creeper:  # suit burns, faster the deeper you wade; the shield soaks it first
		absorb((Config.OP_CREEPER_BASE_DPS + depth * Config.OP_CREEPER_DPS) * dt)
		since_hurt = 0.0
		Sfx.play("sizzle")
	elif since_hurt > Config.REGEN_DELAY:
		var cap := OperativeUpgrades.shield_max()
		if shield < cap:
			shield = minf(cap, shield + Config.SUIT_REGEN * dt)
		suit = minf(OperativeUpgrades.suit_max(), suit + Config.SUIT_REGEN * dt)
	hurt_flash = maxf(0.0, hurt_flash - dt)
	if suit <= 0.0:
		Bus.operative_down.emit()


func _interact(input: InputState, dt := 0.0) -> void:
	var feet := controller.pos
	var best: Dictionary = {}
	var bd := INF
	var candidates: Array = world.interactables.duplicate()
	var np = node_pos.call()
	if np is Vector3:
		candidates.append({ "pos": np, "radius": ArmouryMenu.REACH,
			"prompt": func(): return "" if ArmouryMenu.is_open() else "[%s] Armoury" % Keybinds.short("use"),
			"use": func(): ArmouryMenu.open(self, stockpile) })
	for b in beacons.call(world):
		candidates.append({ "pos": b.pos, "radius": 1.8, "prompt": func(): return "[%s] Recall to the Command Node (free)" % Keybinds.short("use"),
			"use": func(): commit_recall.call() })
	candidates.append_array(DemoCharge.candidates(world))
	for it in candidates:
		var d := Vector2(it.pos.x - feet.x, it.pos.z - feet.z).length()
		if it.get("prefer", false):
			d -= 1.0  # a planted charge beats a sabotage prompt at the same spot
		if it.has("near") and not it.near.call(feet):
			continue
		if d <= it.radius and d < bd and it.prompt.call() != "":
			best = it
			bd = d
	prompt = best.prompt.call() if not best.is_empty() else ""
	_drive_channel_holdbar(best)
	if ArmouryMenu.take_suppress():
		return
	if not best.is_empty() and float(best.get("hold", 0.0)) > 0.0:
		_hold_use(best, input, dt)
	else:
		hold_t = 0.0
		if not best.is_empty() and input.act("use"):
			best.use.call()


## Sabotage channels report progress on the HoldBar instead of countdown/percent text.
func _drive_channel_holdbar(best: Dictionary) -> void:
	var cf: Callable = best.get("channel_frac", Callable())
	if not cf.is_valid():
		return
	var f := clampf(float(cf.call()), 0.0, 1.0)
	if f > 0.0 and f < 1.0:
		hold_label = "SABOTAGE %s" % String(best.get("channel_what", "target")).to_upper()
		hold_frac = f


## Hold-to-use interactables (Salvage Engine sockets): `hold` seconds with the use key held.
func _hold_use(it: Dictionary, input: InputState, dt: float) -> void:
	var ok: bool = it.get("ready", func(): return true).call()
	if not ok or not input.held("use"):
		hold_t = 0.0
		return
	hold_t += dt
	var frac := minf(1.0, hold_t / float(it.hold))
	it.progress.call(frac, weapons.gun.global_position + (-camera.global_transform.basis.z) * 0.3)
	hold_label = _hold_label(it)  # the HoldBar shows the fill; no percent in the prompt
	hold_frac = frac
	if hold_t >= float(it.hold):
		hold_t = 0.0
		it.use.call()


## "HOOK THE CACHE [E]": verb from the interactable prompt, key from the keybinds.
func _hold_label(it: Dictionary) -> String:
	var p := String(it.get("prompt", func(): return "").call())
	var verb := p
	if verb.begins_with("["):
		verb = verb.get_slice("] ", 1)
	return "%s [%s]" % [verb.to_upper().left(42), Keybinds.short("use")]


func _recall(dt: float, input: InputState) -> void:
	if input.held("recall") and world != null:
		recall_hold += dt
		recall_cd = preview_recall.call()
		hold_label = "RECALL [%s]" % Keybinds.short("recall")
		hold_frac = minf(1.0, recall_hold / Config.RECALL_HOLD)
		if recall_hold >= Config.RECALL_HOLD:
			recall_hold = 0.0
			commit_recall.call()
	else:
		recall_hold = 0.0
		recall_cd = 0.0
