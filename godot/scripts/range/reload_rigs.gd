class_name ReloadRigs
## FB-R: per-gun reload rig points (gun-model space, muzzle -Z, measured on the glb). Read through ReloadAnims.rig.
## Mag offsets are [position, rotation] about `pivot` (AK: the mag well's front lip, so "rock" pivots the mag on it;
## P90: the top mag's front edge, so "rock" lifts its rear); `hold` = where the left hand holds the mag (seated);
## `charge` = the handle / slide grip point; `stop_hand` = support palm with the thumb on the slide stop;
## `bone` + `travel` = the bone that racks and how far (rearward is +Z). Static-mesh guns (no Magazine bone):
## `mag_box` = the region cut out as the Mag node, `mag_body` = [centre, size, rot] box added inside the grip,
## `bolt_box` = the region cut out as the slide (moved by `travel`). No bone and no bolt_box: only the hand racks.
## `hands` overrides ReloadAnims.HANDS frames for this gun. `pose_shift` = [gp, gr] added to every reload pose of the
## plan (not the rest pose), so one gun can sit differently from the others sharing its plan.

const RIGS := {
	"ak47": {"plan": "rifle", "pivot": Vector3(-0.002, -0.04, -0.062), "hold": Vector3(-0.002, -0.115, -0.085),
		"rock": [Vector3.ZERO, Vector3(0.35, 0.0, 0.0)],
		"slip": [Vector3(0.0, -0.04, -0.02), Vector3(0.45, 0.0, 0.0)],
		"near": [Vector3(0.0, -0.06, -0.03), Vector3(0.45, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.11, -0.04), Vector3(0.5, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.06), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "charge": Vector3(0.055, 0.05, -0.085),
		"bone": "Bolt", "travel": Vector3(0.0, 0.0, 0.09)},
	"m1911": {"plan": "pistol", "pivot": Vector3(0.0, -0.03, 0.07), "hold": Vector3(0.0, -0.075, 0.065),
		"slip": [Vector3(0.0, -0.035, 0.012), Vector3.ZERO],
		"near": [Vector3(0.0, -0.05, 0.017), Vector3.ZERO],
		"out": [Vector3(0.0, -0.11, 0.037), Vector3.ZERO],
		"pouch": [Vector3(-0.12, -0.42, 0.2), Vector3(0.5, 0.0, 0.5)],
		"drop": [Vector3(0.0, -0.5, 0.15), Vector3(0.8, 0.0, 0.3)],
		"pouch_hand": Vector3(-0.12, -0.46, 0.18), "charge": Vector3(0.0, 0.065, 0.085),
		"stop_hand": Vector3(-0.03, -0.06, 0.09),  # palm low on the frame, thumb up on the stop, slide clear
		"bone": "Slide", "travel": Vector3(0.0, 0.0, 0.12)},  # slide verts are 0.5 Slide: 6 cm shown
	"glock18": {"plan": "pistol",  # single mesh: base plate cut by region, body box hidden in the grip, slide cut
		"mag_box": AABB(Vector3(-0.0115, -0.053, 0.066), Vector3(0.023, 0.014, 0.046)),
		"mag_body": [Vector3(0.0, -0.01, 0.083), Vector3(0.019, 0.075, 0.024), Vector3(-0.2, 0.0, 0.0)],
		"bolt_box": AABB(Vector3(-0.02, 0.021, -0.13), Vector3(0.04, 0.05, 0.26)),
		"pivot": Vector3(0.0, -0.05, 0.085), "hold": Vector3(0.0, -0.092, 0.05),
		"pose_shift": [Vector3(-0.05, -0.02, -0.04), Vector3(-0.15, 0.0, 0.2)],
		"slip": [Vector3(0.0, -0.035, 0.007), Vector3.ZERO],
		"near": [Vector3(0.0, -0.05, 0.01), Vector3.ZERO],
		"out": [Vector3(0.0, -0.10, 0.02), Vector3.ZERO],
		"pouch": [Vector3(-0.12, -0.42, 0.2), Vector3(0.5, 0.0, 0.5)],
		"drop": [Vector3(0.0, -0.5, 0.15), Vector3(0.8, 0.0, 0.3)],
		"pouch_hand": Vector3(-0.12, -0.46, 0.18), "charge": Vector3(0.0, 0.05, 0.08),
		"stop_hand": Vector3(-0.02, -0.065, 0.02), "travel": Vector3(0.0, 0.0, 0.06),  # palm under the trigger guard, slide clear
		"hands": {"mag": {"f": Vector3(0.0, -0.2, -1.0), "n": Vector3(0.25, 1.0, 0.0)}}},  # palm up under the base plate
	"mp5": {"plan": "hk",  # single mesh: the straight mag cut by region; no handle part, the hand racks it
		"mag_box": AABB(Vector3(-0.02, -0.14, -0.14), Vector3(0.04, 0.186, 0.06)),
		"pivot": Vector3(0.0, 0.0, -0.135), "hold": Vector3(0.0, -0.08, -0.11),
		"rock": [Vector3.ZERO, Vector3(0.15, 0.0, 0.0)],
		"slip": [Vector3(0.0, -0.05, -0.01), Vector3(0.2, 0.0, 0.0)],
		"near": [Vector3(0.0, -0.07, -0.02), Vector3(0.2, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, -0.03), Vector3(0.25, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.3), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.04), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.27), "charge": Vector3(-0.03, 0.095, -0.2),
		"slap_hand": Vector3(-0.11, 0.10, -0.11),  # 8 cm out to the left of the locked handle: the slap strikes sideways
		"lock_hand": Vector3(-0.03, 0.115, -0.11),  # locked handle: back by travel, 2 cm up into the notch
		"travel": Vector3(0.0, 0.0, 0.09),
		"hands": {"charge": {"f": Vector3(0.0, 0.3, -1.0), "n": Vector3(1.0, 0.0, 0.0)},
			"lock": {"f": Vector3(0.0, 0.3, -1.0), "n": Vector3(1.0, 0.0, 0.0)}}},
	"scarh": {"plan": "ar",  # single mesh: the straight 20-rounder cut by region (well bottom y -0.065); catch above the well
		"mag_box": AABB(Vector3(-0.04, -0.16, -0.03), Vector3(0.08, 0.16, 0.092)),
		"pivot": Vector3(0.0, -0.065, -0.022), "hold": Vector3(0.0, -0.125, 0.02),
		"slip": [Vector3(0.0, -0.035, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.07, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"stop_hand": Vector3(-0.055, -0.035, 0.03),  # palm left of the well, thumb up on the bolt catch
		"press_hand": Vector3(-0.045, -0.03, 0.03),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},  # long gun: well up into the view
	"sr25": {"plan": "ar",  # single mesh: straight AR-10 mag cut by region (well bottom y 0.0); catch above the well
		"mag_box": AABB(Vector3(-0.03, -0.11, -0.025), Vector3(0.04, 0.17, 0.096)),  # whole mag part reaches y 0.056
		"pivot": Vector3(0.0, 0.0, -0.02), "hold": Vector3(0.0, -0.07, 0.02),
		"slip": [Vector3(0.0, -0.035, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.07, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"stop_hand": Vector3(-0.055, 0.0, 0.06), "press_hand": Vector3(-0.045, 0.005, 0.06),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},
	"saiga12": {"plan": "rifle",  # AK pattern: single mesh, the box mag cut by region, rocked about its front lip
		"mag_box": AABB(Vector3(-0.12, -0.20, -0.06), Vector3(0.24, 0.26, 0.122)),  # 4 mag parts, up to y 0.055
		"pivot": Vector3(0.0, 0.0, -0.054), "hold": Vector3(0.0, -0.13, 0.0),
		"rock": [Vector3.ZERO, Vector3(0.30, 0.0, 0.0)],
		"slip": [Vector3(0.0, -0.04, -0.02), Vector3(0.40, 0.0, 0.0)],
		"near": [Vector3(0.0, -0.06, -0.03), Vector3(0.40, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.12, -0.04), Vector3(0.45, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.06), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "charge": Vector3(0.035, 0.06, 0.08),  # charge: estimate (right side)
		"travel": Vector3(0.0, 0.0, 0.09),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},
	"sks": {"plan": "rifle",  # stand-in model: detachable box mag cut by region, rocked about its front lip
		"mag_box": AABB(Vector3(-0.02, -0.16, -0.025), Vector3(0.04, 0.20, 0.104)),  # body up to y 0.034 + base plate; guard starts z 0.081
		"pivot": Vector3(0.0, 0.0, -0.0225), "hold": Vector3(0.0, -0.10, 0.025),
		"rock": [Vector3.ZERO, Vector3(0.30, 0.0, 0.0)],
		"slip": [Vector3(0.0, -0.04, -0.02), Vector3(0.40, 0.0, 0.0)],
		"near": [Vector3(0.0, -0.06, -0.03), Vector3(0.40, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.12, -0.04), Vector3(0.45, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.06), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "charge": Vector3(0.035, 0.07, 0.06),  # charge: estimate (right side)
		"travel": Vector3(0.0, 0.0, 0.09),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},
	"p90": {"plan": "bullpup", "pivot": Vector3(0.0, 0.025, -0.125), "hold": Vector3(-0.01, 0.045, 0.12),
		"rock": [Vector3.ZERO, Vector3(-0.22, 0.0, 0.0)],
		"slip": [Vector3(0.0, 0.05, 0.06), Vector3(-0.3, 0.0, 0.0)],
		"out": [Vector3(0.0, 0.07, 0.10), Vector3(-0.3, 0.0, 0.2)],
		"near": [Vector3(0.0, 0.06, -0.04), Vector3(-0.2, 0.0, 0.0)],
		"hook": [Vector3(0.0, 0.008, -0.03), Vector3(-0.06, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.35, 0.3), Vector3(0.6, 0.0, 0.8)],
		"drop": [Vector3(0.0, -0.45, 0.15), Vector3(0.9, 0.0, 0.5)],
		"pouch_hand": Vector3(-0.15, -0.4, 0.27), "charge": Vector3(-0.035, -0.005, -0.12),
		"travel": Vector3(0.0, 0.0, 0.08),
		"hands": {"mag": {"f": Vector3(0.3, 0.2, -1.0), "n": Vector3(0.8, -0.6, 0.0)},  # from the left, fingers over the top mag
			"charge": {"f": Vector3(0.0, 0.2, -1.0), "n": Vector3(1.0, 0.0, 0.0)}}},  # side handle, left hand
}
