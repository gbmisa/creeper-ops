class_name ItemDefs
## Tarkov-style item definitions for the range inventory (Track INV).
## kind: gun, mag, ammo, armor, rig, backpack, med.
## Guns read w/h/kg from WeaponDefs (inv_w/inv_h). Pure data, no UI.

const ROUND_KG := {
	"45acp": 0.015, "57x28": 0.008, "762x39": 0.016,
	"12ga": 0.050, "3006": 0.025, "338": 0.030,
}

## caliber -> mag item id (12ga has no detachable mag; the shotgun loads shells).
const MAG_FOR_CAL := {
	"45acp": "mag_45acp", "57x28": "mag_57x28", "762x39": "mag_762x39",
	"3006": "mag_3006", "338": "mag_338",
}

const _MAG_ROWS := {
	"mag_45acp": {"name": "M1911 magazine", "cal": "45acp", "cap": 7, "w": 1, "h": 1, "kg": 0.09},
	"mag_57x28": {"name": "P90 magazine", "cal": "57x28", "cap": 50, "w": 1, "h": 2, "kg": 0.20},
	"mag_762x39": {"name": "AK magazine", "cal": "762x39", "cap": 30, "w": 1, "h": 2, "kg": 0.23},
	"mag_3006": {"name": "M1 en-bloc clip", "cal": "3006", "cap": 8, "w": 1, "h": 1, "kg": 0.05},
	"mag_338": {"name": ".338 magazine", "cal": "338", "cap": 5, "w": 1, "h": 2, "kg": 0.15},
}

const _AMMO_MAX_STACK := {"45acp": 60, "57x28": 100, "762x39": 90, "12ga": 30, "3006": 40, "338": 30}

const _GEAR_ROWS := {
	"armor_vest": {"name": "Plate vest", "kind": "armor", "w": 3, "h": 3, "kg": 3.5},
	"rig_std": {"name": "Chest rig", "kind": "rig", "w": 2, "h": 2, "kg": 0.8, "grid": [4, 2]},
	"pack_small": {"name": "Small backpack", "kind": "backpack", "w": 3, "h": 3, "kg": 1.2, "grid": [4, 4]},
	"pack_big": {"name": "Large backpack", "kind": "backpack", "w": 4, "h": 4, "kg": 2.0, "grid": [5, 6]},
	"med_bandage": {"name": "Bandage", "kind": "med", "w": 1, "h": 1, "kg": 0.05},
	"med_ifak": {"name": "IFAK", "kind": "med", "w": 2, "h": 1, "kg": 0.30},
}

static var _rows := {}


static func rows() -> Dictionary:
	if _rows.is_empty():
		_build()
	return _rows


static func of(id: String) -> Dictionary:
	var d: Dictionary = (rows()[id] as Dictionary).duplicate()
	d["id"] = id
	return d


static func has(id: String) -> bool:
	return rows().has(id)


static func is_pistol(weapon_id: String) -> bool:
	return (rows()[weapon_id] as Dictionary).get("pistol", false)


static func _build() -> void:
	for wid in WeaponDefs.ORDER:
		var w := WeaponDefs.of(wid)
		_rows[wid] = {"name": w["name"], "kind": "gun", "weapon": wid,
			"w": w["inv_w"], "h": w["inv_h"], "kg": w["kg"],
			"pistol": w["class"] == "pistol", "cal": w["cal"]}
	for mid in _MAG_ROWS:
		var m: Dictionary = (_MAG_ROWS[mid] as Dictionary).duplicate()
		m["kind"] = "mag"
		_rows[mid] = m
	for cal in TacAmmoDefs.CALIBERS:
		_rows["ammo_" + cal] = {"name": "%s loose" % cal, "kind": "ammo", "cal": cal,
			"w": 1, "h": 1, "kg": 0.0, "max_stack": _AMMO_MAX_STACK[cal]}
	for gid in _GEAR_ROWS:
		_rows[gid] = (_GEAR_ROWS[gid] as Dictionary).duplicate()
