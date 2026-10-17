class_name ReloadRigs
## FB-R: per-gun reload rig points (gun-model space, muzzle -Z, measured on the glb). Read through ReloadAnims.rig.
## Mag offsets are [position, rotation] about `pivot` (AK: the mag well's front lip, so "rock" pivots the mag on it;
## P90: the top mag's front edge, so "rock" lifts its rear); `hold` = where the left hand holds the mag (seated);
## `charge` = the handle / slide grip point; `stop_hand` = support palm with the thumb on the slide stop;
## `bone` + `travel` = the bone that racks and how far (rearward is +Z). Static-mesh guns (no Magazine bone):
## `mag_box` = the region cut out as the Mag node, `mag_body` = [centre, size, rot] box added inside the grip
## (`well_plug` = the same, dark, left in the gun to close the cut hole),
## `bolt_box` = the region cut out as the slide (moved by `travel`). No bone and no bolt_box: only the hand racks.
## `hands` overrides ReloadAnims.HANDS frames for this gun. `pose_shift` = [gp, gr] added to every reload pose of the
## plan (not the rest pose), so one gun can sit differently from the others sharing its plan; `charge_shift` = the
## same for the empty-only charge poses (default none).

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
		"well_plug": [Vector3(0.0, -0.04, 0.016), Vector3(0.05, 0.03, 0.085), Vector3.ZERO],  # F103: closes the empty well
		"pivot": Vector3(0.0, -0.065, -0.022), "hold": Vector3(0.0, -0.125, 0.02),
		"slip": [Vector3(0.0, -0.035, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.07, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"stop_hand": Vector3(-0.055, -0.07, 0.04),  # palm low on the left of the lower, thumb up on the bolt catch
		"press_hand": Vector3(-0.04, -0.07, 0.04),  # pushed 1.5 cm in
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},  # long gun: well up into the view
	"m4a1": {"plan": "ar",  # single mesh: the curved STANAG mag is 8 slices under the well lip (y -0.029); whole parts only
		"mag_box": AABB(Vector3(-0.02, -0.16, -0.03), Vector3(0.04, 0.149, 0.115)), "mag_parts": true,
		"pivot": Vector3(0.0, -0.025, -0.015), "hold": Vector3(0.0, -0.115, 0.045),
		"slip": [Vector3(0.0, -0.035, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.07, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"stop_hand": Vector3(-0.05, -0.02, 0.06), "press_hand": Vector3(-0.035, -0.02, 0.06),  # bolt catch (mesh probe) ~(-0.013, 0.022, 0.07)
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},  # sits close at hip: well up into the view
	"vector": {"plan": "ar",  # scratch model: straight mag + base plate under the well (lip y -0.032); release lever left, above the guard
		"mag_box": AABB(Vector3(-0.03, -0.21, 0.0), Vector3(0.06, 0.1785, 0.07)), "mag_parts": true,  # mag top y -0.032 = well bottom
		"pivot": Vector3(0.0, -0.032, 0.012), "hold": Vector3(0.0, -0.12, 0.036),
		"slip": [Vector3(0.0, -0.035, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.07, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"stop_hand": Vector3(-0.05, -0.01, 0.08), "press_hand": Vector3(-0.035, -0.01, 0.08),
		"pose_shift": [Vector3(0.0, 0.0, -0.10), Vector3.ZERO]},  # blocky gun sits close at hip
	"sr25": {"plan": "ar",  # single mesh: straight AR-10 mag cut by region (well bottom y 0.0); catch above the well
		"mag_box": AABB(Vector3(-0.03, -0.11, -0.025), Vector3(0.04, 0.17, 0.096)),  # whole mag part reaches y 0.056
		"pivot": Vector3(0.0, 0.0, -0.02), "hold": Vector3(0.0, -0.07, 0.02),
		"slip": [Vector3(0.0, -0.035, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.07, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.13, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"stop_hand": Vector3(-0.055, -0.03, 0.08), "press_hand": Vector3(-0.04, -0.03, 0.08),  # palm low beside the well's rear, thumb up; press 1.5 cm in
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
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "charge": Vector3(0.04, 0.065, 0.02),  # right of the receiver (no separate handle part): fingers wrap its top
		"travel": Vector3(0.0, 0.0, 0.09),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)],
		"charge_shift": [Vector3(0.0, 0.0, -0.08), Vector3.ZERO]},  # long gun: rack pose as far off as the mag change
	"sks": {"plan": "rifle",  # stand-in model: detachable box mag cut by region, rocked about its front lip
		"mag_box": AABB(Vector3(-0.02, -0.16, -0.025), Vector3(0.04, 0.11, 0.104)),  # F105: top at the band (y -0.05), the housing above stays; guard starts z 0.081
		"pivot": Vector3(0.0, -0.05, -0.0225), "hold": Vector3(0.0, -0.10, 0.025),  # F105: pivot on the new mag top
		"rock": [Vector3.ZERO, Vector3(0.30, 0.0, 0.0)],
		"slip": [Vector3(0.0, -0.04, -0.02), Vector3(0.40, 0.0, 0.0)],
		"near": [Vector3(0.0, -0.06, -0.03), Vector3(0.40, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.12, -0.04), Vector3(0.45, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.06), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "charge": Vector3(0.032, 0.054, -0.092),  # under the handle part on the right (mesh probe): fingers wrap the receiver top
		"travel": Vector3(0.0, 0.0, 0.09),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)],
		"charge_shift": [Vector3(0.0, 0.0, -0.08), Vector3.ZERO]},
	"sniper": {"plan": "boltbox",  # AXMC: Magazine bone (split by weight); short box mag under the action, front lip z 0.134
		"pivot": Vector3(-0.004, -0.015, 0.134), "hold": Vector3(-0.004, -0.055, 0.17),
		"slip": [Vector3(0.0, -0.03, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.06, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.11, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},  # long gun: well up into the view
	"mosin": {"plan": "boltbox",  # no mag part on the mesh: a 5-round box (metal, surface 1) hidden in the stock ahead of the guard
		"mag_body": [Vector3(-0.008, 0.0, 0.135), Vector3(0.02, 0.06, 0.075), Vector3.ZERO, 1],
		"pivot": Vector3(-0.008, -0.03, 0.098), "hold": Vector3(-0.008, -0.045, 0.135),  # palm under the box: it shows above
		"slip": [Vector3(0.0, -0.03, 0.0), Vector3.ZERO],
		"near": [Vector3(0.0, -0.06, -0.01), Vector3(0.1, 0.0, 0.0)],
		"out": [Vector3(0.0, -0.10, 0.0), Vector3(0.1, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22),
		"pose_shift": [Vector3(0.0, 0.05, -0.08), Vector3(0.05, 0.0, 0.0)]},
	"shotgun": {"plan": "tube", "loose": true,  # one shell per press; the shell rests hidden in the receiver over the port
		"mag_body": [Vector3(0.0, 0.05, 0.03), Vector3(0.02, 0.02, 0.065), Vector3.ZERO, 0],  # shell (the glb's shell material)
		"pivot": Vector3(0.0, 0.04, -0.005), "hold": Vector3(0.0, 0.035, 0.075),  # palm under the shell's base, thumb pushes
		"near": [Vector3(0.0, -0.08, 0.04), Vector3(0.35, 0.0, 0.0)],  # under the loading port, nose tipped up into it
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"hands": {"mag": {"f": Vector3(0.0, 0.3, -1.0), "n": Vector3(0.0, 1.0, 0.0)}}},
	"garand": {"plan": "enbloc",  # Magazine bone = the clip + 8 rounds in the receiver (split by weight)
		"pivot": Vector3(-0.005, 0.004, 0.227), "hold": Vector3(-0.005, 0.085, 0.235),  # palm above the clip, thumb on the rounds
		"ping": [Vector3(0.03, 0.16, 0.03), Vector3(0.6, 0.0, 0.8)],
		"drop": [Vector3(0.1, -0.5, 0.1), Vector3(1.5, 0.0, 1.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"near": [Vector3(0.0, 0.06, 0.0), Vector3.ZERO],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "clear_hand": Vector3(-0.09, 0.12, 0.10),
		"hands": {"mag": {"f": Vector3(1.0, -0.3, -0.3), "n": Vector3(0.0, -1.0, 0.0)}},  # from the left, fingers across the receiver
		"pose_shift": [Vector3(0.0, -0.04, -0.12), Vector3.ZERO]},  # receiver out of the face
	"revolver": {"plan": "cylinder", "mag_on_hinge": true,  # cylinder cut as a hinged part; rounds = a box inside it
		"hinge": {"box": AABB(Vector3(-0.023, 0.007, 0.007), Vector3(0.046, 0.048, 0.053)), "whole": true,
			"pivot": Vector3(-0.008, -0.005, 0.03), "axis": Vector3(0.0, 0.0, 1.0), "angle": 1.5},  # crane: swings out left
		"mag_body": [Vector3(0.0, 0.031, 0.034), Vector3(0.03, 0.03, 0.05), Vector3.ZERO, 2],
		"pivot": Vector3(0.0, 0.031, 0.034), "hold": Vector3(-0.02, 0.0, 0.034),  # fingers under the cylinder's left side, thumb pushes it out
		# mag offsets are in the open cylinder's frame (turned 1.5 rad about Z): its "down" is about -X
		"slip": [Vector3(0.0, 0.0, 0.05), Vector3.ZERO],
		"drop": [Vector3(-0.5, -0.04, 0.12), Vector3(0.0, 0.0, 1.0)],
		"pouch": [Vector3(-0.43, 0.09, 0.2), Vector3(0.5, 0.0, 0.5)],
		"near": [Vector3(0.0, 0.0, 0.07), Vector3.ZERO],
		"pouch_hand": Vector3(-0.12, -0.46, 0.18),
		"hands": {"mag": {"f": Vector3(0.0, 0.0, -1.0), "n": Vector3(1.0, 0.0, 0.0)}},
		"pose_shift": [Vector3(0.0, -0.04, -0.10), Vector3.ZERO]},  # pistol out from the face: the hand on the cylinder
	"pkm": {"plan": "belt",  # single mesh: the box (whole parts under y 0.02), the feed cover hinged at its front
		"mag_box": AABB(Vector3(-0.015, -0.145, -0.085), Vector3(0.07, 0.165, 0.147)), "mag_parts": true,
		"hinge": {"box": AABB(Vector3(-0.03, 0.10, -0.095), Vector3(0.06, 0.025, 0.29)), "whole": true,
			"pivot": Vector3(0.0, 0.112, -0.09), "axis": Vector3(1.0, 0.0, 0.0), "angle": -0.8},  # rear lifts
		"pivot": Vector3(0.02, 0.018, -0.075), "hold": Vector3(-0.015, -0.06, -0.01),  # palm on the box's left face
		"slip": [Vector3(0.0, -0.03, 0.0), Vector3.ZERO],
		"out": [Vector3(-0.02, -0.14, 0.02), Vector3(0.2, 0.0, 0.0)],
		"near": [Vector3(-0.02, -0.08, 0.0), Vector3(0.15, 0.0, 0.0)],
		"pouch": [Vector3(-0.15, -0.45, 0.25), Vector3(0.7, 0.0, 0.6)],
		"drop": [Vector3(0.0, -0.55, -0.02), Vector3(1.0, 0.0, 0.4)],
		"pouch_hand": Vector3(-0.15, -0.5, 0.22), "lid_hand": Vector3(0.0, 0.135, 0.15), "tray_hand": Vector3(0.0, 0.13, 0.02),
		"flip_hand": Vector3(-0.02, 0.19, 0.13),
		"charge": Vector3(0.045, 0.058, 0.05), "travel": Vector3(0.0, 0.0, 0.08),
		"pose_shift": [Vector3(0.0, 0.0, -0.06), Vector3.ZERO]},
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
