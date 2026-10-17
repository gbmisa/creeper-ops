class_name SupplyGive
## Placing a SUPPLY item (made fresh: mags full with the default grade, guns with their default fit). Never the floor.


## Click: slot if free, else rig, pockets, backpack (Inventory.add). "" when placed, else the reason.
static func give(inv: Inventory, id: String) -> String:
	var it := inv.make(id)
	if inv.add(it):
		return ""
	return "No room for %s" % ItemDefs.of(id)["name"]


## Dragged onto a slot or grid cell ({loc, x, y, rot}; {} = outside every region). "" when placed, else the reason.
static func give_at(inv: Inventory, id: String, t: Dictionary) -> String:
	if t.is_empty():
		return ""
	var it := inv.make(id)
	if inv.place(it, t["loc"], t["x"], t["y"], t["rot"]):
		return ""
	return "No room for %s there" % ItemDefs.of(id)["name"]


## Dragging an inventory item onto the SUPPLY panel: it is deleted.
static func take_back(inv: Inventory, world: WorldItems, it: Dictionary) -> void:
	if it["loc"] != "":
		inv.remove(it)
	if it.has("world"):
		world.release(it)
