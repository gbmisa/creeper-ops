class_name SmokeNetwork
## Network routing: planned (unfinished) relays relay packets immediately (relaying
## only, never senders), rebuild re-runs when construction finishes, cutting a relay
## darkens everything downstream of it, and packets take the shortest path.


static func _chain_types(sm: StructureManager, s: Structure) -> Array:
	var out: Array = []
	var net: Network = sm.network
	var n: Structure = s
	while n != null:
		out.push_front("%s%s" % [n.type, "" if n.is_built() else "(planned)"])
		n = net._prev.get(n)
	return out


static func _prev_is(sm: StructureManager, s: Structure, want: Structure) -> bool:
	return sm.network._prev.get(s) == want


static func run(g) -> void:
	var sm: StructureManager = g.structures
	g.economy.energy = 500.0
	var node := sm.command_node()
	var nx := node.x
	var nz := node.z

	# (a) A planned relay routes immediately: node -> relay(planned) -> reactor.
	var relay := sm.place("relay", nx + 9, nz, false)
	var reactor := sm.place("reactor", nx + 17, nz, true)
	SmokeTest._sim(g, 0.5)
	SmokeTest._check("planned relay placed", relay != null and reactor != null)
	var chain := _chain_types(sm, reactor) if reactor != null else []
	SmokeTest._check("route goes through the planned relay",
		chain == ["node", "relay(planned)", "reactor"], str(chain))
	SmokeTest._check("planned relay is connected", relay != null and relay.connected)
	SmokeTest._check("planned relay is not a sender",
		relay == null or not Network._sender(relay))

	# (b) Finishing construction keeps the short route; no extra placement/destruction.
	if relay != null:
		relay.delivered = relay.def.cost
		SmokeTest._sim(g, 1.0)
		SmokeTest._check("relay finished building", relay.is_built())
		var chain2 := _chain_types(sm, reactor)
		SmokeTest._check("route still via the relay after completion",
			chain2 == ["node", "relay", "reactor"], str(chain2))

	# (c) Cutting the relay darkens everything downstream of it.
	if relay != null and reactor != null:
		sm.remove(relay, "cut")
		SmokeTest._sim(g, 0.5)
		SmokeTest._check("reactor dark after its relay is cut", not reactor.connected)
		sm.remove(reactor, "cleanup")

	# (d) Packets take the shortest path when several routes exist.
	var s1 := sm.place("relay", nx + 9, nz, true)
	var l1 := sm.place("relay", nx + 4, nz - 9, true)
	var l2 := sm.place("relay", nx + 12, nz - 7, true)
	var r2 := sm.place("reactor", nx + 17, nz, true)
	SmokeTest._sim(g, 0.5)
	var short_ok := s1 != null and l1 != null and l2 != null and r2 != null
	SmokeTest._check("short-path fixtures placed", short_ok)
	if short_ok:
		# Short: node->s1->r2 = 17 cells. Long: node->l1->l2->r2 ~= 26.6 cells.
		SmokeTest._check("reactor routes via the shorter path", _prev_is(sm, r2, s1),
			str(_chain_types(sm, r2)))
		SmokeTest._check("short route is actually shorter",
			sm.network.route_length(r2) < 20.0 * Config.CELL,
			"len=%.1f" % sm.network.route_length(r2))
	for s in [s1, l1, l2, r2]:
		if s != null:
			sm.remove(s, "cleanup")
	SmokeTest._sim(g, 0.5)
