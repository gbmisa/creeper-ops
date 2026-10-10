class_name NestOverrun
## The "overrun" waves: at full pressure every nest marches a wave straight at the Command Node.


static func tick(host: SporeNests, dt: float) -> void:
	if host.pressure() < 1.0 or host.alive_count() == 0:
		host.overrun_t = 0.0
		return
	host.overrun_t += dt
	if host.overrun_t < Config.OVERRUN_INTERVAL:
		return
	host.overrun_t = 0.0
	var dest: Vector3 = host.node_pos.call()
	var wave := Config.OVERRUN_BASE + Config.OVERRUN_PER_TIER * Pressure.legacy_tier(host.pressure())
	for n in host.nests:
		if not n.alive:
			continue
		for _i in wave:
			if host.raiders.list.size() >= Config.RAIDER_MAX_TOTAL:
				return
			var tier_pick := host.pick_tier()
			if CastleLancers.is_lancer(tier_pick):
				tier_pick = RaiderDefs.named("Spitter")  # Lancers hold castles, they never march
			host.raiders.spawn(n, tier_pick, false)
			var r: Dictionary = host.raiders.list.back()
			r.guard = false
			r["overrun"] = true
			r["rush"] = dest
	Bus.say("The nests overrun: a wave is marching straight at the Command Node.", "bad")
