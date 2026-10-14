class_name TacAmmoDefs
## Ammo grades. dmg/pen scale with v/v0 in flight. pellets > 1: dmg is per pellet.

const DEFAULTS := {"frag": 0.0, "lbleed": 0.15, "hbleed": 0.05, "pellets": 1, "acc": 1.0, "malf": 0.002}

## cal -> default grade id order (first is the default load)
const CALIBERS := {
	"45acp": ["45_fmj", "45_ap", "45_hs"],
	"57x28": ["57_ss190", "57_sb193", "57_r37f"],
	"762x39": ["762_ps", "762_bp", "762_hp"],
	"12ga": ["12_buck7", "12_buckmag", "12_ap20", "12_flech"],
	"3006": ["3006_fmj", "3006_m2"],
	"338": ["338_fmj", "338_ap", "338_tacx"],
}

const ROWS := {
	"45_fmj": {"name": "45 FMJ", "cal": "45acp", "dmg": 72.0, "pen": 25.0, "armor_dmg": 0.36, "v0": 340.0, "drag": 0.0021},
	"45_ap": {"name": "45 AP", "cal": "45acp", "dmg": 66.0, "pen": 38.0, "armor_dmg": 0.48, "v0": 299.0, "drag": 0.0021},
	"45_hs": {"name": "45 Hydra-Shok", "cal": "45acp", "dmg": 100.0, "pen": 13.0, "armor_dmg": 0.15, "v0": 340.0, "drag": 0.0021, "frag": 0.5},
	"57_ss190": {"name": "5.7 SS190", "cal": "57x28", "dmg": 49.0, "pen": 37.0, "armor_dmg": 0.53, "v0": 715.0, "drag": 0.0016},
	"57_sb193": {"name": "5.7 SB193", "cal": "57x28", "dmg": 59.0, "pen": 27.0, "armor_dmg": 0.4, "v0": 305.0, "drag": 0.0016},
	"57_r37f": {"name": "5.7 R37.F", "cal": "57x28", "dmg": 98.0, "pen": 8.0, "armor_dmg": 0.2, "v0": 729.0, "drag": 0.0016, "frag": 0.6},
	"762_ps": {"name": "7.62 PS", "cal": "762x39", "dmg": 57.0, "pen": 35.0, "armor_dmg": 0.52, "v0": 700.0, "drag": 0.0012},
	"762_bp": {"name": "7.62 BP", "cal": "762x39", "dmg": 58.0, "pen": 47.0, "armor_dmg": 0.63, "v0": 730.0, "drag": 0.0012},
	"762_hp": {"name": "7.62 HP", "cal": "762x39", "dmg": 80.0, "pen": 15.0, "armor_dmg": 0.2, "v0": 754.0, "drag": 0.0012, "frag": 0.4},
	"12_buck7": {"name": "12ga 7mm buck", "cal": "12ga", "dmg": 39.0, "pen": 3.0, "armor_dmg": 0.26, "v0": 415.0, "drag": 0.006, "pellets": 8},
	"12_buckmag": {"name": "12ga Magnum buck", "cal": "12ga", "dmg": 50.0, "pen": 2.0, "armor_dmg": 0.2, "v0": 385.0, "drag": 0.006, "pellets": 8},
	"12_ap20": {"name": "12ga AP-20 slug", "cal": "12ga", "dmg": 164.0, "pen": 37.0, "armor_dmg": 0.65, "v0": 510.0, "drag": 0.0035},
	"12_flech": {"name": "12ga Flechette", "cal": "12ga", "dmg": 25.0, "pen": 31.0, "armor_dmg": 0.26, "v0": 320.0, "drag": 0.005, "pellets": 8},
	"3006_fmj": {"name": ".30-06 FMJ", "cal": "3006", "dmg": 90.0, "pen": 40.0, "armor_dmg": 0.5, "v0": 840.0, "drag": 0.0008},
	"3006_m2": {"name": ".30-06 M2 AP", "cal": "3006", "dmg": 85.0, "pen": 55.0, "armor_dmg": 0.6, "v0": 830.0, "drag": 0.0008},
	"338_fmj": {"name": ".338 FMJ", "cal": "338", "dmg": 122.0, "pen": 47.0, "armor_dmg": 0.6, "v0": 900.0, "drag": 0.00045},
	"338_ap": {"name": ".338 AP", "cal": "338", "dmg": 115.0, "pen": 79.0, "armor_dmg": 0.87, "v0": 849.0, "drag": 0.00045},
	"338_tacx": {"name": ".338 TAC-X", "cal": "338", "dmg": 196.0, "pen": 18.0, "armor_dmg": 0.5, "v0": 880.0, "drag": 0.00045, "frag": 0.5},
}


static func of(id: String) -> Dictionary:
	var d := DEFAULTS.duplicate()
	d.merge(ROWS[id], true)
	d["id"] = id
	return d


static func grades(cal: String) -> Array:
	return CALIBERS[cal]


## Next grade in the caliber's list (wraps), for the bench.
static func next_grade(id: String) -> String:
	var list: Array = CALIBERS[ROWS[id]["cal"]]
	return list[(list.find(id) + 1) % list.size()]
