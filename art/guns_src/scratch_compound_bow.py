# Compound bow, scratch low-poly (F146, Opus). Built by scratch_parts.py. Gun space: arrow line = bore (x 0, y 0),
# arrow points -Z, the archer is at +Z. The bow stands upright (limbs along y). Riser sits right of the arrow
# (right-handed archer: arrow on the left of the riser). Nodes: String (blend shape "draw": nock pulled back
# DRAW m), Arrow (nocked, at rest; code slides it +Z with the draw), IronSight (3-pin sight, hide under optics).
MATS = {"riser": ("2b2e2a", 0.6, 0.35), "limb": ("1c1d1b", 0.7, 0.05), "grip": ("121212", 0.9, 0.0),
	"metal": ("6a6d70", 0.4, 0.8), "string": ("3a3530", 0.9, 0.0), "carbon": ("17181a", 0.5, 0.2),
	"vane": ("b8462e", 0.7, 0.0), "pin_g": ("39ff4a", 0.3, 0.0), "pin_y": ("ffe23a", 0.3, 0.0), "pin_r": ("ff3a2e", 0.3, 0.0)}
YS = 0.080      # sight line (eye at anchor, top pin)
NOCK_Z = 0.205  # string at rest (brace height ~0.17 m behind the grip)
DRAW = 0.55     # full draw: nock moves back this far
CAM_Y, CAM_Z, CAM_R = 0.475, 0.170, 0.034
RX = 0.017      # riser centre x


def mirror_y(parts):  # mirror (z, y) profiles / boxes / x-cylinders in y for the lower limb
	out = []
	for p in parts:
		if p[0] == "prism":
			out.append(("prism", [(z, -y) for z, y in reversed(p[1])]) + p[2:])
		elif p[0] == "cylx":
			out.append(("cylx", -p[1]) + p[2:])
		elif p[0] == "box":
			(x0, y0, z0), (x1, y1, z1) = p[1], p[2]
			out.append(("box", (x0, -y1, z0), (x1, -y0, z1)) + p[3:])
	return out


UPPER = [
	# split limbs, each a tapered bar from the riser pocket out to the cam axle
	("prism", [(0.005, 0.330), (0.045, 0.345), (CAM_Z + 0.012, CAM_Y - 0.004), (CAM_Z - 0.010, CAM_Y + 0.008)], 0.004, "limb", -0.010),
	("prism", [(0.005, 0.330), (0.045, 0.345), (CAM_Z + 0.012, CAM_Y - 0.004), (CAM_Z - 0.010, CAM_Y + 0.008)], 0.004, "limb", 0.010),
	("box", (-0.003, 0.320, -0.010), (0.031, 0.350, 0.050), "metal"),  # limb pocket
	("cylx", CAM_Y, CAM_Z, -0.016, 0.016, 0.0035, "metal", 8),           # axle
	("cylx", CAM_Y, CAM_Z, -0.006, 0.006, CAM_R, "metal", 14),           # cam
	("cylx", CAM_Y - 0.012, CAM_Z - 0.008, -0.004, 0.004, CAM_R * 0.55, "riser", 10),  # cam module
]

PARTS = [
	# reflex riser: thin in x, curving forward at the sight window, grip bulging back toward the archer
	("prism", [(0.020, 0.360), (-0.030, 0.260), (-0.058, 0.140), (-0.052, 0.040), (-0.030, -0.020), (-0.036, -0.150),
		(-0.058, -0.230), (-0.030, -0.300), (0.020, -0.360), (0.045, -0.350), (0.000, -0.280), (-0.010, -0.200),
		(0.030, -0.150), (0.052, -0.120), (0.058, -0.050), (0.030, 0.000), (-0.018, 0.050), (-0.026, 0.150),
		(-0.004, 0.260), (0.045, 0.350)], 0.013, "riser", RX),
	("prism", [(0.006, -0.025), (0.044, -0.030), (0.062, -0.060), (0.060, -0.125), (0.040, -0.150), (0.004, -0.140)], 0.017, "grip", RX),
	("box", (-0.004, -0.004, -0.030), (0.004, -0.002, 0.010), "metal"),  # arrow rest (whisker biscuit lip)
	("box", (0.003, -0.012, -0.034), (RX, 0.002, 0.012), "metal"),
	# cable guard rod + slide
	("cyl", 0.026, 0.12, 0.000, 0.120, 0.004, "metal", 8),
	("box", (0.022, 0.110, 0.110), (0.036, 0.130, 0.130), "riser"),
	# cables: cam to cam, beside the string
	("box", (0.009, -CAM_Y, 0.181), (0.012, CAM_Y, 0.184), "string"),
	("box", (0.013, -CAM_Y + 0.02, 0.176), (0.016, CAM_Y - 0.02, 0.179), "string"),
	# stabilizer forward from the riser, below the grip
	("cyl", RX, -0.110, -0.300, -0.040, 0.009, "carbon", 10),
	("cyl", RX, -0.110, -0.335, -0.300, 0.016, "metal", 10),
	# optic rail: short picatinny on a bracket ahead of the riser (optics hide the pin sight)
	("box", (0.000, 0.028, -0.090), (RX + 0.010, 0.036, -0.030), "riser"),
	("box", (-0.011, 0.028, -0.210), (0.011, 0.036, -0.070), "metal"),
] + [("box", (-0.0115, 0.036, z), (0.0115, 0.039, z + 0.005)) + ("metal",) for z in [-0.205 + 0.011 * i for i in range(12)]] \
  + UPPER + mirror_y(UPPER)


def string(nock_z, peep_z):
	# two halves from each cam's back to the nock point; peep (rear sight) and D-loop ride on it
	top = [(CAM_Z + CAM_R - 0.002, CAM_Y - 0.010), (CAM_Z + CAM_R + 0.002, CAM_Y - 0.010), (nock_z + 0.002, 0.0), (nock_z - 0.002, 0.0)]
	return [
		("prism", top, 0.0015, "string"),
		("prism", [(z, -y) for z, y in reversed(top)], 0.0015, "string"),
		("ring", (0.0, YS, peep_z), 0.007, 0.0028, 0.004, "metal", 10),
		("box", (-0.003, -0.008, nock_z - 0.004), (0.003, 0.008, nock_z + 0.012), "metal"),  # nock set + D-loop
	]


def peep_at(nock_z):  # the peep sits on the straight top half of the string at height YS
	t = YS / (CAM_Y - 0.010)
	return nock_z + (CAM_Z + CAM_R - nock_z) * t


NODES = {
	"String": string(NOCK_Z, peep_at(NOCK_Z)),
	"Arrow": [
		("cyl", 0.0, 0.0, -0.520, NOCK_Z, 0.0042, "carbon", 8),
		("cyl", 0.0, 0.0, -0.560, -0.520, 0.0005, "metal", 8, 0.0062),  # broadhead cone (r1 at the shaft end)
		("box", (-0.012, -0.0005, -0.556), (0.012, 0.0005, -0.528), "metal"),  # blades
		("box", (-0.0005, -0.012, -0.556), (0.0005, 0.012, -0.528), "metal"),
		("box", (-0.0007, 0.004, 0.100), (0.0007, 0.016, 0.175), "vane"),
		("box", (0.004, -0.010, 0.100), (0.015, -0.0086, 0.175), "vane"),
		("box", (-0.015, -0.010, 0.100), (-0.004, -0.0086, 0.175), "vane"),
		("box", (-0.0045, -0.0045, NOCK_Z - 0.012), (0.0045, 0.0045, NOCK_Z + 0.002), "vane"),  # nock
	],
	"IronSight": [
		("box", (0.000, 0.040, -0.140), (RX + 0.008, 0.046, -0.040), "riser"),   # bracket from the riser
		("box", (0.022, 0.040, -0.150), (0.030, YS + 0.036, -0.135), "riser"),  # vertical bar
		("ring", (0.0, YS - 0.009, -0.142), 0.031, 0.025, 0.014, "riser", 16),   # round housing
		("box", (0.0, YS - 0.0010, -0.144), (0.026, YS + 0.0010, -0.140), "metal"),  # 20 m pin
		("box", (-0.0012, YS - 0.0012, -0.144), (0.0012, YS + 0.0012, -0.140), "pin_g"),
		("box", (0.0, YS - 0.0100, -0.144), (0.026, YS - 0.0080, -0.140), "metal"),  # 40 m
		("box", (-0.0012, YS - 0.0102, -0.144), (0.0012, YS - 0.0078, -0.140), "pin_y"),
		("box", (0.0, YS - 0.0190, -0.144), (0.026, YS - 0.0170, -0.140), "metal"),  # 60 m
		("box", (-0.0012, YS - 0.0192, -0.144), (0.0012, YS - 0.0168, -0.140), "pin_r"),
	],
}
SHAPES = {"String": ("draw", string(NOCK_Z + DRAW, peep_at(NOCK_Z + DRAW)))}
EXTRA = {"arrow": [("cyl", 0.0, 0.0, -0.520, NOCK_Z, 0.0042, "carbon", 8)] + NODES["Arrow"][1:]}
POINTS = {"sight_front": (0.0, YS, -0.142), "sight_rear": (0.0, YS, peep_at(NOCK_Z + DRAW)),
	"sight_rear_rest": (0.0, YS, peep_at(NOCK_Z)), "rail": (0.0, 0.039, -0.140),
	"grip_l": (RX, -0.085, 0.030), "grip_r": (0.0, 0.0, NOCK_Z), "grip_r_drawn": (0.0, 0.0, NOCK_Z + DRAW),
	"muzzle": (0.0, 0.0, -0.560), "nock": (0.0, 0.0, NOCK_Z)}
