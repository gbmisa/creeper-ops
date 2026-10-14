class_name RangeLoadout
## The player's inventory carried between maps: Inventory.to_dict() data. Empty = start with the default kit.

static var saved := {}


static func save(inv: Inventory) -> void:
	saved = inv.to_dict()
