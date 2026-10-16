class_name RangeTestF81
## F81: the range never runs dry. Real path: RangeSession (maps.selected left at its default, NOT forced infinite),
## PlayerWeapons.setup (StarterLoadout kit), every gun, real R presses through PlayerWeapons._process.

const VERBOSE := false


static func _rig(t: RangeTest, id: String, map: String = "range") -> Dictionary:
	var session := RangeSession.new(81)
	session.maps.selected = map
	var input := InputState.new()
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	session.add_player(1, true).node = player
	t.add_child(player)
	player.set_physics_process(false)
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	w.setup(player, input, t.bal, rack, session)
	w.set_process(false)
	w.give(id)
	player.enabled = true
	return {"w": w, "input": input, "player": player, "rack": rack}


static func _press(r: Dictionary, w: PlayerWeapons, dt: float = 1.0 / 60.0) -> void:
	r["input"].frame._pressed["t_reload"] = true
	w._process(dt)
	r["input"].frame._pressed.clear()


static func _settle(w: PlayerWeapons, secs: float = 20.0) -> void:
	var el := 0.0
	while el < secs and w.gun.busy_kind != "":
		w._process(1.0 / 60.0)
		el += 1.0 / 60.0


static func _drain(g: Gun, left: int) -> void:
	while g.mag.count() > left:
		g.mag.pop()
	if left == 0:
		g.chamber = ""
	g.needs_cycle = false
	g.fire_cd = 0.0


static func run(t: RangeTest) -> void:
	for id in WeaponDefs.ORDER:
		var r := _rig(t, id)
		var w: PlayerWeapons = r["w"]
		var g := w.gun
		var cap := int(g.stat("mag"))
		var tube: bool = g.def["action"] == "tube"
		var enbloc: bool = g.def["action"] == "enbloc"
		var bad := []
		var inv_before := _loose(w.inv)
		for k in 10:
			_drain(g, 0 if (enbloc or k % 2 == 0) else 1 + k % 3)
			var presses := cap - g.mag.count() if tube else 1
			for p in presses:
				_press(r, w)
				if k % 3 == 2 and p == 0 and not tube:  # double tap mid-animation (fast reload)
					w._process(0.1)
					_press(r, w, 0.05)
				_settle(w)
			var total: int = g.rounds_total()
			if VERBOSE or total < cap - 1 or g.busy_kind != "" or not g.spares.is_empty() or w.gun_item.has("staged") or g.ammo_pick == "":
				bad.append("c%d inf=%s pick=%s staged=%s mag=%d tot=%d/%d" % [k, w.reloader.infinite, g.ammo_pick, w.gun_item.has("staged"), g.mag.count(), total, cap])
		t.check("F81 range: %s ends full 10x via real presses %s" % [id, bad.slice(0, 2)], bad.is_empty())
		t.check("F81 range: %s leaves the inventory untouched" % id, _loose(w.inv) == inv_before)
		_free(r)


## Fuzz: random fire / R / double R / slot switch / menu open / bench ammo change / drop+re-take, then one clean R
## must leave a full gun that fires. Logs infinite / ammo_pick / staged / mag per failing gun.
static func fuzz(t: RangeTest) -> void:
	for id in WeaponDefs.ORDER:
		var r := _rig(t, id)
		var w: PlayerWeapons = r["w"]
		var rng := RandomNumberGenerator.new()
		rng.seed = 81
		var bad := ""
		for step in 60:
			var g := w.gun
			match rng.randi() % 8:
				0, 1:
					_drain(g, rng.randi() % 3)
					_press(r, w)
				2:
					_press(r, w)
					w._process(rng.randf() * 0.4)
					_press(r, w)
				3:
					w.select_slot("holster" if w.gun_item["loc"] == "primary" else "primary")
				4:
					w.ui_open = true
					w._process(rng.randf())
					w.ui_open = false
				5:
					if w.gun.def["action"] != "tube":
						_press(r, w)
					for i in rng.randi() % 40:
						w._process(1.0 / 60.0)
				6:
					RangeBench.cycle_ammo(w.gun)
					w.reload_cancel()
					w.refill_mags()
				7:
					_settle(w)
		_settle(w)
		var g := w.gun
		_drain(g, 0)
		var cap := int(g.stat("mag"))
		for p in (cap if g.def["action"] == "tube" else 1):
			_press(r, w)
			_settle(w)
		if g.rounds_total() < cap - 1 or w.gun_item.has("staged") or not g.spares.is_empty():
			bad = "inf=%s pick=%s staged=%s mag=%d/%d spares=%d" % [w.reloader.infinite, g.ammo_pick, w.gun_item.has("staged"), g.mag.count(), cap, g.spares.size()]
		t.check("F81 fuzz: %s full after a clean R %s" % [id, bad], bad == "")
		_free(r)


## Everything but the guns themselves (their mags change when fired).
static func _loose(inv: Inventory) -> String:
	var out := []
	for it in inv.all_items():
		if not it.has("gun"):
			out.append(it["id"] + str(it.get("rounds", it.get("count", 0))) + str(it.get("ammo", "")))
	return str(out)


static func _free(r: Dictionary) -> void:
	r["w"].free()
	r["rack"].free()
	r["player"].free()
	r["input"].free()
