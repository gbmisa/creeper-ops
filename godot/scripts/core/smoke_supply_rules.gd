class_name SmokeSupplyRules
## Packets have no priority (round robin), units walk round structures, and units restock at
## the nearest barracks rather than the one that trained them. Called from SmokeTest.run.


static func run(g) -> void:
	var sm: StructureManager = g.structures
	_round_robin(g, sm)
	_solid_towers(g, sm)
	_nearest_barracks(g, sm)
	_nullifier_soaks(g, sm)


static func _round_robin(g, sm: StructureManager) -> void:
	var list: Array = []
	var nd := sm.command_node()
	for i in 3:
		list.append(sm.place("collector", nd.x - 3 + i * 3, nd.z - 3))
	var bank: float = g.economy.energy
	g.economy.energy = 0.0
	SmokeTest._sim(g, 1.0)  # let the network link them, with nothing to send
	for s in list:
		s.req_acc = 0.0
	g.economy.energy = 3.0
	sm.packets.update(1.0, list, true)
	var each := list.map(func(s): return s.in_flight + s.delivered)
	SmokeTest._check("packets: round robin, one each when energy is short", each == [1, 1, 1], "(%s)" % str(each))
	for s in list:
		sm.remove(s)
	g.economy.energy = bank


static func _solid_towers(g, sm: StructureManager) -> void:
	var grid: Grid = g.surface.grid
	var wall: Array = []
	for dz in range(-1, 2):
		wall.append(sm.place("relay", 37, 74 + dz, true))
	var path := Pathfind.find(grid, g.surface.creeper, Vector2i(34, 74), Vector2i(40, 74), UnitDefs.DEFS.soldier, 6000, g.surface.occupied)
	var through := false
	var prev := Vector2(34.5, 74.5) * Config.CELL
	for p in path:
		for k in 10:
			var q: Vector2 = prev.lerp(p, k / 10.0)
			var c := grid.world_to_cell(q.x, q.y)
			through = through or g.surface.occupied.call(c.x, c.y)
		prev = p
	SmokeTest._check("units: paths go round structures", not path.is_empty() and not through,
		"(%d waypoints, walls %s)" % [path.size(), str(wall.map(func(w): return w != null))])
	for s in wall:
		if s:
			sm.remove(s)


static func _nearest_barracks(g, sm: StructureManager) -> void:
	var far: Structure = sm.place("barracks", 34, 72, true)
	var near: Structure = sm.place("barracks", 46, 72, true)
	near.ammo = 20.0
	var u: Unit = g.units.spawn("soldier", 46 * Config.CELL, 69 * Config.CELL)
	u.home = far
	u.ammo = 0.0
	UnitSupply.update(g.units, u, 0.016, [])
	SmokeTest._check("units: restock at the nearest barracks", u.depot == near and u.state == "resupply",
		"(depot %s)" % (u.depot.x if u.depot else -1))
	g.units.kill(u)
	sm.remove(far)
	sm.remove(near)


static func _nullifier_soaks(g, sm: StructureManager) -> void:
	var nd := sm.command_node()
	var n: Structure = sm.place("nullifier", nd.x + 4, nd.z + 4)
	var c: Structure = sm.place("cannon", nd.x - 4, nd.z + 4)
	for s in [n, c]:
		g.surface.creeper.set_depth(s.x, s.z, 0.5)
		StructureUpkeep.creeper_and_repair(sm, s, 0.1)
	SmokeTest._check("creeper: unbuilt Nullifier soaks HP instead of dying", not n.dead and n.hp < n.def.hp)
	SmokeTest._check("creeper: other unbuilt structures still die at once", c.dead)
	for s in [n, c]:
		g.surface.creeper.set_depth(s.x, s.z, 0.0)
		if not s.dead:
			sm.remove(s)
