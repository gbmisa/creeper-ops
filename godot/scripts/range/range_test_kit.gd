class_name RangeTestKit
## F55: a built kit (2 guns + a pistol, fitted parts, mags, recoil toggle) survives deploy -> skirmish -> extract -> range.


static func run(t: RangeTest) -> void:
	var session := RangeSession.new(2468)
	var ps := session.add_player(1, true)
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	t.add_child(player)
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	w.setup(player, input, t.bal, rack, session)
	for it in w.inv.all_items():
		if it["loc"] in PlayerWeapons.HAND_SLOTS:
			w.inv.remove(it)
	var want := {"primary": ["mp5", ["reddot", "suppressor"]], "secondary": ["m4a1", ["compensator"]], "holster": ["glock18", ["flashhider"]]}
	for slot in want:
		var it := w.inv.make(want[slot][0])
		w.inv.place(it, slot)
		for f in want[slot][1]:
			w.inv.request_fit(it, w.inv.make(f))
	w.inv.add(w.inv.make("mag_mp5"))
	session.set_local_recoil(true)
	var before := _sig(w.inv)
	t.check("kit: built 3 guns with fitted parts", before.has("primary:mp5:reddot,suppressor") and before.has("secondary:m4a1:compensator") and before.has("holster:glock18:flashhider"))
	session.save_kit(w.inv)
	var s2 := RangeSession.new(2469)  # the new session a map load builds
	var w2 := PlayerWeapons.new()
	t.add_child(w2)
	s2.add_player(1, true)
	w2.setup(player, input, t.bal, rack, s2)
	t.check("kit: skirmish session has every gun, fit, mag and the pack", _sig(w2.inv) == before)
	t.check("kit: recoil toggle carried into the skirmish session", w2.recoil.tarkov)
	var game := SkirmishGame.new()
	t.add_child(game)
	game.build_world()
	var log := RangeHitLog.new()
	t.add_child(log)
	game.start(player, w2, t.bal, log, t, s2)
	game.finish(true)
	game.end_screen.queue_free()
	var s3 := RangeSession.new(2470)  # back in the range
	var w3 := PlayerWeapons.new()
	t.add_child(w3)
	s3.add_player(1, true)
	w3.setup(player, input, t.bal, rack, s3)
	t.check("kit: back in the range after extract, the same kit and fits", _sig(w3.inv) == before)
	t.check("kit: recoil toggle still carried after the round trip", w3.recoil.tarkov)
	s3.set_local_recoil(false)
	s3.clear_kit()
	game.queue_free()
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Sorted signature of every item: hand guns as slot:id:fits, others as id.
static func _sig(inv: Inventory) -> Array:
	var out := []
	for it in inv.all_items():
		if it.has("gun") and it["loc"] in PlayerWeapons.HAND_SLOTS:
			var fits := []
			for k in (it["gun"] as Gun).fit:
				fits.append(str((it["gun"] as Gun).fit[k]))
			fits.sort()
			out.append("%s:%s:%s" % [it["loc"], it["id"], ",".join(fits)])
		else:
			out.append(str(it["id"]))
	out.sort()
	return out
