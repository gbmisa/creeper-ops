class_name GunsmithMags
## F147: the gunsmith's "Magazines" row. Lists every mag item that fits a gun (supply, unlimited, made full with the
## gun's default ammo grade by ItemDefs.make) and places a new one in the tactical rig, else the bags. Never the floor.


## Catalogue rows ({"id", "catalog": true, "mag": true}) for every mag item whose "gun" is `gun_id`.
static func choices(gun: Gun) -> Array:
	var gun_id := gun.id
	var out := []
	for id in ItemDefs.ROWS:
		var d: Dictionary = ItemDefs.ROWS[id]
		if d["kind"] == "mag" and d["gun"] == gun_id:
			out.append({"id": id, "catalog": true, "mag": true})
	return out


## Makes one full mag and adds it: first free spot in the rig, else the bags. "" when placed, else the reason.
static func give(inv: Inventory, id: String) -> String:
	var it := inv.make(id)
	for g in Inventory.GRIDS:
		var gs := inv.grid_size(g)
		for rot in [0, 1]:
			for y in gs.y:
				for x in gs.x:
					if inv.request_place(it, g, x, y, rot)["ok"]:
						return ""
	return "No room for a magazine"


## One list row: a part (AttachmentDefs) or a mag (ItemDefs), tagged supply / in bag.
static func draw_row(ci: CanvasItem, font: Font, r: Rect2, it: Dictionary, alpha := 1.0) -> void:
	var col: Color = InventoryView.KIND_COL["mag" if it.has("mag") else "attach"]
	ci.draw_rect(r, Color(col.r, col.g, col.b, alpha))
	ci.draw_rect(r, Color(0.9, 0.9, 0.8, alpha * 0.6), false, 1.0)
	var nm: String = ItemDefs.ROWS[it["id"]]["name"] if it.has("mag") else AttachmentDefs.ROWS[it["id"]]["name"]
	var tag := "supply" if it.has("catalog") else "in bag"
	ci.draw_string(font, r.position + Vector2(8, 22), "%s  (%s)" % [nm, tag], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, alpha))


## The "Magazines" row under the slots (lit while picked; shows `note`, e.g. "No room for a magazine").
static func draw_button(ci: CanvasItem, font: Font, r: Rect2, on: bool, note: String) -> void:
	ci.draw_rect(r, Color(0.2, 0.26, 0.22, 0.95) if on else Color(0.08, 0.09, 0.07, 0.95))
	ci.draw_rect(r, Color(0.46, 0.49, 0.33, 0.9 if on else 0.6), false, 2.0 if on else 1.0)
	ci.draw_string(font, r.position + Vector2(10, 18), "MAGAZINES", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.DIM)
	ci.draw_string(font, r.position + Vector2(10, 37), "Full mags into your rig" if note == "" else note, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.TEXT)


## F145: every part for `slot` that fits the gun: bag spares first, then catalogue ids not in the bags
## ({"id", "catalog": true}; made from supply when clicked). The fitted part is left out.
static func parts(gun: Gun, spares: Array, slot: String) -> Array:
	var out := []
	var seen := {}
	for it in spares:
		var id: String = it["id"]
		if AttachmentDefs.ROWS[id]["slot"] == slot and AttachmentDefs.why_not(gun.def, id) == "":
			out.append(it)
			seen[id] = true
	for id in AttachmentDefs.ROWS:
		if AttachmentDefs.ROWS[id]["slot"] == slot and not seen.has(id) and gun.fit.get(slot, "") != id \
				and AttachmentDefs.why_not(gun.def, id) == "":
			out.append({"id": id, "catalog": true})
	return out
