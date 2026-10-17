class_name GearPresets
## F140: saved loadout presets (one per mannequin) in a ConfigFile. A preset is {name, kit} where kit is
## Inventory.to_dict() (the same data the deploy kit-persist uses). Tests point `path` at a temp file.

const COUNT := 3
static var path := "user://presets.cfg"


static func default_name(i: int) -> String:
	return "Preset %d" % (i + 1)


## {name, kit} for mannequin i; kit is {} when nothing is saved there.
static func load_slot(i: int) -> Dictionary:
	var cf := ConfigFile.new()
	cf.load(path)   # missing file: every slot reads empty
	return {"name": str(cf.get_value("preset%d" % i, "name", default_name(i))), "kit": cf.get_value("preset%d" % i, "kit", {})}


static func save_slot(i: int, preset_name: String, kit: Dictionary) -> void:
	var cf := ConfigFile.new()
	cf.load(path)
	cf.set_value("preset%d" % i, "name", preset_name)
	cf.set_value("preset%d" % i, "kit", kit)
	cf.save(path)


static func rename_slot(i: int, preset_name: String) -> void:
	var p := load_slot(i)
	save_slot(i, preset_name, p["kit"])
