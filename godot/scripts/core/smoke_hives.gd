class_name SmokeHives
## Stage 8 hives: stages, pit channels, Core immunity, raze, rebuild, save (§3.3).


static func run(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var grid: Grid = g.level.grid
	nests.time = 0.0 # earlier smokes may have peaked the clock; stage follows pressure again
	for n in nests.nests:
		Hives.sync(nests, n)
	_shape(nests, grid)
	_stages(nests)
	_round(nests, grid)
	_channels(nests)
	_growth(g, nests)
	_core(g, nests, grid)


static func _named(nests: SporeNests, who: String) -> Dictionary:
	for n in nests.nests:
		if str(n.name) == who:
			return n
	return {}


static func _shape(nests: SporeNests, grid: Grid) -> void:
	var hive := _named(nests, "Central knoll")
	var sample := hive.sample as Vector2i
	SmokeTest._check("hive berm is one Earth level", hive.berm > 0 and sample.x >= 0
		and grid.material[grid.idx(sample.x, sample.y)] == Grid.Mat.EARTH
		and is_equal_approx(grid.height_at(sample.x, sample.y), float(hive.floor) + 1.0),
		"(raised %s)" % hive.berm)
	SmokeTest._check("active hive core is Blight", grid.zone_at(int(hive.x), int(hive.z)) == Grid.Zone.BLIGHT)
	SmokeTest._check("stage 0 is core plus one pit", Hives.channels(hive) == 1 and not Hives.find(hive, "core").is_empty())


static func _stages(nests: SporeNests) -> void:
	SmokeTest._check("hive stages follow pressure",
		Hives.stage_for(0.0) == 0 and Hives.stage_for(0.19) == 0 and Hives.stage_for(0.2) == 1
		and Hives.stage_for(0.45) == 2 and Hives.stage_for(0.7) == 3 and Hives.stage_for(0.9) == 4
		and Hives.stage_for(nests.pressure()) == int(nests.nests[0].stage))


static func _count(hive: Dictionary, kind: String) -> int:
	var n := 0
	for part in hive.parts:
		var p: Dictionary = part
		if p.alive and p.grown and str(p.kind) == kind:
			n += 1
	return n


static func _round(nests: SporeNests, grid: Grid) -> void:
	var hive := _named(nests, "Spire Heights")
	var snap := nests.state()
	var core := Hives.find(hive, "core")
	var hp: float = core.hp
	core.hp = 3.0
	hive.stage = 9
	nests.load_state(snap)
	hive = _named(nests, "Spire Heights")
	core = Hives.find(hive, "core")
	SmokeTest._check("hive state round-trips", int(hive.stage) == 0 and is_equal_approx(float(core.hp), hp)
		and grid.zone_at(int(hive.x), int(hive.z)) == Grid.Zone.BLIGHT, "(hp %.1f)" % core.hp)


static func _channels(nests: SporeNests) -> void:
	var fast := _named(nests, "Rift")
	var slow := _named(nests, "Central knoll")
	Hives.unlock_to(nests, fast, 1)
	Hives.age(fast, Config.HIVE_GROW)
	SmokeTest._check("stage 1 adds a pit and a spitter", _count(fast, "pit") == 2 and _count(fast, "spitter") == 1)
	var saved_f: int = int(fast.count)
	var saved_s: int = int(slow.count)
	fast.count = 0
	slow.count = 0
	var half: float = nests.spawn_wait(fast)
	var full: float = nests.spawn_wait(slow)
	SmokeTest._check("two pits spawn twice as fast", half * 2.0 < full + 0.05 and half > 1.0, "(%.2f vs %.2f)" % [half, full])
	fast.timer = half
	slow.timer = half
	var grew: int = nests.try_spawn(fast)
	var held: int = nests.try_spawn(slow)
	SmokeTest._check("the slower pit has not spawned yet", grew == 1 and held == 0, "(%d / %d)" % [grew, held])
	if grew == 1 and not nests.raiders.list.is_empty():
		var last: Dictionary = nests.raiders.list.back()
		if last.nest == fast:
			nests.raiders.kill(last)
	var pit := Hives.find(fast, "pit")
	# find returns the first living pit; kill a stage-1 one so a channel actually closes
	for part in fast.parts:
		var p: Dictionary = part
		if p.alive and str(p.kind) == "pit" and int(p.stage) == 1:
			pit = p
	HiveParts.hurt(nests, fast, pit, 999.0, "unit")
	SmokeTest._check("killing a pit slows spawns", Hives.channels(fast) == 1
		and nests.spawn_wait(fast) > half * 1.5)
	fast.count = saved_f
	slow.count = saved_s


static func _growth(g, nests: SporeNests) -> void:
	var hive := _named(nests, "Spire Heights")
	nests.time = 2040.0
	Hives.unlock_to(nests, hive, 4)
	Hives.age(hive, Config.HIVE_GROW)
	var p := Pressure.value(g.level, nests.time)
	var core := Hives.find(hive, "core")
	var want := (Config.HIVE_CORE_BASE + Config.HIVE_CORE_PER_P * p) * Config.HIVE_STAGE4_HP
	SmokeTest._check("stage 4 grows every part and adds half HP", int(hive.stage) == 4
		and _count(hive, "pit") == 3 and _count(hive, "spitter") == 2 and _count(hive, "launcher") == 1
		and is_equal_approx(float(core.hp), want) and is_equal_approx(float(core.max_hp), want),
		"(hp %.1f want %.1f p %.2f)" % [core.hp, want, p])
	var mortal := false
	for part in hive.parts:
		var q: Dictionary = part
		if str(q.id) == "mortar":
			mortal = true
	SmokeTest._check("mortar body waits for phase 7", not mortal)
	nests.time = 0.0


static func _core(g, nests: SporeNests, grid: Grid) -> void:
	var hive := _named(nests, "Central knoll")
	var core := Hives.find(hive, "core")
	var hp: float = core.hp
	var listed := false
	for r in nests.raiders.list:
		var row: Dictionary = r
		if row.get("node") == core.node:
			listed = true
	HiveParts.hurt(nests, hive, core, 500.0, "cannon")
	SmokeTest._check("core ignores cannons", is_equal_approx(float(core.hp), hp) and not listed)
	HiveParts.hurt(nests, hive, core, 10.0, "operative")
	SmokeTest._check("operative hurts the core", float(core.hp) < hp - 9.0)
	var salvage: float = g.stockpile.salvage
	var got := [false]
	var cb := func(id: String):
		if id == "nests":
			got[0] = true
	Bus.objective_done.connect(cb)
	HiveParts.hurt(nests, hive, core, 9999.0, "lance")
	SmokeTest._check("razing clears Blight and pays salvage", str(hive.state) == "razed" and not hive.alive
		and grid.zone_at(int(hive.x), int(hive.z)) == Grid.Zone.NONE
		and g.stockpile.salvage >= salvage + Config.HIVE_SALVAGE - 0.01)
	var pad: Structure = g.structures.place("outpost", int(hive.x), int(hive.z), true)
	HiveSite.tick(nests, hive, 0.05)
	SmokeTest._check("outpost on the core claims the hive", str(hive.state) == "outpost")
	g.structures.remove(pad)
	HiveSite.tick(nests, hive, 0.05)
	SmokeTest._check("losing the outpost leaves it razed", str(hive.state) == "razed")
	var block: Structure = g.structures.place("collector", int(hive.x) + 3, int(hive.z), true)
	for _i in 3:
		nests.raiders.spawn(hive, RaiderDefs.named("Skitter"), true)
		(nests.raiders.list.back().node as Node3D).position = hive.pos
	for _i in 600:
		HiveSite.tick(nests, hive, 0.05)
	SmokeTest._check("a structure within 4 cells blocks rebuild", str(hive.state) == "razed")
	g.structures.remove(block)
	for _i in 200:
		HiveSite.tick(nests, hive, 0.05)
	SmokeTest._check("rebuild needs the full 30s", str(hive.state) == "razed")
	for _i in 401:
		HiveSite.tick(nests, hive, 0.05)
	SmokeTest._check("three raiders rebuild the hive", str(hive.state) == "active" and int(hive.stage) >= 1
		and grid.zone_at(int(hive.x), int(hive.z)) == Grid.Zone.BLIGHT)
	for r in nests.raiders.list.duplicate():
		var row: Dictionary = r
		if row.nest == hive:
			nests.raiders.kill(row)
	if Bus.objective_done.is_connected(cb):
		Bus.objective_done.disconnect(cb)
	SmokeTest._check("one razed hive does not finish the objective", not got[0])
