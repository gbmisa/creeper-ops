class_name SecretArms
## Hidden weapons, kept out of WeaponDefs.ORDER / ROWS (so never in the rack, crates, loot or sound test).
## WeaponDefs.of / TacAmmoDefs.of / ItemDefs fall back to these tables. The Tempest is a power railgun:
## 600 rpm, 200-round cell, no recoil or sway, flat fast round, pen 100, kills any zone. Weight 0 kg, sidearm slot.

const TEMPEST := "tempest"
const CELL := "tempest_cell"

const ROWS := {
	"tempest": {"tier": 3, "unlock": 99, "role": "Secret railgun", "slots": [], "name": "TEMPEST", "class": "pistol", "cal": "tempest",
		"mag": 200, "rpm": 600.0, "modes": ["auto"], "ergo": 90.0, "conv": 8.4, "cam_share": 0.15, "angle": 90.0, "kg": 0.0,
		"up": 0.0, "side": 0.0, "moa": 0.0, "action": "detachable", "cycle": 0.0, "reload": 1.0, "reload_fast": 1.0,
		"spares": 0, "zeros": [100.0], "ads_pos": Vector3(0.0, -0.0698, -0.370), "hip_pos": Vector3(0.15, -0.14, -0.34),
		"model": "tempest", "model_fallback": "sniper", "grip_r": Vector3(0.047, -0.030, 0.135),
		"grip_l": Vector3(-0.035, -0.03, 0.14), "mag_l": Vector3(0.0, -0.09, 0.10), "butt": -0.1, "inv_w": 2, "inv_h": 1,
		"scope": 1.0, "hip": 0.0, "no_recoil": true},
}
const AMMO := {
	"tempest_cell": {"name": "Tempest cell", "cal": "tempest", "dmg": 9999.0, "pen": 100.0, "armor_dmg": 0.0, "v0": 2500.0,
		"drag": 0.0, "lbleed": 0.0, "hbleed": 0.0, "malf": 0.0},
}
const CALIBERS := {"tempest": ["tempest_cell"]}
const CHAIN_R := 4.0       # m: arc to bots this close to the impact
const CHAIN_DMG := 9999.0


static func has_weapon(id: String) -> bool:
	return ROWS.has(id)
