class_name WeaponDefs
## Weapon rows. action: detachable (chamber + mag), tube (pump, loads one at a time), enbloc (Garand clip).
## cycle > 0: bolt/pump must cycle after every shot. ads_pos / hip_pos (viewmodel offsets, m) and scope are viewmodel data (range/).

const ORDER := ["m1911", "p90", "ak47", "shotgun", "garand", "sniper"]

const ROWS := {
	"m1911": {"name": "M1911A1", "class": "pistol", "cal": "45acp", "mag": 7, "rpm": 500.0, "modes": ["semi"], "ergo": 90.0,
		"kg": 1.1, "up": 1.6, "side": 0.6, "moa": 4.5, "action": "detachable", "cycle": 0.0, "reload": 2.0, "reload_fast": 1.3,
		"spares": 3, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.0698, -0.370), "hip_pos": Vector3(0.15, -0.14, -0.34),
		"model": "m1911", "scope": 1.0},
	"p90": {"name": "FN P90", "class": "smg", "cal": "57x28", "mag": 50, "rpm": 900.0, "modes": ["semi", "auto"], "ergo": 74.0,
		"kg": 2.6, "up": 0.35, "side": 0.25, "moa": 3.2, "action": "detachable", "cycle": 0.0, "reload": 2.8, "reload_fast": 1.9,
		"spares": 3, "zeros": [50.0], "ads_pos": Vector3(0.0000, -0.0795, -0.850), "hip_pos": Vector3(0.17, -0.17, -0.45),
		"model": "p90", "scope": 1.0},
	"ak47": {"name": "AK-47", "class": "assault rifle", "cal": "762x39", "mag": 30, "rpm": 600.0, "modes": ["semi", "auto"], "ergo": 50.0,
		"kg": 3.6, "up": 0.75, "side": 0.45, "moa": 3.0, "action": "detachable", "cycle": 0.0, "reload": 3.0, "reload_fast": 2.1,
		"spares": 3, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.1130, -0.950), "hip_pos": Vector3(0.16, -0.18, -0.58),
		"model": "ak47", "scope": 1.0},
	"shotgun": {"name": "M870", "class": "shotgun", "cal": "12ga", "mag": 6, "rpm": 120.0, "modes": ["semi"], "ergo": 55.0,
		"kg": 3.4, "up": 3.0, "side": 1.0, "moa": 10.0, "action": "tube", "cycle": 0.55, "reload": 0.9, "reload_fast": 0.9,
		"spares": 24, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.0973, -0.760), "hip_pos": Vector3(0.16, -0.17, -0.62),
		"model": "shotgun", "scope": 1.0, "pellet_spread": 2.2},
	"garand": {"name": "M1 Garand", "class": "marksman", "cal": "3006", "mag": 8, "rpm": 400.0, "modes": ["semi"], "ergo": 40.0,
		"kg": 4.3, "up": 1.8, "side": 0.7, "moa": 1.8, "action": "enbloc", "cycle": 0.0, "reload": 2.6, "reload_fast": 2.6,
		"spares": 4, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.0940, -0.810), "hip_pos": Vector3(0.16, -0.17, -0.66),
		"model": "garand", "scope": 1.0},
	"sniper": {"name": "AXMC .338", "class": "bolt-action", "cal": "338", "mag": 5, "rpm": 60.0, "modes": ["semi"], "ergo": 35.0,
		"kg": 6.5, "up": 3.5, "side": 0.8, "moa": 0.6, "action": "detachable", "cycle": 1.1, "reload": 3.2, "reload_fast": 2.3,
		"spares": 4, "zeros": [100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.0970, -0.860), "hip_pos": Vector3(0.16, -0.18, -0.72),
		"model": "sniper", "scope": 6.0},
}


static func of(id: String) -> Dictionary:
	var d: Dictionary = ROWS[id].duplicate()
	d["id"] = id
	return d
