class_name TacticalScene
extends Node3D
## Shared root for the on-foot maps (F82): FiringRange (firing_range.tscn) and SkirmishScene (skirmish.tscn).
## Owns args, the --range-test entry, Esc/pause and the build steps both maps use. Each subclass writes its
## own `_build()` in order (child order is process order, so keep it when editing).

var args := {}
var input: InputState
var session: RangeSession
var player: TacticalPlayer
var weapons: PlayerWeapons
var bal: Ballistics
var rack: RangeRack
var menu: RangeMenu
var targets: RangeTargets
var hit_log: RangeHitLog
var bots: RangeBots
var world_items: WorldItems
var inv_ui: InventoryUI
var skirmish: SkirmishGame   # only on the Skirmish map


## Which RangeMaps id this scene is. Subclasses override.
func map_id() -> String:
	return "range"


func _ready() -> void:
	Keybinds.persist = false
	args = RangeArgs.parse()
	if args.has("map"):
		RangeMaps.pending = str(args["map"])
	process_priority = 100  # runs after the player / weapons, so end_frame() clears input last
	if args.has("range-test"):
		var broken := RangeTestLoadCheck.broken()
		for path in broken:
			print("[range] FAIL script compiles: ", path)
		if not broken.is_empty():
			print("[range] FAILED ", broken.size(), " script(s) do not compile")
			get_tree().quit(1)
			return
		var t := RangeTest.new()
		add_child(t)
		await t.run()
		get_tree().quit(1 if t.failed > 0 else 0)
		return
	if args.has("map") and str(args["map"]) != map_id():
		RangeMaps.go(str(args["map"]))   # --map=X on the other map's scene: load the right scene
		return
	RangeMaps.pending = map_id()
	TacticalViewmodel.tune = args.has("tune")
	_build()
	if args.has("shot") or args.has("weapon"):
		var s := RangeShot.new()
		add_child(s)
		s.run(self)


func _build() -> void:
	pass


func _begin() -> void:
	session = RangeSession.new(int(args.get("seed", 0)))
	session.maps.selected = map_id()
	input = InputState.new()
	add_child(input)


func _add_rack(pos := Vector3.ZERO, moved := false) -> void:
	rack = RangeRack.new()
	add_child(rack)
	if moved:
		rack.position = pos
	bal = Ballistics.new()
	add_child(bal)
	var impacts := RangeImpacts.new()
	add_child(impacts)
	bal.impact.connect(impacts.on_impact)


func _add_player(spawn: Vector3) -> void:
	var ps := session.add_player(1, true)
	player = TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	add_child(player)
	player.global_position = spawn
	player.yaw = 0.0
	player.pitch = 0.0
	var fp_body := FpBody.new()
	player.add_child(fp_body)
	fp_body.setup(player)
	weapons = PlayerWeapons.new()
	add_child(weapons)
	weapons.setup(player, input, bal, rack, session)
	var vm := TacticalViewmodel.new()
	player.cam.add_child(vm)
	vm.setup(weapons, player)
	targets = RangeTargets.new()


func _add_feedback() -> void:
	hit_log = RangeHitLog.new()
	add_child(hit_log)
	var fb := RangeFeedback.new()
	add_child(fb)
	fb.setup(bal, targets, hit_log)


func _add_items() -> void:
	world_items = WorldItems.new()
	add_child(world_items)
	world_items.setup(player, weapons)


func _add_inventory() -> void:
	inv_ui = InventoryUI.new()
	add_child(inv_ui)
	inv_ui.setup(weapons, player, world_items)


func _add_hud() -> RangeHud:
	var hud := RangeHud.new()
	add_child(hud)
	hud.setup(weapons, player)
	hud.process_mode = Node.PROCESS_MODE_ALWAYS   # F19: HUD stays live while the pause menu freezes the world
	var body_hud := RangeBodyHud.new()
	hud.add_child(body_hud)
	body_hud.setup(player)
	bots = RangeBots.new()
	return hud


func _add_menu() -> void:
	player.god = args.has("god")
	if args.has("bots") and skirmish == null:
		bots.spawn_scavs()
	menu = RangeMenu.new()
	add_child(menu)
	menu.setup(session)
	menu.resumed.connect(func(): player.enabled = true)
	menu.deploy_requested.connect(func(): session.deploy(weapons.inv))
	menu.reset_requested.connect(func(): session.maps.change(session.maps.selected))
	if not args.has("shot"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_dt: float) -> void:
	if input == null:
		return
	if input.was_pressed(KEY_ESCAPE) and not (skirmish != null and skirmish.over):
		if inv_ui != null and inv_ui.is_open:
			inv_ui.close()
		elif menu.visible:
			menu.close()
		else:
			player.enabled = false
			menu.open()
	input.end_frame()
