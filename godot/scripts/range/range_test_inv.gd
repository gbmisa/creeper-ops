class_name RangeTestInv
## INV-1 data-model checks: item defs, grid fits/rotation/overlap, slot rules,
## first_fit order, reload mag swap, tube shell feed, weight sum. Pure logic.


static func run(t: RangeTest) -> void:
	_defs(t)
	_fits(t)
	_slots(t)
	_first_fit(t)
	_reload_swap(t)
	_tube(t)
	_weight(t)
	_drop_pickup(t)
	_drop_no_room(t)
	_quick_move(t)
	_crate(t)
	_keybinds(t)


static func _defs(t: RangeTest) -> void:
	var sizes := {"m1911": [2, 1], "p90": [3, 2], "ak47": [4, 2],
		"shotgun": [5, 2], "garand": [5, 2], "sniper": [5, 2]}
	var ok := true
	for wid in sizes:
		var d := ItemDefs.of(wid)
		ok = ok and d["kind"] == "gun" and d["w"] == sizes[wid][0] and d["h"] == sizes[wid][1]
	t.check("gun grid sizes match the brief", ok)
	var m := ItemDefs.of("mag_762x39")
	t.check("AK mag def", m["kind"] == "mag" and m["cap"] == 30 and m["cal"] == "762x39")
	t.check("rig grid def", (ItemDefs.of("rig_std")["grid"] as Array) == [4, 2])
	t.check("pistol flag", ItemDefs.is_pistol("m1911") and not ItemDefs.is_pistol("ak47"))


static func _rigged() -> Inventory:
	var inv := Inventory.new()
	var rig := inv.make("rig_std")
	inv.place(rig["uid"], "rig")
	return inv


static func _fits(t: RangeTest) -> void:
	var inv := _rigged()  # rig grid is 4x2
	var ak := inv.make("ak47")  # 4x2
	t.check("AK fits 4x2 rig grid unrotated", inv.fits("rig_grid", ak, 0, 0))
	ak["rot"] = 1  # 2x4: too tall
	t.check("rotated AK too tall for rig grid", not inv.fits("rig_grid", ak, 0, 0))
	ak["rot"] = 0
	var big := inv.make("pack_big")  # 4x4
	t.check("big backpack does not fit rig grid", not inv.fits("rig_grid", big, 0, 0))
	var mag := inv.make("mag_762x39")  # 1x2
	t.check("mag fits empty rig cell", inv.fits("rig_grid", mag, 0, 0))
	inv.place(mag["uid"], "rig_grid", 0, 0)
	var mag2 := inv.make("mag_762x39")
	t.check("overlap rejected", not inv.fits("rig_grid", mag2, 0, 0))
	t.check("adjacent cell fits", inv.fits("rig_grid", mag2, 1, 0))
	t.check("out of bounds rejected", not inv.fits("rig_grid", mag2, 4, 0))


static func _slots(t: RangeTest) -> void:
	var inv := Inventory.new()
	var ak := inv.make("ak47")
	var m1911 := inv.make("m1911")
	var vest := inv.make("armor_vest")
	t.check("long gun not in holster", not inv.place(ak["uid"], "holster"))
	t.check("pistol not in primary", not inv.place(m1911["uid"], "primary"))
	t.check("pistol in holster", inv.place(m1911["uid"], "holster"))
	t.check("holster holds one", not inv.place(inv.make("m1911")["uid"], "holster"))
	t.check("long gun in primary", inv.place(ak["uid"], "primary"))
	t.check("second long gun in secondary", inv.place(inv.make("ak47")["uid"], "secondary"))
	t.check("armor not in primary", not inv.place(vest["uid"], "primary"))
	t.check("armor in armor slot", inv.place(vest["uid"], "armor"))
	var rig := inv.make("rig_std")
	t.check("rig not in backpack slot", not inv.place(rig["uid"], "backpack"))
	t.check("rig in rig slot", inv.place(rig["uid"], "rig"))
	t.check("rig grid active at 4x2", (inv.grid_dim["rig_grid"] as Vector2i) == Vector2i(4, 2))


static func _first_fit(t: RangeTest) -> void:
	var inv := Inventory.new()
	var mag := inv.make("mag_762x39")
	inv.first_fit(mag)
	t.check("no rig: mag goes to pockets", str((inv.loc[mag["uid"]] as Dictionary)["c"]) == "pockets")
	var inv2 := _rigged()
	var mag2 := inv2.make("mag_762x39")
	inv2.first_fit(mag2)
	t.check("rig: mag goes to rig grid first", str((inv2.loc[mag2["uid"]] as Dictionary)["c"]) == "rig_grid")
	# fill the 4x2 rig grid with four 1x2 mags, the fifth spills to pockets
	for i in 4:
		inv2.first_fit(inv2.make("mag_762x39"))
	var spill := inv2.make("mag_45acp")
	inv2.first_fit(spill)
	t.check("full rig grid spills to pockets", str((inv2.loc[spill["uid"]] as Dictionary)["c"]) == "pockets")
	var ak := inv2.make("ak47")
	inv2.first_fit(ak)
	t.check("gun prefers primary slot", str((inv2.loc[ak["uid"]] as Dictionary)["c"]) == "primary")
	var ak2 := inv2.make("ak47")
	inv2.first_fit(ak2)
	t.check("second long gun to secondary", str((inv2.loc[ak2["uid"]] as Dictionary)["c"]) == "secondary")
	var p := inv2.make("m1911")
	inv2.first_fit(p)
	t.check("pistol to holster", str((inv2.loc[p["uid"]] as Dictionary)["c"]) == "holster")


static func _reload_swap(t: RangeTest) -> void:
	var inv := _rigged()
	var ak := inv.make("ak47")
	inv.place(ak["uid"], "primary")
	var auid: int = ak["uid"]
	var mag_a := inv.make("mag_762x39")  # inserted, full
	inv.to_gun(mag_a["uid"], auid)
	var mag_b := inv.make("mag_762x39")  # 10 rds
	mag_b["rounds"] = 10
	inv.place(mag_b["uid"], "rig_grid", 0, 0)
	var mag_c := inv.make("mag_762x39")  # 25 rds
	mag_c["rounds"] = 25
	inv.place(mag_c["uid"], "rig_grid", 1, 0)
	var cloc: Dictionary = (inv.loc[mag_c["uid"]] as Dictionary).duplicate()
	var gun := Gun.new("ak47")  # refill: mag 30 + chamber
	gun.spares.clear()
	var res := PlayerWeapons.swap_mag(inv, gun, auid, false)
	t.check("reload swap ok", bool(res["ok"]), str(res))
	t.check("fullest spare (25) chosen", gun.mag.count() == 24 and gun.chamber != "")
	t.check("new mag marked in gun", inv.mag_in_gun(auid) == mag_c["uid"])
	var old_item: Dictionary = inv.items[mag_a["uid"]]
	t.check("old mag kept with 30 rounds", int(old_item["rounds"]) == 30 and not bool(old_item["in_gun"]))
	t.check("old mag back where the new one was",
		str((inv.loc[mag_a["uid"]] as Dictionary)["c"]) == str(cloc["c"])
		and int((inv.loc[mag_a["uid"]] as Dictionary)["x"]) == int(cloc["x"]))
	# no mags left that fit: fresh gun, empty inventory
	var inv2 := _rigged()
	var gun2 := Gun.new("ak47")
	gun2.spares.clear()
	var res2 := PlayerWeapons.swap_mag(inv2, gun2, 999, false)
	t.check("no mag = no reload + message", not bool(res2["ok"]) and str(res2["msg"]).begins_with("No "))
	# fast reload drops the old mag
	var inv3 := _rigged()
	var ak3 := inv3.make("ak47")
	inv3.place(ak3["uid"], "primary")
	var ma := inv3.make("mag_762x39")
	inv3.to_gun(ma["uid"], ak3["uid"])
	var mb := inv3.make("mag_762x39")
	inv3.place(mb["uid"], "rig_grid", 0, 0)
	var gun3 := Gun.new("ak47")
	gun3.spares.clear()
	PlayerWeapons.swap_mag(inv3, gun3, ak3["uid"], true)
	t.check("fast reload drops the old mag", not inv3.items.has(ma["uid"]))


static func _tube(t: RangeTest) -> void:
	var inv := _rigged()
	var shells := inv.make("ammo_12ga")
	inv.place(shells["uid"], "pockets", 0, 0)
	var gun := Gun.new("shotgun")
	gun.spares.clear()
	gun.mag = Magazine.new(6)  # half-empty tube
	for i in 3:
		gun.mag.push("12_buck7")
	var res := PlayerWeapons.feed_shell(inv, gun, false)
	t.check("shell fed from stack", bool(res["ok"]) and gun.spares.size() == 1)
	t.check("stack decremented", int((inv.items[shells["uid"]] as Dictionary)["count"]) == 29)
	t.check("tube reload starts with fed shell", gun.reload(false))
	gun.update(5.0)
	t.check("shell lands in the tube", gun.mag.count() == 4)
	var inv2 := _rigged()
	var gun2 := Gun.new("shotgun")
	gun2.spares.clear()
	var res2 := PlayerWeapons.feed_shell(inv2, gun2, false)
	t.check("no shells = no reload + message", not bool(res2["ok"]))


static func _weight(t: RangeTest) -> void:
	var inv := _rigged()  # rig 0.8
	var ak := inv.make("ak47")  # 3.6
	inv.place(ak["uid"], "primary")
	var m1911 := inv.make("m1911")  # 1.1
	inv.place(m1911["uid"], "holster")
	var ma := inv.make("mag_762x39")  # 0.23 + 30*0.016
	inv.to_gun(ma["uid"], ak["uid"])
	var mp := inv.make("mag_45acp")  # 0.09 + 7*0.015
	inv.to_gun(mp["uid"], m1911["uid"])
	# 3.6 + 1.1 + 0.8 + (0.23+0.48) + (0.09+0.105) = 6.405
	t.check("weight sums items + mags + rounds", absf(inv.total_kg() - 6.405) < 0.01, str(inv.total_kg()))


static func _drop_pickup(t: RangeTest) -> void:
	var inv := Inventory.new()
	var ak: Dictionary = inv.make("ak47")
	inv.place(ak["uid"], "primary", 0, 0)
	var mag: Dictionary = inv.make("mag_762x39")
	inv.to_gun(mag["uid"], ak["uid"])
	var gun := Gun.new("ak47")
	var data := WorldItem.pack_gun(inv, ak["uid"], gun)
	t.check("drop packs gun and its mag", (data["items"] as Array).size() == 2)
	t.check("gun leaves the inventory", not inv.items.has(ak["uid"]))
	var placed: Array = WorldItem.unpack(inv, data)
	t.check("pickup restores both items", placed.size() == 2)
	t.check("gun back in primary", str((inv.loc[ak["uid"]] as Dictionary)["c"]) == "primary")
	var mid := inv.mag_in_gun(ak["uid"])
	t.check("mag re-attached with 30 rounds",
		mid != -1 and int((inv.items[mid] as Dictionary)["rounds"]) == 30)


static func _drop_no_room(t: RangeTest) -> void:
	var inv := Inventory.new()
	for s in ["primary", "secondary"]:
		var g: Dictionary = inv.make("ak47")
		inv.place(g["uid"], s, 0, 0)
	var ak: Dictionary = inv.make("ak47")  # never placed
	var mag: Dictionary = inv.make("mag_762x39")
	inv.to_gun(mag["uid"], ak["uid"])
	var mid := inv.mag_in_gun(ak["uid"])
	var data := {"items": [inv.items[mid], ak]}  # mag first on purpose
	inv.items.erase(ak["uid"])
	inv.items.erase(mid)
	var placed: Array = WorldItem.unpack(inv, data)
	t.check("gun does not fit anywhere", not placed.has(ak["uid"]))
	t.check("mag becomes loose", placed.has(mid) and not bool((inv.items[mid] as Dictionary)["in_gun"]))
	t.check("loose mag lands in pockets", str((inv.loc[mid] as Dictionary)["c"]) == "pockets")


static func _quick_move(t: RangeTest) -> void:
	var inv := Inventory.new()
	var rig: Dictionary = inv.make("rig_std")
	inv.place(rig["uid"], "rig", 0, 0)
	var pack: Dictionary = inv.make("pack_small")
	inv.place(pack["uid"], "backpack", 0, 0)
	var ak: Dictionary = inv.make("ak47")
	inv.place(ak["uid"], "primary", 0, 0)
	t.check("quick move slotted gun to grid", inv.quick_move(ak["uid"]))
	t.check("gun left primary", (inv.equipped("primary") as Dictionary).is_empty())
	t.check("gun in rig grid first", str((inv.loc[ak["uid"]] as Dictionary)["c"]) == "rig_grid")
	var inv2 := Inventory.new()
	var rig2: Dictionary = inv2.make("rig_std")
	inv2.place(rig2["uid"], "rig", 0, 0)
	var mag: Dictionary = inv2.make("mag_762x39")
	inv2.place(mag["uid"], "pockets", 0, 0, 1)  # 1x2 mag fits 4x1 pockets rotated
	t.check("quick move mag prefers rig", inv2.quick_move(mag["uid"]))
	t.check("mag in rig grid", str((inv2.loc[mag["uid"]] as Dictionary)["c"]) == "rig_grid")


static func _crate(t: RangeTest) -> void:
	var s := RangeCrate.default_stock()
	t.check("crate has stock", s.size() >= 15)
	var ok := true
	for id in s:
		if (ItemDefs.of(id) as Dictionary).is_empty():
			ok = false
	t.check("all crate ids valid", ok)
	t.check("crate covers mags/ammo/rig/pack/armor/med",
		s.has("mag_762x39") and s.has("ammo_12ga") and s.has("rig_std")
		and s.has("pack_big") and s.has("armor_vest") and s.has("med_ifak"))


static func _keybinds(t: RangeTest) -> void:
	t.check("t_inventory bound to Tab", Keybinds.keys("t_inventory").has(KEY_TAB))
	t.check("t_drop bound to G", Keybinds.keys("t_drop").has(KEY_G))
