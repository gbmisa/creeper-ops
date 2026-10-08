class_name SmokeArmoury
## Stage 10a: Salvage buys stop at the tier cap, multipliers apply, the shield soaks,
## mobility reaches a higher ledge, advanced weapons spend Salvage, and upgrades survive death.


static func run(g) -> void:
	_shop(g)
	_firepower(g)
	_armour(g)
	_mobility(g)
	_rail(g)
	_plasma(g)
	_demo(g)
	_death(g)
	OperativeUpgrades.reset()


static func _shop(g) -> void:
	OperativeUpgrades.reset()
	var pile: Stockpile = g.stockpile
	pile.salvage = 0.0
	SmokeTest._check("armoury: buy fails without salvage", OperativeUpgrades.buy("firepower", pile) != "")
	pile.salvage = 20.0
	var ok := OperativeUpgrades.buy("firepower", pile) == "" and OperativeUpgrades.level("firepower") == 1
	SmokeTest._check("armoury: buy spends salvage", ok and pile.salvage <= 0.001, "salvage %.1f" % pile.salvage)
	pile.salvage = 45.0 + 80.0
	OperativeUpgrades.buy("firepower", pile)
	OperativeUpgrades.buy("firepower", pile)
	SmokeTest._check("armoury: stops at max tier", OperativeUpgrades.maxed("firepower") and OperativeUpgrades.buy("firepower", pile) != "")
	OperativeUpgrades.reset()
	SmokeTest._check("armoury: reset clears", OperativeUpgrades.level("firepower") == 0 and OperativeUpgrades.level("unlock_railgun") == 0)


static func _firepower(g) -> void:
	OperativeUpgrades.reset()
	var w: OperativeWeapons = g.fps.weapons
	var hit := _target(g.surface, Vector3(80, 80, 70))
	_aim(w, Vector3(80, 80, 90), hit.pos)
	w._fire(g.surface)
	SmokeTest._check("armoury: rifle base damage", is_equal_approx(hit.dmg, Config.RIFLE.damage), str(hit.dmg))
	g.stockpile.salvage = 20.0
	OperativeUpgrades.buy("firepower", g.stockpile)
	hit.dmg = 0.0
	w._fire(g.surface)
	SmokeTest._check("armoury: firepower 1 is +25% rifle", is_equal_approx(hit.dmg, Config.RIFLE.damage * 1.25), str(hit.dmg))
	w.launcher.update(0.05, g.surface)
	SmokeTest._check("armoury: rocket magazine +1", w.launcher.mag_size() == Config.ROCKET.mag + 1 and w.launcher.loaded == Config.ROCKET.mag + 1)
	_free_target(g.surface, hit)


static func _armour(g) -> void:
	OperativeUpgrades.reset()
	g.stockpile.salvage = 20.0 + 45.0 + 80.0
	for i in 3:
		OperativeUpgrades.buy("armour", g.stockpile)
	g.fps.reset_suit()
	var cap := Config.SUIT_MAX * 1.75
	SmokeTest._check("armoury: armour raises suit max", is_equal_approx(g.fps.suit, cap) and is_equal_approx(OperativeUpgrades.shield_max(), 30.0))
	var before: float = g.fps.suit
	g.fps.damage(12.0)
	var soaked := is_equal_approx(g.fps.suit, before) and is_equal_approx(g.fps.shield, 18.0)
	g.fps.damage(20.0)
	soaked = soaked and is_equal_approx(g.fps.shield, 0.0) and is_equal_approx(g.fps.suit, before - 2.0)
	SmokeTest._check("armoury: tier 3 shield soaks first", soaked, "suit %.1f shield %.1f" % [g.fps.suit, g.fps.shield])


static func _mobility(g) -> void:
	var grid: Grid = g.surface.grid
	var low := _ledge(g, grid)
	SmokeTest._check("armoury: found a ledge", low.x >= 0, str(low))
	if low.x < 0:
		return
	var high := low + Vector2i(1, 0)
	TerrainEdit.raise(g.surface, [high], 2.0)
	OperativeUpgrades.reset()
	var cam := Camera3D.new()
	var pc := PlayerController.new(cam)
	var inp := SmokeCastleWalk.FakeInput.new()
	var t0 := _leap(pc, grid, inp, low, high, false)
	OperativeUpgrades.grant("mobility")
	OperativeUpgrades.grant("mobility")
	var t2 := _leap(pc, grid, inp, low, high, false)
	TerrainEdit.raise(g.surface, [high], 1.0)
	var t2b := _leap(pc, grid, inp, low, high, false)
	OperativeUpgrades.grant("mobility")
	var t3 := _leap(pc, grid, inp, low, high, true)
	TerrainEdit.raise(g.surface, [high], -3.0)
	inp.free()
	cam.free()
	SmokeTest._check("armoury: single jump misses the ledge", t0 != high, str(t0))
	SmokeTest._check("armoury: double jump reaches it", t2 == high, str(t2))
	SmokeTest._check("armoury: jump jet reaches one level more", t2b != high and t3 == high, "tier2 %s tier3 %s" % [t2b, t3])


static func _leap(pc: PlayerController, grid: Grid, inp: SmokeCastleWalk.FakeInput, low: Vector2i, high: Vector2i, jet: bool) -> Vector2i:
	pc.spawn(grid, low.x, low.y)  # cell centre: the shared edge is a ramp, and a jump that starts on it is snapped
	pc.on_ground = true
	var goal := grid.cell_center(high.x, high.y)
	inp.hold = { "op_forward": true }
	if jet:
		inp.hold["jump"] = true
	inp.press = { "jump": true }
	var hopped := false
	for i in 200:
		var d := Vector2(goal.x - pc.pos.x, goal.z - pc.pos.z)
		pc.yaw = atan2(-d.x, -d.y)
		if OperativeUpgrades.air_jumps() > 0 and not hopped and not pc.on_ground and pc.vel_y < 0.4 and pc.pos.y > grid.smooth_y(pc.pos.x, pc.pos.z) + 0.3:
			inp.press = { "jump": true }
			hopped = true
		pc.update(1.0 / 60.0, inp, grid)
		inp.press = {}
		if grid.world_to_cell(pc.pos.x, pc.pos.z) == high and pc.on_ground:
			break
	inp.hold = {}
	return grid.world_to_cell(pc.pos.x, pc.pos.z)


static func _rail(g) -> void:
	OperativeUpgrades.reset()
	OperativeUpgrades.grant("unlock_railgun")
	var w: OperativeWeapons = g.fps.weapons
	var a := _target(g.surface, Vector3(80, 80, 74))
	var b := _target(g.surface, Vector3(80, 80, 66))
	var side := _target(g.surface, Vector3(92, 80, 70))
	_aim(w, Vector3(80, 80, 86), b.pos)
	g.stockpile.salvage = 0.0
	w.advanced.charge = float(AdvancedWeapons.WEAPONS.railgun.charge) - 0.01
	w.advanced._rail(0.05, true, g.surface)
	SmokeTest._check("armoury: railgun dry does not fire", a.dmg == 0.0 and "Salvage" in w.advanced.need, w.advanced.need)
	g.stockpile.salvage = 2.0
	w.advanced._moaned = false
	w.advanced.charge = float(AdvancedWeapons.WEAPONS.railgun.charge) - 0.01
	w.advanced._rail(0.05, true, g.surface)
	var pierced: bool = is_equal_approx(a.dmg, 30.0) and is_equal_approx(b.dmg, 30.0) and side.dmg == 0.0
	SmokeTest._check("armoury: railgun pierces two targets", pierced and g.stockpile.salvage <= 0.001, "a %.0f b %.0f side %.0f" % [a.dmg, b.dmg, side.dmg])
	_free_target(g.surface, a)
	_free_target(g.surface, b)
	_free_target(g.surface, side)


static func _plasma(g) -> void:
	OperativeUpgrades.grant("unlock_plasma")
	var grid: Grid = g.surface.grid
	var spot := _ledge(g, grid)
	if spot.x < 0:
		SmokeTest._check("armoury: plasma spot", false)
		return
	var feet := grid.cell_ground(spot.x, spot.y)
	var w: OperativeWeapons = g.fps.weapons
	_aim(w, feet + Vector3(0, Config.EYE, 0), feet + Vector3(6, Config.EYE, 0))
	var saved := {}
	var here := grid.world_to_cell(feet.x, feet.z)
	for c in grid.cells_in_radius(here.x, here.y, Config.SPRAYER.range / Config.CELL):
		saved[c] = g.surface.creeper.depth_at(c.x, c.y)
		g.surface.creeper.set_depth(c.x, c.y, 8.0)
	w.tank = Config.TANK_MAX
	for i in 8:
		w._spray(0.05, g.surface, feet)
	var spray := _pool(g, saved)
	for c in saved:
		g.surface.creeper.set_depth(c.x, c.y, 8.0)
	g.stockpile.salvage = 50.0
	for i in 8:
		w.advanced._plasma_cone(0.05, g.surface, feet)
	var plasma := _pool(g, saved)
	for c in saved:
		g.surface.creeper.set_depth(c.x, c.y, saved[c])
	SmokeTest._check("armoury: plasma clears faster than the sprayer", plasma > spray + 0.5, "spray %.2f plasma %.2f" % [spray, plasma])


static func _demo(g) -> void:
	OperativeUpgrades.grant("unlock_demo")
	var core: Dictionary = g.cave_hazards.core
	var calls := [0]
	var old: Callable = core.target.on_hit
	core.target.on_hit = func(_d, _p): calls[0] += 1
	var near := _target(g.cave, core.pos + Vector3(3, 1, 0))
	var far := _target(g.cave, core.pos + Vector3(20, 1, 0))
	g.fps.weapons.advanced.demo.plant(g.cave, core.pos + Vector3(0, 1, 0))
	for i in 50:
		g.fps.weapons.advanced.demo.update(0.05)
	SmokeTest._check("armoury: demo hurts a target, not the Deep Core", calls[0] == 0 and is_equal_approx(near.dmg, 120.0) and far.dmg == 0.0,
		"core calls %d near %.0f far %.0f" % [calls[0], near.dmg, far.dmg])
	core.target.on_hit = old
	_free_target(g.cave, near)
	_free_target(g.cave, far)
	_throw_range(g)
	g.stockpile.salvage = 0.0
	var before: int = g.fps.weapons.advanced.demo.charges.size()
	g.fps.weapons.advanced._moaned = false
	g.fps.weapons.advanced._throw(g.surface)
	SmokeTest._check("armoury: demo dry does not throw", g.fps.weapons.advanced.demo.charges.size() == before and "Salvage" in g.fps.weapons.advanced.need)
	g.stockpile.salvage = 8.0
	g.fps.weapons.advanced._moaned = false
	g.fps.weapons.advanced._throw(g.surface)
	SmokeTest._check("armoury: demo spends 8 salvage", g.stockpile.salvage <= 0.001 and g.fps.weapons.advanced.demo.charges.size() == before + 1)
	g.fps.weapons.advanced.demo.clear()


static func _throw_range(g) -> void:
	var run := _run(g.surface.grid, 14)
	if run.x < 0:
		SmokeTest._check("armoury: demo flat ground", false)
		return
	var ground: Vector3 = g.surface.grid.cell_ground(run.x, run.y)
	var from: Vector3 = ground + Vector3(0, 1.6, 0)
	g.fps.weapons.advanced.demo.launch(g.surface, from, Vector3(1, 0, 0))
	var t := 0.0
	while t < 3.0 and not g.fps.weapons.advanced.demo.charges.is_empty() and not g.fps.weapons.advanced.demo.charges[0].stuck:
		g.fps.weapons.advanced.demo.update(1.0 / 60.0)
		t += 1.0 / 60.0
	var dist := 0.0
	if not g.fps.weapons.advanced.demo.charges.is_empty():
		var p: Vector3 = g.fps.weapons.advanced.demo.charges[0].pos
		dist = Vector2(p.x - from.x, p.z - from.z).length()
	g.fps.weapons.advanced.demo.clear()
	SmokeTest._check("armoury: demo throw is about 20 m", dist > 16.0 and dist < 24.0, "%.1f m" % dist)


static func _death(g) -> void:
	_respawn(g)
	OperativeUpgrades.reset()
	g.stockpile.salvage = 100.0
	OperativeUpgrades.buy("firepower", g.stockpile)
	var n: Structure = g.structures.command_node()
	g.economy.energy = 8000.0
	g.stockpile.salvage = 8000.0
	g.fps.enter(g.surface, Vector2i(n.x + 2, n.z), 0.0)
	g.fps.since_hurt = 0.0
	g.fps.shield = 0.0
	g.fps.suit = 5.0
	g.fps.damage(50.0)
	g.fps.update(0.05, g.input)
	SmokeTest._check("armoury: upgrade kept at death", g.deploy.down and OperativeUpgrades.level("firepower") == 1)
	_respawn(g)
	SmokeTest._check("armoury: upgrade kept after respawn", not g.deploy.down and OperativeUpgrades.level("firepower") == 1)
	g.flow.to_command("")


static func _respawn(g) -> void:
	g.economy.energy = maxf(g.economy.energy, 8000.0)
	g.stockpile.salvage = maxf(g.stockpile.salvage, 8000.0)
	var t := 0.0
	while g.deploy.down and t < Config.RESPAWN_TIME + 2.0:
		g.deploy.update(0.05)
		t += 0.05


static func _pool(g, saved: Dictionary) -> float:
	var left := 0.0
	for c in saved:
		left += g.surface.creeper.depth_at(c.x, c.y)
	return float(saved.size()) * 8.0 - left


static func _ledge(g, grid: Grid) -> Vector2i:
	return _span(g, grid, 2)


static func _run(grid: Grid, n: int) -> Vector2i:
	for z in range(4, grid.h - 4):
		for x in range(4, grid.w - n - 4):
			var h := grid.height_at(x, z)
			if h > 6.0:
				continue
			var ok := true
			for i in n:
				if grid.height_at(x + i, z) != h or grid.material[grid.idx(x + i, z)] == Grid.Mat.SPIRE:
					ok = false
					break
			if ok:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _span(g, grid: Grid, n: int) -> Vector2i:
	var sm: StructureManager = g.structures
	for z in range(4, grid.h - 4):
		for x in range(4, grid.w - n - 4):
			var h := grid.height_at(x, z)
			if h > 6.0:
				continue
			var ok := true
			for i in n:
				var c := Vector2i(x + i, z)
				if grid.height_at(c.x, c.y) != h or grid.zone_at(c.x, c.y) != Grid.Zone.NONE:
					ok = false
				if grid.material[grid.idx(c.x, c.y)] == Grid.Mat.SPIRE or sm.structure_at(c.x, c.y):
					ok = false
			if ok:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _aim(w: OperativeWeapons, from: Vector3, at: Vector3) -> void:
	w.camera.global_position = from
	w.camera.look_at(at, Vector3.UP)


static func _target(world: World, pos: Vector3) -> Dictionary:
	var node := Node3D.new()
	node.position = pos
	world.add_child(node)
	var hit := { "dmg": 0.0, "pos": pos, "node": node }
	hit["target"] = { "node": node, "oy": 0.0, "radius": 1.0, "alive": func(): return true,
		"on_hit": func(d, _p): hit.dmg += d }
	world.add_target(hit.target)
	return hit


static func _free_target(world: World, hit: Dictionary) -> void:
	world.remove_target(hit.target)
	(hit.node as Node3D).queue_free()
