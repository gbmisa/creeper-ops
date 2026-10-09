class_name RecoilDefs
## Per-weapon recoil feel data (Art 3, brief F). FEEL ONLY: damage, fire rate, range and
## ammo are untouched, so time-to-kill never changes. kick: viewmodel spring strength per
## shot (1.0 = one crossbow shot). cam: multiplier on VM_CAM_KICK. yaw: random camera yaw
## punch per shot (rad, recovers). bloom_*: Pulse Rifle spread while LMB is held (degrees).

const DEFS := {
	"rifle": { "kick": 0.85, "cam": 1.0, "yaw": 1.0, "bloom_add": 0.28, "bloom_max": 1.4, "bloom_recover": 6.0 },
	"crossbow": { "kick": 2.0, "cam": 1.2, "yaw": 1.3, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0 },
	"rocket": { "kick": 2.4, "cam": 1.4, "yaw": 2.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0 },
	"sprayer": { "kick": 0.15, "cam": 0.0, "yaw": 0.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0 },
	"railgun": { "kick": 1.9, "cam": 1.1, "yaw": 1.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0 },
	"plasma": { "kick": 0.16, "cam": 0.2, "yaw": 0.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0 },
	"demo": { "kick": 1.2, "cam": 1.0, "yaw": 1.0, "bloom_add": 0.0, "bloom_max": 0.0, "bloom_recover": 0.0 },
}


static func of(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["rifle"])
