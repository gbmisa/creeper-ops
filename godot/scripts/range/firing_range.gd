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


func _ready() -> void:
	Keybinds.persist = false
	args = RangeArgs.parse()
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
	RangeLayout.build(self)
	rack = RangeRack.new()
	add_child(rack)
	bal = Ballistics.new()
	add_child(bal)
	var impacts := RangeImpacts.new()
	add_child(impacts)
	bal.impact.connect(impacts.on_impact)
	player = TacticalPlayer.new()
	player.input = input
	add_child(player)
	player.global_position = RangeLayout.SPAWN
	player.yaw = 0.0
	player.pitch = 0.0
	weapons = PlayerWeapons.new()
	add_child(weapons)
	weapons.setup(player, input, bal, rack)
	var vm := TacticalViewmodel.new()
	player.cam.add_child(vm)
	vm.setup(weapons, player)
	targets = RangeTargets.new()
	add_child(targets)
	hit_log = RangeHitLog.new()
	add_child(hit_log)
	var fb := RangeFeedback.new()
	add_child(fb)
	fb.setup(bal, targets, hit_log)
	var bench := RangeBench.new()
	add_child(bench)
	bench.setup(weapons, player, targets, hit_log)
	world_items = WorldItems.new()
	add_child(world_items)
	world_items.setup(player, weapons)
	RangeCrate.build(self, world_items)
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
	add_child(bots)
	bots.setup(player, weapons, bal, hit_log)
	player.god = args.has("god")
	if args.has("bots"):
		bots.spawn_scavs()
	menu = RangeMenu.new()
	add_child(menu)
	menu.resumed.connect(func(): player.enabled = true)
	menu.reset_requested.connect(func(): get_tree().reload_current_scene())
	if not args.has("shot"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_dt: float) -> void:
	if input == null:
		return
	if input.was_pressed(KEY_ESCAPE):
		if inv_ui != null and inv_ui.is_open:
			inv_ui.close()
		elif menu.visible:
			menu.close()
		else:
			player.enabled = false
			menu.open()
	input.end_frame()
