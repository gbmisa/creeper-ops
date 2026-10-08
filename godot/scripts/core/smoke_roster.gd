class_name SmokeRoster
## Stage 8 roster, hive and mortar checks. Each phase adds a block. Called from SmokeTest.run.


static func run(g) -> void:
	_pressure(g)
	_spawn_curve(g)
	_overrun(g)


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
	SmokeTest._check("pressure holds brute time", absf(Pressure.value(level, 480.0) - 0.20) < 0.021)
	SmokeTest._check("pressure holds ravager time", absf(Pressure.value(level, 900.0) - 0.60) < 0.021)
	SmokeTest._check("pressure holds behemoth time", absf(Pressure.value(level, 1320.0) - 0.85) < 0.021)


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
