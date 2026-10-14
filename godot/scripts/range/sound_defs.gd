class_name SoundDefs
## Range sound table: which recorded sample plays for which item and event (files in assets/audio/range/, credits in
## CREDITS.md there). Guns resolve by gun id, then calibre, then class. Names are file stems without ".ogg".

const DIR := "res://assets/audio/range/"
const GUN_EVENTS := ["shot", "shot_suppressed", "tail", "dry", "mag_out", "mag_in", "action", "mode"]

## Report profiles: shot sample, suppressed sample, distant/room tail, shot level (dB).
const PROFILES := {
	"pistol45": {"shot": "shot_1911", "sup": "sup_pistol", "tail": "tail_1911", "db": -1.0},
	"pistol9": {"shot": "shot_ppq", "sup": "sup_pistol", "tail": "tail_ppq", "db": -2.0},
	"mag44": {"shot": "shot_44mag", "sup": "sup_heavy", "tail": "tail_savage", "db": 2.0},
	"smg9": {"shot": "shot_cg", "sup": "sup_smg", "tail": "tail_cg", "db": -2.0},
	"smg45": {"shot": "shot_vector", "sup": "sup_smg", "tail": "tail_cg", "db": -2.0},
	"smg57": {"shot": "shot_p90", "sup": "sup_smg", "tail": "tail_ppsh", "db": -3.0},
	"ak": {"shot": "shot_ak", "sup": "sup_rifle", "tail": "tail_ak", "db": 0.0},
	"m4": {"shot": "shot_ar15", "sup": "sup_rifle", "tail": "tail_ar15", "db": -1.0},
	"nato762": {"shot": "shot_scar", "sup": "sup_rifle", "tail": "tail_savage", "db": 1.0},
	"sks": {"shot": "shot_sks", "sup": "sup_rifle", "tail": "tail_sks", "db": 0.0},
	"dmr": {"shot": "shot_sr25", "sup": "sup_sniper", "tail": "tail_savage", "db": 1.0},
	"garand": {"shot": "shot_1917", "sup": "sup_rifle", "tail": "tail_1917", "db": 1.0},
	"mosin": {"shot": "shot_mosin", "sup": "sup_heavy", "tail": "tail_mosin", "db": 1.0},
	"axmc": {"shot": "shot_338", "sup": "sup_sniper", "tail": "tail_tikka", "db": 3.0},
	"pkm": {"shot": "shot_pkm", "sup": "sup_heavy", "tail": "tail_mosin", "db": 2.0},
	"pump12": {"shot": "shot_model12", "sup": "sup_shotgun", "tail": "tail_model12", "db": 2.0},
	"tempest": {"shot": "shot_338", "sup": "sup_sniper", "tail": "tail_tikka", "db": 0.0, "pitch": 1.7},  # secret railgun: pitched-up .338 crack (+ zap, TempestFx)
	"semi12": {"shot": "shot_saiga", "sup": "sup_shotgun", "tail": "tail_nova", "db": 1.0},
}
const GUN_PROFILE := {
	"m1911": "pistol45", "glock18": "pistol9", "revolver": "mag44", "mp5": "smg9", "p90": "smg57", "vector": "smg45",
	"ak47": "ak", "m4a1": "m4", "scarh": "nato762", "sks": "sks", "garand": "garand", "sr25": "dmr", "mosin": "mosin",
	"sniper": "axmc", "tempest": "tempest", "pkm": "pkm", "shotgun": "pump12", "saiga12": "semi12",
}
const CAL_PROFILE := {
	"45acp": "pistol45", "9x19": "pistol9", "44mag": "mag44", "57x28": "smg57", "762x39": "ak", "556x45": "m4",
	"762x51": "nato762", "762x54r": "mosin", "3006": "garand", "338": "axmc", "12ga": "pump12",
}
const CLASS_PROFILE := {
	"pistol": "pistol45", "smg": "smg9", "assault rifle": "ak", "shotgun": "pump12", "marksman": "sks",
	"bolt-action": "mosin", "lmg": "pkm",
}

## Mechanical sets: mag_out, mag_in, action (slide/charge/bolt/pump/belt), dry fire, fire-mode switch.
const MECH := {
	"pistol": {"mag_out": "pistol_mag_out", "mag_in": "pistol_mag_in", "action": "pistol_slide"},
	"revolver": {"mag_out": "pistol_mag_out", "mag_in": "round_in", "action": "mode_click"},
	"smg": {"mag_out": "smg_mag_out", "mag_in": "smg_mag_in", "action": "rifle_charge"},
	"rifle": {"mag_out": "rifle_mag_out", "mag_in": "rifle_mag_in", "action": "rifle_charge"},
	"semi_auto": {"mag_out": "rifle_mag_out", "mag_in": "round_in", "action": "saiga_charge"},
	"saiga": {"mag_out": "rifle_mag_out", "mag_in": "rifle_mag_in", "action": "saiga_charge"},
	"pump": {"mag_out": "pistol_mag_out", "mag_in": "shotgun_shell_in", "action": "shotgun_pump"},
	"bolt": {"mag_out": "pistol_mag_out", "mag_in": "round_in", "action": "bolt_action"},
	"garand": {"mag_out": "garand_ping", "mag_in": "smg_mag_in", "action": "rifle_charge"},
	"belt": {"mag_out": "belt_open", "mag_in": "lmg_belt_in", "action": "belt_close"},
}
const GUN_MECH := {
	"m1911": "pistol", "glock18": "pistol", "revolver": "revolver", "mp5": "smg", "p90": "smg", "vector": "smg",
	"ak47": "rifle", "m4a1": "rifle", "scarh": "rifle", "sks": "semi_auto", "garand": "garand", "sr25": "rifle",
	"mosin": "bolt", "sniper": "bolt", "pkm": "belt", "shotgun": "pump", "saiga12": "saiga",
}
const CLASS_MECH := {"pistol": "pistol", "smg": "smg", "assault rifle": "rifle", "shotgun": "pump", "marksman": "semi_auto",
	"bolt-action": "bolt", "lmg": "belt"}
const DRY := "dry_click"
const MODE := "mode_click"

## Attachment fit / remove, by attachment id (slots: sight, muzzle, under, mag).
const ATTACH := {
	"reddot": {"fit": "attach_sight_fit", "remove": "attach_sight_rem"},
	"holo": {"fit": "attach_sight_fit", "remove": "attach_sight_rem"},
	"acog3x": {"fit": "attach_sight_fit", "remove": "attach_sight_rem"},
	"lpvo": {"fit": "attach_sight_fit", "remove": "attach_sight_rem"},
	"scope8x": {"fit": "attach_sight_fit", "remove": "attach_sight_rem"},
	"suppressor": {"fit": "attach_muzzle_fit", "remove": "attach_muzzle_rem"},
	"compensator": {"fit": "attach_muzzle_fit", "remove": "attach_muzzle_rem"},
	"flashhider": {"fit": "attach_muzzle_fit", "remove": "attach_muzzle_rem"},
	"vgrip": {"fit": "attach_under_fit", "remove": "attach_under_rem"},
	"agrip": {"fit": "attach_under_fit", "remove": "attach_under_rem"},
	"laser": {"fit": "attach_latch", "remove": "attach_under_rem"},
	"extmag": {"fit": "attach_mag_fit", "remove": "attach_mag_rem"},
}

## Inventory sounds by item kind (ItemDefs kind, plus "attachment" and "utility").
const INVENTORY := {
	"gun": {"pick": "inv_metal", "drop": "inv_drop_gun", "move": "inv_metal_move"},
	"mag": {"pick": "inv_plastic", "drop": "inv_metal_heavy", "move": "inv_metal_move"},
	"ammo": {"pick": "inv_coins", "drop": "inv_coins", "move": "inv_coins_move"},
	"armor": {"pick": "inv_cloth", "drop": "inv_soft", "move": "inv_cloth_move"},
	"rig": {"pick": "inv_cloth", "drop": "inv_soft", "move": "inv_cloth_move"},
	"backpack": {"pick": "inv_leather_big", "drop": "inv_soft", "move": "inv_leather_move"},
	"med": {"pick": "inv_plastic", "drop": "inv_soft", "move": "inv_cloth_move"},
	"attachment": {"pick": "inv_metal", "drop": "inv_metal_heavy", "move": "inv_metal_move"},
	"utility": {"pick": "inv_metal", "drop": "inv_wood", "move": "inv_metal_move"},
}

## Utility items (UTIL code calls RangeAudio.util(id, event, pos)).
const UTILITY := {
	"grapple": {"fire": "grapple_fire", "reel": "grapple_reel", "impact": "grapple_impact", "release": "grapple_release", "ready": "mode_click"},
	"frag": {"pin": "grenade_pin", "throw": "throw_whoosh", "bounce": "grenade_bounce", "blast": "frag_blast"},
	"smoke": {"pin": "grenade_pin", "throw": "throw_whoosh", "bounce": "smoke_bounce", "hiss": "smoke_hiss"},
	"flash": {"pin": "grenade_pin", "throw": "throw_whoosh", "bounce": "grenade_bounce", "bang": "flash_bang", "tinnitus": "flash_tinnitus"},
	"stim": {"use": "stim_use"},
	"binoculars": {"raise": "binoc_raise", "lower": "binoc_lower", "zoom": "binoc_zoom"},
}


## Profile key for a gun: explicit id, else calibre, else class.
static func profile_of(gun_id: String, cal := "", cls := "") -> String:
	if GUN_PROFILE.has(gun_id):
		return GUN_PROFILE[gun_id]
	if CAL_PROFILE.has(cal):
		return CAL_PROFILE[cal]
	return CLASS_PROFILE.get(cls, "ak")


static func mech_of(gun_id: String, cls := "") -> Dictionary:
	return MECH[GUN_MECH.get(gun_id, CLASS_MECH.get(cls, "rifle"))]


## Sample stem for one gun event ("" when unmapped).
static func gun_event(gun_id: String, ev: String, cal := "", cls := "") -> String:
	var p: Dictionary = PROFILES[profile_of(gun_id, cal, cls)]
	match ev:
		"shot":
			return p["shot"]
		"shot_suppressed":
			return p["sup"]
		"tail":
			return p["tail"]
		"dry":
			return DRY
		"mode":
			return MODE
		_:
			return mech_of(gun_id, cls).get(ev, "")


static func path(stem: String) -> String:
	return DIR + stem + ".ogg"
