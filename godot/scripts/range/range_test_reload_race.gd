class_name RangeTestReloadRace
## F66: pressing R on the very frame a reload finishes must not start a second reload on the stale old (empty) mag
## ("Reload played, still empty"). Drives PlayerWeapons._process by hand with a scripted R press.


static func run(t: RangeTest) -> void:
	var session := RangeSession.new(66)
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
	w.reloader.infinite = true
	w.give("mp5")
	player.enabled = true
	var g := w.gun
	while g.mag.count() > 0:
		g.mag.pop()
	g.chamber = ""
	w.start_reload(false)
	w._process(g.busy_t - 0.01)  # just short of done
	input.frame._pressed["t_reload"] = true
	w._process(0.05)  # the reload finishes inside this frame, R is pressed in it
	input.frame._pressed.clear()
	w._process(10.0)
	t.check("reload race: R on the finishing frame leaves a full gun (%d)" % g.mag.count(), g.mag.count() >= int(g.stat("mag")) - 1 and g.chamber != "")
	t.check("reload race: no stale staged reload left", not w.gun_item.has("staged") and g.spares.is_empty())
	w.free()
	rack.free()
	player.free()
	input.free()


## F66b: a second R at any point of a reload (inside DOUBLE_TAP = fast reload, later = ignored) must still end with a
## full gun that can fire. Plain and empty, three guns.
static func second_r(t: RangeTest) -> void:
	for id in ["mp5", "ak47", "glock18"]:
		for empty in [true, false]:
			var bad := []
			for at in [0.0, 0.1, 0.25, 0.4, 0.8, 1.5, 2.2]:
				var r := _rig(t, id, empty)
				var w: PlayerWeapons = r["w"]
				var g := w.gun
				w.start_reload(false)
				var el := 0.0
				var pressed := false
				while el < 6.0:
					if not pressed and el >= at:
						r["input"].frame._pressed["t_reload"] = true
						pressed = true
					w._process(1.0 / 60.0)
					r["input"].frame._pressed.clear()
					el += 1.0 / 60.0
				g.fire_cd = 0.0
				var res := g.fire(RandomNumberGenerator.new())
				if g.rounds_total() < int(g.stat("mag")) - 1 or g.busy_kind != "" or g.chamber == "" or res["reason"] == "empty":
					bad.append("%.2f:%d" % [at, g.rounds_total()])
				_free(r)
			t.check("second R: %s %s ends full and fires %s" % [id, "empty" if empty else "partial", bad], bad.is_empty())


static func _rig(t: RangeTest, id: String, empty: bool) -> Dictionary:
	var session := RangeSession.new(66)
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
	w.reloader.infinite = true
	w.give(id)
	player.enabled = true
	if empty:
		while w.gun.mag.count() > 0:
			w.gun.mag.pop()
		w.gun.chamber = ""
	return {"w": w, "input": input, "player": player, "rack": rack}


static func _free(r: Dictionary) -> void:
	r["w"].free()
	r["rack"].free()
	r["player"].free()
	r["input"].free()
