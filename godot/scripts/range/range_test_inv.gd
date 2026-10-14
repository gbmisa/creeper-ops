class_name RangeTestInv
## Inventory checks (pure logic): grid fit / rotation / overlap, first_fit order, slot rules, stacks, weight, reload mag swap.


static func run(t: RangeTest) -> void:
	_grids(t)
	_slots_and_order(t)
	_weight_and_stacks(t)
	_reload(t)
	_round_trip(t)


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
	var b1 := ItemDefs.make("pack_small")
	inv.place(b1, "ground", 0, 0)
	t.check("inv: ground items obey bounds and overlap, bags included", not inv.fits("ground", ItemDefs.make("pack_small"), 1, 1, 0) \
		and not inv.fits("ground", ItemDefs.make("pack_small"), 9, 0, 0) and inv.fits("ground", ItemDefs.make("pack_small"), 3, 0, 0))
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


## Needs the scene tree: PlayerWeapons on a real player, drop -> world item -> pickup round trip.
static func world(t: RangeTest) -> void:
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	t.add_child(player)
	var rack := RangeRack.new()
	t.add_child(rack)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var bal := Ballistics.new()
	t.add_child(bal)
	weapons.setup(player, input, bal, rack)
	var wi := WorldItems.new()
	t.add_child(wi)
	wi.setup(player, weapons)
	await t.get_tree().physics_frame
	var inv := weapons.inv
	t.check("inv: player starts with the AK in hand", weapons.gun != null and weapons.gun.def["id"] == "ak47" and weapons.gun_item["loc"] == "primary")
	var start_kg := player.carried_kg
	t.check("inv: carried_kg is the inventory weight", absf(start_kg - inv.total_kg()) < 0.001 and start_kg > 3.6)
	weapons.gun.mag.rounds.resize(7)
	weapons.drop_current()
	t.check("inv: dropping the gun empties the hand and its slot", weapons.gun.def["id"] == "m1911" if weapons.gun != null else false)
	var dropped := wi.items
	t.check("inv: the dropped gun is a world item", dropped.size() == 1 and dropped[0]["id"] == "ak47")
	t.check("inv: carried weight fell by the gun", absf(player.carried_kg - (start_kg - 3.6)) < 0.001)
	var it: Dictionary = dropped[0]
	t.check("inv: the world item is found nearby and under the view", wi.nearby(it["world"].global_position, 0.1).size() == 1)
	t.check("inv: pickup puts the gun back in its slot with its rounds", wi.take(it, inv) and it["loc"] == "primary" \
		and (it["gun"] as Gun).mag.count() == 7 and wi.items.is_empty())
	weapons.sync()
	t.check("inv: weight is back after the pickup", absf(player.carried_kg - start_kg) < 0.001)
	_ui_checks(t, weapons, wi, player)
	_fill_bags(inv)
	var big := ItemDefs.make("sniper")
	for slot in ["primary", "secondary"]:
		if inv.equipped(slot) != null:
			inv.remove(inv.equipped(slot))
		inv.place(ItemDefs.make("sniper"), slot)
	wi.drop(big, Vector3(0, 0.5, 4.0))
	t.check("inv: a pickup with no room is refused and the item stays in the world", not wi.take(big, inv) and wi.items.has(big))
	t.check("inv: world items can be located by the view ray", wi.pick(Vector3(0, 0.6, 3.0), Vector3(0, 0, 1)) == big)


## Pockets, rig and backpack all full of bandages.
static func _fill_bags(inv: Inventory) -> void:
	inv.place(ItemDefs.make("pack_small"), "backpack")
	for g in Inventory.GRIDS:
		var gs := inv.grid_size(g)
		for it in inv.grid_items(g).duplicate():
			inv.remove(it)
		for y in gs.y:
			for x in gs.x:
				inv.place(ItemDefs.make("med_bandage"), g, x, y)


static func _ui_checks(t: RangeTest, weapons: PlayerWeapons, wi: WorldItems, player: TacticalPlayer) -> void:
	var inv := weapons.inv
	var ui := InventoryUI.new()
	t.add_child(ui)
	ui.setup(weapons, player, wi)
	var sn := ItemDefs.make("sniper")
	wi.drop(sn, player.eye_pos() + Vector3(0, -0.5, -1.0))
	ui.open()
	t.check("inv ui: ground grid lists items within 2 m", sn["loc"] == "ground" and inv.ground.size() == 1 and weapons.ui_open)
	ui._on_drop(sn, {"loc": "secondary", "x": 0, "y": 0, "rot": 0}, {"loc": "ground", "x": 0, "y": 0, "rot": 0})
	t.check("inv ui: dragging a ground gun onto a slot equips it and clears the world item", inv.equipped("secondary") == sn and wi.items.is_empty() and inv.ground.is_empty())
	ui._on_drop(sn, {"loc": "holster", "x": 0, "y": 0, "rot": 0}, {"loc": "secondary", "x": 0, "y": 0, "rot": 0})
	t.check("inv ui: a long gun cannot go in the holster", inv.equipped("secondary") == sn)
	var primary = inv.equipped("primary")
	ui._on_drop(sn, {"loc": "primary", "x": 0, "y": 0, "rot": 0}, {"loc": "secondary", "x": 0, "y": 0, "rot": 0})
	t.check("inv ui: dropping on an occupied slot swaps", inv.equipped("primary") == sn and inv.equipped("secondary") == primary)
	ui._on_drop(sn, {}, {"loc": "primary", "x": 0, "y": 0, "rot": 0})
	t.check("inv ui: dropping outside the window puts it on the ground", inv.equipped("primary") == null and wi.items.has(sn) and inv.ground.has(sn) and weapons.gun != null)
	ui.quick_move(sn)
	t.check("inv ui: ctrl+click on a ground gun takes it to a free slot", sn["loc"] == "primary" and wi.items.is_empty())
	ui.quick_move(sn)
	t.check("inv ui: ctrl+click on a carried item moves it elsewhere", sn["loc"] != "primary")
	ui.close()
	t.check("inv ui: closing frees the player to shoot", not weapons.ui_open)


static func _round_trip(t: RangeTest) -> void:
	var inv := _kit()
	inv.place(ItemDefs.make("pack_small"), "backpack")
	var ammo := ItemDefs.make("762_ps", {"count": 45})
	inv.place(ammo, "pack_g", 2, 1, 1)
	var mag: Dictionary = inv.find_mags("ak47")[0]
	mag["rounds"] = 11
	var g: Gun = inv.equipped("primary")["gun"]
	g.mag.rounds.resize(9)
	g.zero_idx = 2
	g.mode = "auto"
	var d := inv.to_dict()
	var back := Inventory.from_dict(d)
	var bg: Gun = back.equipped("primary")["gun"]
	var m2: Array = back.grid_items("rig_g").filter(func(i): return i["uid"] == mag["uid"])
	var a2: Array = back.grid_items("pack_g")
	t.check("inventory round-trips through to_dict/from_dict", bg.mag.count() == 9 and bg.chamber == g.chamber and bg.zero_idx == 2 and bg.mode == "auto" \
		and m2.size() == 1 and m2[0]["rounds"] == 11 and m2[0]["x"] == mag["x"] and a2.size() == 1 and a2[0]["count"] == 45 and a2[0]["rot"] == 1 \
		and a2[0]["x"] == 2 and a2[0]["y"] == 1 and absf(back.total_kg() - inv.total_kg()) < 0.001 and back.to_dict() == d, str(back.to_dict() == d))
