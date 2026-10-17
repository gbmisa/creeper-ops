class_name ReloadPlansMore
## FB-R2: reload plans beyond ReloadAnims.PLANS (same phase format, read through ReloadAnims.plan).
##   boltbox  bolt-action with a detachable box mag (AXMC, Mosin): straight mag out / in like the AR; on an empty
##            chamber the "bolt" mark (end of `settle`) has the viewmodel work the bolt over the `work` phase
##            (BoltCycle on the Mosin, the glb's cycle clip on the AXMC; ReloadTimeline.mark_next_len = its length).

##   tube     pump shotgun: one shell per press (the logic loads one round per reload): from the pouch on the belt
##            to the loading port, thumbed in. The shell is a loose round (rig "loose"), hidden in the gun at rest.
##   enbloc   M1 Garand: the empty clip pings out, a full one from the pouch is thumbed down into the receiver, the
##            hand jerks clear and the bolt slams home (gun bump).
##   cylinder revolver: the cylinder swings out on its crane (rig "hinge"), muzzle up, the empties fall out, a
##            speedloader goes in, the cylinder is pushed home. The rounds ride the cylinder (rig "mag_on_hinge").
## Tube / en-bloc reload_fast is the same time as reload: "fast" is the same list.

const BOLT_POSE := [Vector3(-0.10, 0.10, -0.10), Vector3(0.15, 0.55, -0.85)]  # as ReloadAnims.RIFLE_POSE
const TUBE_POSE := [Vector3(-0.08, 0.08, -0.08), Vector3(0.15, 0.50, -1.25)]  # rolled right: the loading port to the hand
const GARAND_POSE := [Vector3(-0.06, 0.06, -0.06), Vector3(0.10, 0.45, 0.25)]  # receiver top turned to the camera
const REV_POSE := [Vector3(-0.07, 0.08, -0.10), Vector3(0.35, 0.35, -0.60)]  # as ReloadAnims.PISTOL_POSE

const TUBE := [
	{"n": "start", "w": 0.18, "gp": TUBE_POSE[0], "gr": TUBE_POSE[1], "hl": "mag"},  # hand down to a shell on the belt
	{"n": "fetch", "w": 0.26, "mag": "near", "mark": "mag_show"},  # shell under the port, nose first
	{"n": "push", "w": 0.16, "mag": "seat", "ease": "out", "mark": "mag_in"},  # thumbed into the tube
	{"n": "ready", "w": 0.40, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
]
const ENBLOC := [
	{"n": "start", "w": 0.11, "gp": GARAND_POSE[0], "gr": GARAND_POSE[1], "hl": "pouch"},
	{"n": "ping", "w": 0.08, "mag": "ping", "ease": "out", "mark": "mag_out"},  # the empty clip flies up and out
	{"n": "fall", "w": 0.10, "mag": "drop", "ease": "in"},
	{"n": "fetch", "w": 0.12, "mag": "pouch", "hl": "mag", "mark": "mag_show"},
	{"n": "show", "w": 0.12, "mag": "near"},  # full clip above the open receiver
	{"n": "press", "w": 0.12, "mag": "seat", "ease": "in", "mark": "mag_in"},  # thumbed down
	{"n": "clear", "w": 0.08, "hl": "clear", "ease": "out"},  # the hand jerks up and forward, out of the bolt's way
	{"n": "slam", "w": 0.05, "gp": GARAND_POSE[0] + Vector3(0, 0, 0.015), "ease": "out", "mark": "charged"},
	{"n": "ready", "w": 0.22, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
]
const CYLINDER := [
	{"n": "start", "w": 0.08, "gp": REV_POSE[0], "gr": REV_POSE[1], "hl": "mag"},  # left fingers on the cylinder
	{"n": "open", "w": 0.08, "open": 1.0, "ease": "out"},  # swung out on the crane
	{"n": "kick", "w": 0.06, "gr": REV_POSE[1] + Vector3(0.9, 0.0, 0.0), "mag": "slip", "hl": "let", "mark": "mag_out"},
	{"n": "fall", "w": 0.10, "mag": "drop", "ease": "in"},  # muzzle up: the empties fall out the back
	{"n": "fetch", "w": 0.16, "gr": REV_POSE[1], "mag": "pouch", "hl": "pouch", "mark": "mag_show"},
	{"n": "show", "w": 0.14, "mag": "near", "hl": "mag"},  # speedloader behind the open cylinder
	{"n": "insert", "w": 0.08, "mag": "seat", "ease": "out", "mark": "mag_in"},
	{"n": "twist", "w": 0.06},  # speedloader released
	{"n": "close", "w": 0.08, "open": 0.0, "ease": "in"},  # cylinder pushed home
	{"n": "ready", "w": 0.16, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
]

const PLANS := {
	"tube": {"plain": TUBE, "fast": TUBE, "mag_from": "pouch"},
	"enbloc": {"plain": ENBLOC, "fast": ENBLOC},
	"cylinder": {"plain": CYLINDER, "fast": CYLINDER},
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
