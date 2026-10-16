class_name WeaponDefs
## Weapon rows. action: detachable (chamber + mag), tube (pump, loads one at a time), enbloc (Garand clip).
## cycle > 0: bolt/pump must cycle after every shot. ads_pos / hip_pos (viewmodel offsets, m), scope, grip_r / grip_l / mag_l (hand-bone targets in gun space, muzzle -Z, after the m1911 flip)
## and butt (m the butt plate sits behind (+) / ahead (-) of the eye at full ADS; P4: stocked guns weld the
## cheek 0.30 m forward of the plate, pistols keep an arm's-length hold) and eye (optional: the ADS eye-to-butt distance
## instead of butt, so the eye stays behind a rear sight near the stock; bots keep butt) are viewmodel data (range/).
## ads_pos.y is minus the iron sight line (gun space; art/gen/mounts.json ads_y holds the same value).
## While aiming, the viewmodel materials use z-clip scale (TacticalConfig.VM_Z_CLIP), so nothing clips the near plane (FB-H).

## Rack order: the original six, then the new lines (tier ascending within a line). RACK_ROWS groups them for the rack.
const ORDER := ["m1911", "p90", "ak47", "shotgun", "garand", "sniper",
	"glock18", "revolver", "mp5", "vector", "m4a1", "scarh", "saiga12", "sks", "sr25", "mosin", "pkm"]
## One rack line per weapon family, earlier tier first.
const RACK_ROWS := [["m1911", "glock18", "revolver"], ["mp5", "p90", "vector"], ["ak47", "m4a1", "scarh"],
	["shotgun", "saiga12"], ["sks", "garand", "sr25"], ["mosin", "sniper"], ["pkm"]]
## fit: parts a new gun comes with (slot -> AttachmentDefs id; FB-H: the P90 has no irons, so it ships with a red dot).
## model_fallback: until guns/<id>.glb exists the row uses this model (fb_flip replaces "flip" then).

const ROWS := {
	"m1911": {"tier": 1, "unlock": 1, "role": "Reliable sidearm: hard-hitting .45, 7 rounds", "slots": ["sight","muzzle"], "name": "M1911A1", "class": "pistol", "cal": "45acp", "mag": 7, "rpm": 500.0, "modes": ["semi"], "ergo": 90.0,
		"conv": 10, "cam_share": 0.15, "angle": 90.0, "kg": 1.1, "up": 1.6, "side": 0.6, "moa": 4.5, "action": "detachable", "cycle": 0.0, "reload": 2.0, "reload_fast": 1.3,
		"spares": 3, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.0670, -0.370), "hip_pos": Vector3(0.15, -0.14, -0.34),
		"model": "m1911", "grip_r": Vector3(0.047,-0.030,0.135), "grip_l": Vector3(-0.035,-0.03,0.14), "mag_l": Vector3(0.0,-0.09,0.10), "butt": -0.1, "inv_w": 2, "inv_h": 1, "scope": 1.0, "flip": true},
	"p90": {"tier": 2, "unlock": 6, "role": "Big 50-round mag, armor-piercing 5.7: sustained SMG fire", "slots": ["sight","muzzle"], "name": "FN P90", "class": "smg", "cal": "57x28", "mag": 50, "rpm": 900.0, "modes": ["semi", "auto"], "ergo": 74.0,
		"conv": 6.9, "cam_share": 0.3, "angle": 94.0, "kg": 2.6, "up": 0.35, "side": 0.25, "moa": 3.2, "action": "detachable", "cycle": 0.0, "reload": 2.8, "reload_fast": 1.9,
		"spares": 3, "zeros": [50.0], "ads_pos": Vector3(0.0000, -0.0900, -0.850), "hip_pos": Vector3(0.17, -0.17, -0.45),
		"model": "p90", "grip_r": Vector3(0.047,-0.050,0.160), "grip_l": Vector3(0.0,-0.095,0.0), "mag_l": Vector3(0.0,0.11,-0.05), "butt": 0.30, "inv_w": 3, "inv_h": 2, "scope": 1.0, "fit": {"sight": "reddot"}},
	"ak47": {"tier": 1, "unlock": 1, "role": "Rugged all-rounder: heavy hits, climbs hard", "slots": ["sight","muzzle","mag"], "name": "AK-47", "class": "assault rifle", "cal": "762x39", "mag": 30, "rpm": 600.0, "modes": ["semi", "auto"], "ergo": 50.0,
		"conv": 4.6, "cam_share": 0.35, "angle": 82.0, "kg": 3.6, "up": 0.75, "side": 0.45, "moa": 3.0, "action": "detachable", "cycle": 0.0, "reload": 3.0, "reload_fast": 2.1,
		"spares": 3, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.1310, -0.950), "hip_pos": Vector3(0.16, -0.18, -0.58),
		"model": "ak47", "grip_r": Vector3(0.042,-0.030,0.240), "grip_l": Vector3(0.0,0.04,-0.10), "mag_l": Vector3(0.0,-0.12,-0.04), "butt": 0.30, "inv_w": 4, "inv_h": 2, "scope": 1.0},
	"shotgun": {"tier": 1, "unlock": 2, "role": "Pump shotgun: devastating up close, slow", "slots": ["sight","muzzle"], "name": "M870", "class": "shotgun", "cal": "12ga", "mag": 6, "rpm": 120.0, "modes": ["semi"], "ergo": 55.0,
		"conv": 7, "cam_share": 0.5, "angle": 90.0, "kg": 3.4, "up": 3.0, "side": 1.0, "moa": 10.0, "action": "tube", "cycle": 0.55, "reload": 0.9, "reload_fast": 0.9,
		"spares": 24, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.0973, -0.760), "hip_pos": Vector3(0.16, -0.17, -0.62),
		"model": "shotgun", "grip_r": Vector3(0.042,-0.020,0.320), "grip_l": Vector3(0.0,0.015,-0.10), "mag_l": Vector3(0.0,-0.02,0.0), "butt": 0.30, "inv_w": 5, "inv_h": 2, "scope": 1.0, "pellet_spread": 2.2},
	"garand": {"tier": 2, "unlock": 8, "role": "Semi DMR: .30-06 power, 8-round clip", "slots": ["sight","muzzle"], "name": "M1 Garand", "class": "marksman", "cal": "3006", "mag": 8, "rpm": 400.0, "modes": ["semi"], "ergo": 40.0,
		"conv": 10, "cam_share": 0.35, "angle": 92.0, "kg": 4.3, "up": 1.8, "side": 0.7, "moa": 1.8, "action": "enbloc", "cycle": 0.0, "reload": 2.6, "reload_fast": 2.6,
		"spares": 4, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.0970, -0.810), "hip_pos": Vector3(0.16, -0.17, -0.66),
		"model": "garand", "grip_r": Vector3(0.042,0.000,0.340), "grip_l": Vector3(0.0,0.02,-0.15), "mag_l": Vector3(0.0,-0.02,0.0), "butt": 0.30, "inv_w": 5, "inv_h": 2, "scope": 1.0},
	"sniper": {"tier": 3, "unlock": 18, "role": "Bolt sniper: 6x scope, best accuracy and range", "slots": ["sight","muzzle","under"], "name": "AXMC .338", "class": "bolt-action", "cal": "338", "mag": 5, "rpm": 60.0, "modes": ["semi"], "ergo": 35.0,
		"conv": 6, "cam_share": 0.5, "angle": 90.0, "kg": 6.5, "up": 3.5, "side": 0.8, "moa": 0.6, "action": "detachable", "cycle": 1.1, "reload": 3.2, "reload_fast": 2.3,
		"spares": 4, "zeros": [100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.0970, -0.860), "hip_pos": Vector3(0.16, -0.18, -0.72),
		"model": "sniper", "grip_r": Vector3(0.042,-0.040,0.340), "grip_l": Vector3(0.0,0.0,-0.15), "mag_l": Vector3(0.0,-0.03,0.05), "butt": 0.30, "inv_w": 5, "inv_h": 2, "scope": 6.0, "sway_mult": 0.5},
	"glock18": {"tier": 2, "unlock": 8, "role": "Full-auto pistol: holster CQB burst, poor range and pen", "slots": ["sight","muzzle"], "name": "Glock 18", "class": "pistol", "cal": "9x19", "mag": 17, "rpm": 1100.0, "modes": ["semi", "auto"], "ergo": 88.0,
		"conv": 8.4, "cam_share": 0.15, "angle": 84.0, "kg": 0.9, "up": 2.4, "side": 1.1, "moa": 5.5, "action": "detachable", "cycle": 0.0, "reload": 1.9, "reload_fast": 1.2,
		"spares": 3, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.0510, -0.370), "hip_pos": Vector3(0.15, -0.14, -0.34), "grip_r": Vector3(0.047,-0.030,0.135), "grip_l": Vector3(-0.035,-0.03,0.14), "mag_l": Vector3(0.0,-0.09,0.10), "butt": -0.1,
		"model": "glock18", "model_fallback": "m1911", "inv_w": 2, "inv_h": 1, "scope": 1.0, "fb_flip": true},
	"revolver": {"tier": 3, "unlock": 20, "role": "6 rounds, one-shots limbs, slow reload, huge recoil", "slots": ["sight","muzzle"], "name": "Colt .44 Magnum", "class": "pistol", "cal": "44mag", "mag": 6, "rpm": 120.0, "modes": ["semi"], "ergo": 70.0,
		"conv": 7, "cam_share": 0.15, "angle": 92.0, "kg": 1.5, "up": 4.5, "side": 1.2, "moa": 3.5, "action": "enbloc", "cycle": 0.0, "reload": 5.0, "reload_fast": 5.0,
		"spares": 3, "zeros": [25.0, 50.0], "ads_pos": Vector3(0.0000, -0.0698, -0.370), "hip_pos": Vector3(0.15, -0.14, -0.34), "grip_r": Vector3(0.047,-0.030,0.135), "grip_l": Vector3(-0.035,-0.03,0.14), "mag_l": Vector3(0.0,-0.09,0.10), "butt": -0.1,
		"model": "revolver", "model_fallback": "m1911", "inv_w": 2, "inv_h": 1, "scope": 1.0, "fb_flip": true},
	"mp5": {"tier": 1, "unlock": 1, "role": "Accurate, low-recoil SMG: the safe CQB pick", "slots": ["sight","muzzle","under"], "name": "MP5", "class": "smg", "cal": "9x19", "mag": 30, "rpm": 800.0, "modes": ["semi", "auto"], "ergo": 72.0,
		"conv": 6.1, "cam_share": 0.3, "angle": 88.0, "kg": 2.9, "up": 0.3, "side": 0.2, "moa": 2.2, "action": "detachable", "cycle": 0.0, "reload": 2.5, "reload_fast": 1.7,
		"spares": 4, "zeros": [25.0, 50.0, 100.0], "ads_pos": Vector3(0.0000, -0.1310, -0.850), "hip_pos": Vector3(0.17, -0.17, -0.45), "grip_r": Vector3(0.047,-0.050,0.160), "grip_l": Vector3(0.0,-0.1295,-0.136), "mag_l": Vector3(0.0,0.11,-0.05), "butt": 0.30, "eye": 0.10,
		"model": "mp5", "model_fallback": "p90", "inv_w": 3, "inv_h": 2, "scope": 1.0},
	"vector": {"tier": 3, "unlock": 22, "role": "1100 rpm, tiny recoil, short range, eats mags", "slots": ["sight","muzzle","under","mag"], "name": "KRISS Vector", "class": "smg", "cal": "45acp", "mag": 25, "rpm": 1100.0, "modes": ["semi", "auto"], "ergo": 78.0,
		"conv": 8.4, "cam_share": 0.3, "angle": 95.0, "kg": 2.7, "up": 0.18, "side": 0.12, "moa": 3.8, "action": "detachable", "cycle": 0.0, "reload": 2.2, "reload_fast": 1.5,
		"spares": 5, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.1940, -0.850), "hip_pos": Vector3(0.17, -0.17, -0.45), "grip_r": Vector3(0.047,-0.050,0.160), "grip_l": Vector3(0.0,-0.095,0.0), "mag_l": Vector3(0.0,0.11,-0.05), "butt": 0.30, "eye": -0.12,
		"model": "vector", "model_fallback": "p90", "inv_w": 3, "inv_h": 2, "scope": 1.0},
	"m4a1": {"tier": 2, "unlock": 10, "role": "Low recoil, most attachment slots: the upgrade over the AK", "slots": ["sight","muzzle","under","mag"], "name": "M4A1", "class": "assault rifle", "cal": "556x45", "mag": 30, "rpm": 800.0, "modes": ["semi", "auto"], "ergo": 62.0,
		"conv": 6.1, "cam_share": 0.3, "angle": 88.0, "kg": 3.2, "up": 0.5, "side": 0.3, "moa": 2.0, "action": "detachable", "cycle": 0.0, "reload": 2.6, "reload_fast": 1.8,
		"spares": 3, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.1540, -0.950), "hip_pos": Vector3(0.16, -0.18, -0.58), "grip_r": Vector3(0.042,-0.030,0.240), "grip_l": Vector3(0.0,0.04,-0.10), "mag_l": Vector3(0.0,-0.12,-0.04), "butt": 0.30, "eye": 0.08,
		"model": "m4a1", "arms_pose": "arms_m4a1", "model_fallback": "ak47", "inv_w": 4, "inv_h": 2, "scope": 1.0},
	"scarh": {"tier": 3, "unlock": 25, "role": "7.62 NATO penetration, heavier, slower ADS", "slots": ["sight","muzzle","under","mag"], "name": "SCAR-H", "class": "assault rifle", "cal": "762x51", "mag": 20, "rpm": 600.0, "modes": ["semi", "auto"], "ergo": 45.0,
		"conv": 4.6, "cam_share": 0.35, "angle": 86.0, "kg": 4.4, "up": 0.85, "side": 0.45, "moa": 1.8, "action": "detachable", "cycle": 0.0, "reload": 3.2, "reload_fast": 2.3,
		"spares": 3, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.1460, -0.950), "hip_pos": Vector3(0.16, -0.18, -0.58), "grip_r": Vector3(0.042,-0.030,0.240), "grip_l": Vector3(0.0,0.04,-0.10), "mag_l": Vector3(0.0,-0.12,-0.04), "butt": 0.30, "eye": 0.19,
		"model": "scarh", "model_fallback": "ak47", "inv_w": 5, "inv_h": 2, "scope": 1.0},
	"saiga12": {"tier": 2, "unlock": 12, "role": "Mag-fed semi shotgun: room clearing", "slots": ["sight","muzzle","mag"], "name": "Saiga-12", "class": "shotgun", "cal": "12ga", "mag": 8, "rpm": 240.0, "modes": ["semi"], "ergo": 52.0,
		"conv": 7, "cam_share": 0.5, "angle": 88.0, "kg": 3.6, "up": 2.6, "side": 0.9, "moa": 9.0, "action": "detachable", "cycle": 0.0, "reload": 3.2, "reload_fast": 2.2,
		"spares": 3, "zeros": [25.0], "ads_pos": Vector3(0.0000, -0.1880, -0.760), "hip_pos": Vector3(0.16, -0.17, -0.62), "grip_r": Vector3(0.042,-0.020,0.320), "grip_l": Vector3(0.0,0.015,-0.10), "mag_l": Vector3(0.0,-0.02,0.0), "butt": 0.30, "eye": 0.16,
		"model": "saiga12", "model_fallback": "shotgun", "inv_w": 5, "inv_h": 2, "scope": 1.0, "pellet_spread": 2.2},
	"sks": {"tier": 1, "unlock": 3, "role": "Cheap semi 7.62x39, iron sights: the early DMR", "slots": ["muzzle"], "name": "SKS", "class": "marksman", "cal": "762x39", "mag": 10, "rpm": 360.0, "modes": ["semi"], "ergo": 45.0,
		"conv": 10, "cam_share": 0.35, "angle": 86.0, "kg": 3.9, "up": 1.5, "side": 0.6, "moa": 2.4, "action": "detachable", "cycle": 0.0, "reload": 2.8, "reload_fast": 2.0,
		"spares": 4, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.1500, -0.810), "hip_pos": Vector3(0.16, -0.17, -0.66), "grip_r": Vector3(0.042,0.000,0.340), "grip_l": Vector3(0.0,0.02,-0.15), "mag_l": Vector3(0.0,-0.02,0.0), "butt": 0.30, "eye": 0.19,
		"model": "sks", "model_fallback": "garand", "inv_w": 5, "inv_h": 2, "scope": 1.0},
	"sr25": {"tier": 3, "unlock": 24, "role": "20-round semi DMR: best mid-range", "slots": ["sight","muzzle","under","mag"], "name": "SR-25", "class": "marksman", "cal": "762x51", "mag": 20, "rpm": 450.0, "modes": ["semi"], "ergo": 55.0,
		"conv": 10, "cam_share": 0.35, "angle": 90.0, "kg": 4.5, "up": 1.2, "side": 0.5, "moa": 1.0, "action": "detachable", "cycle": 0.0, "reload": 2.8, "reload_fast": 1.9,
		"spares": 3, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0115, -0.1040, -0.810), "hip_pos": Vector3(0.16, -0.17, -0.66), "grip_r": Vector3(0.042,0.000,0.340), "grip_l": Vector3(0.0,0.02,-0.15), "mag_l": Vector3(0.0,-0.02,0.0), "butt": 0.30,
		"model": "sr25", "model_fallback": "garand", "inv_w": 5, "inv_h": 2, "scope": 1.0},
	"mosin": {"tier": 1, "unlock": 6, "role": "Cheap bolt sniper, iron sights, strong round", "slots": ["sight","muzzle"], "name": "Mosin-Nagant", "class": "bolt-action", "cal": "762x54r", "mag": 5, "rpm": 50.0, "modes": ["semi"], "ergo": 38.0,
		"conv": 6, "cam_share": 0.5, "angle": 90.0, "kg": 4.0, "up": 3.2, "side": 0.9, "moa": 1.6, "action": "detachable", "cycle": 1.3, "reload": 3.8, "reload_fast": 2.8,
		"spares": 4, "zeros": [100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0080, -0.0910, -0.860), "hip_pos": Vector3(0.16, -0.18, -0.72), "grip_r": Vector3(0.042,-0.040,0.340), "grip_l": Vector3(0.0,0.0,-0.15), "mag_l": Vector3(0.0,-0.03,0.05), "butt": 0.30, "bolt_knob": Vector3(0.0241, 0.0644, 0.1985),
		"model": "mosin", "model_fallback": "sniper", "inv_w": 5, "inv_h": 2, "scope": 1.0},
	"pkm": {"tier": 3, "unlock": 28, "role": "100-round belt, suppression, very heavy, slow reload", "slots": ["sight","muzzle"], "name": "PKM", "class": "lmg", "cal": "762x54r", "mag": 100, "rpm": 650.0, "modes": ["auto"], "ergo": 25.0,
		"conv": 5.0, "cam_share": 0.3, "angle": 85.0, "kg": 8.4, "up": 0.9, "side": 0.6, "moa": 3.8, "action": "detachable", "cycle": 0.0, "reload": 7.0, "reload_fast": 5.5,
		"spares": 1, "zeros": [50.0, 100.0, 200.0, 300.0, 400.0, 500.0], "ads_pos": Vector3(0.0000, -0.1340, -0.950), "hip_pos": Vector3(0.16, -0.18, -0.58), "grip_r": Vector3(0.041,0.010,0.150), "grip_l": Vector3(0.0,0.015,-0.290), "mag_l": Vector3(0.029,-0.060,-0.010), "butt": 0.30, "eye": 0.17,
		"model": "pkm", "model_fallback": "ak47", "inv_w": 6, "inv_h": 2, "scope": 1.0},
}


static func of(id: String) -> Dictionary:
	var d: Dictionary = ROWS[id].duplicate()
	d["id"] = id
	if d.has("model_fallback") and not ResourceLoader.exists("res://assets/models/guns/%s.glb" % d["model"]):
		d["model"] = d["model_fallback"]
		d["flip"] = d.get("fb_flip", false)
	return d


## The gun model's AnimationPlayer; generated models have none, so an empty one is added (all clip lookups no-op).
static func anim_of(glb: Node) -> AnimationPlayer:
	var found := glb.find_children("*", "AnimationPlayer", true, false)
	if not found.is_empty():
		return found[0]
	var ap := AnimationPlayer.new()
	glb.add_child(ap)
	return ap
