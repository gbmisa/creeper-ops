class_name WornArmor
## P12: the HELMET and ARMOR slot items protect the player through BodyHealth.armor, the same path bot armor uses.
## Durability lives on the item ("dur") so it travels with it between maps; the body's slot is the working copy.


static func sync(inv: Inventory, body: BodyHealth) -> void:
	var want := {}  # zone -> worn item
	for s in ["helmet", "armor"]:
		var it = inv.slots[s]
		if it != null:
			for z in ArmorDefs.of(it["id"])["zones"]:
				want[z] = it
	for z in body.armor.keys():
		if not want.has(z):
			body.armor.erase(z)
	for z in want:
		var it: Dictionary = want[z]
		var slot = body.armor.get(z)
		if slot == null or slot.get("uid", -1) != it["uid"]:
			body.armor[z] = {"id": it["id"], "dur": it.get("dur", ArmorDefs.of(it["id"])["max_dur"]), "uid": it["uid"]}
		else:
			it["dur"] = slot["dur"]
