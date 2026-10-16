# PKM machine gun, scratch low-poly, gun space (muzzle -Z, +Y up), metres. Built by scratch_gun.py.
# Carry handle folded to the left (FB-H), bipod folded under the barrel, 100-round box on the right.
MATS = {"steel": ("2c2e31", 0.55, 0.6), "dark": ("17181a", 0.8, 0.2), "wood": ("6b3f22", 0.7, 0.0),
	"olive": ("4a4f34", 0.85, 0.0), "brass": ("a08040", 0.4, 0.8)}
YS = 0.066  # iron sight line
PARTS = [
	# barrel, flash hider, gas block + tube
	("cyl", 0.0, 0.0, -0.55, -0.12, 0.011, "steel"),
	("cyl", 0.0, 0.0, -0.595, -0.545, 0.016, "dark"),
	("box", (-0.012, -0.045, -0.425), (0.012, 0.012, -0.385), "steel"),
	("cyl", 0.0, -0.032, -0.39, -0.10, 0.009, "steel"),
	# receiver + ribbed top cover
	("box", (-0.028, -0.048, -0.12), (0.028, 0.034, 0.18), "steel"),
	("prism", [(-0.10, 0.034), (0.18, 0.034), (0.18, 0.046), (-0.08, 0.050)], 0.024, "dark"),
] + [("box", (-0.024, 0.046, z), (0.024, 0.050, z + 0.008), "dark") for z in [-0.06 + 0.03 * i for i in range(8)]] + [
	# carry handle folded left, bipod folded under
	("box", (-0.036, -0.008, -0.235), (-0.012, 0.008, -0.215), "steel"),
	("box", (-0.052, -0.012, -0.33), (-0.036, 0.016, -0.14), "wood"),
	("box", (-0.010, -0.050, -0.50), (-0.004, -0.042, -0.24), "steel"),
	("box", (0.004, -0.050, -0.50), (0.010, -0.042, -0.24), "steel"),
	("box", (-0.012, -0.052, -0.25), (0.012, -0.040, -0.23), "steel"),
	# trigger guard, trigger, pistol grip
	("box", (-0.006, -0.082, 0.058), (0.006, -0.075, 0.125), "steel"),
	("box", (-0.006, -0.082, 0.054), (0.006, -0.048, 0.060), "steel"),
	("box", (-0.0025, -0.072, 0.080), (0.0025, -0.048, 0.085), "steel"),
	("prism", [(0.112, -0.048), (0.162, -0.048), (0.192, -0.165), (0.146, -0.172)], 0.017, "wood"),
	# skeleton stock: top bar, lower bar, upright, butt
	("prism", [(0.18, 0.030), (0.55, 0.012), (0.55, -0.010), (0.18, -0.005)], 0.016, "wood"),
	("prism", [(0.18, -0.048), (0.55, -0.118), (0.55, -0.145), (0.18, -0.080)], 0.016, "wood"),
	("box", (-0.016, -0.090, 0.18), (0.016, 0.030, 0.215), "wood"),
	("box", (-0.019, -0.150, 0.55), (0.019, 0.016, 0.575), "dark"),
	# 100-round box on the right, belt into the feed
	("box", (-0.010, -0.205, -0.085), (0.052, -0.052, 0.045), "olive"),
	("box", (-0.012, -0.212, -0.090), (0.054, -0.205, 0.050), "dark"),
	("box", (0.028, -0.052, -0.045), (0.040, 0.010, 0.005), "brass"),
	# charging handle (right), front sight (hooded post), rear notch on the cover's front
	("box", (0.028, -0.020, 0.030), (0.046, -0.004, 0.048), "steel"),
	("box", (-0.012, 0.008, -0.530), (0.012, 0.022, -0.510), "steel"),
	("box", (-0.012, 0.022, -0.526), (-0.009, 0.072, -0.514), "steel"),
	("box", (0.009, 0.022, -0.526), (0.012, 0.072, -0.514), "steel"),
	("box", (-0.002, 0.022, -0.522), (0.002, YS, -0.518), "steel"),
	("box", (-0.012, 0.050, -0.085), (0.012, 0.056, -0.045), "steel"),
	("box", (-0.012, 0.056, -0.072), (-0.004, YS + 0.005, -0.066), "steel"),
	("box", (0.004, 0.056, -0.072), (0.012, YS + 0.005, -0.066), "steel"),
	("box", (-0.004, 0.056, -0.072), (0.004, YS, -0.066), "steel"),
]
# notch: rear point = notch bottom centre; front = post tip. Hand points for weapon_defs (grip_r keeps the 0.042 x offset).
POINTS = {"sight_rear": (0.0, YS, -0.069), "sight_front": (0.0, YS, -0.520),
	"grip_r": (0.042, -0.060, 0.140), "grip_l": (0.0, -0.055, -0.300), "mag_l": (0.030, -0.130, -0.020)}
