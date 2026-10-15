class_name SmokeCastleRate
## PT4 C: a hostile castle's garrison never spawns more HP per second than the rifle budget.
## Drives StrongholdTick.hostile directly at fixed pressure, killing the garrison each step so
## only the timer limits spawns. Reports HP/s with the budget on (and off, for comparison).


## HP spawned over `secs` at pressure `p`; budget_on false clears the wait (the old behaviour).
static func hp_spawned(r: Dictionary, p: float, secs: float, budget_on: bool, names: Array = []) -> float:
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var v: Dictionary = castles.views[c.id]
	var raiders: Raiders = castles.nests.raiders
	castles.nests.time = _time_for(castles.nests, p)
	c.garrison_timer = 0.0
	c.erase("garrison_wait")
	seed(7)
	var total := 0.0
	var n := 0
	var t := 0.0
	while t < secs:
		StrongholdTick.hostile(castles, c, r.lay, v, r.op.pos, 0.1)
		if not budget_on:
			c.erase("garrison_wait")
		while raiders.list.size() > n:
			total += float(raiders.list[n].hp)
			names.append(str(raiders.list[n].tier.name))
			n += 1
		for x in raiders.list.duplicate():
			if x.guard and x.nest == v.garrison:
				raiders.kill(x)
		n = raiders.list.size()
		t += 0.1
	return total


static func _time_for(nests: SporeNests, p: float) -> float:
	var lo := 0.0
	var hi := 100000.0
	for i in 60:
		var mid := (lo + hi) * 0.5
		nests.time = mid
		if nests.pressure() < p:
			lo = mid
		else:
			hi = mid
	return hi


static func run(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var budget := CastleDefs.spawn_budget()
	SmokeTest._check("castle rate: budget is 0.75 x rifle DPS at tier 3 (9.4 HP/s)",
		absf(budget - 0.75 * (1.0 / 0.14) * 1.75) < 0.01, "(%.2f)" % budget)
	var parts: Array = []
	var cap_ok := true
	var largest := 0.0
	for p in [0.0, 0.5, 1.0]:
		var old_names: Array = []
		var before := hp_spawned(r, p, 300.0, false, old_names) / 300.0
		var names: Array = []
		var after_total := hp_spawned(r, p, 300.0, true, names)
		parts.append("p%.1f %.1f -> %.1f HP/s" % [p, before, after_total / 300.0])
		for nm in names:
			largest = maxf(largest, float(RaiderDefs.named(nm).hp))
		cap_ok = cap_ok and after_total <= budget * 300.0 + largest
		if p == 0.0:
			SmokeTest._check("castle rate: pressure 0 cadence unchanged (same spawns as without the budget)",
				absf(after_total - before * 300.0) < 0.01 and names == old_names, "(%d spawns)" % names.size())
	SmokeTest._check("castle rate: 300 s of spawns <= budget x 300 + one largest enemy", cap_ok, "(" + "; ".join(parts) + ")")
	r.w.queue_free()
