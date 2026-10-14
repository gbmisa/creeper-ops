class_name RangeTestDeploy
## Deploy / extract / KIA kit carry-over checks for `--range-test`.

static func run(t: RangeTest) -> void:
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	t.add_child(player)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var rack := RangeRack.new()
	t.add_child(rack)
	weapons.setup(player, input, t.bal, rack)
	RangeLoadout.clear()
	var ids := _ids(weapons.inv)
	RangeLoadout.save(weapons.inv)
	t.check("deploy: saves the inventory", not RangeLoadout.saved.is_empty() and _ids(Inventory.from_dict(RangeLoadout.saved)) == ids)
	var w2 := PlayerWeapons.new()
	t.add_child(w2)
	w2.setup(player, input, t.bal, rack)
	t.check("skirmish start: loads the saved kit (same items)", _ids(w2.inv) == ids)
	var game := SkirmishGame.new()
	t.add_child(game)
	game.player = player
	game.weapons = weapons
	var loot := ItemDefs.make("med_ifak", {})
	weapons.inv.add(loot)
	game.finish(true)
	t.check("extract: keeps the carried-out kit, loot included", _ids(Inventory.from_dict(RangeLoadout.saved)).has("med_ifak") and _ids(Inventory.from_dict(RangeLoadout.saved)).size() == ids.size() + 1)
	game.end_screen.queue_free()
	var g2 := SkirmishGame.new()
	t.add_child(g2)
	g2.player = player
	g2.weapons = weapons
	g2.finish(false)
	t.check("KIA: clears the saved kit (default kit next)", RangeLoadout.saved.is_empty())
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
