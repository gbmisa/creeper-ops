class_name Inventory
extends RefCounted
## Tarkov-style inventory: equipment slots + grid containers. Pure logic, no UI.
##
## Item instances are Dictionaries: {id, uid, rot, count?, rounds?, ammo?, in_gun?, gun_uid?}.
## - rot: 0 = as def, 1 = rotated (w/h swapped).
## - ammo items stack: count (max per def). mag items hold rounds of one ammo grade.
## - a mag inserted in a gun has in_gun=true and lives outside the grids (loc "gun").
##
## Containers: slots primary/secondary/holster/armor/rig/backpack (one item each),
## grids pockets (4x1), rig_grid (from equipped rig), pack_grid (from equipped backpack).

const SLOT_NAMES := ["primary", "secondary", "holster", "armor", "rig", "backpack"]
const POCKETS := "pockets"
const RIG_GRID := "rig_grid"
const PACK_GRID := "pack_grid"
const GUN_HOME := "gun"

var _next_uid := 1
var items := {}      # uid -> item Dictionary
var slot_uid := {}   # slot name -> uid (-1 = empty)
var grid_uids := {}  # grid name -> Array[uid]
var grid_dim := {}   # grid name -> Vector2i
var loc := {}        # uid -> {c, x, y}


func _init() -> void:
	for s in SLOT_NAMES:
		slot_uid[s] = -1
	grid_dim[POCKETS] = Vector2i(4, 1)
	grid_uids[POCKETS] = []


## Create an (unplaced) item instance.
func make(item_id: String) -> Dictionary:
	var d := ItemDefs.of(item_id)
	var it := {"id": item_id, "uid": _next_uid, "rot": 0}
	_next_uid += 1
	match d["kind"]:
		"ammo":
			it["count"] = d["max_stack"]
		"mag":
			it["rounds"] = d["cap"]
			it["ammo"] = TacAmmoDefs.grades(d["cal"])[0]
			it["in_gun"] = false
			it["gun_uid"] = -1
	items[it["uid"]] = it
	return it


func cell_size(item: Dictionary) -> Vector2i:
	var d := ItemDefs.of(item["id"])
	var w: int = d["w"]
	var h: int = d["h"]
	if int(item.get("rot", 0)) == 1:
		return Vector2i(h, w)
	return Vector2i(w, h)


func slot_accepts(slot: String, item_id: String) -> bool:
	var d := ItemDefs.of(item_id)
	match slot:
		"primary", "secondary":
			return d["kind"] == "gun" and not bool(d.get("pistol", false))
		"holster":
			return d["kind"] == "gun" and bool(d.get("pistol", false))
		"armor":
			return d["kind"] == "armor"
		"rig":
			return d["kind"] == "rig"
		"backpack":
			return d["kind"] == "backpack"
	return false


func equipped(slot: String) -> Dictionary:
	var uid: int = slot_uid.get(slot, -1)
	return (items[uid] as Dictionary).duplicate() if items.has(uid) else {}


func fits(grid: String, item: Dictionary, x: int, y: int) -> bool:
	if not grid_dim.has(grid):
		return false
	var dim: Vector2i = grid_dim[grid]
	var sz := cell_size(item)
	if x < 0 or y < 0 or x + sz.x > dim.x or y + sz.y > dim.y:
		return false
	for uid in grid_uids[grid]:
		if uid == item["uid"]:
			continue
		var o: Dictionary = items[uid]
		var osz := cell_size(o)
		var ox: int = (loc[uid] as Dictionary)["x"]
		var oy: int = (loc[uid] as Dictionary)["y"]
		if x < ox + osz.x and ox < x + sz.x and y < oy + osz.y and oy < y + sz.y:
			return false
	return true


## Move an item to a container. Grids take x/y/rot; slots ignore them.
func place(uid: int, container: String, x: int = 0, y: int = 0, rot: int = 0) -> bool:
	if not items.has(uid):
		return false
	var item: Dictionary = items[uid]
	if SLOT_NAMES.has(container):
		if not slot_accepts(container, item["id"]):
			return false
		var occ: int = slot_uid[container]
		if occ != -1 and occ != uid:
			return false
	elif grid_dim.has(container):
		var keep_rot: int = item["rot"]
		item["rot"] = rot
		var ok := fits(container, item, x, y)
		item["rot"] = keep_rot
		if not ok:
			return false
	else:
		return false
	if not _unplace(uid):
		return false
	item["rot"] = rot
	if SLOT_NAMES.has(container):
		slot_uid[container] = uid
		loc[uid] = {"c": container, "x": -1, "y": -1}
		if container == "rig":
			_activate_grid(RIG_GRID, ItemDefs.of(item["id"])["grid"])
		elif container == "backpack":
			_activate_grid(PACK_GRID, ItemDefs.of(item["id"])["grid"])
	else:
		(grid_uids[container] as Array).append(uid)
		loc[uid] = {"c": container, "x": x, "y": y}
	return true


## Take an item out of the inventory entirely; returns the item ({} if missing).
func remove(uid: int) -> Dictionary:
	if not items.has(uid):
		return {}
	_unplace(uid, true)
	var it: Dictionary = items[uid]
	items.erase(uid)
	loc.erase(uid)
	return it


## First-fit order: fitting equipment slot, then rig grid, pockets, backpack grid.
func first_fit(item: Dictionary) -> bool:
	var uid: int = item["uid"]
	if not items.has(uid):
		return false
	var d := ItemDefs.of(item["id"])
	var try_slots: Array = []
	match d["kind"]:
		"gun":
			try_slots = ["holster"] if bool(d.get("pistol", false)) else ["primary", "secondary"]
		"armor":
			try_slots = ["armor"]
		"rig":
			try_slots = ["rig"]
		"backpack":
			try_slots = ["backpack"]
	for s in try_slots:
		if place(uid, s):
			return true
	for g in _grid_order():
		var dim: Vector2i = grid_dim[g]
		for rot in [0, 1]:
			for y in dim.y:
				for x in dim.x:
					if place(uid, g, x, y, rot):
						return true
	return false


## Alias used by drag/drop and quick-move.
func move(uid: int, container: String, x: int = 0, y: int = 0, rot: int = 0) -> bool:
	return place(uid, container, x, y, rot)


## Sum of item kg + mag rounds + ammo stacks (in kg).
func total_kg() -> float:
	var kg := 0.0
	for uid in items:
		var item: Dictionary = items[uid]
		if not loc.has(uid):
			continue
		var d := ItemDefs.of(item["id"])
		kg += float(d["kg"])
		var rk: float = ItemDefs.ROUND_KG.get(d.get("cal", ""), 0.0)
		if d["kind"] == "mag":
			kg += float(item.get("rounds", 0)) * rk
		elif d["kind"] == "ammo":
			kg += float(item.get("count", 0)) * rk
	return kg


## Mag item currently inserted in a gun (in_gun), or -1.
func mag_in_gun(gun_uid: int) -> int:
	for uid in items:
		var it: Dictionary = items[uid]
		if bool(it.get("in_gun", false)) and int(it.get("gun_uid", -1)) == gun_uid:
			return uid
	return -1


## Spare mag items of a caliber (not in a gun), fullest first.
func spare_mags(cal: String) -> Array:
	var out: Array = []
	for uid in items:
		var it: Dictionary = items[uid]
		if not loc.has(uid) or bool(it.get("in_gun", false)):
			continue
		var d := ItemDefs.of(it["id"])
		if d["kind"] == "mag" and d["cal"] == cal:
			out.append(it)
	out.sort_custom(func(a, b): return int(a["rounds"]) > int(b["rounds"]))
	return out


## Loose-ammo stacks of a caliber with rounds left, in rig/pockets/backpack order.
func ammo_stacks(cal: String) -> Array:
	var out: Array = []
	for g in _grid_order():
		for uid in grid_uids[g]:
			var it: Dictionary = items[uid]
			var d := ItemDefs.of(it["id"])
			if d["kind"] == "ammo" and d["cal"] == cal and int(it.get("count", 0)) > 0:
				out.append(it)
	return out


## Move a mag item into a gun (out of the grids). Returns false if missing.
func to_gun(uid: int, gun_uid: int) -> bool:
	if not items.has(uid):
		return false
	_unplace(uid)
	var it: Dictionary = items[uid]
	it["in_gun"] = true
	it["gun_uid"] = gun_uid
	loc[uid] = {"c": GUN_HOME, "x": -1, "y": -1}
	return true


## Take a mag item out of a gun (caller places it next).
func from_gun(uid: int) -> void:
	if items.has(uid):
		var it: Dictionary = items[uid]
		it["in_gun"] = false
		it["gun_uid"] = -1
		loc.erase(uid)


func _grid_order() -> Array:
	var out: Array = []
	if grid_dim.has(RIG_GRID):
		out.append(RIG_GRID)
	out.append(POCKETS)
	if grid_dim.has(PACK_GRID):
		out.append(PACK_GRID)
	return out


func _activate_grid(grid: String, wh: Array) -> void:
	grid_dim[grid] = Vector2i(wh[0], wh[1])
	if not grid_uids.has(grid):
		grid_uids[grid] = []


## Returns false if a rig/backpack grid still holds items (caller must empty it first).
## Ctrl+click: a slotted item goes to the first fitting grid (rig, pockets, backpack);
## a grid item uses first_fit (slot first, then grids).
func quick_move(uid: int) -> bool:
	if not items.has(uid) or not loc.has(uid):
		return false
	var item: Dictionary = items[uid]
	var from: String = (loc[uid] as Dictionary)["c"]
	var dims := cell_size(item)
	if SLOT_NAMES.has(from):
		var w: int = dims[0]
		var h: int = dims[1]
		for g in _grid_order():
			var dd: Vector2i = grid_dim[g]
			for r in [0, 1]:
				var cw := w if r == 0 else h
				var ch := h if r == 0 else w
				if cw > dd.x or ch > dd.y:
					continue
				for yy in dd.y - ch + 1:
					for xx in dd.x - cw + 1:
						if place(uid, g, xx, yy, r):
							return true
		return false
	item["rot"] = 0
	return first_fit(item)


func _unplace(uid: int, force: bool = false) -> bool:
	if not loc.has(uid):
		return true
	var c: String = (loc[uid] as Dictionary)["c"]
	if SLOT_NAMES.has(c):
		if (c == "rig" and grid_uids.has(RIG_GRID) and not (grid_uids[RIG_GRID] as Array).is_empty()) \
		or (c == "backpack" and grid_uids.has(PACK_GRID) and not (grid_uids[PACK_GRID] as Array).is_empty()):
			if not force:
				return false
		if slot_uid[c] == uid:
			slot_uid[c] = -1
		if c == "rig":
			grid_dim.erase(RIG_GRID)
			grid_uids.erase(RIG_GRID)
		elif c == "backpack":
			grid_dim.erase(PACK_GRID)
			grid_uids.erase(PACK_GRID)
	elif grid_uids.has(c):
		(grid_uids[c] as Array).erase(uid)
	elif c == GUN_HOME:
		pass
	loc.erase(uid)
	return true
