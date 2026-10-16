class_name RangeTestF127
## F127: M870 tube reload in Skirmish never reports "out of ammo" while the pockets still hold 12ga shells.


static func _shells(w: PlayerWeapons) -> int:
	var n := 0
	for it in w.inv.all_items():
		if it["id"] in TacAmmoDefs.ROWS and TacAmmoDefs.ROWS[it["id"]]["cal"] == "12ga":
			n += int(it["count"])
	return n


static func run(t: RangeTest) -> void:
	var r := RangeTestAmmo2._rig(t, true)
	var w: PlayerWeapons = r["w"]
	w.give("shotgun")
	var g: Gun = w.gun
	w.inv.add(w.inv.make(g.ammo_pick, {"count": 12}))
	var msgs: Array[String] = []
	w.message.connect(func(m): msgs.append(m))
	var cap := int(g.stat("mag"))
	while g.mag.count() > 0:
		g.mag.pop()
	g.chamber = ""
	g.needs_cycle = false
	var start := _shells(w)
	for i in cap:
		r["input"].frame._pressed["t_reload"] = true
		w._process(0.016)
		r["input"].frame._pressed.clear()
		w._process(10.0)
	t.check("f127: empty tube refilled by %d presses (%d/%d), msgs %s" % [cap, g.mag.count(), cap, str(msgs)], g.mag.count() == cap and msgs.is_empty())
	t.check("f127: shells conserved (%d -> %d)" % [start, _shells(w) + g.mag.count()], start == _shells(w) + g.mag.count())
	RangeTestAmmo2._free(r)
