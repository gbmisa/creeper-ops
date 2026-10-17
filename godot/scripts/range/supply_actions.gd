class_name SupplyActions
extends RefCounted
## Applies the SUPPLY panel's requests (take, drag-drop, return, refill) to the inventory. Owned by InventoryUI.

var weapons: PlayerWeapons
var world: WorldItems
var settle: Callable


func _init(w: PlayerWeapons, wi: WorldItems, view: InventoryView, settle_cb: Callable) -> void:
	weapons = w
	world = wi
	settle = settle_cb
	view.supply_take.connect(func(id: String): _done(SupplyGive.give(w.inv, id), id))
	view.supply_drop.connect(func(id: String, t: Dictionary): _done(SupplyGive.give_at(w.inv, id, t), id))
	view.supply_return.connect(_return)
	view.supply_refill.connect(_refill)


func _done(why: String, _id: String) -> void:
	if why != "":
		weapons.message.emit(why)
	settle.call()


func _return(it: Dictionary) -> void:
	SupplyGive.take_back(weapons.inv, world, it)
	weapons.message.emit("Returned %s" % ItemDefs.def_of(it)["name"])
	settle.call()


## Same refill as the ammo bench had before.
func _refill() -> void:
	var g := weapons.gun
	if g == null:
		weapons.message.emit("No gun held")
		return
	var tube: bool = g.def["action"] == "tube"
	weapons.reload_cancel()
	g.refill()
	weapons.refill_mags()
	weapons.message.emit("%s refilled" % HandGear.refill_msg(g, tube))
