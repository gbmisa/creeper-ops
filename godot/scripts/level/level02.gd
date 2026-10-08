class_name Level02
## Level 02 "The Crown Marches": 160 x 160, five castles whose Sentinels (CastleGuards) shoot
## 32 cells from the first second. Data lives here; terrain shaping is Level02Terrain.
## Same dictionary shape as Level01.build() so every subsystem treats them alike.

const W := 160
const H := 160
## Raids start early and the nests toughen fast: turtling loses.
const RAID_SCHEDULE := {
	"raid_delay": 180.0,
	"tier_times": [0.0, 300.0, 600.0, 900.0],
}
## Harder clock: Brute ~5 min, Ravager ~10, Behemoth ~15. Grace matches the raid start.
const PRESSURE := { "grace": 180.0, "cap": 1800.0 }
const PRESSURE_POINTS := [
	{ "t": 180.0, "p": 0.0 },
	{ "t": 300.0, "p": 0.20 },
	{ "t": 600.0, "p": 0.60 },
	{ "t": 900.0, "p": 0.85 },
	{ "t": 1800.0, "p": 1.0 },
]
## Ground castles keep a moat; raised ones a drawbridge. Sizes >= 19 get gatehouses.
## `guards`: Sentinels posted on tower tops, then along the walls. `yield` scales Aether/Salvage.
const CASTLES := [
	{ "id": "ashgate", "name": "Ashgate Hold", "x": 14, "z": 104, "size": 19, "floor": 2, "variant": "ground",
		"moat": true, "gates": ["e"], "climbs": ["s"], "spire_h": 20, "towers": true, "gatehouse": true, "guards": 5 },
	{ "id": "thornwall", "name": "Thornwall", "x": 126, "z": 108, "size": 19, "floor": 3, "variant": "raised",
		"bridge": true, "gates": ["w"], "climbs": ["s"], "spire_h": 20, "towers": true, "gatehouse": true, "guards": 5 },
	{ "id": "crown", "name": "Crown Keep", "x": 62, "z": 62, "size": 37, "floor": 3, "variant": "ground", "plan": "concentric",
		"moat": true, "gates": ["s", "n"], "inner_gate": "e", "climbs": ["e"], "inner_climbs": ["w"], "spire_h": 24,
		"guards": 8, "yield": 2.0 },
	{ "id": "northreach", "name": "Northreach", "x": 16, "z": 20, "size": 21, "floor": 4, "variant": "raised",
		"bridge": true, "gates": ["s"], "climbs": ["e"], "spire_h": 20, "towers": true, "gatehouse": true, "guards": 6 },
	{ "id": "stormcrown", "name": "Stormcrown", "x": 122, "z": 22, "size": 17, "floor": 3, "variant": "ground",
		"moat": true, "gates": ["w"], "climbs": ["s"], "spire_h": 20, "towers": true, "guards": 5 },
]
const CASTLE_RULES := { "aggression": 1.1, "reprisal_warn": 60.0, "nest_buff": 0.2 }
const SHIELD_HINT := "Its shield is powered from underground: send the Operative into the Rift and destroy the Deep Core."
const OBJECTIVES := [
	{ "id": "spire", "who": "Operative", "text": "Destroy the Spore Spire", "hint": "East Blight plateau: ramp on its south side. Totem (Orbital tab) near the ramp foot, then press E at the Spire." },
	{ "id": "e1", "who": "Network", "text": "Nullify Emitter West", "hint": "Relays and weapons out to it, clear the creeper, then a Nullifier within 10 cells." },
	{ "id": "e2", "who": "Network", "text": "Nullify Emitter East", "hint": "Same drill, in the east valley." },
	{ "id": "e4", "who": "Network", "text": "Nullify Emitter North-West", "hint": "Behind Northreach and Crown Keep: mind the Sentinels' 32-cell reach." },
	{ "id": "core", "who": "Operative", "text": "Destroy the Deep Core", "hint": "Walk the Operative into the Rift (west Blight) and press E. Shoot the 3 Shield Pylons, then the Core." },
	{ "id": "e3", "who": "Network", "text": "Nullify Emitter North", "hint": "Shielded until the Deep Core dies." },
	{ "id": "e5", "who": "Network", "text": "Nullify Emitter Marches", "hint": "Shielded until the Deep Core dies." },
	{ "id": "nests", "who": "Units", "text": "Destroy all Spore Nests", "hint": "Optional, but the clock is against you.", "optional": true },
]
## Scripted base for --demo (debug only): the landing mesa, the first relays and a few weapons.
const DEMO := [
	["collector", 74, 144], ["collector", 86, 144], ["collector", 80, 141], ["collector", 74, 150], ["collector", 86, 150],
	["reactor", 76, 148], ["reactor", 84, 148], ["reactor", 80, 152], ["reactor", 74, 156], ["collector", 72, 154], ["collector", 88, 154], ["collector", 80, 156], ["collector", 70, 144], ["collector", 90, 144],
	["cannon", 78, 138], ["cannon", 82, 138], ["cannon", 80, 136], ["mortar", 80, 146],
	["beam", 76, 139], ["reactor", 82, 150], ["storage", 78, 150], ["barracks", 86, 154],
	["sniper", 73, 141], ["sniper", 87, 141], ["sniper", 76, 137], ["sniper", 84, 137],
	["sniper", 72, 146], ["sniper", 88, 146], ["sniper", 76, 153], ["sniper", 84, 153], ["sniper", 70, 150], ["sniper", 90, 150],
]


static func build() -> Dictionary:
	var g := Grid.new(W, H)
	var castles := CASTLES.duplicate(true)
	Level02Terrain.shape(g, castles)
	for c in castles:
		c["layout"] = CastleShape.build(g, c)
	var level := {
		"name": "The Crown Marches",
		"grid": g,
		"landing_hint": Vector2i(80, 142),
		"landing_min_dist": 18.0,
		"emitters": [
			{ "id": "e1", "name": "Emitter West", "x": 38, "z": 92, "amount": 4.0, "interval": 0.5 },
			{ "id": "e2", "name": "Emitter East", "x": 122, "z": 92, "amount": 4.0, "interval": 0.5 },
			{ "id": "e4", "name": "Emitter North-West", "x": 56, "z": 40, "amount": 6.0, "interval": 0.5 },
			{ "id": "e3", "name": "Emitter North", "x": 80, "z": 26, "amount": 5.0, "interval": 0.5, "start": 300.0, "shielded_by": "core", "shield_hint": SHIELD_HINT },
			{ "id": "e5", "name": "Emitter Marches", "x": 112, "z": 72, "amount": 5.0, "interval": 0.5, "start": 600.0, "shielded_by": "core", "shield_hint": SHIELD_HINT },
		],
		"vents": [
			{ "x": 46, "z": 84, "amount": 1.6, "interval": 1.0 },
			{ "x": 116, "z": 86, "amount": 1.6, "interval": 1.0 },
			{ "x": 62, "z": 118, "amount": 1.4, "interval": 1.0 },
		],
		"hives": [
			{ "name": "Rift", "x": 15, "z": 60 },
			{ "name": "Spire Heights", "x": 133, "z": 64 },
			{ "name": "North Knoll", "x": 82, "z": 40 },
			{ "name": "West Moor", "x": 44, "z": 66 },
			{ "name": "East Moor", "x": 104, "z": 100 },
			{ "name": "Southern Barrows", "x": 30, "z": 146 },
		],
		"raid_schedule": RAID_SCHEDULE,
		"pressure": PRESSURE,
		"pressure_points": PRESSURE_POINTS,
		"spire": { "x": 138, "z": 58 },
		"castles": castles,
		"castle_rules": CASTLE_RULES,
		"ores": [
			{ "x": 96, "z": 124 },
			{ "x": 52, "z": 48 },
			{ "x": 108, "z": 48 },
		],
		"rift": { "x": 20, "z": 64 },
		"objectives": OBJECTIVES,
		"demo": DEMO,
		"demo_target": Vector2i(104, 100),
		"spire_totem": Vector2i(137, 108),
		"intro": [
			["Ops: Choose where the Command Node lands. The southern mesa is dry, high and far from every emitter.", "radio"],
			["Ops: Five castles hold this country. Each is garrisoned by Sentinels that see 32 cells: further than a Sniper.", "radio"],
			["Ops: A Sentinel glows for under a second, then lobs a slow bolt at where you stand. Keep moving and it lands behind you.", "radio"],
			["Ops: Walls and hills block their line of sight. Approach under cover, climb the spire, kill the crown nest, and the garrison dies with it.", "radio"],
			["Ops: Raids start in three minutes. The nests will not wait.", "radio"],
		],
	}
	level["nests"] = level.hives # alias: older readers still say nests
	HiveShape.stamp_all(g, level.hives)
	var hazards: Array = level.emitters + level.vents + level.nests + [level.spire, level.rift]
	for p in hazards:
		LevelShape.disc(g, p.x, p.z, 1.5, func(x, z, _d): g.blocked[g.idx(x, z)] = 1)
	level["hazard_points"] = hazards
	return level
