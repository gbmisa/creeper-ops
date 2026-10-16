class_name RangeTestF90
## F90: deploying into Skirmish gives every hand-slot gun at least TacticalConfig.SKIRMISH_SPARE_MAGS full spare mags
## of its loaded ammo, starter kit or saved kit; spares already carried are kept (never removed).


static func _count(w: PlayerWeapons, gun_id: String) -> Array:
	var n := 0
	var full := true
	for it in w.inv.all_items():
		if it["id"] in ItemDefs.ROWS and ItemDefs.ROWS[it["id"]]["kind"] == "mag" and ItemDefs.ROWS[it["id"]]["gun"] == gun_id:
			n += 1
			full = full and int(it["rounds"]) >= int(ItemDefs.def_of(it)["cap"])
	return [n, full]


static func run(t: RangeTest) -> void:
	var want := TacticalConfig.SKIRMISH_SPARE_MAGS
	# starter kit (nothing saved) straight into Skirmish
	var s := RangeTestAmmo2._rig(t, true)
	var w: PlayerWeapons = s["w"]
	for slot in PlayerWeapons.HAND_SLOTS:
		var it = w.inv.equipped(slot)
		if it != null and it.has("gun") and it["gun"].def["action"] != "tube":
			var c := _count(w, it["gun"].def["id"])
			t.check("f90: starter kit %s carries %d full spare mags (want >= %d)" % [it["gun"].def["id"], c[0], want], c[0] >= want and c[1])
	RangeTestAmmo2._free(s)
	# a saved kit with every spare mag taken out
	var r := RangeTestAmmo2._rig(t, false)
	var rw: PlayerWeapons = r["w"]
	var session: RangeSession = r["session"]
	for it in rw.inv.all_items().duplicate():
		if ItemDefs.def_of(it)["kind"] == "mag":
			rw.inv.remove(it)
	session.save_kit(rw.inv)
	RangeTestAmmo2._free(r)
	var k := RangeTestAmmo2._rig(t, true)
	var kw: PlayerWeapons = k["w"]
	var ak: Gun = kw.inv.equipped("primary")["gun"]
	var c2 := _count(kw, ak.def["id"])
	t.check("f90: saved kit with no spares gets %d full %s mags" % [c2[0], ak.def["id"]], c2[0] >= want and c2[1])
	var typed := true
	for it in kw.inv.all_items():
		if it["id"] == "mag_" + ak.def["id"]:
			typed = typed and it["ammo"] == ak.ammo_pick
	t.check("f90: added mags hold the gun's loaded ammo (%s)" % ak.ammo_pick, typed)
	# a kit that already carries more than enough keeps them all
	for _i in want + 1:
		kw.inv.add(kw.inv.make("mag_" + ak.def["id"]))
	var before: int = _count(kw, ak.def["id"])[0]
	session.save_kit(kw.inv)
	RangeTestAmmo2._free(k)
	var m := RangeTestAmmo2._rig(t, true)
	var after: int = _count(m["w"], ak.def["id"])[0]
	t.check("f90: extra spares are kept (%d -> %d)" % [before, after], after == before)
	RangeTestAmmo2._free(m)
	session.clear_kit()
	# the range map is not touched
	var rr := RangeTestAmmo2._rig(t, false)
	var plain := Inventory.new()
	StarterLoadout.fill(plain)
	var base := 0
	for it in plain.all_items():
		if it["id"] == "mag_ak47":
			base += 1
	var got: int = _count(rr["w"], "ak47")[0]
	t.check("f90: range start keeps the starter kit's %d AK mags (%d)" % [base, got], got == base)
	RangeTestAmmo2._free(rr)
