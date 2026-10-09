class_name SmokePt3
## Playtest 3: the Null Sprayer is a tool (not a field wiper) and cave mites obey rock.


static func run(g) -> void:
	_sprayer(g)
	_mites()


static func _sprayer(g) -> void:
	var grid: Grid = g.surface.grid
	var spot := SmokeArmoury._ledge(g, grid)
	if spot.x < 0:
		SmokeTest._check("pt3: sprayer spot", false)
		return
	var feet := grid.cell_ground(spot.x, spot.y)
	var w: OperativeWeapons = g.fps.weapons
	SmokeArmoury._aim(w, feet + Vector3(0, Config.EYE, 0), feet + Vector3(6, Config.EYE, 0))
	var saved := {}
	var here := grid.world_to_cell(feet.x, feet.z)
	for c in grid.cells_in_radius(here.x, here.y, Config.SPRAYER.range / Config.CELL):
		saved[c] = g.surface.creeper.depth_at(c.x, c.y)
		g.surface.creeper.set_depth(c.x, c.y, 8.0)
	w.tank = Config.TANK_MAX
	var dt := 0.05
	var steps := 0
	var removed := 0.0
	var at_1s := 0.0
	while w.tank > 0.0 and steps < 400:
		w._spray(dt, g.surface, feet)
		g.surface.creeper._annihilate()
		steps += 1
		if steps == 20:
			at_1s = SmokeArmouryGuns._pool(g, saved)
	removed = SmokeArmouryGuns._pool(g, saved)
	for c in saved:
		g.surface.creeper.set_depth(c.x, c.y, saved[c])
	# Old tuning (anti 5.0) removed 3x more per second; assert the new rate is at most ~1/3 of that.
	var old_rate := at_1s * 5.0 / float(Config.SPRAYER.anti_per_sec)
	SmokeTest._check("pt3: sprayer removal is about a third of the old rate", at_1s <= old_rate * 0.36 and at_1s > 0.5,
		"%.2f/s now vs %.2f/s before" % [at_1s, old_rate])
	var secs := float(steps) * dt
	SmokeTest._check("pt3: sprayer tank empties in ~8 s", absf(secs - Config.TANK_MAX / Config.SPRAYER.tank_per_sec) < 0.2 and secs > 7.0 and secs < 9.0,
		"%.2f s, total %.1f removed, refill %.0f s" % [secs, removed, Config.TANK_MAX / Config.TANK_REGEN])


static func _mites() -> void:
	var grid := Grid.new(30, 30)
	for z in 30:
		for x in range(14, 17):
			grid.set_height(x, z, 10.0)   # a wall across the whole map
	var a := Vector3(10, 3, 30)
	var b := Vector3(50, 3, 30)
	SmokeTest._check("pt3: core has no line of fire through a wall", not CaveMites.has_line(grid, a, b))
	var step: Variant = CaveMites.steer(grid, Vector3(26, 3, 30), b, Config.MITE_SPEED * 0.1)
	var pos := Vector3(26, 3, 30)
	var stuck: bool = true
	for i in 200:
		var nxt: Variant = CaveMites.steer(grid, pos, b, 0.5)
		if nxt == null:
			break
		pos = nxt
		if pos.x > 36.0:
			stuck = false
			break
	SmokeTest._check("pt3: a mite never passes through the wall", stuck and pos.x < 36.0, "x %.1f, first step %s" % [pos.x, str(step)])
	var open := Vector3(10, 30, 30)   # above the wall: open air
	SmokeTest._check("pt3: line of fire over the wall is clear", CaveMites.has_line(grid, open, Vector3(50, 30, 30)))
