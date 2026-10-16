class_name RangeTestOneType
## F79: a magazine / tube holds ONE ammo type. A different type is refused, old per-round lists collapse to the
## first round's type, and a tube reload only takes the type already in the tube.


static func run(t: RangeTest) -> void:
	var m := Magazine.new(5)
	t.check("onetype: first round sets the type, same type joins", m.push("45_fmj") and m.push("45_fmj"))
	t.check("onetype: another type is refused", not m.push("45_hs") and m.count() == 2)
	m.pop()
	m.pop()
	t.check("onetype: an emptied mag takes a new type", m.push("45_hs") and m.top() == "45_hs")
	var old := Magazine.from_dict({"cap": 5, "rounds": ["45_fmj", "45_hs", "45_ap"]})
	t.check("onetype: old mixed saves collapse to the first round's type", old.rounds.count("45_fmj") == 3 and old.count() == 3)
	var inv := Inventory.new()
	var gi := inv.make("shotgun")
	var g: Gun = gi["gun"]
	g.mag.rounds.clear()
	g.chamber = ""
	g.needs_cycle = false
	inv.add(inv.make("12_buck7", {"count": 3}))
	inv.add(inv.make("12_ap20", {"count": 3}))
	var rl := InvReload.new(inv)
	var types := {}
	for i in 6:
		if rl.begin(gi, false) != "ok":
			break
		g.update(10.0)
		rl.finish(gi)
		types[g.mag.top()] = true
	t.check("onetype: tube loads %d shells of a single type" % g.mag.count(), g.mag.count() == 3 and types.size() == 1)
	var other := "12_ap20" if g.mag.top() == "12_buck7" else "12_buck7"
	var left := inv.take_round("12ga", g.mag.top())
	t.check("onetype: take_round(only) never returns another type", left == "" or left == g.mag.top() and left != other)
