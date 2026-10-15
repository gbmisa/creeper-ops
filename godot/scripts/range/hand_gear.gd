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
	var d := ItemDefs.def_of(it)
	var want := "holster" if d["kind"] == "gun" and d.get("pistol", false) else "primary"
	w.inv.add(it)  # may fail when full; place() below handles an unplaced item
	if it["loc"] in PlayerWeapons.HAND_SLOTS:
		w.select_slot(it["loc"])
		return
	# Debug give (--weapon): the gun must end up in the hand even when its slot is taken
	# or the inventory is full. Force it into the want slot, re-homing the occupant —
	# or dropping it to the world when nothing fits.
	var occ = w.inv.equipped(want)
	if occ != null:
		w.inv.remove(occ)
	if w.inv.place(it, want):
		if occ != null:
			var to := w.inv.first_fit(occ, want)
			if to.is_empty():
				w.item_dropped.emit(occ)
			else:
				w.inv.place(occ, to["loc"], to["x"], to["y"], to["rot"])
		w.select_slot(want)
	else:
		if occ != null:
			w.inv.place(occ, want)
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
