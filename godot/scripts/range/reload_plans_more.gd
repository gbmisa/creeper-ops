class_name ReloadPlansMore
## FB-R2: reload plans beyond ReloadAnims.PLANS (same phase format, read through ReloadAnims.plan).
##   boltbox  bolt-action with a detachable box mag (AXMC, Mosin): straight mag out / in like the AR; on an empty
##            chamber the "bolt" mark (end of `settle`) has the viewmodel work the bolt over the `work` phase
##            (BoltCycle on the Mosin, the glb's cycle clip on the AXMC; ReloadTimeline.mark_next_len = its length).

const BOLT_POSE := [Vector3(-0.10, 0.10, -0.10), Vector3(0.15, 0.55, -0.85)]  # as ReloadAnims.RIFLE_POSE

const PLANS := {
	"boltbox": {
		"plain": [
			{"n": "start", "w": 0.14, "gp": BOLT_POSE[0], "gr": BOLT_POSE[1], "hl": "mag"},
			{"n": "out", "w": 0.12, "mag": "out", "ease": "out", "mark": "mag_out"},
			{"n": "stow", "w": 0.14, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.07, "mark": "mag_show"},
			{"n": "show", "w": 0.11, "mag": "near"},
			{"n": "tip", "w": 0.07, "mag": "slip", "ease": "out"},
			{"n": "seat", "w": 0.07, "mag": "seat", "gp": BOLT_POSE[0] + Vector3(0, 0.015, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.04, "gp": BOLT_POSE[0]},
			{"n": "ready", "w": 0.24, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [  # mag release: the old mag slides out and falls while the hand goes to the pouch
			{"n": "start", "w": 0.13, "gp": BOLT_POSE[0], "gr": BOLT_POSE[1], "hl": "pouch"},
			{"n": "slip", "w": 0.06, "mag": "slip", "ease": "out", "mark": "mag_out"},
			{"n": "drop", "w": 0.12, "mag": "drop", "ease": "in"},
			{"n": "fetch", "w": 0.08, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.15, "mag": "near", "hl": "mag"},
			{"n": "tip", "w": 0.07, "mag": "slip", "ease": "out"},
			{"n": "seat", "w": 0.07, "mag": "seat", "gp": BOLT_POSE[0] + Vector3(0, 0.015, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.06, "gp": BOLT_POSE[0]},
			{"n": "ready", "w": 0.26, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge": [  # support hand back on the fore-end, gun back at rest: the bolt is worked as after a shot
			{"n": "settle", "w": 0.30, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip", "mark": "bolt"},
			{"n": "work", "w": 0.70, "mark": "charged"},
		],
		"charge_takes": {"hold": 1.0, "fetch": 0.6, "ready": 0.4},
	},
}
