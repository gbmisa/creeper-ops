class_name RangeTestBow
## F146: the compound bow and crossbow. A full-draw arrow flies, drops and sticks in a wall; picking it up returns it
## to the inventory; a short draw lets down without shooting; reload nocks one loose arrow from the bags.


static func run(t: RangeTest) -> void:
	_sights_and_places(t)
	await _flight(t)


static func _sights_and_places(t: RangeTest) -> void:
	for id in ["compound_bow", "crossbow"]:
		var d := WeaponDefs.of(id)
		var ok: Array = []
		for a in AttachmentDefs.ROWS.keys():
			if AttachmentDefs.why_not(d, a) == "":
				ok.append(a)
		t.check("%s: takes exactly 3 optics (red dot, holo, ACOG), nothing else" % id, ok.size() == 3 and "reddot" in ok and "holo" in ok and "acog3x" in ok, str(ok))
		var g := Gun.new(id)
		g.set_fit("sight", "acog3x")
		t.check("%s: ACOG zooms 3x and moves the sight line" % id, is_equal_approx(g.stat("scope"), 3.0) and g.eff_def()["ads_pos"] != d["ads_pos"])
		t.check("%s: has ADS sight points (mounts.json), so the irons are placed" % id, not AdsPose.points(d, "", 0.4).is_empty())
	var in_rack := 0
	for row in RangeRack.GRID:
		in_rack += int("compound_bow" in row) + int("crossbow" in row)
	var crate := RangeCrate.LOOT.map(func(r): return r[0])
	t.check("bows: on the rack, arrows and bolts in the crate", in_rack == 2 and "arrow_field" in crate and "bolt_broad" in crate)
	t.check("bows: not in the 17-gun roster", not WeaponDefs.ORDER.has("compound_bow") and not WeaponDefs.ROWS.has("crossbow"))
	var sup: float = BotNoise.SHOT_R * AttachmentDefs.ROWS["suppressor"]["mods"]["noise"]
	var bow_r: float = BotNoise.SHOT_R * Gun.new("compound_bow").stat("noise")
	t.check("bow: bots hear a shot at 1/5 of a suppressed gun's range", is_equal_approx(bow_r * 5.0, sup), "%f vs %f" % [bow_r, sup])
	t.check("bows: own sounds (twang, thunk, thud) exist", RangeAudio.stream(SoundDefs.gun_event("compound_bow", "shot", "arrow", "bow")) != null
		and RangeAudio.stream(SoundDefs.gun_event("crossbow", "shot", "bolt", "crossbow")) != null and RangeAudio.stream("arrow_thud") != null)
	var gun := Gun.new("compound_bow")
	t.check("bows: bench wording is arrows / bolts", HandGear.refill_word(gun, false) == "arrows" and HandGear.refill_word(Gun.new("crossbow"), false) == "bolts")


static func _flight(t: RangeTest) -> void:
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	var session := RangeSession.new(4244)
	session.add_player(1, true).node = player
	player.session = session
	t.add_child(player)
	player.global_position = Vector3(200, 0, 0)
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	var bal := Ballistics.new()
	bal.auto_step = false
	t.add_child(bal)
	w.setup(player, input, bal, rack, session)
	var wi := WorldItems.new()
	t.add_child(wi)
	wi.setup(player, w)
	var fx := ArrowFx.new()
	t.add_child(fx)
	fx.setup(w, bal, wi)
	t._wall(Vector3(200, 2, -40.25), Vector3(8, 8, 0.5), "plywood", 0.5)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	w.reloader.infinite = false
	w.inv.remove(w.inv.equipped("primary"))
	w.give("compound_bow")
	t.check("bow: takes the primary slot and is in hand", w.inv.equipped("primary") != null and w.gun != null and w.gun.id == "compound_bow")
	w.draw_t = 0.0
	var arrows := func() -> int:
		var n := 0
		for it in w.inv.all_items():
			if it["id"] == "arrow_field":
				n += int(it["count"])
		return n
	w.inv.add(w.inv.make("arrow_field", {"count": 5}))
	t.check("bow: comes with one arrow nocked, none in the mag", w.gun.chamber == "arrow_field" and w.gun.mag.count() == 0)
	# short draw: let down without shooting
	for i in 3:
		BowDraw.tick(w, true, i == 0, true, 0.05)
	BowDraw.tick(w, false, false, false, 0.016)
	t.check("bow: releasing before 25% draw lets down, the arrow stays nocked", w.gun.chamber == "arrow_field" and bal.shots.is_empty() and w.bow_draw == 0.0)
	# full draw
	for i in 10:
		BowDraw.tick(w, true, i == 0, true, 0.1)
	t.check("bow: full draw after ~0.8 s", w.bow_draw >= 1.0 and w.bow_hold > 0.0)
	BowDraw.tick(w, false, false, false, 0.016)
	t.check("bow: release shoots one arrow, nothing nocked after", bal.shots.size() == 1 and w.gun.chamber == "")
	var v0: float = TacAmmoDefs.of("arrow_field")["v0"]
	t.check("bow: full draw leaves at the arrow's v0", absf((bal.shots[0]["vel"] as Vector3).length() - v0) < 1.0)
	var y0: float = (bal.shots[0]["pos"] as Vector3).y
	for i in 900:
		if bal.shots.is_empty():
			break
		bal.step(1.0 / 60.0)
	t.check("bow: the arrow stuck in the wall and can be looked at", wi.items.size() == 1 and wi.items[0]["id"] == "arrow_field" and fx._stuck.size() == 1)
	var hit_y: float = (wi.items[0]["world"] as Node3D).global_position.y
	var sight_y: float = player.eye_pos().y
	t.check("bow: visible drop at 40 m past the 20 m zero (more than 0.3 m under the sight line)", sight_y - hit_y > 0.3 and y0 > hit_y, "eye %.2f hit %.2f" % [sight_y, hit_y])
	var before: int = arrows.call()
	t.check("bow: taking the stuck arrow puts it back in the inventory", wi.take(wi.items[0], w.inv) and arrows.call() == before + 1 and wi.items.is_empty())
	# reload nocks one loose arrow
	var left: int = arrows.call()
	w.start_reload(false)
	t.check("bow: reload takes one arrow from the bags", w.gun.busy_kind == "reload" and arrows.call() == left - 1)
	for i in 400:
		w.gun.update(0.01)
	w.reloader.finish(w.gun_item)
	t.check("bow: nocked again after the reload", w.gun.chamber == "arrow_field")
	# crossbow: fire shoots at once, reload ~3.5 s x reload speed
	w.give("crossbow")
	var cb: Dictionary = {}
	for it in w.inv.all_items():
		if it["id"] == "crossbow":
			cb = it
	t.check("crossbow: row, bolt stacks and nocked bolt exist", not cb.is_empty() and (cb["gun"] as Gun).chamber == "bolt_field" and ItemDefs.has("bolt_broad"))
	var g: Gun = cb["gun"]
	var res := g.fire(w.rng)
	var pouch := Magazine.new(1)
	pouch.push("bolt_field")
	g.spares.append(pouch)
	g.fire_cd = 0.0
	t.check("crossbow: fire shoots one bolt, then cock + load takes 3.5 s", res["fired"] and g.chamber == "" and g.reload() and is_equal_approx(g.busy_t, 3.5))
	for n in [input, player, rack, w, bal, wi, fx]:
		n.queue_free()
