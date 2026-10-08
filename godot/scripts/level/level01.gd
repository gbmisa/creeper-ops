class_name Level01
## Level 01 "Hollow Ridge": surface layout. Pure data + shaping helpers so new levels can
## copy this file. See docs/LEVEL01_DESIGN.md. Blight zones (no building) are reachable only
## by the Operative and barracks units. Heights are whole CW3 levels (0..10): flat tops.
## Named shelves stay sheer and are climbed by explicit stairs; everywhere else, neighbours
## differ by at most one level. The Command Node lands wherever the player chooses
## (landing rules: Landing.can_land); `landing_hint` is just the suggested site.

const W := 80
const H := 80
## When raids start, and when each Config.RAIDER_TIERS index unlocks (seconds).
const RAID_SCHEDULE := {
	"raid_delay": 300.0,
	"tier_times": [0.0, 480.0, 900.0, 1320.0],
}
## Pressure curve (§4.1). Points hold the old unlocks: Brute ~8 min (0.20), Ravager ~15 (0.60),
## Behemoth ~22 (0.85). Grace matches the raid start; cap is the spec's 2400 s.
const PRESSURE := { "grace": 300.0, "cap": 2400.0 }
const PRESSURE_POINTS := [
	{ "t": 300.0, "p": 0.0 },
	{ "t": 480.0, "p": 0.20 },
	{ "t": 900.0, "p": 0.60 },
	{ "t": 1320.0, "p": 0.85 },
	{ "t": 2400.0, "p": 1.0 },
]
## Castles (CastleShape rows). The Operative takes them; raiders take them back.
## Ashmoat (Stage 21): a compact concentric castle in the SW (outer wall, bailey, inner wall,
## keep hall), its moat fed by the core-fed vent on its north side; one trebuchet on the NW tower
## with a short reach (24 cells): it guards the castle's surroundings, not the landing mesa. High Bastion stays a Stage 7 raised keep on its plateau
## (no room in the north for a 31-cell castle), reached by a drawbridge from the south or the
## climbing pillars on its east.
const CASTLES := [
	{ "id": "ashmoat", "name": "Ashmoat Keep", "x": 0, "z": 49, "size": 31, "floor": 2, "plan": "concentric",
		"bailey": 5, "variant": "ground", "moat": true, "gates": ["n"], "inner_gate": "e", "climbs": ["e"],
		"spire_h": 20, "engines": 1, "engine_range": 24.0 },
	{ "id": "bastion", "name": "High Bastion", "x": 25, "z": 2, "size": 15, "floor": 4,
		"variant": "raised", "bridge": true, "gates": ["s"], "climbs": ["e"], "spire_h": 20 },
]
## Scripted base for --demo (debug only; Debug.DEMO_BUILD with the relay chain moved off Ashmoat's moat).
const DEMO := [
	["relay", 34, 58], ["relay", 33, 47], ["relay", 27, 36], ["relay", 24, 24], ["relay", 19, 14], ["nullifier", 17, 14],
	["collector", 34, 63], ["collector", 46, 63], ["collector", 40, 59], ["collector", 35, 70], ["collector", 45, 70],
	["cannon", 33, 56], ["cannon", 47, 57], ["cannon", 40, 55], ["cannon", 35, 50], ["mortar", 37, 59],
	["beam", 44, 60], ["reactor", 43, 62], ["storage", 37, 63], ["barracks", 47, 66],
	["sniper", 36, 56], ["sniper", 44, 56],
	["sniper", 40, 57], ["sniper", 32, 58], ["sniper", 48, 58], ["beam", 38, 59], ["beam", 42, 59],
	["sniper", 34, 55], ["sniper", 46, 55], ["beam", 36, 57],
	["cannon", 35, 61], ["cannon", 41, 61], ["cannon", 49, 62],
	["reactor", 36, 66], ["reactor", 40, 66], ["reactor", 44, 66], ["reactor", 36, 69], ["reactor", 44, 69], ["storage", 40, 69],
]
## Salvage Engines (EngineDefs). One safe wreck near the base; the rest sit beside hives and the
## Bastion, where hooking is a risk: `hive` / `castle` engines ship only once that is razed / held.
const ENGINES := [
	{ "id": "e1", "x": 58, "z": 67, "kind": "wreck" },
	{ "id": "e2", "x": 28, "z": 22, "kind": "forge", "hive": "Central knoll" },
	{ "id": "e3", "x": 47, "z": 15, "kind": "wreck", "castle": "bastion" },
	{ "id": "e4", "x": 66, "z": 26, "kind": "bore", "hive": "Spire Heights" },
	{ "id": "e5", "x": 22, "z": 42, "kind": "forge", "hive": "Rift" },
]
## Castle stakes (CastleRaids; keys default to Config.CASTLE_RULES). Level 1 is gentle.
const CASTLE_RULES := { "aggression": 0.5, "reprisal_warn": 90.0, "nest_buff": 0.15 }


static func _smoothstep(a: float, b: float, t: float) -> float:
	var k := clampf((t - a) / (b - a), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


static func _disc(g: Grid, cx: int, cz: int, r: float, fn: Callable) -> void:
	for c in g.cells_in_radius(cx, cz, r):
		fn.call(c.x, c.y, Vector2(c.x - cx, c.y - cz).length())


static func _rect(g: Grid, x0: int, z0: int, x1: int, z1: int, fn: Callable) -> void:
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			if g.in_bounds(x, z):
				fn.call(x, z)


static func _blight(g: Grid, cx: int, cz: int, r: float) -> void:
	_disc(g, cx, cz, r, func(x, z, _d): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)


static func _bowl(g: Grid, cx: int, cz: int, r0: float, r1: float, floor_h: float) -> void:
	_disc(g, cx, cz, r1, func(x, z, d):
		g.set_height(x, z, floor_h + (g.height_at(x, z) - floor_h) * _smoothstep(r0, r1, d)))


static func _mesa(g: Grid, cx: int, cz: int, r0: float, r1: float, top: float) -> void:
	_disc(g, cx, cz, r1, func(x, z, d):
		var hh := g.height_at(x, z)
		g.set_height(x, z, maxf(hh, top - (top - hh) * _smoothstep(r0, r1, d))))


static func _set_rect(g: Grid, x0: int, z0: int, x1: int, z1: int, v: float) -> void:
	_rect(g, x0, z0, x1, z1, func(x, z): g.set_height(x, z, v))


## Shelves keep their cliffs. The lowland steps one level at a time, and each named
## shelf gets a stair a raider can climb. The southern mesa keeps only its north stair
## and the west-ridge gap; castle footprints are left for CastleShape.
static func _routes(g: Grid) -> void:
	var keep := LevelRamps.mask(g)
	LevelRamps.cover_disc(keep, g, 40, 64, 10.5)
	LevelRamps.cover_rect(keep, g, 30, 70, 50, 79)
	LevelRamps.cover_rect(keep, g, 38, 44, 42, 55)
	LevelRamps.cover_disc(keep, g, 24, 66, 7.0)
	LevelRamps.cover_disc(keep, g, 57, 64, 7.0)
	LevelRamps.cover_rect(keep, g, 10, 51, 34, 53)
	LevelRamps.uncover_rect(keep, g, 27, 51, 29, 53)
	LevelRamps.cover_disc(keep, g, 14, 12, 7.0)
	LevelRamps.cover_disc(keep, g, 14, 42, 11.0)  # Rift hollow + cave-mouth rim
	LevelRamps.cover_rect(keep, g, 54, 3, 73, 19)
	LevelRamps.cover_disc(keep, g, 40, 24, 6.0)
	LevelRamps.cover_disc(keep, g, 68, 50, 6.0)
	LevelRamps.cover_disc(keep, g, 26, 26, 4.0)
	LevelRamps.cover_disc(keep, g, 52, 38, 4.0)
	for c in CASTLES:
		LevelRamps.cover_rect(keep, g, int(c.x) - 4, int(c.z) - 4, int(c.x) + int(c.size) + 3, int(c.z) + int(c.size) + 3)
	LevelRamps.smooth_lowland(g, keep)
	LevelRamps.stairs(g, Vector2i(14, 15), Vector2i(14, 29), 5, 2)
	LevelRamps.stairs(g, Vector2i(68, 50), Vector2i(56, 50), 5, 2)
	LevelRamps.stairs(g, Vector2i(24, 66), Vector2i(24, 74), 5, 2)
	LevelRamps.stairs(g, Vector2i(57, 64), Vector2i(57, 76), 5, 2)
	LevelRamps.stairs(g, Vector2i(40, 24), Vector2i(40, 30), 5, 1)
	LevelRamps.stairs(g, Vector2i(72, 11), Vector2i(79, 11), 3, 2)  # Spire Heights: east face, away from the mesa
	LevelRamps.stairs(g, Vector2i(18, 52), Vector2i(18, 36), 5, 2)
	LevelRamps.stairs(g, Vector2i(32, 52), Vector2i(32, 36), 3, 2)
	LevelRamps.stairs(g, Vector2i(26, 26), Vector2i(26, 32), 3, 1)
	LevelRamps.stairs(g, Vector2i(52, 38), Vector2i(52, 46), 3, 1)


static func build() -> Dictionary:
	var g := Grid.new(W, H)
	var noise := Noise2D.new(7)
	# Rolling lowland (levels 1-3) cut by an east-west valley: the creeper highway.
	for z in H:
		for x in W:
			var n := noise.fbm(x / 14.0, z / 14.0, 4)
			var valley := exp(-pow((z - 30 - sin(x / 9.0) * 4.0) / 5.0, 2.0)) * 2.4
			g.set_height(x, z, maxf(0.0, 2.6 + (n - 0.5) * 14.0 - valley))
	# Southern mesa (the suggested landing site), level 6, sheer on three sides.
	_mesa(g, 40, 64, 8.5, 10.5, 6.0)
	_set_rect(g, 30, 70, 50, 79, 6.0)
	# Stair ramp north off the mesa (one level per 2 cells) down to the lowland.
	for z in range(44, 56):
		var hz := 6.0 - (55 - z) * 0.5
		_rect(g, 38, z, 42, z, func(x, zz): g.set_height(x, zz, maxf(1.0, hz)))
	# Side terraces: level 4 shelves west and east of the mesa give room for collectors.
	_mesa(g, 24, 66, 5, 7, 4.0)
	_mesa(g, 57, 64, 5, 7, 4.0)
	# West ridge (level 8) shields the mesa from the Rift basin; a level-3 gap at x 27-29.
	_rect(g, 10, 51, 34, 53, func(x, z):
		g.set_height(x, z, 3.0 if x >= 27 and x <= 29 else 8.0))
	# NW emitter plateau (level 7): creeper pours off it in cascades.
	_mesa(g, 14, 12, 5, 7, 7.0)
	_bowl(g, 14, 12, 0, 2.5, 6.0)  # shallow crater around the emitter
	# Rift hollow (cave mouth), west. Level-2 floor, the Rift on a one-step rock (level 3) so
	# it floods last but the Operative can still walk up to it.
	_bowl(g, 14, 42, 3.5, 8, 2.0)
	_disc(g, 14, 42, 1.6, func(x, z, _d): g.set_height(x, z, 3.0))
	_blight(g, 12, 41, 7)
	# Cave-mouth rim (Playtest 1C): a level-5 ring with an east and a north gap, the only
	# ways in or out of the hollow. Kept out of smooth_lowland via the keep mask in _routes.
	_disc(g, 14, 42, 10.5, func(x, z, d):
		if d < 8.5:
			return
		if absf(float(z - 42)) <= 1.0 and x > 14:
			return  # east gap
		if absf(float(x - 14)) <= 1.0 and z < 42:
			return  # north gap
		if g.height_at(x, z) < 5.0:
			g.set_height(x, z, 5.0))
	# NE "Spire Heights": sheer level-10 plateau, Blight on top. The single stair is on the
	# east side (see _routes), facing away from the southern landing mesa.
	_rect(g, 54, 3, 73, 19, func(x, z):
		var edge := mini(mini(x - 54, 73 - x), mini(z - 3, 19 - z))
		g.set_height(x, z, 8.0 if edge < 1 else 10.0))
	_rect(g, 54, 3, 73, 19, func(x, z): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)
	# Central Blight knoll with a nest: the units' first real fight.
	_mesa(g, 40, 24, 3, 6, 5.0)
	_blight(g, 40, 24, 5)
	# Playtest 1C: Blight band across the southern approach. The walk to the knoll
	# crosses Blight (nothing can be built there); the network routes around either end.
	_rect(g, 32, 31, 48, 34, func(x, z): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)
	# East emitter shelf (level 5) and a few lowland buttes for line-of-fire and choke points.
	_mesa(g, 68, 50, 4, 6, 5.0)
	_mesa(g, 26, 26, 2, 4, 4.0)
	_mesa(g, 52, 38, 2, 4, 4.0)
	_mesa(g, 70, 70, 3, 5, 3.0)
	_routes(g)
	# CW3 terrain is whole levels 0..10.
	for i in g.height.size():
		g.height[i] = clampf(roundf(g.height[i]), 0.0, Config.MAX_LEVEL)
	# Castles are shaped last, in whole levels (spires rise past MAX_LEVEL; CastleShape).
	var castles := CASTLES.duplicate(true)
	for c in castles:
		c["layout"] = CastleShape.build(g, c)

	var level := {
		"name": "Hollow Ridge",
		"grid": g,
		"landing_hint": Vector2i(40, 66),
		"landing_min_dist": 14.0,  # cells from any emitter/vent/nest
		"emitters": [
			{ "id": "e1", "name": "Emitter NW", "x": 14, "z": 12, "amount": 3.0, "interval": 0.5 },
			{ "id": "e2", "name": "Emitter East", "x": 68, "z": 50, "amount": 3.0, "interval": 0.5, "shielded_by": "core",
				"shield_hint": "Its shield is powered from underground: send the Operative into the Rift and destroy the Deep Core." },
		],
		"vents": [  # fed by the Deep Core, shut off when it dies
			{ "x": 24, "z": 36, "amount": 1.6, "interval": 1.0 },
			{ "x": 20, "z": 45, "amount": 1.4, "interval": 1.0 },  # pours into Ashmoat's north moat
		],
		"hives": [
			{ "name": "Rift", "x": 9, "z": 38, "access": "cavemouth" },
			{ "name": "Spire Heights", "x": 59, "z": 13, "access": "plateau" },
			{ "name": "Central knoll", "x": 40, "z": 23, "access": "blight" },
		],
		"raid_schedule": RAID_SCHEDULE,
		"pressure": PRESSURE,
		"pressure_points": PRESSURE_POINTS,
		"spire": { "x": 66, "z": 9 },
		"castles": castles,
		"castle_rules": CASTLE_RULES,
		"ores": [
			{ "x": 50, "z": 58 },
			{ "x": 72, "z": 36 },
			{ "x": 33, "z": 66 },  # under Ashmoat's east wall
		],
		"ammo_unlock": "e1",  # improved ammo (AmmoGrades) once this objective completes
		"engines": ENGINES.duplicate(true),
		"rift": { "x": 14, "z": 42 },
		"demo": DEMO,
		"intro": [
			["Ops: Choose where the Command Node lands. High, dry ground far from emitters buys you time.", "radio"],
			["Ops: Energy IS packets. The Node fires one wherever a structure asks, as long as the bank has energy.", "radio"],
			["Ops: Collectors claim land for income. Relays carry packets to the front. Weapons can fly to new spots.", "radio"],
			["Ops: Purple Blight can't be built on. Barracks units can go there, but they run dry and must come home.", "radio"],
		],
	}
	level["nests"] = level.hives # alias: older readers still say nests
	HiveShape.stamp_all(g, level.hives)
	EngineShape.stamp_all(g, level.engines)
	var hazards: Array = level.emitters + level.vents + level.nests + [level.spire, level.rift]
	for p in hazards:
		_disc(g, p.x, p.z, 1.5, func(x, z, _d): g.blocked[g.idx(x, z)] = 1)
	level["hazard_points"] = hazards
	return level
