class_name RaiderDefs
extends RefCounted
## Enemy roster (§4.2). Replaces Config.RAIDER_TIERS.
## Brute, Ravager and Behemoth keep today's stats. Skitter dps is the Stage 8 balance pass.
## The Spitter is the spec lobber: 10 HP, range 20. Unlock is a pressure, not a clock time.
## `special` rows are not in the ordinary weighted pick: Spotter arrives with a mortar (phase 7).
## Loot numbers are the Salvage pickup when that raider dies (Loot).
## Weight among the ordinary unlocked rows is 2^order (oldest 1, next 2, ...), so the newest
## is about half of a two-type pool and still the most common in a larger one.


const ROWS := [
	{ "name": "Skitter", "hp": 4.0, "dps": 6.0, "speed": 4.2, "size": 0.45, "color": Color("a8ff5a"),
		"attack": "melee", "range": 0.5, "unlock": 0.0, "loot": 1, "loot_p": 0.1, "role": "front" },
	{ "name": "Spitter", "hp": 10.0, "dps": 0.0, "speed": 3.0, "size": 0.6, "color": Color("d6ff3a"),
		"attack": "acid", "range": 20.0, "interval": 2.0, "damage": 6.0, "splash": 1.5,
		"unlock": 0.10, "loot": 1, "loot_p": 1.0, "role": "ranged" },
	{ "name": "Brute", "hp": 16.0, "dps": 8.0, "speed": 3.4, "size": 0.75, "color": Color("ffd24a"),
		"attack": "melee", "range": 0.6, "wall_mult": 3.0, "unlock": 0.20, "loot": 2, "loot_p": 1.0, "role": "front" },
	{ "name": "Lancer", "hp": 14.0, "dps": 0.0, "speed": 2.6, "size": 0.85, "color": Color("e6d2ff"),
		"attack": "beam", "range": 32.0, "interval": 1.5, "damage": 25.0,
		"unlock": 0.55, "loot": 3, "loot_p": 1.0, "role": "ranged" },
	{ "name": "Burrower", "hp": 20.0, "dps": 0.0, "speed": 3.0, "size": 0.7, "color": Color("c4a06a"),
		"attack": "burrow", "range": 0.5, "damage": 60.0, "splash": 1.5, "surface": 1.5,
		"unlock": 0.65, "loot": 2, "loot_p": 1.0, "role": "front", "special": "burrow" },
	{ "name": "Warden", "hp": 30.0, "dps": 0.0, "speed": 2.8, "size": 1.0, "color": Color("ffb03a"),
		"attack": "aura", "range": 5.0, "unlock": 0.50, "loot": 3, "loot_p": 1.0, "role": "support" },
	{ "name": "Ravager", "hp": 40.0, "dps": 16.0, "speed": 4.0, "size": 0.9, "color": Color("ff7a3a"),
		"attack": "melee", "range": 0.7, "unlock": 0.60, "loot": 4, "loot_p": 1.0, "role": "front" },
	{ "name": "Spotter", "hp": 8.0, "dps": 0.0, "speed": 4.5, "size": 0.5, "color": Color("7ee0ff"),
		"attack": "none", "range": 12.5, "unlock": 0.70, "loot": 2, "loot_p": 1.0, "role": "support", "special": "spotter" },
	{ "name": "Behemoth", "hp": 120.0, "dps": 35.0, "speed": 2.6, "size": 1.4, "color": Color("ff3355"),
		"attack": "melee", "range": 1.0, "wall_mult": 3.0, "unlock": 0.85, "loot": 8, "loot_p": 1.0, "role": "front" },
]


static func named(n: String) -> Dictionary:
	for row in ROWS:
		var d: Dictionary = row
		if d.name == n:
			return d
	return {}


## Rows whose unlock is at or below `p`, in unlock order. Includes Spotter.
static func unlocked(p: float) -> Array:
	var rows: Array = []
	for row in ROWS:
		var d: Dictionary = row
		if float(d.unlock) <= p + 0.0001:
			rows.append(d)
	rows.sort_custom(func(a, b): return float(a.unlock) < float(b.unlock))
	return rows


## Newest ordinary row at this pressure (Spotter excluded; it is not a breed tier).
static func newest(p: float) -> Dictionary:
	var best := named("Skitter")
	for row in unlocked(p):
		var d: Dictionary = row
		if str(d.get("special", "")) == "spotter":
			continue
		if float(d.unlock) >= float(best.unlock):
			best = d
	return best


## Weighted pick. `roll` in 0..1 picks without touching the global RNG; below 0 uses randf().
static func pick(p: float, roll := -1.0) -> Dictionary:
	var rows: Array = []
	for row in unlocked(p):
		var d: Dictionary = row
		if str(d.get("special", "")) == "spotter":
			continue
		rows.append(d)
	if rows.is_empty():
		return named("Skitter")
	var total := 0
	for i in rows.size():
		total += 1 << i
	var r := randf() if roll < 0.0 else clampf(roll, 0.0, 0.9999)
	var ticket := mini(total - 1, int(floor(r * float(total))))
	var acc := 0
	for i in rows.size():
		acc += 1 << i
		if ticket < acc:
			return rows[i] as Dictionary
	return rows.back() as Dictionary
