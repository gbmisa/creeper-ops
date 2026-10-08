class_name SmokeRoster
## Stage 8 roster, hive and mortar checks. Each phase adds a block. Called from SmokeTest.run.


static func run(g) -> void:
	_pressure(g)
	_spawn_curve(g)
	_overrun(g)
	_roster(g)
	_ranged(g)


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


static func _same(who: String, hp: float, dps: float, speed: float, size: float, hex: String) -> bool:
	var d := RaiderDefs.named(who)
	return not d.is_empty() and is_equal_approx(float(d.hp), hp) and is_equal_approx(float(d.dps), dps) \
		and is_equal_approx(float(d.speed), speed) and is_equal_approx(float(d.size), size) and d.color == Color(hex)


static func _roster(g) -> void:
	var kept := _same("Skitter", 4.0, 3.0, 4.2, 0.45, "a8ff5a") \
		and _same("Brute", 16.0, 8.0, 3.4, 0.75, "ffd24a") \
		and _same("Ravager", 40.0, 16.0, 4.0, 0.9, "ff7a3a") \
		and _same("Behemoth", 120.0, 35.0, 2.6, 1.4, "ff3355")
	SmokeTest._check("roster keeps the old four", kept)
	SmokeTest._check("roster unlocks skitter only at 0", _names(0.0) == ["Skitter"])
	SmokeTest._check("roster unlocks spitter at 0.10", _has(0.10, "Spitter") and not _has(0.10, "Brute"))
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


static func _ranged(g) -> void:
	_spitter_hits_cannon(g)
	_lancer_picks_sniper(g)
	_shot_can_miss(g)


static func _pad(g, x0: int, z0: int, x1: int, z1: int) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)


static func _clear_shots(g) -> void:
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)


static func _spawn_at(g, who: String, cell: Vector2i) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	nests.raiders.spawn(nests.nests[0], RaiderDefs.named(who), true)
	var r := nests.raiders.list.back() as Dictionary
	r.guard = true
	(r.node as Node3D).position = g.surface.grid.cell_ground(cell.x, cell.y)
	return r


static func _spitter_hits_cannon(g) -> void:
	_pad(g, 4, 70, 28, 74)
	_clear_shots(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 21, 72, true)
	var r := _spawn_at(g, "Spitter", Vector2i(6, 72))
	var hp0: float = cannon.hp
	for _i in 50:  # 2.5 s: the first lob lands, the next has not
		g.hazards.nests.raiders.update(0.05, [cannon.prey], [])
		g.surface.effects.update(0.05)
	SmokeTest._check("spitter in range damages a cannon", cannon.hp < hp0 - 5.0 and cannon.hp > hp0 - 7.0,
		"(hp %.1f of %.1f)" % [cannon.hp, hp0])
	g.hazards.nests.raiders.kill(r)
	sm.remove(cannon)
	_clear_shots(g)


static func _lancer_picks_sniper(g) -> void:
	_pad(g, 2, 60, 36, 64)
	_clear_shots(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 12, 62, true)
	var sniper := sm.place("sniper", 28, 62, true)
	var r := _spawn_at(g, "Lancer", Vector2i(4, 62))
	var prey: Array = [
		{ "node": cannon.node, "radius": 1.0, "type": "cannon", "weapon": true,
			"alive": func(): return not cannon.dead, "hit": func(d): sm.damage(cannon, d) },
		{ "node": sniper.node, "radius": 1.0, "type": "sniper", "weapon": true,
			"alive": func(): return not sniper.dead, "hit": func(d): sm.damage(sniper, d) },
	]
	var ch0: float = cannon.hp
	var sh0: float = sniper.hp
	for _i in 90:  # 4.5 s: one charge and one flight, not a second bolt
		g.hazards.nests.raiders.update(0.05, prey, [])
		g.surface.effects.update(0.05)
	SmokeTest._check("lancer picks a sniper over a nearer cannon", sniper.hp < sh0 - 20.0 and is_equal_approx(cannon.hp, ch0),
		"(sniper %.1f, cannon %.1f)" % [sniper.hp, cannon.hp])
	g.hazards.nests.raiders.kill(r)
	sm.remove(cannon)
	sm.remove(sniper)
	_clear_shots(g)


static func _shot_can_miss(g) -> void:
	_pad(g, 2, 50, 40, 54)
	_clear_shots(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 21, 52, true)
	var r := _spawn_at(g, "Spitter", Vector2i(6, 52))
	var raiders: Raiders = g.hazards.nests.raiders
	var shot: Dictionary = {}
	for _i in 4:
		raiders.update(0.05, [cannon.prey], [])
		if g.surface.effects.lobs().size() > 0:
			shot = g.surface.effects.lobs()[0]
			break
	SmokeTest._check("spitter looses a lob", not shot.is_empty())
	cannon.node.position += Vector3(40, 0, 0)
	var hp0: float = cannon.hp
	for _i in 80:
		if not g.surface.effects.lobs().has(shot):
			break
		g.surface.effects.update(0.05)
	SmokeTest._check("a shot in flight misses a cannon that moved", is_equal_approx(cannon.hp, hp0),
		"(hp %.1f)" % cannon.hp)
	raiders.kill(r)
	sm.remove(cannon)
	_clear_shots(g)
