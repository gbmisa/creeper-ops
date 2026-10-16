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
	w.queue_free()
	rack.queue_free()
	player.queue_free()
	input.free()
