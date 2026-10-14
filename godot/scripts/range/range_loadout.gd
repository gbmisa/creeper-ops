class_name RangeLoadout
## The player's inventory carried between maps: Inventory.to_dict() data. Empty = start with the default kit.

static var saved := {}


static func save(inv: Inventory) -> void:
	saved = inv.to_dict()


## Carry-out kit: save the inventory, then load the Skirmish map. Used by the Deploy truck and the Esc menu.
static func deploy(inv: Inventory) -> void:
	save(inv)
	RangeMaps.go("skirmish")


## KIA: the kit is lost, the next start uses the default kit.
static func clear() -> void:
	saved = {}
