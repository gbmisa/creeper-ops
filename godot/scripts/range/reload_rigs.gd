class_name ReloadRigs
## FB-R: per-gun reload rig points (gun-model space, muzzle -Z, measured on the glb). Read through ReloadAnims.rig.
## Mag offsets are [position, rotation] about `pivot` (AK: the mag well's front lip, so "rock" pivots the mag on it;
## P90: the top mag's front edge, so "rock" lifts its rear); `hold` = where the left hand holds the mag (seated);
## `charge` = the handle / slide grip point; `stop_hand` = support palm with the thumb on the slide stop;
## `bone` + `travel` = the bone that racks and how far (rearward is +Z). Static-mesh guns (no Magazine bone):
## `mag_box` = the region cut out as the Mag node, `mag_body` = [centre, size, rot] box added inside the grip,
## `bolt_box` = the region cut out as the slide (moved by `travel`). No bone and no bolt_box: only the hand racks.
## `hands` overrides ReloadAnims.HANDS frames for this gun.

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
		"mag_body": [Vector3(0.0, -0.022, 0.085), Vector3(0.019, 0.05, 0.024), Vector3(-0.2, 0.0, 0.0)],
		"bolt_box": AABB(Vector3(-0.02, 0.021, -0.13), Vector3(0.04, 0.05, 0.26)),
		"pivot": Vector3(0.0, -0.05, 0.085), "hold": Vector3(0.0, -0.072, 0.085),
		"slip": [Vector3(0.0, -0.035, 0.007), Vector3.ZERO],
		"near": [Vector3(0.0, -0.05, 0.01), Vector3.ZERO],
		"out": [Vector3(0.0, -0.10, 0.02), Vector3.ZERO],
		"pouch": [Vector3(-0.12, -0.42, 0.2), Vector3(0.5, 0.0, 0.5)],
		"drop": [Vector3(0.0, -0.5, 0.15), Vector3(0.8, 0.0, 0.3)],
		"pouch_hand": Vector3(-0.12, -0.46, 0.18), "charge": Vector3(0.0, 0.05, 0.08),
		"stop_hand": Vector3(-0.03, -0.06, 0.09), "travel": Vector3(0.0, 0.0, 0.04)},
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
		"travel": Vector3(0.0, 0.0, 0.09),
		"hands": {"charge": {"f": Vector3(0.0, 0.3, -1.0), "n": Vector3(1.0, 0.0, 0.0)}}},
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
