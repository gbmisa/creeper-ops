class_name SmokeSenders
## Stage 6: a far structure is fed by the nearer Outpost, routes fall back when that
## Outpost dies, packets still launch while the Node flies, and Outposts raise the shared bank.


static func run(g) -> void:
	var outpost: Dictionary = StructureDefs.DEFS.outpost
	SmokeTest._check("outpost is a sender", outpost.sender and outpost.relays and outpost.cost == 40
		and StructureDefs.DEFS.node.sender and not outpost.movable)
	_routes(g)
	_storage(g)
	_node_flying(g)


static func _starts_at(route: PackedVector3Array, s: Structure) -> bool:
	return not route.is_empty() and route[0].distance_to(s.link_point()) < 0.01


static func _dry(g, type: String, x: int, z: int) -> void:
	var grid: Grid = g.level.grid
	for c in Placement.footprint_cells(type, x, z):
		if grid.in_bounds(c.x, c.y):
			g.surface.creeper.set_depth(c.x, c.y, 0.0)


static func _routes(g) -> void:
	var sm: StructureManager = g.structures
	var n := sm.command_node()
	var rx := n.x + 12
	var ox := n.x + 22
	var fx := n.x + 26
	_dry(g, "relay", rx, n.z)
	_dry(g, "outpost", ox, n.z)
	_dry(g, "collector", fx, n.z)
	var relay: Structure = sm.place("relay", rx, n.z, true)
	var outpost: Structure = sm.place("outpost", ox, n.z, true)
	var far: Structure = sm.place("collector", fx, n.z, true)
	sm.network.rebuild(sm.list)
	var via := sm.network.route(far)
	var bridge := sm.network.route(relay)
	SmokeTest._check("far structure routes from the outpost", _starts_at(via, outpost), "(hops %d)" % via.size())
	SmokeTest._check("nearer outpost beats the node", _starts_at(bridge, outpost), "(hops %d)" % bridge.size())
	sm.remove(outpost)
	sm.network.rebuild(sm.list)
	SmokeTest._check("route falls back to the node", _starts_at(sm.network.route(relay), n))
	SmokeTest._check("out of range route is empty", sm.network.route(far).is_empty())
	sm.remove(relay)
	sm.remove(far)


static func _storage(g) -> void:
	var sm: StructureManager = g.structures
	_tick(g, 0.05)
	var before: float = g.economy.max_energy
	var income: float = g.economy.income
	_dry(g, "outpost", 60, 77)
	_dry(g, "outpost", 68, 77)
	var a := sm.place("outpost", 60, 77, true)
	var b := sm.place("outpost", 68, 77, true)
	_tick(g, 0.05)
	SmokeTest._check("two outposts raise the bank",
		is_equal_approx(g.economy.max_energy, before + 2.0 * Config.OUTPOST_STORAGE),
		"(%.0f -> %.0f)" % [before, g.economy.max_energy])
	SmokeTest._check("outposts produce nothing", is_equal_approx(g.economy.income, income),
		"(%.2f -> %.2f)" % [income, g.economy.income])
	sm.remove(a)
	sm.remove(b)
	_tick(g, 0.05)


static func _node_flying(g) -> void:
	var sm: StructureManager = g.structures
	var n := sm.command_node()
	var oz := n.z + 6
	_dry(g, "outpost", n.x - 4, oz)
	_dry(g, "collector", n.x - 4, oz - 2)
	var outpost: Structure = sm.place("outpost", n.x - 4, oz, true)
	var job: Structure = sm.place("collector", n.x - 4, oz - 2)
	var saved := n.pos
	n.flight = { "from": n.pos, "to": n.pos, "cruise": n.pos.y + Config.LIFT_HEIGHT, "t": 0.0, "travel": 30.0 }
	sm.dirty = true
	sm.network.rebuild(sm.list)
	SmokeTest._check("flying node still links the outpost", n.is_flying() and _starts_at(sm.network.route(job), outpost))
	g.economy.energy = 40.0
	var sent0 := job.delivered + job.in_flight
	_tick(g, 1.0)
	var sent1 := job.delivered + job.in_flight
	SmokeTest._check("packets launch while the node flies", n.is_flying() and sent1 > sent0, "(%d -> %d)" % [sent0, sent1])
	n.flight = null
	n.pos = saved
	n.node.position = saved
	sm.dirty = true
	sm.remove(job)
	sm.remove(outpost)
	_tick(g, 0.05)


static func _tick(g, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		g.structures.update(0.05, t)
		t += 0.05
