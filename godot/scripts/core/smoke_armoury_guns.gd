class_name SmokeArmouryGuns
## Railgun, plasma, demolition charge, and upgrades kept across death.


static func _rail(g) -> void:
	OperativeUpgrades.reset()
	OperativeUpgrades.grant("unlock_railgun")
	var w: OperativeWeapons = g.fps.weapons
	var a := SmokeArmoury._target(g.surface, Vector3(80, 80, 74))
	var b := SmokeArmoury._target(g.surface, Vector3(80, 80, 66))
	var side := SmokeArmoury._target(g.surface, Vector3(92, 80, 70))
	SmokeArmoury._aim(w, Vector3(80, 80, 86), b.pos)
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
	SmokeArmoury._free_target(g.surface, a)
	SmokeArmoury._free_target(g.surface, b)
	SmokeArmoury._free_target(g.surface, side)


static func _plasma(g) -> void:
	OperativeUpgrades.grant("unlock_plasma")
	var grid: Grid = g.surface.grid
	var spot := SmokeArmoury._ledge(g, grid)
	if spot.x < 0:
		SmokeTest._check("armoury: plasma spot", false)
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
	for i in 8:
		w._spray(0.05, g.surface, feet)
	# The sprayer lays anti-creeper; it annihilates on the sim tick (none ran above).
	g.surface.creeper._annihilate()
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
	var core: Dictionary = g.cave_hazards.core
	var calls := [0]
	var old: Callable = core.target.on_hit
	core.target.on_hit = func(_d, _p): calls[0] += 1
	var near := SmokeArmoury._target(g.cave, core.pos + Vector3(3, 1, 0))
	var far := SmokeArmoury._target(g.cave, core.pos + Vector3(20, 1, 0))
	DemoCharge.plant(g.cave, core.pos + Vector3(0, 1, 0))
	for i in 100:
		DemoCharge.tick(g.cave, 0.05)
	SmokeTest._check("armoury: demo hurts a target, not the Deep Core", calls[0] == 0 and is_equal_approx(near.dmg, Config.DEMO_DAMAGE) and far.dmg == 0.0,
		"core calls %d near %.0f far %.0f" % [calls[0], near.dmg, far.dmg])
	core.target.on_hit = old
	SmokeArmoury._free_target(g.cave, near)
	SmokeArmoury._free_target(g.cave, far)
	DemoCharge.clear()
	_buy_charges(g)


static func _buy_charges(g) -> void:
	OperativeUpgrades.reset()
	g.stockpile.salvage = Config.DEMO_CHARGE_COST - 1.0
	var why := OperativeUpgrades.buy_charge(g.stockpile)
	SmokeTest._check("armoury: charge refused when Salvage is short", why != "" and OperativeUpgrades.charges == 0
		and is_equal_approx(g.stockpile.salvage, Config.DEMO_CHARGE_COST - 1.0))
	g.stockpile.salvage = Config.DEMO_CHARGE_COST * (Config.DEMO_CHARGE_MAX + 1)
	var start: float = g.stockpile.salvage
	SmokeTest._check("armoury: buying a charge spends Salvage and adds one",
		OperativeUpgrades.buy_charge(g.stockpile) == "" and OperativeUpgrades.charges == 1
		and is_equal_approx(g.stockpile.salvage, start - Config.DEMO_CHARGE_COST))
	for i in Config.DEMO_CHARGE_MAX:
		OperativeUpgrades.buy_charge(g.stockpile)
	SmokeTest._check("armoury: charge cap enforced and nothing spent past it", OperativeUpgrades.charges == Config.DEMO_CHARGE_MAX
		and is_equal_approx(g.stockpile.salvage, start - Config.DEMO_CHARGE_COST * Config.DEMO_CHARGE_MAX))
	OperativeUpgrades.reset()


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


