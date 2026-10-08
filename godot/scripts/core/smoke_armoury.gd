class_name SmokeArmoury
## Stage 10a: Salvage buys stop at the tier cap, multipliers apply, the shield soaks,
## mobility reaches a higher ledge, advanced weapons spend Salvage, and upgrades survive death.


static func run(g) -> void:
	_shop(g)
	_firepower(g)
	_armour(g)
	_mobility(g)
	SmokeArmouryGuns._rail(g)
	SmokeArmouryGuns._plasma(g)
	SmokeArmouryGuns._demo(g)
	SmokeArmouryGuns._death(g)
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


static func _ledge(g, grid: Grid) -> Vector2i:
	return _span(g, grid, 2)


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
