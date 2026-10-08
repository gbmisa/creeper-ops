class_name Miner
## A built Miner on an ore vein yields 1 ore per MINER_INTERVAL.
## With a route home, a return packet carries it. Cut off, it holds up to MINER_BUFFER.


static func update(mgr, s: Structure, dt: float) -> void:
	if s.type != "miner" or not s.is_built() or s.is_flying() or s.dead:
		return
	var deposits: Deposits = mgr.deposits
	if deposits == null:
		return
	_ship(mgr, s)
	if dt <= 0.0:
		return
	s.ore_acc += dt
	while s.ore_acc >= Config.MINER_INTERVAL:
		var vein := deposits.ore_at(s.x, s.z)
		if vein.is_empty() or float(vein.left) < 1.0:
			s.ore_acc = 0.0
			return
		var routed: bool = not mgr.network.route(s).is_empty()
		if not routed and s.ore_hold + 1.0 > Config.MINER_BUFFER + 0.001:
			s.ore_acc = Config.MINER_INTERVAL  # retry next frame; the vein is not spent
			return
		s.ore_acc -= Config.MINER_INTERVAL
		vein.left = float(vein.left) - 1.0
		deposits.touch(vein)
		if routed and mgr.packets.launch_return(s, "ore", 1.0):
			continue
		s.ore_hold += 1.0


static func _ship(mgr, s: Structure) -> void:
	if s.ore_hold < 1.0 or mgr.network.route(s).is_empty():
		return
	var n := int(s.ore_hold)
	for _k in n:
		if not mgr.packets.launch_return(s, "ore", 1.0):
			return
		s.ore_hold -= 1.0
