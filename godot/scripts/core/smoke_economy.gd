class_name SmokeEconomy
static func run(g) -> void:
	_defs()
	_veins(g.level.grid, g.level.ores, "L1")
	var built: Dictionary = Level02.build()
	_veins(built.grid, built.ores, "L2")
	_outpost(g)
	_reject(g)
	_returns(g)
	_cut(g)
	_cap(g)
	_walls(g)
static func _defs() -> void:
	var miner: Dictionary = StructureDefs.DEFS.miner
	SmokeTest._check("miner def", miner.cost == 15 and not miner.get("weapon", false) and not miner.get("relays", false)
		and not miner.get("movable", false) and StructureDefs.MENU.Structures.has("miner"))
	SmokeTest._check("repair is on the castle tab", StructureDefs.ACTIONS.has("@repair")
		and StructureDefs.MENU.Castle.has("@repair"))
static func _veins(grid: Grid, ores: Array, tag: String) -> void:
	SmokeTest._check("%s has ore veins" % tag, ores.size() >= 3, "(%d)" % ores.size())
	for row in ores:
		var x := int(row.x)
		var z := int(row.z)
		var why := _ground(grid, x, z)
		SmokeTest._check("%s ore %d,%d is open ground" % [tag, x, z], why == "", why)
static func _ground(grid: Grid, x: int, z: int) -> String:
	if not grid.in_bounds(x, z):
		return "out of bounds"
	var i := grid.idx(x, z)
	if grid.zone[i] == Grid.Zone.BLIGHT:
		return "blight"
	if grid.blocked[i] != 0:
		return "blocked"
	var mat: int = grid.material[i]
	if mat == Grid.Mat.STONE or mat == Grid.Mat.SPIRE or mat == Grid.Mat.PLATED:
		return "stone"
	return ""
static func _outpost(g) -> void:
	var sm: StructureManager = g.structures
	var cell := _outpost_cell(g, sm)
	if cell.x < 0:
		SmokeTest._check("outpost test cell free", false)
		return
	g.stockpile.ore = 0.0
	var denied: Dictionary = Placement.can_place(sm, "outpost", cell.x, cell.y)
	SmokeTest._check("outpost needs ore", not denied.ok and "Ore" in str(denied.reason), denied.reason)
	g.stockpile.ore = Config.OUTPOST_ORE
	var ok: Dictionary = Placement.can_place(sm, "outpost", cell.x, cell.y)
	SmokeTest._check("outpost places with ore", ok.ok, ok.reason)
	var paid: Structure = sm.place("outpost", cell.x, cell.y, false)
	SmokeTest._check("outpost spends its ore up front", paid != null and not paid.is_built()
		and is_equal_approx(g.stockpile.ore, 0.0))
	if paid:
		sm.remove(paid)
	g.stockpile.ore = 7.0
	var free: Structure = sm.place("outpost", cell.x, cell.y, true)
	SmokeTest._check("instant outpost does not spend ore", free != null and is_equal_approx(g.stockpile.ore, 7.0))
	if free:
		sm.remove(free)
static func _outpost_cell(g, sm: StructureManager) -> Vector2i:
	var n: Structure = sm.command_node()
	for dist in range(3, 11):
		for zoff in range(dist - 10, 11 - dist):
			for xsgn in [-1, 1]:
				var c := Vector2i(n.x + xsgn * dist, n.z + zoff)
				if _pad_outpost(g, sm, c): return c
	return Vector2i(-1, -1)
static func _pad_outpost(g, sm: StructureManager, cell: Vector2i) -> bool:
	var cells := Placement.footprint_cells("outpost", cell.x, cell.y)
	var h: float = g.surface.grid.height_at(cell.x, cell.y)
	var edits: Array = []
	for c in cells:
		if _ground(g.level.grid, c.x, c.y) != "" or sm.structure_at(c.x, c.y) != null: return false
		_dry(g, c)
		edits.append({ "x": c.x, "z": c.y, "height": h })
	TerrainEdit.apply(g.surface, edits)
	return Placement.ground_reason(sm, "outpost", cell.x, cell.y) == ""
static func _reject(g) -> void:
	var sm: StructureManager = g.structures
	var cell := _open(g, 4, 1)
	if cell.x < 0:
		SmokeTest._check("miner reject cell free", false)
		return
	_dry(g, cell)
	var denied: Dictionary = Placement.can_place(sm, "miner", cell.x, cell.y)
	SmokeTest._check("miner must sit on ore", not denied.ok and "ore" in str(denied.reason).to_lower(), denied.reason)
	SmokeTest._check("place() refuses a miner off a vein", sm.place("miner", cell.x, cell.y, true) == null)
static func _returns(g) -> void:
	var sm: StructureManager = g.structures
	var cell := _open(g, 4, 0)
	if cell.x < 0:
		SmokeTest._check("return-packet cell free", false)
		return
	var vein: Dictionary = g.structures.deposits.add(cell.x, cell.y, 1.0)
	_dry(g, cell)
	var miner := sm.place("miner", cell.x, cell.y, true)
	if miner == null:
		SmokeTest._check("miner placed on the vein", false)
		return
	sm.network.rebuild(sm.list)
	var route := sm.network.route(miner)
	SmokeTest._check("miner routes to the node", route.size() >= 2 and _starts(route, sm.command_node()), "hops %d" % route.size())
	var salv0: float = g.stockpile.salvage
	SmokeTest._check("salvage return packet launches", sm.packets.launch_return(miner, "salvage", 2.0))
	_step(g, [cell], 1.5)
	SmokeTest._check("salvage return packet arrives", is_equal_approx(g.stockpile.salvage, salv0 + 2.0),
		"(%.2f -> %.2f)" % [salv0, g.stockpile.salvage])
	miner.ore_acc = Config.MINER_INTERVAL
	var ore0: float = g.stockpile.ore
	_step(g, [cell], 0.05)
	SmokeTest._check("miner shipped its last ore", not miner.dead and float(vein.left) == 0.0
		and sm.packets.flying.any(func(p): return p.get("returns", false)))
	sm.remove(miner)
	_step(g, [cell], 1.5)
	SmokeTest._check("ore still arrives after the miner dies", is_equal_approx(g.stockpile.ore, ore0 + 1.0),
		"(%.2f -> %.2f)" % [ore0, g.stockpile.ore])
static func _cut(g) -> void:
	var sm: StructureManager = g.structures
	var pair := _pair(g)
	if pair.is_empty():
		SmokeTest._check("relay chain cells free", false)
		return
	var relay_c: Vector2i = pair.relay
	var miner_c: Vector2i = pair.miner
	var vein: Dictionary = g.structures.deposits.add(miner_c.x, miner_c.y, 40.0)
	_dry(g, relay_c)
	_dry(g, miner_c)
	var relay := sm.place("relay", relay_c.x, relay_c.y, true)
	var miner := sm.place("miner", miner_c.x, miner_c.y, true)
	if relay == null or miner == null:
		SmokeTest._check("relay chain placed", false)
		return
	sm.network.rebuild(sm.list)
	var route := sm.network.route(miner)
	SmokeTest._check("far miner routes through the relay", route.size() >= 3 and _starts(route, sm.command_node())
		and not _starts(route, miner), "hops %d" % route.size())
	vein.left = 1.0
	miner.ore_acc = Config.MINER_INTERVAL
	var ore0: float = g.stockpile.ore
	_step(g, [relay_c, miner_c], 0.05)
	_step(g, [relay_c, miner_c], 4.0)
	SmokeTest._check("connected miner delivers ore", not miner.dead and is_equal_approx(g.stockpile.ore, ore0 + 1.0)
		and not sm.packets.flying.any(func(p): return p.get("returns", false)), "(ore %.2f)" % g.stockpile.ore)
	vein.left = 40.0
	miner.ore_acc = 0.0
	miner.ore_hold = 0.0
	sm.remove(relay)
	_step(g, [miner_c], 0.05)
	sm.network.rebuild(sm.list)
	var ore1: float = g.stockpile.ore
	var left1: float = float(vein.left)
	SmokeTest._check("cutting the relay drops the route", sm.network.route(miner).is_empty())
	_step(g, [miner_c], 8.0)
	var gained := left1 - float(vein.left)
	SmokeTest._check("cut relays stop ore income", not miner.dead and is_equal_approx(g.stockpile.ore, ore1)
		and miner.ore_hold >= 1.0 and miner.ore_hold <= Config.MINER_BUFFER and is_equal_approx(gained, miner.ore_hold),
		"(hold %.0f ore %.2f)" % [miner.ore_hold, g.stockpile.ore])
	var shipped: float = miner.ore_hold
	_dry(g, relay_c)
	relay = sm.place("relay", relay_c.x, relay_c.y, true)
	_step(g, [relay_c, miner_c], 0.05)
	SmokeTest._check("reconnecting flushes the buffer", miner.ore_hold == 0.0
		and sm.packets.flying.filter(func(p): return p.get("returns", false)).size() == int(shipped))
	_step(g, [relay_c, miner_c], 4.0)
	SmokeTest._check("buffered ore arrives", is_equal_approx(g.stockpile.ore, ore1 + shipped),
		"(%.2f, shipped %.0f)" % [g.stockpile.ore, shipped])
	sm.remove(miner)
	if relay:
		sm.remove(relay)
static func _cap(g) -> void:
	var sm: StructureManager = g.structures
	var cell := _open(g, 30, 0)
	if cell.x < 0:
		SmokeTest._check("buffer-cap cell free", false)
		return
	var vein: Dictionary = g.structures.deposits.add(cell.x, cell.y, 30.0)
	var miner := sm.place("miner", cell.x, cell.y, true)
	if miner == null:
		SmokeTest._check("buffer-cap miner placed", false)
		return
	sm.network.rebuild(sm.list)
	SmokeTest._check("buffer-cap miner is off the network", sm.network.route(miner).is_empty())
	for _i in 12:
		Miner.update(sm, miner, Config.MINER_INTERVAL)
	SmokeTest._check("disconnected miner stores 10 then stops", is_equal_approx(miner.ore_hold, Config.MINER_BUFFER)
		and is_equal_approx(float(vein.left), 20.0), "(hold %.0f left %.0f)" % [miner.ore_hold, vein.left])
	sm.remove(miner)
static func _walls(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = {}
	for it in castles.list:
		if str(it.id) == "ashmoat":
			c = it
	var lay: Dictionary = castles.lays[c.id]
	var cell: Vector2i = lay.segments[0].cells[0]
	var grid: Grid = g.surface.grid
	SmokeTest._check("hostile walls cannot be repaired", not WallRepair.check(castles, cell).ok)
	StrongholdRules.to_held(g.surface, c, lay)
	var h0 := grid.height_at(cell.x, cell.y)
	c.walls[0].hp = Config.CASTLE_WALL_HP - 50.0
	g.stockpile.salvage = 0.0
	SmokeTest._check("repair refuses an empty stockpile", not WallRepair.apply(castles, cell).ok)
	g.stockpile.salvage = 50.0 / Config.WALL_REPAIR_HP
	var partial: Dictionary = WallRepair.apply(castles, cell)
	SmokeTest._check("partial repair spends salvage and restores hp", partial.ok
		and is_equal_approx(c.walls[0].hp, Config.CASTLE_WALL_HP) and is_equal_approx(g.stockpile.salvage, 0.0)
		and is_equal_approx(grid.height_at(cell.x, cell.y), h0))
	StrongholdRules.damage(g.surface, c, lay, "walls", 0, 9999.0)
	SmokeTest._check("breach drops the wall", is_equal_approx(grid.height_at(cell.x, cell.y), float(lay.yard))
		and c.walls[0].hp <= 0.0)
	g.stockpile.salvage = Config.CASTLE_WALL_HP / Config.WALL_REPAIR_HP
	var full: Dictionary = WallRepair.apply(castles, cell)
	SmokeTest._check("repair rebuilds a breach", full.ok and is_equal_approx(c.walls[0].hp, Config.CASTLE_WALL_HP)
		and is_equal_approx(grid.height_at(cell.x, cell.y), float(lay.wall_top))
		and grid.material[grid.idx(cell.x, cell.y)] == Grid.Mat.STONE
		and is_equal_approx(g.stockpile.salvage, 0.0))
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	StrongholdMeshes.refresh(castles.views[c.id], c)
static func _starts(route: PackedVector3Array, s: Structure) -> bool:
	return not route.is_empty() and route[0].distance_to(s.link_point()) < 0.01
static func _open(g, dx: int, dz: int) -> Vector2i:
	var n: Structure = g.structures.command_node()
	for zoff in [0, 1, -1, 2, -2, 3, -3]:
		var c := Vector2i(n.x + dx, n.z + dz + zoff)
		if _ground(g.level.grid, c.x, c.y) == "" and g.structures.structure_at(c.x, c.y) == null:
			return c
	return Vector2i(-1, -1)
static func _pair(g) -> Dictionary:
	var n: Structure = g.structures.command_node()
	for zoff in [0, 1, -1, 2, -2, 3, -3]:
		var relay := Vector2i(n.x + 8, n.z + zoff)
		var miner := Vector2i(n.x + 20, n.z + zoff)
		if _ground(g.level.grid, relay.x, relay.y) == "" and _ground(g.level.grid, miner.x, miner.y) == "" \
				and g.structures.structure_at(relay.x, relay.y) == null \
				and g.structures.structure_at(miner.x, miner.y) == null:
			return { "relay": relay, "miner": miner }
	return {}
static func _dry(g, c: Vector2i) -> void:
	if g.level.grid.in_bounds(c.x, c.y):
		g.surface.creeper.set_depth(c.x, c.y, 0.0)
static func _step(g, cells: Array, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		g.surface.update(0.05)
		for c in cells:
			_dry(g, c)
		g.structures.update(0.05, g.time)
		g.stockpile.tick(0.05)
		g.time += 0.05
		t += 0.05
