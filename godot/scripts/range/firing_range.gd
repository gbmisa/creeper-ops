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
var inv_ui: InventoryUI
var crate: RangeCrate
var world_items: Array = []


func _ready() -> void:
	Keybinds.persist = false
	args = RangeArgs.parse()
	process_priority = 100  # runs after the player / weapons, so end_frame() clears input last
	if args.has("range-test-logic"):
		var tl := RangeTest.new()
		RangeTestLogic.run(tl)
		print("[range] LOGIC: %d passed, %d failed" % [tl.passed, tl.failed])
		get_tree().quit(1 if tl.failed > 0 else 0)
		return
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
	crate = RangeCrate.new()
	add_child(crate)
	crate.position = RangeLayout.RACK_POS + Vector3(2.2, 0, 0)
	inv_ui = InventoryUI.new()
	add_child(inv_ui)
	inv_ui.setup(player, weapons)
	inv_ui.world_items = world_items
	weapons.world_items = world_items
	weapons.drop_requested.connect(_on_drop_requested)
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
		if menu.visible:
			menu.close()
		else:
			player.enabled = false
			menu.open()
	if not menu.visible and player.enabled and input.act("t_inventory"):
		inv_ui.toggle()
	if not menu.visible and player.enabled and not inv_ui.is_open and input.act("t_drop"):
		weapons.drop_held()
	_take_from_crate()
	input.end_frame()


## Supply crate: F takes the next stocked item via first_fit (only when nothing
## else claimed the use prompt this frame).
func _take_from_crate() -> void:
	if crate == null or not player.enabled or inv_ui.is_open or weapons.prompt != "":
		return
	var cid := crate.pick(player.eye_pos())
	if cid == "":
		return
	weapons.prompt = "%s: take %s (crate)" % [Keybinds.short("t_use"), ItemDefs.of(cid)["name"]]
	if input.act("t_use"):
		var id := crate.take_next()
		var item := weapons.inv.make(id)
		if weapons.inv.first_fit(item):
			weapons.sync_weight()
		else:
			weapons.inv.remove(item["uid"])
			weapons.message.emit("No room for %s" % ItemDefs.of(id)["name"])


## An inventory item dropped to the ground becomes a physics pickup in front of the player.
func _on_drop_requested(data: Dictionary) -> void:
	var wi := WorldItem.make_node(data)
	var fwd := -player.cam.global_basis.z
	fwd.y = 0.0
	wi.position = player.global_position + fwd.normalized() * 1.2 + Vector3(0, 0.6, 0)
	add_child(wi)
	world_items.append(wi)
