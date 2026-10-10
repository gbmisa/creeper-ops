class_name SmokeRoster
## Stage 8 roster, hive and mortar checks. Each phase adds a block. Called from SmokeTest.run.


static func run(g) -> void:
	_pressure(g)
	_spawn_curve(g)
	_overrun(g)
	_roster(g)
	SmokeRosterFight.run(g)


static func _pressure(g) -> void:
	var level: Dictionary = g.level
	var grace: float = level.pressure.grace
	var cap: float = level.pressure.cap
	SmokeTest._check("pressure 0 before grace", Pressure.value(level, 0.0) == 0.0
		and Pressure.value(level, grace - 1.0) == 0.0)
	SmokeTest._check("pressure 1 at cap", is_equal_approx(Pressure.value(level, cap), 1.0)
		and is_equal_approx(Pressure.value(level, cap + 80.0), 1.0))
	var prev := -0.01
	var mono := true
	for t in [grace, 480.0, 700.0, 900.0, 1320.0, cap]:
		var p := Pressure.value(level, float(t))
		if p < prev - 0.0001:
			mono = false
		prev = p
	SmokeTest._check("pressure monotonic", mono, "(last %.2f)" % prev)
	SmokeTest._check("pressure holds brute time", absf(Pressure.value(level, 660.0) - 0.20) < 0.021)
	SmokeTest._check("pressure holds ravager time", absf(Pressure.value(level, 1500.0) - 0.60) < 0.021)
	SmokeTest._check("pressure holds behemoth time", absf(Pressure.value(level, 2340.0) - 0.85) < 0.021)


static func _spawn_curve(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var saved: float = nests.time
	nests.time = 0.0
	SmokeTest._check("spawn interval at pressure 0", is_equal_approx(nests.spawn_interval(), Config.NEST_SPAWN_START))
	SmokeTest._check("spawn cap at pressure 0", nests.capacity() == Config.NEST_CAP_START)
	nests.time = float(g.level.pressure.cap)
	SmokeTest._check("spawn interval at pressure 1", is_equal_approx(nests.spawn_interval(), Config.NEST_SPAWN_MIN))
	SmokeTest._check("spawn cap at pressure 1", nests.capacity() == Config.NEST_CAP_MAX)
	nests.time = saved


static func _overrun(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var saved_time: float = nests.time
	var saved_ot: float = nests.overrun_t
	var saved_tier: int = nests.tier
	var saved_raiding: bool = nests.raiding
	var timers: Array = []
	var hps: Array = []
	var originals: Array = nests.raiders.list.duplicate()
	var flags: Array = []
	for n in nests.nests:
		timers.append(n.timer)
		hps.append(n.hp)
		n.timer = 0.0
	for r in originals:
		flags.append(r.guard)
	nests.time = float(g.level.pressure.cap) - 0.1
	nests.overrun_t = Config.OVERRUN_INTERVAL - 0.05
	nests.update(0.1)
	var spawned := 0
	for r in nests.raiders.list:
		if r.get("overrun", false):
			spawned += 1
	var want := Config.OVERRUN_BASE + Config.OVERRUN_PER_TIER * Pressure.legacy_tier(1.0)
	var alive: int = nests.nests.filter(func(n): return n.alive).size()
	SmokeTest._check("overrun fires", spawned == alive * want, "(%d raiders, %d nests, wave %d)" % [spawned, alive, want])
	for r in nests.raiders.list.duplicate():
		if r.get("overrun", false):
			nests.raiders.kill(r)
	for i in originals.size():
		if originals[i].alive:
			originals[i].guard = flags[i]
	nests.time = saved_time
	nests.overrun_t = saved_ot
	nests.tier = saved_tier
	nests.raiding = saved_raiding
	for i in nests.nests.size():
		nests.nests[i].timer = timers[i]
		nests.nests[i].hp = hps[i]


static func _same(who: String, hp: float, dps: float, speed: float, size: float, hex: String) -> bool:
	var d := RaiderDefs.named(who)
	return not d.is_empty() and is_equal_approx(float(d.hp), hp) and is_equal_approx(float(d.dps), dps) \
		and is_equal_approx(float(d.speed), speed) and is_equal_approx(float(d.size), size) and d.color == Color(hex)


static func _roster(g) -> void:
	var kept := _same("Skitter", 4.0, 6.0, 4.2, 0.45, "a8ff5a") \
		and _same("Brute", 16.0, 8.0, 3.4, 0.75, "ffd24a") \
		and _same("Ravager", 40.0, 16.0, 4.0, 0.9, "ff7a3a") \
		and _same("Behemoth", 120.0, 35.0, 2.6, 1.4, "ff3355")
	SmokeTest._check("roster keeps the old four", kept)
	SmokeTest._check("roster unlocks skitter only at 0", _names(0.0) == ["Skitter"])
	SmokeTest._check("roster unlocks spitter at 0.10", _has(0.10, "Spitter") and not _has(0.10, "Brute"))
	var spit := RaiderDefs.named("Spitter")
	SmokeTest._check("spitter matches the spec", is_equal_approx(float(spit.hp), 10.0)
		and is_equal_approx(float(spit.range), 14.0) and str(spit.attack) == "acid")
	SmokeTest._check("roster unlocks brute at 0.20", _has(0.20, "Brute") and not _has(0.20, "Lancer"))
	SmokeTest._check("roster holds spotter until 0.70", not _has(0.69, "Spotter") and _has(0.70, "Spotter"))
	SmokeTest._check("roster unlocks behemoth at 0.85", _has(0.85, "Behemoth"))
	SmokeTest._check("roster weight favours the newest", RaiderDefs.pick(0.20, 0.0).name == "Skitter"
		and RaiderDefs.pick(0.20, 0.99).name == "Brute")
	var nests: SporeNests = g.hazards.nests
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	var spawned := true
	for row in RaiderDefs.ROWS:
		var tier: Dictionary = row
		nests.raiders.spawn(nest, tier, true)
		var r: Dictionary = nests.raiders.list.back()
		if not is_equal_approx(float(r.hp), float(tier.hp)) or r.tier.name != tier.name:
			spawned = false
		nests.raiders.kill(r)
	SmokeTest._check("roster every row spawns", spawned, "(%d rows)" % RaiderDefs.ROWS.size())


static func _names(p: float) -> Array:
	var out: Array = []
	for row in RaiderDefs.unlocked(p):
		var d: Dictionary = row
		out.append(d.name)
	return out


static func _has(p: float, who: String) -> bool:
	return who in _names(p)


