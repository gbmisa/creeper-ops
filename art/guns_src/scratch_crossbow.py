# Compound crossbow, scratch low-poly (F146, Opus). Built by scratch_parts.py. Gun space: bolt line = bore (y 0),
# bolt points -Z, butt at +Z. Limbs spread in x at the front. Nodes: String (blend shape "cock": pulled back to the
# latch; 0 = uncocked/fired), Bolt (loaded, on the flight rail; hide after the shot), IronSight (ghost ring + front
# post; hide under optics).
MATS = {"stock": ("2d2f2a", 0.75, 0.05), "dark": ("151615", 0.85, 0.05), "metal": ("5e6164", 0.4, 0.8),
	"limb": ("1b1c1a", 0.7, 0.05), "string": ("3a3530", 0.9, 0.0), "carbon": ("17181a", 0.5, 0.2),
	"vane": ("c8b23a", 0.7, 0.0), "dot": ("ff7a1a", 0.3, 0.0)}
YS = 0.085      # iron sight line
LATCH_Z = 0.060 # string latch (cocked)
REST_Z = -0.255 # string at rest, across the limb tips
TIP_X, TIP_Z, CAM_R = 0.255, -0.300, 0.026


def limb(s):
	return [
		("prismy", [(s * 0.035, -0.385), (s * 0.035, -0.345), (s * (TIP_X - 0.004), TIP_Z + 0.012), (s * (TIP_X + 0.010), TIP_Z - 0.012)], 0.006, "limb", 0.018),
		("prismy", [(s * 0.035, -0.385), (s * 0.035, -0.345), (s * (TIP_X - 0.004), TIP_Z + 0.012), (s * (TIP_X + 0.010), TIP_Z - 0.012)], 0.006, "limb", -0.018),
		("cyly", s * TIP_X, TIP_Z, -0.006, 0.006, CAM_R, "metal", 14),
		("cyly", s * TIP_X, TIP_Z, -0.026, 0.026, 0.003, "metal", 8),
	]


PARTS = [
	# stock: butt, comb, thumbhole grip, fore-end under the flight rail
	("prism", [(0.380, 0.040), (0.395, -0.010), (0.390, -0.120), (0.330, -0.120), (0.230, -0.045), (0.205, -0.050),
		(0.175, -0.175), (0.120, -0.175), (0.110, -0.040), (0.040, -0.040), (0.010, -0.060), (-0.240, -0.055),
		(-0.250, -0.020), (0.120, -0.012), (0.210, 0.010), (0.260, 0.040)], 0.022, "stock"),
	("box", (-0.024, -0.122, 0.330), (0.024, -0.008, 0.400), "dark"),            # butt pad
	("box", (-0.006, -0.090, 0.130), (0.006, -0.040, 0.140), "metal"),           # trigger
	("prism", [(0.095, -0.040), (0.180, -0.040), (0.180, -0.050), (0.105, -0.095), (0.095, -0.090)], 0.006, "dark"),  # guard
	# flight rail + barrel shroud, latch box, safety
	("box", (-0.018, -0.022, -0.390), (0.018, -0.004, LATCH_Z + 0.030), "dark"),
	("box", (-0.004, -0.006, -0.390), (0.004, -0.002, LATCH_Z), "metal"),        # rail groove lip
	("box", (-0.026, -0.010, LATCH_Z - 0.010), (0.026, 0.035, LATCH_Z + 0.080), "dark"),
	("box", (0.026, 0.010, LATCH_Z + 0.040), (0.032, 0.020, LATCH_Z + 0.060), "metal"),
	# optic rail on the latch box
	("box", (-0.011, 0.035, LATCH_Z - 0.050), (0.011, 0.045, LATCH_Z + 0.075), "metal"),
] + [("box", (-0.0115, 0.045, z), (0.0115, 0.048, z + 0.005), "metal") for z in [LATCH_Z - 0.045 + 0.011 * i for i in range(11)]] + [
	# riser block, limb pockets, cocking stirrup, foregrip
	("box", (-0.050, -0.040, -0.400), (0.050, 0.030, -0.330), "dark"),
	("box", (0.030, -0.030, -0.395), (0.045, 0.030, -0.335), "metal"),
	("box", (-0.045, -0.030, -0.395), (-0.030, 0.030, -0.335), "metal"),
	("prismy", [(-0.045, -0.400), (-0.045, -0.470), (0.045, -0.470), (0.045, -0.400), (0.035, -0.400), (0.035, -0.460),
		(-0.035, -0.460), (-0.035, -0.400)], 0.006, "metal", -0.020),
	("box", (-0.016, -0.120, -0.190), (0.016, -0.055, -0.150), "dark"),
	# cables
	("box", (-TIP_X, -0.011, TIP_Z + 0.022), (TIP_X, -0.008, TIP_Z + 0.025), "string"),
	("box", (-TIP_X, 0.008, TIP_Z + 0.022), (TIP_X, 0.011, TIP_Z + 0.025), "string"),
] + limb(1) + limb(-1)


def string(nock_z):
	right = [(TIP_X, TIP_Z + CAM_R - 0.002), (TIP_X, TIP_Z + CAM_R + 0.002), (0.0, nock_z + 0.002), (0.0, nock_z - 0.002)]
	return [
		("prismy", right, 0.0016, "string"),
		("prismy", [(-x, z) for x, z in reversed(right)], 0.0016, "string"),
		("box", (-0.006, -0.003, nock_z - 0.003), (0.006, 0.003, nock_z + 0.004), "metal"),  # serving
	]


NODES = {
	"String": string(REST_Z),
	"Bolt": [
		("cyl", 0.0, 0.006, -0.420, LATCH_Z, 0.0045, "carbon", 8),
		("cyl", 0.0, 0.006, -0.460, -0.420, 0.0005, "metal", 8, 0.0065),
		("box", (-0.0007, 0.010, -0.000), (0.0007, 0.020, 0.045), "vane"),
		("box", (0.004, -0.002, -0.000), (0.014, -0.0006, 0.045), "vane"),
		("box", (-0.014, -0.002, -0.000), (-0.004, -0.0006, 0.045), "vane"),
	],
	"IronSight": [
		("box", (-0.0025, 0.048, LATCH_Z + 0.053), (0.0025, YS - 0.008, LATCH_Z + 0.059), "dark"),   # ghost-ring post
		("ring", (0.0, YS, LATCH_Z + 0.056), 0.0095, 0.0060, 0.005, "dark", 14),                      # rear aperture
		("box", (-0.006, -0.004, -0.330), (0.006, 0.040, -0.318), "dark"),                          # front post stand
		("box", (-0.0015, 0.040, -0.328), (0.0015, YS, -0.320), "dark"),
		("box", (-0.0018, YS - 0.004, -0.329), (0.0018, YS, -0.319), "dot"),
	],
}
SHAPES = {"String": ("cock", string(LATCH_Z))}
EXTRA = {"bolt": [("cyl", 0.0, 0.0, -0.420, LATCH_Z, 0.0045, "carbon", 8),
	("cyl", 0.0, 0.0, -0.460, -0.420, 0.0005, "metal", 8, 0.0065),
	("box", (-0.0007, 0.004, -0.000), (0.0007, 0.014, 0.045), "vane"),
	("box", (0.004, -0.008, -0.000), (0.014, -0.0066, 0.045), "vane"),
	("box", (-0.014, -0.008, -0.000), (-0.004, -0.0066, 0.045), "vane")]}
POINTS = {"sight_front": (0.0, YS, -0.324), "sight_rear": (0.0, YS, LATCH_Z + 0.056),
	"rail": (0.0, 0.048, LATCH_Z + 0.010), "grip_r": (0.0, -0.110, 0.150), "grip_l": (0.0, -0.090, -0.170),
	"muzzle": (0.0, 0.006, -0.460), "latch": (0.0, 0.006, LATCH_Z), "string_rest": (0.0, 0.006, REST_Z)}
