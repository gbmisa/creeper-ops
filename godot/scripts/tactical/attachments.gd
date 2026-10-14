class_name Attachments
## Fitting attachment items onto gun items (the inventory API behind the drag-and-drop UI and the tests).
## Parts are consumed when fitted and come back as fresh items when removed. Pure logic.


## "" if `att` (an attachment item) can go on `gun_item`, else the reason.
static func why_not(gun_item: Dictionary, att: Dictionary) -> String:
	if not gun_item.has("gun") or ItemDefs.def_of(att)["kind"] != "attach":
		return "Not an attachment"
	var g: Gun = gun_item["gun"]
	if g.busy():
		return "Weapon is busy"
	return AttachmentDefs.why_not(g.def, att["id"])


## {ok, why, old}. On success `att` leaves the inventory (the caller releases a world body) and `old` is the part it
## replaced, a new item the caller must place (or {}).
static func fit(inv: Inventory, gun_item: Dictionary, att: Dictionary) -> Dictionary:
	var why := why_not(gun_item, att)
	if why != "":
		return {"ok": false, "why": why, "old": {}}
	var g: Gun = gun_item["gun"]
	var slot: String = AttachmentDefs.ROWS[att["id"]]["slot"]
	var old := {}
	if g.fit.has(slot):
		old = ItemDefs.make(g.fit[slot])
	inv.remove(att)
	g.set_fit(slot, att["id"])
	return {"ok": true, "why": "", "old": old}


## Takes the part in `slot` off. Returns {item, spill}: the part as a new item (loc "") and loose rounds that no
## longer fit the magazine as ammo items. {} if nothing is fitted or the gun is busy.
static func unfit(gun_item: Dictionary, slot: String) -> Dictionary:
	var g: Gun = gun_item["gun"]
	if not g.fit.has(slot) or g.busy():
		return {}
	var id: String = g.fit[slot]
	var spill_rounds := g.clear_fit(slot)
	var spill := []
	var counts := {}
	for r in spill_rounds:
		counts[r] = int(counts.get(r, 0)) + 1
	for r in counts:
		spill.append(ItemDefs.make(r, {"count": counts[r]}))
	return {"item": ItemDefs.make(id), "spill": spill}


## unfit + put the part (and spill) in the inventory. Returns the items that found no room (the caller drops them).
static func unfit_to_inv(inv: Inventory, gun_item: Dictionary, slot: String) -> Array:
	var r := unfit(gun_item, slot)
	var left := []
	if r.is_empty():
		return left
	for it in [r["item"]] + r["spill"]:
		if not inv.add(it):
			left.append(it)
	return left


## First fitted slot in AttachmentDefs.SLOTS order ("" if none).
static func first_fitted(gun_item: Dictionary) -> String:
	for s in AttachmentDefs.SLOTS:
		if (gun_item["gun"] as Gun).fit.has(s):
			return s
	return ""
