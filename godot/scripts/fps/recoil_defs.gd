class_name RecoilDefs
## Per-weapon recoil feel data (Art 3, brief F). FEEL ONLY: damage, fire rate, range and
## ammo are untouched, so time-to-kill never changes. kick: viewmodel spring strength per
## shot (1.0 = one crossbow shot). cam: multiplier on the camera punch AND the sustained
## climb (1.0 = rifle baseline). yaw: random camera yaw punch per shot (rad, recovers).
## bloom_*: Pulse Rifle spread while LMB is held (degrees). climb: sustained vertical
## camera climb added per shot while held (rad); climb_max: its cap (rad). Both ease back
## after release, so tap-fire is unaffected. drift: scales the random yaw-drift part of
## the climb (1.0 = normal, 0.0 = deterministic vertical climb only).

const DEFS := {
	"rifle": { "kick": 0.85, "cam": 1.0, "yaw": 1.0, "bloom_add": 0.8, "bloom_max": 5.5, "bloom_recover": 6.0,
		"climb": 0.004, "climb_max": 0.045 },
	"crossbow": { "kick": 2.0, "cam": 1.2, "yaw": 1.3, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0,
		"climb": 0.006, "climb_max": 0.02 },
	"rocket": { "kick": 2.4, "cam": 1.4, "yaw": 2.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0,
		"climb": 0.008, "climb_max": 0.03 },
	"sprayer": { "kick": 0.15, "cam": 0.0, "yaw": 0.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0,
		"climb": 0.0, "climb_max": 0.0 },
	"railgun": { "kick": 1.9, "cam": 1.1, "yaw": 1.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0,
		"climb": 0.006, "climb_max": 0.025 },
	"plasma": { "kick": 0.16, "cam": 0.2, "yaw": 0.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0,
		"climb": 0.0025, "climb_max": 0.045, "drift": 0.0 },
	"demo": { "kick": 1.2, "cam": 1.0, "yaw": 1.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0,
		"climb": 0.006, "climb_max": 0.025 },
}


static func of(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["rifle"])
