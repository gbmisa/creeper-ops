class_name BowDefs
## F146: the compound bow and the crossbow. Kept out of WeaponDefs.ORDER / ROWS (like SecretArms) so the 17-gun roster
## loops (recoil curves, mag items, irons per gun) never meet a gun without those; WeaponDefs.of / ItemDefs fall back here.
## action "bow": hold fire to draw, release to shoot (BowDraw). action "crossbow": fire shoots, reload = cock + load.
## Both hold one nocked arrow / bolt in Gun.chamber; arrows are loose inventory stacks (cal "arrow" / "bolt").
## Until models/guns/<model>.glb exists the row shows model_fallback (Opus drops compound_bow.glb / crossbow.glb in).
## Grips and sight points come from the scratch models (art/guns_src/scratch_compound_bow.py / scratch_crossbow.py).

const ROWS := {
	"compound_bow": {"tier": 1, "unlock": 1, "role": "Draw and hold: silent, arrows can be picked up again", "slots": ["sight"], "name": "Compound bow",
		"class": "bow", "cal": "arrow", "sight_ok": ["reddot", "holo", "acog3x"], "mag": 1, "rpm": 60.0, "modes": ["semi"], "ergo": 60.0,
		"conv": 8.0, "cam_share": 0.2, "angle": 90.0, "kg": 1.8, "up": 0.3, "side": 0.0, "moa": 4.0, "action": "bow", "cycle": 0.0,
		"reload": 1.0, "reload_fast": 0.8, "spares": 0, "zeros": [20.0, 40.0, 60.0], "noise": 0.08,
		"ads_pos": Vector3(0.010, -0.0800, -0.800), "hip_pos": Vector3(-0.08, -0.10, -0.78),
		"model": "compound_bow", "model_fallback": "sks", "grip_r": Vector3(-0.010, 0.000, 0.271), "grip_l": Vector3(0.007, -0.085, 0.096),
		"mag_l": Vector3(0.007, -0.085, 0.096), "butt": 0.30, "inv_w": 4, "inv_h": 3, "scope": 1.0, "sway_mult": 0.8},
	"crossbow": {"tier": 2, "unlock": 4, "role": "One bolt, slow to cock, hits harder and flatter than the bow", "slots": ["sight"], "name": "Crossbow",
		"class": "crossbow", "cal": "bolt", "sight_ok": ["reddot", "holo", "acog3x"], "mag": 1, "rpm": 60.0, "modes": ["semi"], "ergo": 50.0,
		"conv": 8.0, "cam_share": 0.2, "angle": 90.0, "kg": 3.2, "up": 0.3, "side": 0.0, "moa": 2.5, "action": "crossbow", "cycle": 0.0,
		"reload": 3.5, "reload_fast": 3.0, "spares": 0, "zeros": [20.0, 40.0, 60.0], "noise": 0.08,
		"ads_pos": Vector3(0.0, -0.1485, -0.700), "hip_pos": Vector3(0.16, -0.17, -0.60),
		"model": "crossbow", "model_fallback": "garand", "grip_r": Vector3(0.0, -0.0465, 0.185), "grip_l": Vector3(0.0, -0.0265, -0.135),
		"mag_l": Vector3(0.0, 0.0695, 0.095), "butt": 0.435, "inv_w": 4, "inv_h": 2, "scope": 1.0},
}
## Loose-ammo bows: Gun and InvReload treat these actions alike (one nocked round, refilled from the bags).
const ACTIONS := ["bow", "crossbow"]

## Draw (action "bow"). All numbers here; BowDraw only reads them.
const DRAW_TIME := 0.8        # s from nock to full draw
const MIN_DRAW := 0.25        # releasing below this fraction lets down without shooting
const MIN_SPEED := 0.3        # share of v0 at the minimum draw (speed, and with it damage, scale to 1.0 at full draw)
const HOLD_DRAIN := 0.30      # arm stamina per second at full draw (the ADS regen takes 0.12 of it back)
const SHAKE_AFTER := 4.0      # s held at full draw before the aim starts to shake
const SHAKE_RAMP := 3.0       # s over which the shake grows to SHAKE_DEG
const SHAKE_DEG := 0.5        # sway amplitude (deg) once the shake is full
const KICK_DEG := 0.3         # bow-hand kick: the view lifts this much per shot


static func has_weapon(id: String) -> bool:
	return ROWS.has(id)


static func is_loose(def: Dictionary) -> bool:
	return def["action"] in ACTIONS
