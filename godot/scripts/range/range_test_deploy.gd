class_name RangeTestDeploy
## Deploy / extract / KIA kit carry-over checks for `--range-test` (session-owned kit).

static func run(t: RangeTest) -> void:
	var session := RangeSession.new(1234)
	var ps := session.add_player(1, true)
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	t.add_child(player)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var rack := RangeRack.new()
	t.add_child(rack)
	weapons.setup(player, input, t.bal, rack, session)
	session.clear_kit()
	var log := RangeHitLog.new()
	t.add_child(log)
	var ids := _ids(weapons.inv)
	session.save_kit(weapons.inv)
	t.check("deploy: saves the inventory", not session.saved_kit.is_empty() and _ids(Inventory.from_dict(session.saved_kit)) == ids)
	var w2 := PlayerWeapons.new()
	t.add_child(w2)
	w2.setup(player, input, t.bal, rack, session)
	t.check("skirmish start: loads the saved kit (same items)", _ids(w2.inv) == ids)
	t.check("map load: a NEW session still carries the kit", _ids(Inventory.from_dict(RangeSession.new(5).saved_kit)) == ids)
	var game := SkirmishGame.new()
	t.add_child(game)
	game.build_world()
	game.start(player, weapons, t.bal, log, t, session)
	var loot := weapons.inv.make("med_ifak", {})
	weapons.inv.add(loot)
	game.finish(true)
	t.check("extract: keeps the carried-out kit, loot included", _ids(Inventory.from_dict(session.saved_kit)).has("med_ifak") and _ids(Inventory.from_dict(session.saved_kit)).size() == ids.size() + 1)
	t.check("extract: a NEW session carries kit + loot", _ids(Inventory.from_dict(RangeSession.new(6).saved_kit)).has("med_ifak"))
	game.end_screen.queue_free()
	var g2 := SkirmishGame.new()
	t.add_child(g2)
	g2.build_world()
	g2.start(player, weapons, t.bal, log, t, session)
	g2.finish(false)
	t.check("KIA: clears the saved kit (default kit next)", session.saved_kit.is_empty())
	t.check("KIA: a NEW session has the default kit", RangeSession.new(7).saved_kit.is_empty())
	g2.end_screen.queue_free()
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.queue_free()
	g2.queue_free()


static func _ids(inv: Inventory) -> Array:
	var out := []
	for it in inv.all_items():
		out.append(it["id"])
	out.sort()
	return out
