class_name SmokeFlyers
## Stage 19 flyer core: spawn, terrain-ignoring flight, bat dives, Gasbag creeper drops.


static func run(g) -> void:
	var nests: SporeNests = g.hazards.nests
	nests.time = 0.0
	nests.flyers.clear()
	_spawn(g, nests.flyers)
	_cliff(g, nests.flyers)
	_dive(g, nests.flyers)
	_drop(g, nests.flyers)
	nests.flyers.clear()


static func _row(n: String) -> Dictionary:
	return FlyerDefs.named(n)


static func _spawn(g, fl: Flyers) -> void:
	var base: Vector3 = g.structures.command_node().pos + Vector3(0, 8, 20)
	var ok := true
	for row in FlyerDefs.ROWS:
		var f := fl.spawn(row, base, {})
		ok = ok and f.alive and (f.node as Node3D).is_inside_tree()
	SmokeTest._check("flyers: every type spawns", ok and fl.count() == 3)
	var in_targets: bool = g.surface.targets.size() > 0 and fl.list.all(func(f): return g.surface.targets.has(f.target_def))
	SmokeTest._check("flyers: the Operative can target them", in_targets)
	var enemies: Array = g.hazards.nests.enemies()
	SmokeTest._check("flyers: not unit enemies", fl.list.all(func(f): return not enemies.has(f.target_def)))
	fl.clear()


static func _cliff(g, fl: Flyers) -> void:
	var grid: Grid = g.surface.grid
	var saved := {}
	for x in range(10, 50):
		for z in range(18, 23):
			var i := grid.idx(x, z)
			saved[i] = grid.height[i]
			grid.height[i] = 2.0 if x < 24 else 6.0
	var y0 := grid.smooth_y(20.0, 40.0)
	var f := fl.spawn(_row("Spore Bat"), Vector3(24.0, y0 + 6.0, 40.0), {})
	var node := f.node as Node3D
	var x0 := node.position.x
	var goal := Vector3(80.0, 0, 40.0)
	var peak_gap := 99.0
	for i in 40:  # 2 s at 0.05
		fl.fly(f, goal, 0.05)
		var under := grid.smooth_y(node.position.x, node.position.z)
		peak_gap = minf(peak_gap, node.position.y - under)
	var travelled := node.position.x - x0
	SmokeTest._check("flyers: a cliff does not slow a bat", is_equal_approx(travelled, 7.0 * 2.0), "(%.2f m in 2 s)" % travelled)
	SmokeTest._check("flyers: never dips into the ground", peak_gap > 0.5, "(min gap %.2f)" % peak_gap)
	for i in saved:
		grid.height[i] = saved[i]
	fl.clear()


static func _dive(g, fl: Flyers) -> void:
	var sm: StructureManager = g.structures
	var relay := sm.place("relay", 52, 64, true)
	if relay == null:
		SmokeTest._check("flyers: dive test could place a relay", false)
		return
	var hp0 := relay.hp
	var p := relay.pos + Vector3(10, 6, 0)
	var f := fl.spawn(_row("Spore Bat"), p, { "cd": 0.0 })
	f.target = relay
	for i in 160:  # 8 s
		fl.update(0.05)
		if relay.hp < hp0 or relay.dead:
			break
	SmokeTest._check("flyers: a bat dive damages a relay", relay.dead or relay.hp < hp0, "(hp %.1f/%.1f)" % [relay.hp, hp0])
	if not relay.dead:
		sm.remove(relay)
	fl.clear()


static func _drop(g, fl: Flyers) -> void:
	var grid: Grid = g.surface.grid
	var gb := fl.spawn(_row("Gasbag"), grid.cell_ground(grid.w / 2, grid.h / 2) + Vector3(0, 10, 0), {})
	var node := gb.node as Node3D
	var c := grid.world_to_cell(node.position.x, node.position.z)
	var before: float = g.surface.creeper.depth_at(c.x, c.y)
	FlyerAi.drop(fl, gb)
	SmokeTest._sim(g, 0.9)
	var after: float = g.surface.creeper.depth_at(c.x, c.y)
	SmokeTest._check("flyers: a Gasbag drop raises creeper at its cell", after > before + 1.0, "(%.2f -> %.2f)" % [before, after])
	fl.clear()
