class_name Tempest
## Secret railgun toggle (hidden chord secret_tempest). Moves the sidearm out of the holster (backpack/rig/pockets,
## else the ground; never lost), puts the Tempest in the holster and selects it. Toggling off restores the sidearm.


static func active(w: PlayerWeapons) -> bool:
	var h = w.inv.equipped("holster")
	return h != null and h["id"] == SecretArms.TEMPEST


## One request function for the chord. world_items (optional) lets "off" take the sidearm back from the ground.
static func toggle(w: PlayerWeapons, world_items: WorldItems = null) -> bool:
	if active(w):
		_off(w, world_items)
		return false
	_on(w, world_items)
	return true


static func _on(w: PlayerWeapons, world_items: WorldItems) -> void:
	if world_items != null:  # a Tempest the player dropped earlier is gone, there is only ever one
		for it in world_items.items.duplicate():
			if it["id"] == SecretArms.TEMPEST:
				world_items.release(it)
	var prev = w.inv.equipped("holster")
	if prev != null:
		if w.gun_item == prev:
			w.reloader.cancel(prev)
		w.inv.remove(prev)
	var t := ItemDefs.make(SecretArms.TEMPEST)
	(t["gun"] as Gun).spares.clear()
	w.inv.place(t, "holster")
	w.tempest_prev = prev if prev != null else {}
	if prev != null and not w.inv.add(prev):
		w.item_dropped.emit(prev)  # no room anywhere: it lies on the ground in front of you
	w.gun_item = {}
	w.select_slot("holster")


static func _off(w: PlayerWeapons, world_items: WorldItems) -> void:
	var t = w.inv.equipped("holster")
	w.reloader.cancel(t)
	w.inv.remove(t)
	if not w.gun_item.is_empty() and w.gun_item["uid"] == t["uid"]:
		w.gun_item = {}
		w.gun = null
	var prev: Dictionary = w.tempest_prev
	w.tempest_prev = {}
	if not prev.is_empty():
		if prev["loc"] != "":
			w.inv.remove(prev)
		elif world_items != null and world_items.items.has(prev):
			world_items.release(prev)
		if not w.inv.place(prev, "holster"):
			w.inv.add(prev)
		w.select_slot("holster")
	else:
		w.sync()
