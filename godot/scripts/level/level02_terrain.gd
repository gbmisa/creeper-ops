class_name Level02Terrain
## Terrain for Level 02. Order matters: a gentle lowland (every step at most one level, so
## raiders and the Operative can roam it), castle pads blended into it, and only then the
## cliffed features, which keep clear of the castles.

const NEST_KNOLLS := [Vector2i(15, 60), Vector2i(44, 66), Vector2i(82, 40), Vector2i(112, 104), Vector2i(34, 151)]


static func shape(g: Grid, castles: Array) -> void:
	var noise := Noise2D.new(11)
	for z in g.h:
		for x in g.w:
			var n := noise.fbm(x / 22.0, z / 22.0, 4)
			var west_east := exp(-pow((z - 96 - sin(x / 14.0) * 6.0) / 6.0, 2.0)) * 2.4
			var north_south := exp(-pow((x - 80 - sin(z / 12.0) * 8.0) / 5.0, 2.0)) * 1.8
			g.set_height(x, z, maxf(0.0, 2.8 + (n - 0.5) * 9.0 - west_east - north_south))
	for c in castles:  # pad = castle + its 4-cell apron, blended over 9 more cells
		LevelShape.pad(g, Rect2i(c.x, c.z, c.size, c.size).grow(4), 9, c.floor)
	LevelShape.round_levels(g)
	LevelShape.limit_slope(g)
	_landing(g)
	_rift(g)
	_plateau(g)
	for k in NEST_KNOLLS:
		LevelShape.mesa(g, k.x, k.y, 3, 6, g.height_at(k.x, k.y) + 2.0)
		LevelShape.blight(g, k.x, k.y, 5)
	_hive_sites(g)
	for b in [Vector3(52, 124, 3), Vector3(108, 126, 3), Vector3(60, 28, 3), Vector3(100, 52, 4), Vector3(26, 80, 3)]:
		LevelShape.mesa(g, int(b.x), int(b.y), 2.5, 5.0, g.height_at(int(b.x), int(b.y)) + b.z)
	LevelShape.round_levels(g)


## Southern mesa (level 6, sheer on three sides) with a stair ramp north off it.
static func _landing(g: Grid) -> void:
	LevelShape.mesa(g, 80, 146, 10, 12.5, 6.0)
	LevelShape.set_rect(g, 70, 148, 90, 159, 6.0)
	LevelShape.ramp(g, Vector2i(80, 136), Vector2i(80, 100), 5, 6.0, 2.0)
	for s in [Vector2i(50, 142), Vector2i(110, 142)]:  # side shelves with room for collectors
		LevelShape.mesa(g, s.x, s.y, 4, 6, 4.0)


## Rift hollow: level-2 floor, the Rift on a one-step rock, Blight round it.
## Playtest 1C: a level-5 rim ring (r 8.5-10.5) with east and north gaps, the only
## ways in or out of the hollow (cave mouth). Added after limit_slope, so it stays sheer.
static func _rift(g: Grid) -> void:
	LevelShape.bowl(g, 20, 64, 3.5, 8, 2.0)
	LevelShape.disc(g, 20, 64, 1.6, func(x, z, _d): g.set_height(x, z, 3.0))
	LevelShape.blight(g, 18, 63, 7)
	LevelShape.disc(g, 20, 64, 10.5, func(x, z, d):
		if d < 8.5:
			return
		if absi(z - 64) <= 1 and x > 20:
			return  # east gap
		if absi(x - 20) <= 1 and z < 64:
			return  # north gap
		if g.height_at(x, z) < 5.0:
			g.set_height(x, z, 5.0))


## East plateau (level 10) for the Spore Spire: Blight on top, ramp heading south.
static func _plateau(g: Grid) -> void:
	LevelShape.set_rect(g, 128, 52, 147, 70, 10.0)
	LevelShape.blight_rect(g, 128, 52, 147, 70)
	LevelShape.ramp(g, Vector2i(137, 71), Vector2i(137, 104), 5, 10.0, 2.0)
	for p in [Vector2i(80, 26), Vector2i(112, 72)]:  # emitter shelves: creeper pours off them
		LevelShape.mesa(g, p.x, p.y, 3, 5, g.height_at(p.x, p.y) + 2.0)


## Playtest 1C: one access challenge per hive site (the "access" tags in level02.gd).
## Runs after limit_slope, so the new cliffs stay sheer.
static func _hive_sites(g: Grid) -> void:
	# North Knoll chokepoint: a ridge ring with a single 2-cell pass on the south side.
	var top := g.height_at(82, 40) + 2.0
	LevelShape.disc(g, 82, 40, 11.0, func(x, z, d):
		if d < 9.0:
			return
		if z > 40 and (x == 81 or x == 82):
			return  # the pass
		if g.height_at(x, z) < top:
			g.set_height(x, z, top))
	# West Moor: Blight band across the south-east approach (walk it; the network routes around).
	LevelShape.rect(g, 36, 74, 64, 77, func(x, z): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)
	# East Moor: a shallow creeper channel running south from Emitter East.
	LevelShape.rect(g, 115, 96, 117, 112, func(x, z): g.set_height(x, z, g.height_at(x, z) - 1.0))
	# Southern Barrows plateau: sheer level 6, a single stair on the west side.
	LevelShape.set_rect(g, 28, 145, 40, 157, 6.0)
	LevelShape.ramp(g, Vector2i(27, 151), Vector2i(19, 151), 3, 6.0, 2.0)
