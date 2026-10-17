class_name InventoryGround
extends RefCounted
## The inventory screen's ground grid (items within 2 m) and opening a bag that lies on it. Static helpers.


static func is_bag(it: Dictionary) -> bool:
	var k: String = ItemDefs.def_of(it)["kind"]
	return k == "rig" or k == "backpack"


## Existing cells are kept and new items take the first free spot. If some nearby item found no spot, the grid is
## rebuilt nearest-first so what was just dropped in front of the player (and anything close) is shown.
static func refresh(inv: Inventory, world: WorldItems, pos: Vector3) -> void:
	var near := world.nearby(pos)
	for it in inv.ground.duplicate():
		if not near.has(it):
			inv.request_remove(it)
	var missing := false
	for it in near:
		if it["loc"] != "ground":
			it["loc"] = ""
			if not _put(inv, it):
				missing = true
	if missing:
		for it in inv.ground.duplicate():
			inv.remove(it)
		near.sort_custom(func(a, b): return (a["world"] as Node3D).global_position.distance_to(pos) < (b["world"] as Node3D).global_position.distance_to(pos))
		for it in near:
			_put(inv, it)
	if not inv.opened.is_empty() and inv.opened["loc"] != "ground":
		inv.opened = {}


static func _put(inv: Inventory, it: Dictionary) -> bool:
	var gs := inv.grid_size("ground")
	for rot in [it["rot"], 1 - int(it["rot"])]:
		for y in gs.y:
			for x in gs.x:
				if inv.fits("ground", it, x, y, rot):
					return inv.request_place(it, "ground", x, y, rot)["ok"]
	return false


static func open_bag(inv: Inventory, it: Dictionary) -> void:
	if is_bag(it) and it["loc"] == "ground":
		inv.opened = it
