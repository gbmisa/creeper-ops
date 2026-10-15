class_name StarterLoadout
## The player's starting kit: AK in primary, M1911 in the holster, a chest rig with 3 AK and 2 pistol mags.


static func fill(inv: Inventory) -> void:
	var rig := inv.make("rig_chest")
	inv.place(rig, "rig")
	for id in ["ak47", "m1911"]:
		var gun := inv.make(id)
		(gun["gun"] as Gun).spares.clear()
		inv.add(gun)
	for id in ["mag_ak47", "mag_ak47", "mag_ak47", "mag_m1911", "mag_m1911"]:
		inv.add(inv.make(id))
