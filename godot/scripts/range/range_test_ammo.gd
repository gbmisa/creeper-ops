class_name RangeTestAmmo
## F62: the range map gives infinite ammo (every action kind reloads full, 3 times, inventory untouched);
## a skirmish-style reloader (infinite off) runs out of spares as before.


static func _empty(g: Gun) -> void:
	g.mag.rounds.clear()
	g.chamber = ""
	g.needs_cycle = false
	g.fire_cd = 0.0


## One reload on an emptied gun, finished the way PlayerWeapons does it. Returns begin()'s answer.
static func _reload(rl: InvReload, gi: Dictionary) -> String:
	var g: Gun = gi["gun"]
	_empty(g)
	var r := rl.begin(gi, false)
	if r == "ok":
		g.update(10.0)
		rl.finish(gi)
	return r


static func run(t: RangeTest) -> void:
	t.check("ammo: range map is in the infinite list, skirmish is not", "range" in RangeMaps.INFINITE_AMMO and not ("skirmish" in RangeMaps.INFINITE_AMMO))
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		var inv := Inventory.new()
		var gi := inv.make(id)
		var g: Gun = gi["gun"]
		g.spares.clear()
		g.ammo_pick = TacAmmoDefs.grades(d["cal"])[0]
		var rl := InvReload.new(inv)
		rl.infinite = true
		var n_items := inv.all_items().size()
		var full := true
		for k in 3:
			if d["action"] == "tube":
				var shells := 0
				_empty(g)
				while not g.mag.is_full() and shells < 40:
					var r := rl.begin(gi, false)
					if r != "ok":
						full = false
						break
					g.update(10.0)
					rl.finish(gi)
					shells += 1
				full = full and g.mag.is_full()
			else:
				full = full and _reload(rl, gi) == "ok" and g.mag.count() + (1 if g.chamber != "" else 0) == int(g.stat("mag"))
				full = full and (g.chamber == g.ammo_pick or g.chamber == "") and g.mag.top() == g.ammo_pick
		t.check("ammo: %s (%s) range reloads 3x, each full" % [id, d["action"]], full)
		t.check("ammo: %s range reload leaves the inventory alone" % id, inv.all_items().size() == n_items and g.spares.is_empty())
		# Skirmish rules: no spares, no reload.
		var inv2 := Inventory.new()
		var gi2 := inv2.make(id)
		(gi2["gun"] as Gun).spares.clear()
		_empty(gi2["gun"])
		t.check("ammo: %s without the flag has nothing to reload" % id, InvReload.new(inv2).begin(gi2, false) == "none")
	# Skirmish: one carried mag reloads once, then runs dry.
	var inv3 := Inventory.new()
	var gi3 := inv3.make("m4a1")
	var rl3 := InvReload.new(inv3)
	inv3.add(inv3.make("mag_m4a1"))
	var first := _reload(rl3, gi3)
	var second := _reload(rl3, gi3)
	var count_after := inv3.find_mags("m4a1").size()
	t.check("ammo: skirmish reloader uses the carried mag, then only the emptied one is left", first == "ok" and second == "none" and count_after == 0)
