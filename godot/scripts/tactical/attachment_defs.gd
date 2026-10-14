class_name AttachmentDefs
## Gun attachments (RANGE5 GUNS-2). slot = sight / muzzle / under / mag. `mods` multiply Gun.stat(name) while fitted
## (names: up, side = recoil, hip = hip-fire cone, ads_mult = ADS time, noise = bot hearing radius, flash = muzzle flash
## 0/1, vel = muzzle velocity, mag = capacity, reload = reload time). Sights: zoom (lpvo also zoom_max, toggled with t_zoom),
## axis_h (optic centre above the rail, m), win (window size, m), ret (reticle), `only` (gun ids) limits scope8x to sniper rails.
## size / len are the placeholder box (m); an attachments/<id>.glb replaces it when ART delivers one.

const SLOTS := ["sight", "muzzle", "under", "mag"]
const ROWS := {
	"reddot": {"name": "Red dot sight", "slot": "sight", "w": 1, "h": 1, "kg": 0.15, "zoom": 1.0, "axis_h": 0.032, "win": 0.024,
		"depth": 0.06, "ret": "dot", "mods": {"ads_mult": 0.9}, "note": "1x, fast ADS"},
	"holo": {"name": "Holographic sight", "slot": "sight", "w": 1, "h": 1, "kg": 0.30, "zoom": 1.0, "axis_h": 0.036, "win": 0.034,
		"depth": 0.07, "ret": "ring", "mods": {"ads_mult": 0.95}, "note": "1x, wide window"},
	"acog3x": {"name": "ACOG 3x", "slot": "sight", "w": 2, "h": 1, "kg": 0.40, "zoom": 3.0, "axis_h": 0.040, "win": 0.03,
		"depth": 0.13, "ret": "chevron", "mods": {"ads_mult": 1.15}, "note": "3x, slower ADS"},
	"lpvo": {"name": "LPVO 1-6x", "slot": "sight", "w": 2, "h": 1, "kg": 0.60, "zoom": 1.0, "zoom_max": 6.0, "axis_h": 0.044,
		"win": 0.034, "depth": 0.17, "ret": "cross", "mods": {"ads_mult": 1.2}, "note": "1-6x, toggle zoom"},
	"scope8x": {"name": "Scope 8x", "slot": "sight", "w": 3, "h": 1, "kg": 0.80, "zoom": 8.0, "axis_h": 0.046, "win": 0.036,
		"depth": 0.28, "ret": "mildot", "mods": {"ads_mult": 1.3}, "only": ["sniper", "mosin", "sr25"], "note": "8x, sniper rails only"},
	"suppressor": {"name": "Suppressor", "slot": "muzzle", "w": 2, "h": 1, "kg": 0.50, "len": 0.17, "girth": 0.04,
		"mods": {"noise": 0.4, "flash": 0.0, "vel": 0.95}, "note": "bot hearing x0.4, no flash, -5% velocity"},
	"compensator": {"name": "Compensator", "slot": "muzzle", "w": 1, "h": 1, "kg": 0.15, "len": 0.05, "girth": 0.035,
		"mods": {"up": 0.8, "noise": 1.25}, "note": "vertical recoil -20%, louder"},
	"flashhider": {"name": "Flash hider", "slot": "muzzle", "w": 1, "h": 1, "kg": 0.12, "len": 0.07, "girth": 0.03,
		"mods": {"flash": 0.0, "side": 0.9}, "note": "no flash, horizontal recoil -10%"},
	"vgrip": {"name": "Vertical grip", "slot": "under", "w": 1, "h": 1, "kg": 0.14, "len": 0.09, "girth": 0.03,
		"mods": {"up": 0.85}, "note": "vertical recoil -15%"},
	"agrip": {"name": "Angled grip", "slot": "under", "w": 1, "h": 1, "kg": 0.12, "len": 0.08, "girth": 0.03,
		"mods": {"ads_mult": 0.85}, "note": "ADS time -15%"},
	"laser": {"name": "Laser pointer", "slot": "under", "w": 1, "h": 1, "kg": 0.10, "len": 0.06, "girth": 0.03,
		"mods": {"hip": 0.7}, "note": "hip spread -30%, visible beam (bots see it from further)"},
	"extmag": {"name": "Extended magazine", "slot": "mag", "w": 1, "h": 2, "kg": 0.25, "len": 0.10, "girth": 0.03,
		"mods": {"mag": 1.5, "reload": 1.2}, "note": "+50% capacity, 20% slower reload"},
}


static func has(id: String) -> bool:
	return ROWS.has(id)


static func of(id: String) -> Dictionary:
	var d: Dictionary = ROWS[id].duplicate()
	d["id"] = id
	d["kind"] = "attach"
	return d


## "" when the attachment fits the gun def, else why not.
static func why_not(gun_def: Dictionary, id: String) -> String:
	var r: Dictionary = ROWS[id]
	if not (r["slot"] in gun_def["slots"]):
		return "%s has no %s slot" % [gun_def["name"], r["slot"]]
	if r.has("only") and not (gun_def["id"] in r["only"]):
		return "%s needs a sniper rail" % r["name"]
	return ""


static func describe(id: String) -> String:
	return "%s: %s" % [String(ROWS[id]["slot"]).capitalize(), ROWS[id]["note"]]
