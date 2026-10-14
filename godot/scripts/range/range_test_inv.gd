class_name RangeTestInv
## Inventory checks (pure logic): grid fit / rotation / overlap, first_fit order, slot rules, stacks, weight, reload mag swap.


static func run(t: RangeTest) -> void:
	_grids(t)
	_slots_and_order(t)
	_weight_and_stacks(t)
	_reload(t)


static func _kit() -> Inventory:
	var inv := Inventory.new()
	StarterLoadout.fill(inv)
	return inv


static func _grids(t: RangeTest) -> void:
	var inv := _kit()
	var pk := ItemDefs.make("pack_small")
	inv.place(pk, "backpack")
	var med := ItemDefs.make("med_ifak")  # 1x2
	t.check("inv: item fits an empty cell", inv.fits("pack_g", med, 0, 0, 0))
	t.check("inv: out of bounds is refused", not inv.fits("pack_g", med, 4, 0, 0) and not inv.fits("pack_g", med, 0, 3, 0))
	t.check("inv: rotation swaps the footprint", inv.fits("pack_g", med, 2, 3, 1) and not inv.fits("pack_g", med, 3, 3, 1))
	inv.place(med, "pack_g", 1, 1, 0)
	var other := ItemDefs.make("med_ifak")
	t.check("inv: overlap is refused", not inv.fits("pack_g", other, 1, 2, 0) and inv.fits("pack_g", other, 2, 1, 0))
	t.check("inv: an item ignores itself when moved within a grid", inv.fits("pack_g", med, 1, 2, 0))
	var ak := ItemDefs.make("ak47")
	t.check("inv: pockets are 1x1 only", not inv.fits("pockets", ak, 0, 0, 0) and inv.fits("pockets", ItemDefs.make("med_bandage"), 3, 0, 0))
	t.check("inv: bags cannot go inside grids", not inv.fits("pack_g", ItemDefs.make("rig_chest"), 0, 0, 0))


static func _slots_and_order(t: RangeTest) -> void:
	var inv := _kit()
	var ak = inv.equipped("primary")
	t.check("inv: start kit is AK primary + 1911 holster + rig", ak != null and ak["id"] == "ak47" and inv.equipped("holster")["id"] == "m1911" \
		and inv.equipped("rig") != null)
	var rig_mags: Array = inv.grid_items("rig_g").filter(func(i): return i["id"] == "mag_ak47")
	t.check("inv: start rig holds 3 AK mags and 2 pistol mags", rig_mags.size() == 3 and inv.grid_items("rig_g").size() == 5)
	var sniper := ItemDefs.make("sniper")
	t.check("inv: long gun is refused by the holster, accepted by secondary", not inv.fits("holster", sniper, 0, 0) and inv.fits("secondary", sniper, 0, 0))
	t.check("inv: pistol is refused by primary", not inv.fits("primary", ItemDefs.make("m1911"), 0, 0))
	t.check("inv: first_fit prefers an equipment slot", inv.first_fit(sniper)["loc"] == "secondary")
	inv.add(sniper)
	var p90 := ItemDefs.make("p90")  # 3x2, primary and secondary taken, rig is full of mags, no pockets fit it, no backpack
	t.check("inv: a gun with no slot, rig or pocket space does not fit", inv.first_fit(p90).is_empty())
	var pack := ItemDefs.make("pack_big")
	inv.add(pack)
	t.check("inv: backpack goes to its slot", pack["loc"] == "backpack")
	var to := inv.first_fit(p90)
	t.check("inv: then the gun falls through to the backpack grid", to.get("loc", "") == "pack_g")
	var m := ItemDefs.make("med_bandage")
	t.check("inv: small items go to pockets when the rig is full", inv.first_fit(m)["loc"] == "pockets")
	var f := ItemDefs.make("med_ifak")
	inv.add(f)
	inv.add(ItemDefs.make("med_ifak"))
	inv.remove(f)
	t.check("inv: remove clears the item's place", f["loc"] == "")


static func _weight_and_stacks(t: RangeTest) -> void:
	var inv := Inventory.new()
	t.check("inv: empty weight is 0", inv.total_kg() == 0.0)
	var ak := ItemDefs.make("ak47")
	inv.add(ak)
	t.check("inv: weight sums the gun", absf(inv.total_kg() - 3.6) < 0.001)
	var rig := ItemDefs.make("rig_chest")
	inv.add(rig)
	var mag := ItemDefs.make("mag_ak47")
	inv.add(mag)
	var expect: float = 3.6 + 0.8 + 0.25 + 30 * ItemDefs.ROUND_KG["762x39"]
	t.check("inv: weight counts bag contents and mag rounds", absf(inv.total_kg() - expect) < 0.001, str(inv.total_kg()))
	inv.remove(ak)
	t.check("inv: weight follows removal", absf(inv.total_kg() - (expect - 3.6)) < 0.001)
	var a := ItemDefs.make("762_ps", {"count": 80})
	var b := ItemDefs.make("762_ps", {"count": 30})
	inv.add(a)
	inv.add(b)
	t.check("inv: loose ammo stacks up to the cap", int(a["count"]) == 90 and int(b["count"]) == 20, "%d %d" % [a["count"], b["count"]])
	t.check("inv: stack total is kept", _stack_total(inv) == 110)
	var bag_in_bag := ItemDefs.make("pack_small")
	inv.add(bag_in_bag)
	var moved := inv.move(rig, {"loc": "ground", "x": 0, "y": 0})
	t.check("inv: a bag carries its contents to the ground", moved and rig["items"].size() > 0 and inv.equipped("rig") == null and inv.ground.size() == 1)


static func _stack_total(inv: Inventory) -> int:
	var n := 0
	for it in inv.all_items():
		if it["id"] == "762_ps":
			n += int(it["count"])
	return n


static func _reload(t: RangeTest) -> void:
	var inv := _kit()
	var gi: Dictionary = inv.equipped("primary")
	var g: Gun = gi["gun"]
	var rl := InvReload.new(inv)
	var rig_items: Array = inv.grid_items("rig_g")
	var spare_a: Dictionary = rig_items.filter(func(i): return i["id"] == "mag_ak47")[0]
	spare_a["rounds"] = 10
	var best: Dictionary = rig_items.filter(func(i): return i["id"] == "mag_ak47")[1]
	var best_pos := Vector2i(best["x"], best["y"])
	t.check("reload: fullest compatible mag is chosen", inv.find_mags("ak47")[0]["uid"] != spare_a["uid"])
	g.mag.rounds.resize(12)
	t.check("reload: begin takes the mag out of the rig", rl.begin(gi, false) == "ok" and inv.find_mags("ak47").size() == 2)
	g.update(5.0)
	var left := rl.finish(gi)
	var back: Array = inv.grid_items("rig_g").filter(func(i): return i["id"] == "mag_ak47" and int(i["rounds"]) == 12)
	t.check("reload: old mag returns to the freed spot", left.is_empty() and back.size() == 1 \
		and Vector2i(back[0]["x"], back[0]["y"]) == best_pos, str(back.size()))
	t.check("reload: gun now holds a full mag", g.mag.count() >= 29)
	var fast := rl.begin(gi, true)
	var before := inv.find_mags("ak47").size()
	g.update(5.0)
	rl.finish(gi)
	t.check("reload: fast reload drops the old mag (not returned)", fast == "ok" and inv.find_mags("ak47").size() == before)
	var empty := Inventory.new()
	var gi2 := ItemDefs.make("ak47")
	(gi2["gun"] as Gun).spares.clear()
	empty.place(gi2, "primary")
	t.check("reload: no magazine means no reload", InvReload.new(empty).begin(gi2, false) == "none" and not (gi2["gun"] as Gun).busy())
	var sg := ItemDefs.make("shotgun")
	(sg["gun"] as Gun).spares.clear()
	(sg["gun"] as Gun).mag.rounds.resize(3)
	var inv3 := Inventory.new()
	inv3.place(sg, "primary")
	inv3.place(ItemDefs.make("rig_chest"), "rig")
	var shells := ItemDefs.make("12_buck7", {"count": 2})
	inv3.add(shells)
	var rl3 := InvReload.new(inv3)
	t.check("reload: shotgun takes one loose shell", rl3.begin(sg, false) == "ok" and int(shells["count"]) == 1)
	(sg["gun"] as Gun).update(5.0)
	rl3.finish(sg)
	t.check("reload: shell lands in the tube", (sg["gun"] as Gun).mag.count() == 4)
	var cancel_gi: Dictionary = inv.equipped("primary")
	var n := inv.find_mags("ak47").size()
	rl.begin(cancel_gi, false)
	rl.cancel(cancel_gi)
	t.check("reload: cancel gives the mag back", inv.find_mags("ak47").size() == n and not (cancel_gi["gun"] as Gun).busy())
