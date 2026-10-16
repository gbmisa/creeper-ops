class_name ReloadAnims
## FB-R: reload animation data (Tarkov phases, TRP spec `FB_R_trp_reload_spec.md`). Read by ReloadTimeline.
## PLANS[plan][variant] is a phase list; a phase lists the pose reached at its END, keys missing inherit from the
## phase before (rest = all zero, mag "seat", hand "grip"). Weights are shares of the reload's base time; the
## "charge" variant (empty chamber only) shares TacticalConfig.CHAMBER_TIME and runs before the last phase;
## "empty_bolt" = where the bolt/slide stands for the whole of an empty reload until the charge moves it (slide lock).
##   gp / gr  gun position / rotation offset under the camera (m, rad: x pitch up, y yaw left, z roll left)
##   mag      seat | out | pouch | drop (RIGS[gun] offsets of the Mag node, gun-model space, about `pivot`)
##   hl       left hand: grip (def grip_l) | mag (the Mag node's `hold` point) | pouch | charge (+ bolt travel)
##   bolt     0..1 of RIGS[gun].travel      ease  io (default) | in (falls, speeds up) | out
##   mark     emitted on ReloadTimeline.mark when the phase ends (sound hooks: nothing listens yet)
## AKM plain reload measured in the TRP spec: mag out 0.24, out of the hand 0.38, new mag in 0.75, at rest 1.0.

const PLANS := {
	"rifle": {
		"plain": [
			{"n": "start", "w": 0.12, "gp": Vector3(-0.08, 0.07, -0.14), "gr": Vector3(0.10, 0.18, -0.50), "hl": "mag"},
			{"n": "out", "w": 0.12, "mag": "out", "gr": Vector3(0.12, 0.20, -0.55), "mark": "mag_out"},
			{"n": "stow", "w": 0.14, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.07, "mark": "mag_show"},
			{"n": "show", "w": 0.20, "mag": "out", "gr": Vector3(0.10, 0.18, -0.50)},
			{"n": "insert", "w": 0.10, "mag": "seat", "gp": Vector3(-0.08, 0.06, -0.14), "mark": "mag_in"},
			{"n": "seat", "w": 0.06, "gp": Vector3(-0.08, 0.08, -0.14), "gr": Vector3(0.12, 0.18, -0.50), "ease": "out"},
			{"n": "ready", "w": 0.19, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [
			{"n": "start", "w": 0.10, "gp": Vector3(-0.08, 0.07, -0.14), "gr": Vector3(0.10, 0.18, -0.50), "hl": "mag"},
			{"n": "drop", "w": 0.14, "mag": "drop", "hl": "pouch", "ease": "in", "mark": "mag_out"},
			{"n": "fetch", "w": 0.08, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.24, "mag": "out", "hl": "mag"},
			{"n": "insert", "w": 0.12, "mag": "seat", "gp": Vector3(-0.08, 0.06, -0.14), "mark": "mag_in"},
			{"n": "seat", "w": 0.08, "gp": Vector3(-0.08, 0.08, -0.14), "gr": Vector3(0.12, 0.18, -0.50), "ease": "out"},
			{"n": "ready", "w": 0.24, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge": [  # left hand reaches over the receiver to the handle (right side), racks it, lets it fly
			{"n": "reach", "w": 0.40, "gr": Vector3(0.06, 0.22, 0.12), "hl": "charge"},
			{"n": "pull", "w": 0.30, "bolt": 1.0, "ease": "out"},
			{"n": "release", "w": 0.30, "bolt": 0.0, "ease": "in", "mark": "charged"},
		],
	},
	"pistol": {
		"plain": [
			{"n": "start", "w": 0.12, "gp": Vector3(-0.07, 0.08, -0.10), "gr": Vector3(0.35, 0.35, -0.60), "hl": "mag"},
			{"n": "out", "w": 0.14, "mag": "out", "mark": "mag_out"},
			{"n": "stow", "w": 0.16, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.06, "mark": "mag_show"},
			{"n": "show", "w": 0.20, "mag": "out"},
			{"n": "insert", "w": 0.10, "mag": "seat", "mark": "mag_in"},
			{"n": "seat", "w": 0.06, "gp": Vector3(-0.07, 0.095, -0.10), "ease": "out"},
			{"n": "ready", "w": 0.16, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [
			{"n": "start", "w": 0.10, "gp": Vector3(-0.07, 0.08, -0.10), "gr": Vector3(0.35, 0.35, -0.60), "hl": "pouch"},
			{"n": "drop", "w": 0.14, "mag": "drop", "ease": "in", "mark": "mag_out"},
			{"n": "fetch", "w": 0.08, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.26, "mag": "out", "hl": "mag"},
			{"n": "insert", "w": 0.12, "mag": "seat", "mark": "mag_in"},
			{"n": "seat", "w": 0.08, "gp": Vector3(-0.07, 0.095, -0.10), "ease": "out"},
			{"n": "ready", "w": 0.22, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge": [  # slide locked back on empty (empty_bolt): support hand back on the grip, thumb drops the slide stop
			{"n": "regrip", "w": 0.55, "gr": Vector3(0.12, 0.15, -0.20), "hl": "grip"},
			{"n": "release", "w": 0.45, "bolt": 0.0, "ease": "in", "mark": "charged"},
		],
		"empty_bolt": 1.0,
	},
}

## Per gun (gun-model space, muzzle -Z, measured on the glb): mag offsets are [position, rotation] about `pivot`;
## `hold` = where the left hand holds the mag (seated); `charge` = the handle / slide grip point; `bone` + `travel`
## = the bone that racks and how far (rearward is +Z).
const RIGS := {
	"ak47": {"plan": "rifle", "pivot": Vector3(0.0, 0.03, -0.06), "hold": Vector3(0.0, -0.085, -0.06),
		"out": [Vector3(0.0, -0.11, 0.0), Vector3(0.35, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.02, -0.65, 0.0), Vector3(1.2, 0.0, 0.5)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "charge": Vector3(0.035, 0.095, -0.05),
		"bone": "Bolt", "travel": Vector3(0.0, 0.0, 0.075)},
	"m1911": {"plan": "pistol", "pivot": Vector3(0.0, -0.03, 0.07), "hold": Vector3(0.0, -0.075, 0.095),
		"out": [Vector3(0.0, -0.11, 0.037), Vector3.ZERO],
		"pouch": [Vector3(-0.12, -0.42, 0.2), Vector3(0.5, 0.0, 0.5)],
		"drop": [Vector3(0.0, -0.6, 0.12), Vector3(0.8, 0.0, 0.3)],
		"pouch_hand": Vector3(-0.12, -0.46, 0.18), "charge": Vector3(0.0, 0.065, 0.085),
		"bone": "Slide", "travel": Vector3(0.0, 0.0, 0.06)}  # slide verts are 0.5 Slide: 3 cm shown,
}


## Left-hand frames per anchor (gun-model space; "mag" turns with the Mag node): f = finger direction, n = the way
## the palm faces (FpArms.solve). Anchors name the palm centre; the wrist target is pulled back WRIST_BACK along f
## and WRIST_OFF against n, so the palm closes on the point instead of the wrist.
const HANDS := {
	"mag": {"f": Vector3(0.0, -0.3, -1.0), "n": Vector3(1.0, 0.0, 0.0)},
	"pouch": {"f": Vector3(0.0, -1.0, -0.3), "n": Vector3(1.0, 0.0, 0.0)},
	"charge": {"f": Vector3(1.0, -0.4, 0.0), "n": Vector3(0.0, -1.0, 0.0)},  # overhand: palm on top, fingers hook the right side
}
const WRIST_BACK := 0.075
const WRIST_OFF := 0.03


static func rig(def: Dictionary) -> Dictionary:
	return RIGS.get(str(def.get("model", "")), {})
