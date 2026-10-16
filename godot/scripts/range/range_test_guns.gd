class_name RangeTestGuns
## RANGE5 GUNS-1 checks: all 17 guns build, fire and reload with their mag; each line's later tier wins on its stated advantage.

static func _pen(id: String) -> float:
	return TacAmmoDefs.of(TacAmmoDefs.grades(WeaponDefs.of(id)["cal"])[0])["pen"]


static func _dmg(id: String) -> float:
	return TacAmmoDefs.of(TacAmmoDefs.grades(WeaponDefs.of(id)["cal"])[0])["dmg"]


static func run(t: RangeTest) -> void:
	_each_gun(t)
	_lines(t)
	_specials(t)
	_rack_and_crate(t)


static func _each_gun(t: RangeTest) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var rl := InvReload.new(Inventory.new())
	t.check("roster: 17 guns", WeaponDefs.ORDER.size() == 17 and WeaponDefs.ROWS.size() == 17)
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		var meta_ok: bool = d.has("tier") and d.has("unlock") and d.has("role") and d.has("slots") and d["tier"] in [1, 2, 3] and d["role"] != ""
		t.check("%s: tier/unlock/role/slots set" % id, meta_ok)
		t.check("%s: caliber has ammo, weight and stack data" % id, TacAmmoDefs.CALIBERS.has(d["cal"]) and ItemDefs.ROUND_KG.has(d["cal"]) and ItemDefs.STACK_MAX.has(d["cal"]))
		t.check("%s: model loads (own glb or fallback)" % id, load("res://assets/models/guns/%s.glb" % d["model"]) != null)
		var mag_id: String = "clip_garand" if id == "garand" else "mag_" + id
		var mag_ok: bool = ItemDefs.has(mag_id) and ItemDefs.of(mag_id)["cap"] == d["mag"] and ItemDefs.of(mag_id)["cal"] == d["cal"]
		if d["action"] != "tube":
			t.check("%s: mag item matches gun (cap, caliber)" % id, mag_ok)
		var g := Gun.new(id)
		g.ammo_pick = TacAmmoDefs.grades(d["cal"])[0]
		var r := g.fire(rng)
		t.check("%s: fires" % id, r["fired"] and r["ammo"] != "")
		g.fire_cd = 0.0
		g.release()
		g.update(5.0)
		if d["action"] == "enbloc":
			g.mag.rounds.clear()
		else:
			g.mag.rounds.clear()
			g.chamber = ""
		g.needs_cycle = false
		var spare_rounds := g.spares[0].count() if d["action"] != "tube" else 0
		var started := g.reload(false)
		g.update(10.0)
		var want: int = d["mag"] if d["action"] != "tube" else 1
		t.check("%s: reloads from its spare mag" % id, started and (g.mag.count() + (1 if g.chamber != "" else 0)) >= mini(want, spare_rounds if d["action"] != "tube" else 1), "%d" % g.mag.count())
		var inv_item := rl.item_from_mag(id, g.mag, d["cal"]) if d["action"] != "tube" else {}
		if d["action"] != "tube":
			t.check("%s: gun mag converts to its item" % id, inv_item["id"] == mag_id)


static func _lines(t: RangeTest) -> void:
	var w := func(id: String) -> Dictionary: return WeaponDefs.of(id)
	var lines := [["m1911", "glock18"], ["m1911", "revolver"], ["mp5", "p90", "vector"], ["ak47", "m4a1", "scarh"], ["shotgun", "saiga12"],
		["sks", "garand", "sr25"], ["mosin", "sniper"]]
	for line in lines:
		for i in line.size() - 1:
			var a: Dictionary = w.call(line[i])
			var b: Dictionary = w.call(line[i + 1])
			t.check("line: %s tier <= %s and unlock earlier" % [a["id"], b["id"]], a["tier"] <= b["tier"] and a["unlock"] < b["unlock"])
	var m4: Dictionary = w.call("m4a1")
	var ak: Dictionary = w.call("ak47")
	t.check("m4a1 recoil < ak47 (up and side)", m4["up"] < ak["up"] and m4["side"] < ak["side"])
	var most := true
	for id in WeaponDefs.ORDER:
		most = most and (id == "m4a1" or (m4["slots"] as Array).size() >= (WeaponDefs.of(id)["slots"] as Array).size())
	t.check("m4a1 has the most attachment slots (tied at most with specialists)", most and m4["slots"].size() > ak["slots"].size())
	t.check("scarh default pen > m4a1 and ak47", _pen("scarh") > _pen("m4a1") and _pen("scarh") > _pen("ak47"))
	t.check("scarh slower ADS than m4a1, heavier", RecoilModel.ads_time(w.call("scarh")["ergo"]) > RecoilModel.ads_time(m4["ergo"]) and w.call("scarh")["kg"] > m4["kg"])
	t.check("sr25 mag > garand, tighter moa, less recoil", w.call("sr25")["mag"] > w.call("garand")["mag"] and w.call("sr25")["moa"] < w.call("garand")["moa"] and w.call("sr25")["up"] < w.call("garand")["up"])
	t.check("garand beats sks (moa, damage)", w.call("garand")["moa"] < w.call("sks")["moa"] and _dmg("garand") > _dmg("sks"))
	t.check("vector rpm > p90 > mp5", w.call("vector")["rpm"] > w.call("p90")["rpm"] and w.call("p90")["rpm"] > w.call("mp5")["rpm"])
	t.check("vector recoil < p90 recoil; vector rpm >= 1100", w.call("vector")["up"] < w.call("p90")["up"] and w.call("vector")["rpm"] >= 1100.0)
	t.check("mp5 more accurate and lower recoil than p90; p90 bigger mag", w.call("mp5")["moa"] < w.call("p90")["moa"] and w.call("mp5")["up"] <= w.call("p90")["up"] and w.call("p90")["mag"] > w.call("mp5")["mag"])
	t.check("vector eats its mag faster than 2 s", float(w.call("vector")["mag"]) / (w.call("vector")["rpm"] / 60.0) < 2.0)
	t.check("saiga: bigger mag and faster than m870", w.call("saiga12")["mag"] > w.call("shotgun")["mag"] and w.call("saiga12")["rpm"] > w.call("shotgun")["rpm"] and w.call("saiga12")["action"] == "detachable")
	t.check("mosin: iron sights, cheaper than the AXMC but less accurate", w.call("mosin")["scope"] == 1.0 and w.call("mosin")["moa"] > w.call("sniper")["moa"] and _dmg("mosin") < _dmg("sniper"))
	t.check("mosin bolt cycles", w.call("mosin")["cycle"] > 0.0)


static func _specials(t: RangeTest) -> void:
	var gl := WeaponDefs.of("glock18")
	var m := WeaponDefs.of("m1911")
	t.check("glock18: full auto, faster than m1911, holster pistol", "auto" in gl["modes"] and gl["rpm"] > m["rpm"] and gl["class"] == "pistol")
	t.check("glock18: poor pen vs m1911 and short zero", _pen("glock18") < _pen("m1911") and gl["moa"] > m["moa"])
	var rv := WeaponDefs.of("revolver")
	var limb_max := 0.0
	for z in BodyHealth.LIMBS:
		limb_max = maxf(limb_max, BodyHealth.MAX[z])
	t.check("revolver: 6 rounds, one-shots a limb with every grade", rv["mag"] == 6 and TacAmmoDefs.grades("44mag").all(func(a): return TacAmmoDefs.of(a)["dmg"] > limb_max))
	t.check("revolver: slowest reload of the pistols, biggest recoil", rv["reload"] > gl["reload"] and rv["reload"] > m["reload"] and rv["up"] > m["up"] and rv["up"] > gl["up"])
	var rg := Gun.new("revolver")
	t.check("revolver holds 6 total", rg.rounds_total() == 6)
	var pk := Gun.new("pkm")
	t.check("pkm holds 100 in the belt", WeaponDefs.of("pkm")["mag"] == 100 and pk.mag.count() >= 99 and ItemDefs.of("mag_pkm")["cap"] == 100)
	var heavy := true
	var slow := true
	for id in WeaponDefs.ORDER:
		if id != "pkm":
			heavy = heavy and WeaponDefs.of("pkm")["kg"] > WeaponDefs.of(id)["kg"]
			slow = slow and WeaponDefs.of("pkm")["reload"] > WeaponDefs.of(id)["reload"]
	t.check("pkm: heaviest and slowest reload", heavy and slow and WeaponDefs.of("pkm")["modes"] == ["auto"])


static func _rack_and_crate(t: RangeTest) -> void:
	var rack := RangeRack.new()
	t.add_child(rack)
	t.check("rack holds all 17 guns", rack._slots.size() == 17)
	var lbl := RangeRack.label_text(WeaponDefs.of("scarh"))
	t.check("rack label shows name, tier and role", "SCAR-H" in lbl and "T3" in lbl and WeaponDefs.of("scarh")["role"] in lbl)
	rack.queue_free()
	var mags := 0
	for row in RangeCrate.LOOT:
		if String(row[0]).begins_with("mag_") or String(row[0]).begins_with("clip_"):
			mags += 1
	var all_mag := true
	for id in WeaponDefs.ORDER:
		var mid: String = "clip_garand" if id == "garand" else "mag_" + id
		if id != "shotgun":
			all_mag = all_mag and RangeCrate.LOOT.any(func(r): return r[0] == mid)
	t.check("supply crate holds a mag for every mag-fed gun", all_mag)
	var ammo_ok := true
	for cal in ["9x19", "44mag", "556x45", "762x51", "762x54r"]:
		ammo_ok = ammo_ok and RangeCrate.LOOT.any(func(r): return TacAmmoDefs.ROWS.has(r[0]) and TacAmmoDefs.ROWS[r[0]]["cal"] == cal)
	t.check("supply crate holds ammo for the new calibres", ammo_ok)
