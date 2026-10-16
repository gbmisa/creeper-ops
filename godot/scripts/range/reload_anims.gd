class_name ReloadAnims
## FB-R: reload animation data (Tarkov phases, TRP spec `FB_R_trp_reload_spec.md`). Read by ReloadTimeline.
## PLANS[plan][variant] is a phase list; a phase lists the pose reached at its END, keys missing inherit from the
## phase before (rest = all zero, mag "seat", hand "grip"). Weights are shares of the reload's base time; the
## "charge" variant (empty chamber only) shares TacticalConfig.CHAMBER_TIME and runs before the last phase;
## "empty_bolt" = where the bolt/slide stands for the whole of an empty reload until the charge moves it (slide lock).
##   gp / gr  gun position / rotation offset under the camera (m, rad: x pitch up, y yaw left, z roll left)
##   mag      seat | rock | slip | near | out | pouch | drop (RIGS[gun] offsets of the Mag node, gun-model space, about `pivot`)
##   hl       left hand: grip (def grip_l) | mag (the Mag node's `hold` point) | pouch | charge (+ bolt travel) | stop
##   bolt     0..1 of RIGS[gun].travel      ease  io (default) | in (falls, speeds up) | out
## "charge_takes" {phase: share}: on an empty reload the charge also gets that share of those base phases' time
## (total time unchanged). "charge_pre" phases run before the mag change (HK: lock the handle back first) and share
## the charge time with "charge" (their weights together sum to 1).
##   mark     emitted on ReloadTimeline.mark when the phase ends (sound hooks: nothing listens yet)
## AKM plain reload measured in the TRP spec: mag out 0.24, out of the hand 0.38, new mag in 0.75, at rest 1.0.

const RIFLE_POSE := [Vector3(-0.10, 0.10, -0.10), Vector3(0.15, 0.55, -0.85)]  # gp, gr while the mag is worked
const HK_POSE := [Vector3(-0.10, 0.10, -0.12), Vector3(0.15, 0.50, -0.75)]
const HK_CHARGE := [Vector3(-0.07, 0.07, -0.15), Vector3(0.12, 0.35, 0.10)]  # pushed out, muzzle left: the cocking tube's left side to the camera
const P90_POSE := [Vector3(-0.02, -0.05, -0.26), Vector3(-0.20, 0.70, 0.85)]  # top turned to the camera / left hand
const P90_CHARGE := [Vector3(-0.03, 0.03, -0.06), Vector3(0.05, -0.25, -0.15)]
const PISTOL_POSE := [Vector3(-0.07, 0.08, -0.10), Vector3(0.35, 0.35, -0.60)]

const PLANS := {
	"rifle": {  # AKM: rock the mag forward about its front lip, out, pouch, new one front lip first, rock back
		"plain": [
			{"n": "start", "w": 0.10, "gp": RIFLE_POSE[0], "gr": RIFLE_POSE[1], "hl": "mag"},
			{"n": "rock", "w": 0.07, "mag": "rock", "ease": "out"},
			{"n": "out", "w": 0.08, "mag": "out", "mark": "mag_out"},
			{"n": "stow", "w": 0.13, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.07, "mark": "mag_show"},
			{"n": "show", "w": 0.17, "mag": "near"},
			{"n": "hook", "w": 0.08, "mag": "rock"},
			{"n": "seat", "w": 0.06, "mag": "seat", "gp": RIFLE_POSE[0] + Vector3(0, 0.015, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.04, "gp": RIFLE_POSE[0]},
			{"n": "ready", "w": 0.20, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [  # paddle: the hand rocks the mag out and lets it fall, then the new one from the pouch
			{"n": "start", "w": 0.08, "gp": RIFLE_POSE[0], "gr": RIFLE_POSE[1], "hl": "mag"},
			{"n": "rock", "w": 0.05, "mag": "rock", "ease": "out"},
			{"n": "slip", "w": 0.04, "mag": "slip", "ease": "out", "mark": "mag_out"},
			{"n": "drop", "w": 0.14, "mag": "drop", "hl": "pouch", "ease": "in"},
			{"n": "fetch", "w": 0.07, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.20, "mag": "near", "hl": "mag"},
			{"n": "hook", "w": 0.08, "mag": "rock"},
			{"n": "seat", "w": 0.06, "mag": "seat", "gp": RIFLE_POSE[0] + Vector3(0, 0.015, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.06, "gp": RIFLE_POSE[0]},
			{"n": "ready", "w": 0.22, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge": [  # left hand under the gun to the handle on the right side (EFT AK), gun keeps its yaw, right side rolled up
			{"n": "reach", "w": 0.48, "gp": Vector3(-0.12, 0.11, -0.16), "gr": Vector3(0.10, 0.85, 0.65), "hl": "charge"},
			{"n": "pull", "w": 0.13, "bolt": 1.0, "ease": "out"},
			{"n": "release", "w": 0.07, "bolt": 0.0, "ease": "in", "mark": "charged"},
			{"n": "regrip", "w": 0.32, "gp": Vector3(-0.04, 0.04, -0.06), "gr": Vector3(0.08, 0.30, 0.25), "hl": "grip"},
		],
		"charge_takes": {"hold": 1.0, "fetch": 0.6},  # empty: time for a >= 0.3 s swing into the rack
	},
	"hk": {  # MP5: paddle, mag straight out with a slight rock; empty = HK slap (handle locked back first, slapped home last)
		"plain": [
			{"n": "start", "w": 0.10, "gp": HK_POSE[0], "gr": HK_POSE[1], "hl": "mag"},
			{"n": "rock", "w": 0.05, "mag": "rock", "ease": "out"},
			{"n": "out", "w": 0.08, "mag": "out", "mark": "mag_out"},
			{"n": "stow", "w": 0.14, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.07, "mark": "mag_show"},
			{"n": "show", "w": 0.17, "mag": "near"},
			{"n": "hook", "w": 0.07, "mag": "rock"},
			{"n": "seat", "w": 0.06, "mag": "seat", "gp": HK_POSE[0] + Vector3(0, 0.015, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.05, "gp": HK_POSE[0]},
			{"n": "ready", "w": 0.21, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [
			{"n": "start", "w": 0.08, "gp": HK_POSE[0], "gr": HK_POSE[1], "hl": "mag"},
			{"n": "slip", "w": 0.06, "mag": "slip", "ease": "out", "mark": "mag_out"},
			{"n": "drop", "w": 0.14, "mag": "drop", "hl": "pouch", "ease": "in"},
			{"n": "fetch", "w": 0.07, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.20, "mag": "near", "hl": "mag"},
			{"n": "hook", "w": 0.07, "mag": "rock"},
			{"n": "seat", "w": 0.06, "mag": "seat", "gp": HK_POSE[0] + Vector3(0, 0.015, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.07, "gp": HK_POSE[0]},
			{"n": "ready", "w": 0.25, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge_pre": [  # cock the handle back and lock it up in its notch
			{"n": "reach_h", "w": 0.20, "gp": HK_CHARGE[0], "gr": HK_CHARGE[1], "hl": "charge"},
			{"n": "cock", "w": 0.10, "bolt": 1.0, "ease": "out"},
			{"n": "lock", "w": 0.06},
		],
		"charge": [  # slap it down off the notch: it flies home
			{"n": "reach_s", "w": 0.22, "gp": HK_CHARGE[0], "gr": HK_CHARGE[1], "hl": "charge"},
			{"n": "slap", "w": 0.10, "bolt": 0.0, "ease": "in", "mark": "charged"},
			{"n": "regrip", "w": 0.32, "gp": HK_CHARGE[0] * 0.5, "gr": HK_CHARGE[1] * 0.5, "hl": "grip"},
		],
		"charge_takes": {"hold": 1.0, "fetch": 0.5, "show": 0.25},
	},
	"bullpup": {  # P90: rear of the top mag lifted, pulled off backward; new one laid on in front, pulled back and pressed down
		"plain": [
			{"n": "start", "w": 0.10, "gp": P90_POSE[0], "gr": P90_POSE[1], "hl": "mag"},
			{"n": "rock", "w": 0.08, "mag": "rock", "ease": "out"},
			{"n": "out", "w": 0.10, "mag": "out", "mark": "mag_out"},
			{"n": "stow", "w": 0.13, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.07, "mark": "mag_show"},
			{"n": "show", "w": 0.15, "mag": "near"},
			{"n": "lay", "w": 0.09, "mag": "hook"},
			{"n": "seat", "w": 0.07, "mag": "seat", "gp": P90_POSE[0] + Vector3(0, -0.012, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.04, "gp": P90_POSE[0]},
			{"n": "ready", "w": 0.17, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [
			{"n": "start", "w": 0.08, "gp": P90_POSE[0], "gr": P90_POSE[1], "hl": "mag"},
			{"n": "rock", "w": 0.06, "mag": "rock", "ease": "out"},
			{"n": "slip", "w": 0.05, "mag": "slip", "mark": "mag_out"},
			{"n": "drop", "w": 0.13, "mag": "drop", "hl": "pouch", "ease": "in"},
			{"n": "fetch", "w": 0.07, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.18, "mag": "near", "hl": "mag"},
			{"n": "lay", "w": 0.09, "mag": "hook"},
			{"n": "seat", "w": 0.08, "mag": "seat", "gp": P90_POSE[0] + Vector3(0, -0.012, 0), "ease": "out", "mark": "mag_in"},
			{"n": "hold", "w": 0.05, "gp": P90_POSE[0]},
			{"n": "ready", "w": 0.21, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge": [  # left hand to the side handle under the front of the mag, pulls it back, lets it fly
			{"n": "reach", "w": 0.40, "gp": P90_CHARGE[0], "gr": P90_CHARGE[1], "hl": "charge"},
			{"n": "pull", "w": 0.16, "bolt": 1.0, "ease": "out"},
			{"n": "release", "w": 0.10, "bolt": 0.0, "ease": "in", "mark": "charged"},
			{"n": "regrip", "w": 0.34, "gp": P90_CHARGE[0] * 0.5, "gr": P90_CHARGE[1] * 0.5, "hl": "grip"},
		],
		"charge_takes": {"hold": 1.0, "fetch": 0.5},
	},
	"pistol": {
		"plain": [
			{"n": "start", "w": 0.10, "gp": PISTOL_POSE[0], "gr": PISTOL_POSE[1], "hl": "mag"},
			{"n": "out", "w": 0.12, "mag": "out", "mark": "mag_out"},
			{"n": "stow", "w": 0.15, "mag": "pouch", "mark": "mag_hide"},
			{"n": "fetch", "w": 0.06, "mark": "mag_show"},
			{"n": "show", "w": 0.18, "mag": "near"},
			{"n": "insert", "w": 0.09, "mag": "seat", "mark": "mag_in"},
			{"n": "seat", "w": 0.06, "gp": PISTOL_POSE[0] + Vector3(0, 0.015, 0), "ease": "out"},
			{"n": "hold", "w": 0.04, "gp": PISTOL_POSE[0]},
			{"n": "ready", "w": 0.20, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"fast": [  # right thumb drops the mag: it slides out of the well, then falls
			{"n": "start", "w": 0.08, "gp": PISTOL_POSE[0], "gr": PISTOL_POSE[1], "hl": "pouch"},
			{"n": "slip", "w": 0.07, "mag": "slip", "ease": "out", "mark": "mag_out"},
			{"n": "drop", "w": 0.14, "mag": "drop", "ease": "in"},
			{"n": "fetch", "w": 0.06, "mag": "pouch", "mark": "mag_show"},
			{"n": "show", "w": 0.22, "mag": "near", "hl": "mag"},
			{"n": "insert", "w": 0.10, "mag": "seat", "mark": "mag_in"},
			{"n": "seat", "w": 0.07, "gp": PISTOL_POSE[0] + Vector3(0, 0.015, 0), "ease": "out"},
			{"n": "hold", "w": 0.04, "gp": PISTOL_POSE[0]},
			{"n": "ready", "w": 0.22, "gp": Vector3.ZERO, "gr": Vector3.ZERO, "hl": "grip"},
		],
		"charge": [  # slide locked back (empty_bolt): still canted, support thumb on the slide stop, slide drops
			{"n": "regrip", "w": 0.45, "hl": "stop"},
			{"n": "release", "w": 0.30, "bolt": 0.0, "ease": "in", "mark": "charged"},
			{"n": "settle", "w": 0.25, "hl": "grip"},
		],
		"empty_bolt": 1.0,
		"empty_lock": 0.12,  # s: on an empty reload the slide eases back to the lock over this long at the start
	},
}

## Left-hand frames per anchor (gun-model space; "mag" turns with the Mag node): f = finger direction, n = the way
## the palm faces (FpArms.solve). Anchors name the palm centre; the wrist target is pulled back WRIST_BACK along f
## and WRIST_OFF against n, so the palm closes on the point instead of the wrist.
const HANDS := {
	"mag": {"f": Vector3(0.0, -0.3, -1.0), "n": Vector3(1.0, 0.0, 0.0)},
	"pouch": {"f": Vector3(0.0, -1.0, -0.3), "n": Vector3(1.0, 0.0, 0.0)},
	"charge": {"f": Vector3(0.0, 1.0, -0.2), "n": Vector3(-1.0, 0.0, 0.0)},  # underhand: palm on the right side, fingers up over the handle
	"stop": {"f": Vector3(0.0, 0.0, -1.0), "n": Vector3(1.0, 0.0, 0.0)},  # pistol support hand moved up: thumb on the stop
}
const WRIST_BACK := 0.075
const WRIST_OFF := 0.03


static func rig(def: Dictionary) -> Dictionary:
	return ReloadRigs.RIGS.get(str(def.get("model", "")), {})
