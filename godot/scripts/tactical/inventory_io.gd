class_name InventoryIO
## Plain-data (de)serialisation of items, guns and whole inventories, for carrying a loadout between maps.


static func gun_to_dict(g: Gun) -> Dictionary:
	return {"id": g.def["id"], "mag": g.mag.rounds.duplicate(), "chamber": g.chamber, "mode": g.mode,
		"zero_idx": g.zero_idx, "ammo_pick": g.ammo_pick, "needs_cycle": g.needs_cycle,
		"fit": g.fit.duplicate(), "zoom_hi": g.zoom_hi}


static func gun_from_dict(d: Dictionary) -> Gun:
	var g := Gun.new(d["id"])
	g.spares.clear()
	g.mag.rounds.clear()
	for r in d["mag"]:
		g.mag.rounds.append(str(r))
	g.mag.normalize()
	g.chamber = d["chamber"]
	g.mode = d["mode"]
	g.zero_idx = d["zero_idx"]
	g.ammo_pick = d["ammo_pick"]
	g.needs_cycle = d["needs_cycle"]
	for slot in d.get("fit", {}):
		g.set_fit(slot, d["fit"][slot])
	g.zoom_hi = d.get("zoom_hi", true)
	return g


static func item_to_dict(it: Dictionary) -> Dictionary:
	var out := {}
	for k in it:
		match k:
			"world", "staged":
				pass
			"gun":
				out[k] = gun_to_dict(it[k])
			"items":
				out[k] = (it[k] as Array).map(item_to_dict)
			_:
				out[k] = it[k]
	return out


static func item_from_dict(d: Dictionary, ids: IdSource) -> Dictionary:
	var it := {}
	for k in d:
		match k:
			"gun":
				it[k] = gun_from_dict(d[k])
			"items":
				it[k] = (d[k] as Array).map(func(x): return item_from_dict(x, ids))
			_:
				it[k] = d[k]
	ids.note(int(it["uid"]))
	return it


static func to_dict(inv: Inventory) -> Dictionary:
	var slots := {}
	for s in Inventory.SLOTS:
		slots[s] = item_to_dict(inv.slots[s]) if inv.slots[s] != null else {}
	return {"slots": slots, "pockets": inv.pockets.map(item_to_dict)}


static func load_dict(inv: Inventory, d: Dictionary) -> void:
	for s in Inventory.SLOTS:
		var sd: Dictionary = d["slots"].get(s, {})
		inv.slots[s] = item_from_dict(sd, inv.ids) if not sd.is_empty() else null
	inv.pockets = (d["pockets"] as Array).map(func(x): return item_from_dict(x, inv.ids))
	inv.ground.clear()
