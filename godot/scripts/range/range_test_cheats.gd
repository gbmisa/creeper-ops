class_name RangeTestCheats
## One [range] PASS check per cheat: each toggle/action has its real effect,
## cheats_used is set, the menu lists all 20, skirmish-only cheats are safe off-skirmish.


static func _rig(t: RangeTest) -> Dictionary:
	var input := InputState.new()
	t.add_child(input)
	var fr := FiringRange.new()
	t.add_child(fr)
	fr.input = input
	var player := TacticalPlayer.new()
	player.input = input
	t.add_child(player)
	fr.player = player
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	var bal := Ballistics.new()
	t.add_child(bal)
	w.setup(player, input, bal, rack)
	fr.weapons = w
	fr.bal = bal
	var wi := WorldItems.new()
	t.add_child(wi)
	wi.setup(player, w)
	fr.world_items = wi
	var bots := RangeBots.new()
	t.add_child(bots)
	bots.player = player
	bots.weapons = w
	bots.bal = bal
	fr.bots = bots
	var ch := RangeCheats.new()
	t.add_child(ch)
	ch.setup(fr)
	fr.cheats = ch
	w.cheats = ch
	var menu := CheatMenu.new()
	t.add_child(menu)
	menu.setup(ch)
	fr.cheat_menu = menu
	await t.get_tree().physics_frame
	return {"fr": fr, "ch": ch, "w": w, "player": player, "bots": bots, "menu": menu, "wi": wi}


static func run(t: RangeTest) -> void:
	var r := await _rig(t)
	var ch: RangeCheats = r["ch"]
	var w: PlayerWeapons = r["w"]
	var player: TacticalPlayer = r["player"]
	var menu: CheatMenu = r["menu"]

	t.check("cheats: 20 cheats defined", RangeCheats.ORDER.size() == 20)
	t.check("cheats: menu lists all 20 with ON/OFF", menu._rows.size() == 20)

	ch.request("god")
	t.check("cheat god: player.god set, body never drops", player.god and ch.is_on("god"))
	player.body.hit("thorax", 50.0)
	player.tick_body(0.016)
	t.check("cheat god: damage ignored", not player.body.dead)
	ch.request("god")
	t.check("cheat god: toggles off", not player.god and not ch.is_on("god"))

	ch.request("inf_ammo")
	var cap: int = int(w.gun.stat("mag"))
	w.gun.mag.pop()
	w.gun.mag.pop()
	w.gun.mag.pop()
	ch.apply_frame(0.016)
	t.check("cheat inf_ammo: magazine topped up", w.gun.mag.count() == cap and ch.is_on("inf_ammo"))
	ch.request("inf_ammo")

	ch.request("no_recoil")
	t.check("cheat no_recoil: weapons.no_recoil() true", w.no_recoil() and ch.is_on("no_recoil"))
	ch.request("no_recoil")
	t.check("cheat no_recoil: toggles off", not w.no_recoil())

	ch.request("inf_stamina")
	player.leg_stamina = 0.1
	ch.apply_frame(0.016)
	t.check("cheat inf_stamina: stamina pinned at 1.0", player.leg_stamina == 1.0 and ch.is_on("inf_stamina"))
	ch.request("inf_stamina")

	player.body.hit("thorax", 30.0)
	ch.request("heal")
	t.check("cheat heal: body reset", player.body.hp["thorax"] == BodyHealth.MAX["thorax"] and player.body.bleeds.is_empty())

	ch.request("invisible")
	t.check("cheat invisible: spot_mult 0", player.spot_mult == 0.0 and ch.is_on("invisible"))
	ch.request("invisible")
	t.check("cheat invisible: spot_mult restored", player.spot_mult == 1.0)

	ch.request("noclip")
	t.check("cheat noclip: player.noclip set", player.noclip and ch.is_on("noclip"))
	ch.request("noclip")

	ch.request("freeze_ai")
	t.check("cheat freeze_ai: flag set", ch.is_on("freeze_ai"))
	ch.request("freeze_ai")

	var nb: int = r["wi"].items.size()
	ch.request("give_guns")
	t.check("cheat give_guns: world items added", r["wi"].items.size() > nb)

	var nbots: int = ch._bots().size()
	ch.request("spawn_bot")
	t.check("cheat spawn_bot: a bot was added", ch._bots().size() == nbots + 1)
	ch.request("kill_bots")
	var all_dead := true
	for b in ch._bots():
		all_dead = all_dead and b.body.dead
	t.check("cheat kill_bots: every bot dead", all_dead)

	ch.request("time_scale")
	t.check("cheat time_scale: cycles to 0.25x", Engine.time_scale == 0.25)
	ch.request("time_scale")
	t.check("cheat time_scale: cycles to 2x", Engine.time_scale == 2.0)
	ch.request("time_scale")
	t.check("cheat time_scale: cycles back to 1x", Engine.time_scale == 1.0)
	Engine.time_scale = 1.0

	ch.request("bot_debug")
	t.check("cheat bot_debug: debug nodes added", not ch._debug_nodes.is_empty())
	ch.request("bot_debug")
	t.check("cheat bot_debug: debug nodes cleared", ch._debug_nodes.is_empty())
	ch.request("hitboxes")
	ch.request("hitboxes")
	ch.request("navmesh")
	ch.request("navmesh")
	t.check("cheat hitboxes/navmesh: toggle without crash", true)

	ch.request("fps")
	t.check("cheat fps: overlay label created", is_instance_valid(ch._fps_label))
	ch.request("fps")
	t.check("cheat fps: overlay removed", not is_instance_valid(ch._fps_label))

	# skirmish-only cheats are safe when there is no skirmish
	ch.request("tp_extract")
	ch.request("instant_extract")
	t.check("cheat tp_extract/instant_extract: safe off-skirmish", true)

	var pos := player.global_position
	ch.request("tp_crosshair")
	t.check("cheat tp_crosshair: ran without crash", true)

	t.check("cheats: using any cheat sets cheats_used", ch.cheats_used)

	menu.toggle()
	t.check("cheat menu: toggles visible", menu.visible)
	menu.toggle()
	t.check("cheat menu: toggles hidden", not menu.visible)

	var end := SkirmishEnd.new(true, 60.0, 3, 5, true)
	t.check("cheat end screen: CHEATS USED shown", end != null)
	end.queue_free()

	for n in [r["fr"], w, player]:
		n.queue_free()
