class_name SkirmishKit
## F75: a kit carried into Skirmish starts topped up: every gun loaded, every carried spare mag full.
## Ammo types are kept (the gun's chosen grade; each mag item keeps its own).


## F90: deploying into Skirmish: top up, then every gun in a hand slot carries at least SKIRMISH_SPARE_MAGS full spare
## mags of its loaded ammo (tube guns: that many tubes of loose shells). Spares that don't fit are left out.
static func deploy(inv: Inventory) -> void:
	top_up(inv)
	for slot in PlayerWeapons.HAND_SLOTS:
		var it = inv.equipped(slot)
		if it != null and it.has("gun"):
			_spares(inv, it["gun"])


static func top_up(inv: Inventory) -> void:
	for it in inv.all_items():
		if it.has("gun"):
			_load_gun(it["gun"])
		elif it["id"] in ItemDefs.ROWS and ItemDefs.ROWS[it["id"]]["kind"] == "mag":
			it["rounds"] = maxi(int(ItemDefs.def_of(it)["cap"]), int(it["rounds"]))


static func _load_gun(g: Gun) -> void:
	g.spares.clear()
	g.mag = Magazine.new(int(g.stat("mag")))
	g.mag.fill(g.ammo_pick)
	match g.def["action"]:
		"tube":
			g.chamber = g.ammo_pick
		"detachable":
			g.chamber = g.mag.pop()
		_:
			g.chamber = ""
	g.needs_cycle = false


static func _spares(inv: Inventory, g: Gun) -> void:
	var want := TacticalConfig.SKIRMISH_SPARE_MAGS
	if g.def["action"] == "tube":
		var have := 0
		for it in inv.all_items():
			if it["id"] == g.ammo_pick:
				have += int(it["count"])
		var need := want * int(g.stat("mag")) - have
		if need > 0:
			inv.add(inv.make(g.ammo_pick, {"count": need}))
		return
	var mag_id := ""
	for id in ItemDefs.ROWS:
		if ItemDefs.ROWS[id]["kind"] == "mag" and ItemDefs.ROWS[id].get("gun", "") == g.def["id"]:
			mag_id = id
			break
	if mag_id == "":
		return
	for _i in maxi(0, want - inv.find_mags(g.def["id"]).size()):
		if not inv.add(inv.make(mag_id, {"ammo": g.ammo_pick})):
			return
