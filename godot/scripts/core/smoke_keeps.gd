class_name SmokeKeeps
## Checks: a flying Command Node keeps its network connected but launches nothing, and a held
## castle gets a Castle Keep packet sender that goes when the castle falls, and raiders only
## target prey they can walk to. Called from SmokeTest.run.


static func run(g) -> void:
	_flying_node(g)
	_castle_keep(g)
	_reach()


static func _flying_node(g) -> void:
	var sm: StructureManager = g.structures
	var n := sm.command_node()
	var col: Structure = sm.place("collector", n.x + 5, n.z + 2, true)
	sm.network.rebuild(sm.list)
	var before: bool = col.connected
	var home := Vector2i(n.x, n.z)
	Mover.start(sm, n, n.x - 3, n.z)
	sm.network.rebuild(sm.list)
	var outposts: bool = sm.list.any(func(s): return s.def.get("sender", false) and s != n)
	SmokeTest._check("flying Node: its network stays connected", before and col.connected and n.connected)
	SmokeTest._check("flying Node: still sends packets while connected", not sm.network.route(col).is_empty())
	while n.is_flying():
		Mover.update(n, 0.1)
	sm.network.rebuild(sm.list)
	SmokeTest._check("flying Node: lands connected", col.connected)
	Mover.start(sm, n, home.x, home.y)  # put it back for later checks
	while n.is_flying():
		Mover.update(n, 0.1)
	sm.dirty = true
	sm.remove(col)


static func _castle_keep(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = castles.list[0]
	var lay: Dictionary = castles.lays[c.id]
	StrongholdRules.to_held(g.surface, c, lay)
	g.keeps.update()
	var k: Structure = g.keeps.keeps.get(c.id)
	SmokeTest._check("held castle gets a Castle Keep packet sender",
		k != null and not k.dead and k.def.get("sender", false) and lay.courtyard.has(Vector2i(k.x, k.z)))
	g.structures.network.rebuild(g.structures.list)
	SmokeTest._check("Castle Keep is a network root", k != null and k.connected)
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	castles.on_lost.call(lay.courtyard)
	g.keeps.update()
	SmokeTest._check("Castle Keep goes when the castle falls", k == null or k.dead)


## A mesa 5 levels up is out of reach (even its rim, too high to strike from the foot) until a
## one-level-a-step stair joins it.
static func _reach() -> void:
	var grid := Grid.new(12, 12)
	for z in range(6, 12):
		for x in range(6, 12):
			grid.set_height(x, z, 5.0)
	var f := RaiderField.new(grid)
	var c := func(x, z): return Vector3((x + 0.5) * Config.CELL, grid.cell_ground(x, z).y, (z + 0.5) * Config.CELL)
	var low: bool = f.reachable(c.call(1, 1), c.call(4, 2))
	var up: bool = f.reachable(c.call(1, 1), c.call(9, 9))
	var edge: bool = f.reachable(c.call(1, 1), c.call(6, 9))  # on the rim, above the cliff foot
	for z in range(2, 6):  # a stair, levels 1..4, up to the mesa's north edge
		for x in range(6, 12):
			grid.set_height(x, z, float(z - 1))
	f.invalidate()
	SmokeTest._check("raiders: prey up a cliff is out of reach, reachable once stairs join it",
		low and not up and not edge and f.reachable(c.call(1, 1), c.call(9, 9)), "(low %s up %s edge %s)" % [low, up, edge])
