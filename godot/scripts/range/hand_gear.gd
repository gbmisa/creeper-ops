class_name HandGear
## Keeps PlayerWeapons' hand in step with its Inventory: take a gun, resync after inventory edits, bench refill.


static func give(w: PlayerWeapons, id: String) -> void:
	for s in PlayerWeapons.HAND_SLOTS:
		var have = w.inv.equipped(s)
		if have != null and have["id"] == id:
			w.select_slot(s)
			return
	var it := ItemDefs.make(id)
	(it["gun"] as Gun).spares.clear()
	if not w.inv.add(it):
		w.message.emit("No room for %s" % WeaponDefs.of(id)["name"])
		return
	if it["loc"] in PlayerWeapons.HAND_SLOTS:
		w.select_slot(it["loc"])
	else:
		w.message.emit("%s put away" % WeaponDefs.of(id)["name"])


## Carried weight, and the hand: a gun that left the hand slots is put down (reload cancelled).
static func sync(w: PlayerWeapons) -> void:
	w.player.carried_kg = w.inv.total_kg()
	if not w.gun_item.is_empty() and w.gun_item["loc"] in PlayerWeapons.HAND_SLOTS:
		return
	var had_gun := not w.gun_item.is_empty()
	if had_gun:
		w.reloader.cancel(w.gun_item)
	w.gun_item = {}
	w.gun = null
	for s in PlayerWeapons.HAND_SLOTS:
		if w.inv.equipped(s) != null:
			w.select_slot(s)
			return
	if had_gun:
		w.switched.emit(null)


## Ammo bench: after the gun's grade changed, every carried mag of its caliber is refilled with it.
static func refill_mags(w: PlayerWeapons) -> void:
	w.gun.spares.clear()
	for it in w.inv.all_items():
		if it["id"] in ItemDefs.ROWS and ItemDefs.ROWS[it["id"]]["kind"] == "mag" and ItemDefs.of(it["id"])["cal"] == w.gun.def["cal"]:
			it["rounds"] = maxi(ItemDefs.of(it["id"])["cap"], int(w.gun.stat("mag")))
			it["ammo"] = w.gun.ammo_pick
