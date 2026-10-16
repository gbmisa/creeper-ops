class_name Inventory
extends RefCounted
## Tarkov-style inventory: equipment slots + grids (pockets, equipped rig, equipped backpack, transient ground).
## Items are dicts from ItemDefs.make(); placement is stored on the item (loc, x, y, rot). Pure logic, no UI.

const SLOTS := ["primary", "secondary", "holster", "helmet", "armor", "rig", "backpack"]
const GRIDS := ["rig_g", "pockets", "pack_g"]  # grid locs (a worn rig / backpack's own grid), first_fit order after the slots
const BAG_OF := {"rig_g": "rig", "pack_g": "backpack"}
const GROUND_SIZE := Vector2i(10, 14)

var ids: IdSource  # set by the session (server-issued in MP-2); item uids come from here
var slots := {}  # slot name -> item or null
var pockets: Array = []
var ground: Array = []


func _init(p_ids: IdSource = null) -> void:
	ids = p_ids if p_ids != null else IdSource.new()
	for s in SLOTS:
		slots[s] = null


## A fresh item instance with a session-issued uid (MULTIPLAYER.md rule 6).
func make(id: String, opts: Dictionary = {}) -> Dictionary:
	return ItemDefs.make(id, opts, ids)


func equipped(slot: String):
	return slots.get(slot)


func is_slot(loc: String) -> bool:
	return slots.has(loc)


## Items in a grid ("rig_g", "pockets", "pack_g", "ground"). Empty array when the bag isn't worn.
func grid_items(loc: String) -> Array:
	match loc:
		"pockets":
			return pockets
		"ground":
			return ground
		"rig_g", "pack_g":
			var bag = slots[BAG_OF[loc]]
			return bag["items"] if bag != null else []
	return []


func grid_size(loc: String) -> Vector2i:
	match loc:
		"pockets":
			return ItemDefs.POCKETS
		"ground":
			return GROUND_SIZE
		"rig_g", "pack_g":
			var bag = slots[BAG_OF[loc]]
			if bag != null:
				var g: Array = ItemDefs.def_of(bag)["grid"]
				return Vector2i(g[0], g[1])
	return Vector2i.ZERO


func size_of(item: Dictionary, rot: int = -1) -> Vector2i:
	var d := ItemDefs.def_of(item)
	var r: int = item["rot"] if rot < 0 else rot
	return Vector2i(d["h"], d["w"]) if r == 1 else Vector2i(d["w"], d["h"])


func accepts_slot(slot: String, item: Dictionary) -> bool:
	var d := ItemDefs.def_of(item)
	match slot:
		"primary", "secondary":
			return d["kind"] == "gun" and not d["pistol"]
		"holster":
			return d["kind"] == "gun" and d["pistol"]
		"helmet":
			return d["kind"] == "armor" and d.get("helmet", false)
		"armor":
			return d["kind"] == "armor" and not d.get("helmet", false)
		_:
			return d["kind"] == slot


func fits(loc: String, item: Dictionary, x: int, y: int, rot: int = -1) -> bool:
	if is_slot(loc):
		return slots[loc] == null and accepts_slot(loc, item)
	var kind: String = ItemDefs.def_of(item)["kind"]
	if (kind == "rig" or kind == "backpack") and loc != "ground":
		return false
	var gs := grid_size(loc)
	var sz := size_of(item, rot)
	if gs == Vector2i.ZERO or x < 0 or y < 0 or x + sz.x > gs.x or y + sz.y > gs.y:
		return false
	var r := Rect2i(Vector2i(x, y), sz)
	for o in grid_items(loc):
		if o["uid"] != item["uid"] and r.intersects(Rect2i(Vector2i(o["x"], o["y"]), size_of(o))):
			return false
	return true


func place(item: Dictionary, loc: String, x: int = 0, y: int = 0, rot: int = -1) -> bool:
	if not fits(loc, item, x, y, rot):
		return false
	remove(item)
	if rot >= 0:
		item["rot"] = rot
	item["loc"] = loc
	item["x"] = x
	item["y"] = y
	if is_slot(loc):
		slots[loc] = item
	else:
		grid_items(loc).append(item)
	return true


func remove(item: Dictionary) -> void:
	var loc: String = item["loc"]
	if loc == "":
		return
	if is_slot(loc):
		if slots[loc] == item:
			slots[loc] = null
	else:
		grid_items(loc).erase(item)
	item["loc"] = ""


## Where the item would go: slot first, then rig, pockets, backpack. {} if nothing fits.
func first_fit(item: Dictionary, skip: String = "") -> Dictionary:
	for s in SLOTS:
		if s != skip and fits(s, item, 0, 0):
			return {"loc": s, "x": 0, "y": 0, "rot": item["rot"]}
	for g in GRIDS:
		var gs := grid_size(g) if g != skip else Vector2i.ZERO
		for rot in [item["rot"], 1 - int(item["rot"])]:
			for y in gs.y:
				for x in gs.x:
					if fits(g, item, x, y, rot):
						return {"loc": g, "x": x, "y": y, "rot": rot}
	return {}


## Adds an item: tops up ammo stacks first, then first_fit. False (item untouched) if it doesn't fit.
func add(item: Dictionary) -> bool:
	if ItemDefs.def_of(item)["kind"] == "ammo":
		_top_up(item)
		if int(item["count"]) <= 0:
			return true
	var to := first_fit(item)
	if to.is_empty():
		return false
	return place(item, to["loc"], to["x"], to["y"], to["rot"])


func _top_up(item: Dictionary) -> void:
	var cap: int = ItemDefs.def_of(item)["stack"]
	for g in GRIDS:
		for o in grid_items(g):
			if o["uid"] != item["uid"] and o["id"] == item["id"] and int(o["count"]) < cap:
				merge_stack(item, o)
				if int(item["count"]) <= 0:
					return


## Moves as many rounds as fit from item into target (same id). Empties and removes item when all moved.
func merge_stack(item: Dictionary, target: Dictionary) -> void:
	var cap: int = ItemDefs.def_of(item)["stack"]
	var n := mini(int(item["count"]), cap - int(target["count"]))
	target["count"] = int(target["count"]) + n
	item["count"] = int(item["count"]) - n
	if int(item["count"]) <= 0:
		remove(item)


## to = {loc, x, y, rot}. On failure the item stays where it was.
func move(item: Dictionary, to: Dictionary) -> bool:
	var rot: int = to.get("rot", item["rot"])
	if not fits(to["loc"], item, to["x"], to["y"], rot):
		return false
	return place(item, to["loc"], to["x"], to["y"], rot)


## The one entry for fitting a part on a gun item (a future RPC). {ok, why, old}; see Attachments.fit.
func request_fit(gun_item: Dictionary, att: Dictionary) -> Dictionary:
	return Attachments.fit(self, gun_item, att)


## The one entry for taking a part off. {item, spill} or {}; see Attachments.unfit.
func request_unfit(gun_item: Dictionary, slot: String) -> Dictionary:
	return Attachments.unfit(self, gun_item, slot)


## --- Request API (MULTIPLAYER.md rule 4): the only way to mutate the inventory. ---
## Each validates and returns {ok, why}. In MP-2 these become server RPCs; the UI calls only these.

func request_move(item: Dictionary, to: Dictionary) -> Dictionary:
	if item.get("loc", "") == "":
		return {"ok": false, "why": "not in inventory"}
	if move(item, to):
		return {"ok": true, "why": ""}
	return {"ok": false, "why": "does not fit"}


func request_place(item: Dictionary, loc: String, x: int = 0, y: int = 0, rot: int = -1) -> Dictionary:
	if place(item, loc, x, y, rot):
		return {"ok": true, "why": ""}
	return {"ok": false, "why": "does not fit"}


func request_remove(item: Dictionary) -> Dictionary:
	if item.get("loc", "") == "":
		return {"ok": false, "why": "not in inventory"}
	remove(item)
	return {"ok": true, "why": ""}


## Take an item out of the inventory for the world (drop/pickup flows). The caller spawns it.
func request_drop(item: Dictionary) -> Dictionary:
	return request_remove(item)


## Put a world item into the inventory (first fit). {ok, why, loc}.
func request_pick(item: Dictionary) -> Dictionary:
	var to := first_fit(item)
	if to.is_empty():
		return {"ok": false, "why": "no room", "loc": {}}
	if place(item, to["loc"], to["x"], to["y"], to["rot"]):
		return {"ok": true, "why": "", "loc": to}
	return {"ok": false, "why": "does not fit", "loc": {}}


## Add an item (tops up stacks, then first fit). {ok, why}.
func request_add(item: Dictionary) -> Dictionary:
	if add(item):
		return {"ok": true, "why": ""}
	return {"ok": false, "why": "no room"}


## Everything carried (slots and bag contents, not the ground).
func all_items() -> Array:
	var out := []
	for s in SLOTS:
		var it = slots[s]
		if it != null:
			out.append(it)
			if it.has("items"):
				out.append_array(it["items"])
	out.append_array(pockets)
	return out


func total_kg() -> float:
	var kg := 0.0
	for s in SLOTS:
		if slots[s] != null:
			kg += ItemDefs.item_kg(slots[s])
	for it in pockets:
		kg += ItemDefs.item_kg(it)
	return kg


## Mag items for a gun, fullest first, searched rig then pockets then backpack.
func find_mags(gun_id: String) -> Array:
	var out := []
	for g in GRIDS:
		var found := []
		for it in grid_items(g):
			if it["id"] in ItemDefs.ROWS and ItemDefs.ROWS[it["id"]]["kind"] == "mag" and ItemDefs.ROWS[it["id"]]["gun"] == gun_id \
				and int(it["rounds"]) > 0:
				found.append(it)
		found.sort_custom(func(a, b): return int(a["rounds"]) > int(b["rounds"]))
		out.append_array(found)
	return out


## One loose round of the caliber from the grids, or "" if none. Used by tube reloads.
## `only` (F79): the tube already holds this type, so only that type is taken ("" = any).
func take_round(cal: String, only: String = "") -> String:
	for g in GRIDS:
		for it in grid_items(g):
			if it["id"] in TacAmmoDefs.ROWS and TacAmmoDefs.ROWS[it["id"]]["cal"] == cal \
				and (only == "" or it["id"] == only):
				var id: String = it["id"]
				it["count"] = int(it["count"]) - 1
				if int(it["count"]) <= 0:
					remove(it)
				return id
	return ""


## Full state as plain data (slots, grids, positions, rotation, mag rounds, stacks, gun state). Ground is not saved.
func to_dict() -> Dictionary:
	return InventoryIO.to_dict(self)


func load_dict(d: Dictionary) -> void:
	InventoryIO.load_dict(self, d)


static func from_dict(d: Dictionary, ids: IdSource = null) -> Inventory:
	var inv := Inventory.new(ids)
	inv.load_dict(d)
	return inv
