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
	"9x19": ["9_fmj", "9_ap", "9_hp"],
	"44mag": ["44_jhp", "44_fmj", "44_hc"],
	"556x45": ["556_m855", "556_m995", "556_ssa"],
	"762x51": ["762n_m80", "762n_m61", "762n_match"],
	"762x54r": ["54r_lps", "54r_bs", "54r_sp"],
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
	"9_fmj": {"name": "9x19 FMJ", "cal": "9x19", "dmg": 54.0, "pen": 20.0, "armor_dmg": 0.3, "v0": 360.0, "drag": 0.0022},
	"9_ap": {"name": "9x19 AP 6.3", "cal": "9x19", "dmg": 48.0, "pen": 34.0, "armor_dmg": 0.42, "v0": 340.0, "drag": 0.0022},
	"9_hp": {"name": "9x19 JHP", "cal": "9x19", "dmg": 72.0, "pen": 9.0, "armor_dmg": 0.14, "v0": 360.0, "drag": 0.0022, "frag": 0.4},
	"44_jhp": {"name": ".44 Mag JHP", "cal": "44mag", "dmg": 135.0, "pen": 14.0, "armor_dmg": 0.25, "v0": 440.0, "drag": 0.0025, "frag": 0.3},
	"44_fmj": {"name": ".44 Mag FMJ", "cal": "44mag", "dmg": 115.0, "pen": 26.0, "armor_dmg": 0.4, "v0": 450.0, "drag": 0.0025},
	"44_hc": {"name": ".44 Mag Hard Cast", "cal": "44mag", "dmg": 110.0, "pen": 38.0, "armor_dmg": 0.5, "v0": 410.0, "drag": 0.0025},
	"556_m855": {"name": "5.56 M855", "cal": "556x45", "dmg": 49.0, "pen": 37.0, "armor_dmg": 0.5, "v0": 920.0, "drag": 0.0010},
	"556_m995": {"name": "5.56 M995 AP", "cal": "556x45", "dmg": 46.0, "pen": 53.0, "armor_dmg": 0.68, "v0": 930.0, "drag": 0.0010},
	"556_ssa": {"name": "5.56 SSA", "cal": "556x45", "dmg": 72.0, "pen": 12.0, "armor_dmg": 0.18, "v0": 940.0, "drag": 0.0010, "frag": 0.4},
	"762n_m80": {"name": "7.62x51 M80", "cal": "762x51", "dmg": 74.0, "pen": 53.0, "armor_dmg": 0.62, "v0": 850.0, "drag": 0.0009},
	"762n_m61": {"name": "7.62x51 M61 AP", "cal": "762x51", "dmg": 70.0, "pen": 68.0, "armor_dmg": 0.76, "v0": 840.0, "drag": 0.0009},
	"762n_match": {"name": "7.62x51 Match", "cal": "762x51", "dmg": 82.0, "pen": 45.0, "armor_dmg": 0.55, "v0": 835.0, "drag": 0.0009, "acc": 0.8},
	"54r_lps": {"name": "7.62x54R LPS", "cal": "762x54r", "dmg": 86.0, "pen": 42.0, "armor_dmg": 0.55, "v0": 810.0, "drag": 0.0010},
	"54r_bs": {"name": "7.62x54R BS AP", "cal": "762x54r", "dmg": 80.0, "pen": 62.0, "armor_dmg": 0.72, "v0": 800.0, "drag": 0.0010},
	"54r_sp": {"name": "7.62x54R SP", "cal": "762x54r", "dmg": 120.0, "pen": 14.0, "armor_dmg": 0.25, "v0": 820.0, "drag": 0.0010, "frag": 0.5},
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
