class_name SupplyCatalogDefs
## The loadout room's SUPPLY lists (unlimited): item ids per category, built from the def tables, not by hand.

const NAMES := ["Guns", "Magazines", "Ammo", "Attachments", "Meds", "Grenades", "Gear", "Bows"]
const BOW_CALS := ["arrow", "bolt"]
const GEAR_KINDS := ["rig", "backpack", "headset"]

static var _cache := {}


static func ids(cat: int) -> Array:
	if not _cache.has(cat):
		_cache[cat] = _build(cat)
	return _cache[cat]


static func _kind(kind: String) -> Array:
	var out := []
	for id in ItemDefs.ROWS:
		if ItemDefs.ROWS[id]["kind"] == kind:
			out.append(id)
	return out


static func _ammo(bows: bool) -> Array:
	var out := []
	for id in TacAmmoDefs.ROWS:
		var cal: String = TacAmmoDefs.ROWS[id]["cal"]
		if ItemDefs.ROUND_KG.has(cal) and (cal in BOW_CALS) == bows:
			out.append(id)
	return out


static func _build(cat: int) -> Array:
	match cat:
		0:
			return WeaponDefs.ORDER.duplicate()
		1:
			return _kind("mag")
		2:
			return _ammo(false)
		3:
			return AttachmentDefs.ROWS.keys()
		4:
			return _kind("med")
		5:
			return _kind("utility")
		6:
			var out := []
			for k in GEAR_KINDS:
				out.append_array(_kind(k))
			for id in ArmorDefs.ROWS:
				if ItemDefs.ARMOR_SIZE.has(id):
					out.append(id)
			return out
		7:
			var out := BowDefs.ROWS.keys()
			out.append_array(_ammo(true))
			return out
	return []
