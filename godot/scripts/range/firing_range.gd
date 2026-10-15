class_name FiringRange
extends Node3D
## Scene root for the Firing Range. Wiring only: layout, player, weapons, viewmodel, HUD, menu, shot hook.

var args := {}
var input: InputState
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
var tempest_fx: TempestFx
var skirmish: SkirmishGame   # set when the Skirmish map is selected (RangeMaps)
var cheats: RangeCheats
var cheat_menu: CheatMenu


func _ready() -> void:
	Keybinds.persist = false
	args = RangeArgs.parse()
	if args.has("map"):
		RangeMaps.selected = str(args["map"])
	process_priority = 100  # runs after the player / weapons, so end_frame() clears input last
	if args.has("range-test"):
		var t := RangeTest.new()
		add_child(t)
		await t.run()
		get_tree().quit(1 if t.failed > 0 else 0)
		return
	TacticalViewmodel.tune = args.has("tune")
	_build()
	if args.has("shot") or args.has("weapon"):
		var s := RangeShot.new()
		add_child(s)
		s.run(self)


func _build() -> void:
	input = InputState.new()
	add_child(input)
	var is_skirmish := RangeMaps.selected == "skirmish"
	if is_skirmish:
		skirmish = SkirmishGame.new()
		add_child(skirmish)
		skirmish.build_world()
	else:
		RangeLayout.build(self)
	rack = RangeRack.new()
	add_child(rack)
	if is_skirmish:
		rack.position = SkirmishData.RACK_POS
	bal = Ballistics.new()
	add_child(bal)
	var impacts := RangeImpacts.new()
	add_child(impacts)
	bal.impact.connect(impacts.on_impact)
	player = TacticalPlayer.new()
	player.input = input
	add_child(player)
	player.global_position = SkirmishData.SPAWN if is_skirmish else RangeLayout.SPAWN
	player.yaw = 0.0
	player.pitch = 0.0
	var fp_body := FpBody.new()
	player.add_child(fp_body)
	fp_body.setup(player)
	weapons = PlayerWeapons.new()
	add_child(weapons)
	weapons.setup(player, input, bal, rack)
	var vm := TacticalViewmodel.new()
	player.cam.add_child(vm)
	vm.setup(weapons, player)
	targets = RangeTargets.new()
	if not is_skirmish:
		add_child(targets)
	hit_log = RangeHitLog.new()
	add_child(hit_log)
	var fb := RangeFeedback.new()
	add_child(fb)
	fb.setup(bal, targets, hit_log)
	if not is_skirmish:
		var bench := RangeBench.new()
		add_child(bench)
		bench.setup(weapons, player, targets, hit_log)
	world_items = WorldItems.new()
	add_child(world_items)
	world_items.setup(player, weapons)
	if not is_skirmish:
		RangeCrate.build(self, world_items)
		var truck := RangeTruck.new()
		add_child(truck)
		truck.setup(weapons, player)
	inv_ui = InventoryUI.new()
	add_child(inv_ui)
	inv_ui.setup(weapons, player, world_items)
	var hud := RangeHud.new()
	add_child(hud)
	hud.setup(weapons, player)
	var body_hud := RangeBodyHud.new()
	hud.add_child(body_hud)
	body_hud.setup(player)
	bots = RangeBots.new()
	if is_skirmish:
		skirmish.start(player, weapons, bal, hit_log, hud)
		skirmish.cheats = cheats
		bots.bots = skirmish.bots
		if RangeLoadout.saved.is_empty():
			weapons.give("m1911")   # fallback only when no kit was deployed
	else:
		add_child(bots)
		bots.setup(player, weapons, bal, hit_log)
	player.god = args.has("god")
	if args.has("bots") and not is_skirmish:
		bots.spawn_scavs()
	tempest_fx = TempestFx.new()
	add_child(tempest_fx)
	tempest_fx.setup(weapons, bal, func(): return bots.bots)
	cheats = RangeCheats.new()
	add_child(cheats)
	cheats.setup(self)
	weapons.cheats = cheats
	cheat_menu = CheatMenu.new()
	add_child(cheat_menu)
	cheat_menu.setup(cheats)
	menu = RangeMenu.new()
	add_child(menu)
	menu.resumed.connect(func(): player.enabled = true)
	menu.deploy_requested.connect(func(): RangeLoadout.deploy(weapons.inv))
	menu.reset_requested.connect(func(): get_tree().reload_current_scene())
	if not args.has("shot"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_dt: float) -> void:
	if input == null:
		return
	if input.act_hidden("secret_tempest") and player.enabled and not weapons.ui_open:
		Tempest.toggle(weapons, world_items)
	if input.act_hidden("cheat_menu") and not weapons.ui_open:
		cheat_menu.toggle()
	cheats.apply_frame(_dt)
	if input.was_pressed(KEY_ESCAPE) and not (skirmish != null and skirmish.over):
		if cheat_menu.visible:
			cheat_menu.toggle()
		elif inv_ui != null and inv_ui.is_open:
			inv_ui.close()
		elif menu.visible:
			menu.close()
		else:
			player.enabled = false
			menu.open()
	input.end_frame()
