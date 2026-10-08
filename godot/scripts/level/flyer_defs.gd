class_name FlyerDefs
extends RefCounted
## Flying enemies (Stage 19). Rows are starting numbers; tune here only. `unlock` is a mission
## pressure like RaiderDefs. Flyers ignore terrain: they hold `alt` metres above the highest
## ground in the 3x3 cells under them. Only air weapons hit them (Beam, Flak, Lance, the
## Operative); cannons, mortars, snipers and units cannot.
## Loot is the Salvage pickup chance `loot_p` for `loot` (RaiderDefs convention).

const ROWS := [
	{ "name": "Spore Bat", "hp": 5.0, "speed": 7.0, "alt": 6.0, "size": 0.85, "color": Color("a8ff5a"),
		"unlock": 0.30, "loot": 1, "loot_p": 0.1, "flock": [4, 8], "weight": 4.0,
		"dive_dmg": 4.0, "dive_every": 2.5 },
	{ "name": "Gasbag", "hp": 45.0, "speed": 2.0, "alt": 10.0, "size": 1.7, "color": Color("c4e05a"),
		"unlock": 0.50, "loot": 3, "loot_p": 1.0, "flock": [1, 2], "weight": 2.0,
		"drop_every": 8.0, "drop_amount": 3.0 },
	{ "name": "Wyvern", "hp": 90.0, "speed": 5.0, "alt": 8.0, "size": 1.6, "color": Color("ff7a3a"),
		"unlock": 0.80, "loot": 6, "loot_p": 1.0, "flock": [1, 1], "weight": 1.0,
		"breath_dps": 12.0, "breath_time": 2.0, "breath_every": 6.0, "breath_range": 16.0,
		"breath_half_angle": 0.45, "hunt": 30.0 },
]


static func named(n: String) -> Dictionary:
	for row in ROWS:
		var d: Dictionary = row
		if d.name == n:
			return d
	return {}


static func unlocked(p: float) -> Array:
	var rows: Array = []
	for row in ROWS:
		var d: Dictionary = row
		if float(d.unlock) <= p + 0.0001:
			rows.append(d)
	return rows


## Weighted pick among unlocked rows. `roll` is 0..1.
static func pick(p: float, roll: float) -> Dictionary:
	var rows := unlocked(p)
	if rows.is_empty():
		return {}
	var total := 0.0
	for row in rows:
		total += float(row.weight)
	var at := roll * total
	for row in rows:
		at -= float(row.weight)
		if at <= 0.0:
			return row
	return rows.back()
