class_name Level01
## Level 01 "Hollow Ridge": surface layout. Pure data + shaping helpers so new levels can
## copy this file. See docs/LEVEL01_DESIGN.md. Blight zones (no building) are reachable only
## by the Operative and barracks units. Heights are whole CW3 levels (0..10): flat terraces
## with sheer walls, so ramps and stairs are explicit. The Command Node lands wherever the player chooses
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
## Ashmoat: a ground keep whose moat the core-fed SW vent fills. High Bastion: a raised keep
## on a plateau, reached by a drawbridge from the south or the climbing pillars on its east.
const CASTLES := [
	{ "id": "ashmoat", "name": "Ashmoat Keep", "x": 1, "z": 60, "size": 15, "floor": 2,
		"variant": "ground", "moat": true, "gates": ["n"], "climbs": ["e"], "spire_h": 20 },
	{ "id": "bastion", "name": "High Bastion", "x": 25, "z": 2, "size": 15, "floor": 4,
		"variant": "raised", "bridge": true, "gates": ["s"], "climbs": ["e"], "spire_h": 20 },
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
	# NE "Spire Heights": sheer level-10 plateau, Blight on top, stair ramp heading south.
	_rect(g, 54, 3, 73, 19, func(x, z):
		var edge := mini(mini(x - 54, 73 - x), mini(z - 3, 19 - z))
		g.set_height(x, z, 8.0 if edge < 1 else 10.0))
	for z in range(20, 35):
		var hz := 10.0 - (z - 19) * 0.5
		_rect(g, 60, z, 62, z, func(x, zz): g.set_height(x, zz, maxf(hz, g.height_at(x, zz))))
		for x in [59, 63]:
			g.set_height(x, z, minf(g.height_at(x, z), maxf(1.0, hz - 3.0)))
	_rect(g, 54, 3, 73, 19, func(x, z): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)
	# Central Blight knoll with a nest: the units' first real fight.
	_mesa(g, 40, 24, 3, 6, 5.0)
	_blight(g, 40, 24, 5)
	# East emitter shelf (level 5) and a few lowland buttes for line-of-fire and choke points.
	_mesa(g, 68, 50, 4, 6, 5.0)
	_mesa(g, 26, 26, 2, 4, 4.0)
	_mesa(g, 52, 38, 2, 4, 4.0)
	_mesa(g, 70, 70, 3, 5, 3.0)
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
			{ "x": 18, "z": 58, "amount": 1.4, "interval": 1.0 },
		],
		"hives": [
			{ "name": "Rift", "x": 9, "z": 38 },
			{ "name": "Spire Heights", "x": 59, "z": 13 },
			{ "name": "Central knoll", "x": 40, "z": 23 },
		],
		"raid_schedule": RAID_SCHEDULE,
		"pressure": PRESSURE,
		"pressure_points": PRESSURE_POINTS,
		"spire": { "x": 66, "z": 9 },
		"castles": castles,
		"castle_rules": CASTLE_RULES,
		"rift": { "x": 14, "z": 42 },
		"intro": [
			["Ops: Choose where the Command Node lands. High, dry ground far from emitters buys you time.", "radio"],
			["Ops: Energy IS packets. The Node fires one wherever a structure asks, as long as the bank has energy.", "radio"],
			["Ops: Collectors claim land for income. Relays carry packets to the front. Weapons can fly to new spots.", "radio"],
			["Ops: Purple Blight can't be built on. Barracks units can go there, but they run dry and must come home.", "radio"],
		],
	}
	level["nests"] = level.hives # alias: older readers still say nests
	HiveShape.stamp_all(g, level.hives)
	var hazards: Array = level.emitters + level.vents + level.nests + [level.spire, level.rift]
	for p in hazards:
		_disc(g, p.x, p.z, 1.5, func(x, z, _d): g.blocked[g.idx(x, z)] = 1)
	level["hazard_points"] = hazards
	return level
