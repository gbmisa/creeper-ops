class_name SkirmishKit
## F75: a kit carried into Skirmish starts topped up: every gun loaded, every carried spare mag full.
## Ammo types are kept (the gun's chosen grade; each mag item keeps its own).


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
