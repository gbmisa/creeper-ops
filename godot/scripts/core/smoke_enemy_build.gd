class_name SmokeEnemyBuild
## Stage 8c: hub build rate, Weavers, shields, blight, leeches, rubble (§4.5).


static func run(g) -> void:
	var b: EnemyBuilder = g.builder
	b.clear()
	b.hold = true
	_rates()
	_speed(g, b)
	_shield(g, b)
	_blight(g, b)
	_leech(g, b)
	_rubble(g, b)
	_shots(g, b)
	_planner(g, b)
	_q(g, b)
	_mortars(g, b)
	b.clear()
	b.hold = true


## Q: spitter towers stand on the ground, are capped per kind, and only sit on fair sites.
static func _q(g, b: EnemyBuilder) -> void:
	b.clear()
	_q_height(g, b)
	_q_cap(g, b)
	_q_fair(g, b)
	b.clear()


static func _q_height(g, b: EnemyBuilder) -> void:
	var grid: Grid = g.surface.grid
	var cell := _cell(g, 12, 12)
	var s := b.begin(_hub(g), "spitter", cell, false, -1.0)
	var node := s.node as Node3D
	var want := grid.stand_y(float(cell.x + 0.5) * Config.CELL, float(cell.y + 0.5) * Config.CELL, Grid.Faction.ENEMY)
	SmokeTest._check("q: placed structure stands on the ground", absf(node.position.y - want) < 0.2, str(node.position.y - want))
	TerrainEdit.raise(g.surface, [cell], 2.0)
	SmokeTest._check("q: terrain edit re-seats the structure", absf(node.position.y - (want + 2.0 * Config.LEVEL_H)) < 0.2, str(node.position.y - want))
	TerrainEdit.raise(g.surface, [cell], -2.0)
	SmokeTest._check("q: lowering restores it", absf(node.position.y - want) < 0.2, str(node.position.y - want))
	b.clear()


static func _q_cap(g, b: EnemyBuilder) -> void:
	var hub := _hub(g)
	var saved: float = g.hazards.nests.time
	g.hazards.nests.time = 0.0  # pressure 0 -> cap 2
	b.begin(hub, "spitter", _cell(g, 10, 0), false, -1.0)
	b.begin(hub, "spitter", _cell(g, 12, 0), false, -1.0)
	var kinds := EnemyBuildPlan._kinds(b, hub)
	SmokeTest._check("q: cap holds at pressure 0 (no third spitter)", not kinds.has("spitter"), str(kinds))
	SmokeTest._check("q: other kinds still planned", kinds.has("pylon") and kinds.has("lancer"), str(kinds))
	g.hazards.nests.time = 99999.0  # pressure 1 -> cap 4
	b.begin(hub, "spitter", _cell(g, 14, 0), false, -1.0)
	b.begin(hub, "spitter", _cell(g, 16, 0), false, -1.0)
	kinds = EnemyBuildPlan._kinds(b, hub)
	SmokeTest._check("q: cap grows with pressure (4 at max, no fifth)", not kinds.has("spitter"), str(kinds))
	g.hazards.nests.time = saved
	b.clear()


static func _q_fair(g, b: EnemyBuilder) -> void:
	SmokeTest._check("q: fair range matches the sniper's range",
		is_equal_approx(Config.ENEMY_SPITTER_FAIR_RANGE, float(StructureDefs.DEFS["sniper"].range)),
		"%s vs %s" % [str(Config.ENEMY_SPITTER_FAIR_RANGE), str(StructureDefs.DEFS["sniper"].range)])
	var hubs := 0
	var sited := 0
	for raw in g.castles.list:
		var c: Dictionary = raw
		if str(c.owner) != "enemy":
			continue
		hubs += 1
		var cell: Vector2i = EnemyBuildPlan._cell(b, c, "spitter")
		if cell.x < 0:
			continue
		sited += 1
		SmokeTest._check("q: %s spitter site is fair" % str(c.id), EnemyBuildPlan._fair_spitter_site(b, cell), str(cell))
	SmokeTest._check("q: spitters still placeable (a fair site exists)", sited > 0, "%d of %d hubs" % [sited, hubs])
	b.clear()


static func _rates() -> void:
	var base := Config.ENEMY_BUILD_BASE
	SmokeTest._check("build rate is one structure per 3 min", is_equal_approx(EnemyStructures.rate(0.0, 0.0, 0, 0.0), base))
	SmokeTest._check("a full moat doubles the build rate", is_equal_approx(EnemyStructures.rate(Config.PUMP_REF, 0.0, 0, 0.0), base * 2.0))
	SmokeTest._check("depth 4 doubles the build rate", is_equal_approx(EnemyStructures.rate(0.0, 4.0, 0, 0.0), base * 2.0))
	SmokeTest._check("one leech adds a quarter", is_equal_approx(EnemyStructures.rate(0.0, 0.0, 1, 0.0), base * 1.25))
	SmokeTest._check("pressure 1 doubles the build rate", is_equal_approx(EnemyStructures.rate(0.0, 0.0, 0, 1.0), base * 2.0))
	SmokeTest._check("one build until pressure 0.5", EnemyStructures.slots(0.49) == 1 and EnemyStructures.slots(0.5) == 2)


static func _speed(g, b: EnemyBuilder) -> void:
	b.clear()
	var c := _hub(g)
	var home: Vector2i = g.castles.lays[c.id].home
	var creep: CreeperSim = g.surface.creeper
	var was := creep.depth_at(home.x, home.y)
	creep.set_depth(home.x, home.y, 0.0)
	c.pump.intake = 0.0
	c.pump.jam = 0.0
	c.pump.material = 10.0
	var s := b.begin(c, "spitter", home, false, -1.0)
	b.update(1.0)
	var dry := EnemyStructures.rate(0.0, 0.0, 0, g.hazards.nests.pressure())
	SmokeTest._check("weaver on site builds at the dry rate", b.weavers.size() == 1 and is_equal_approx(float(s.progress), dry), str(s.progress))
	SmokeTest._check("a dry build spends no stock", is_equal_approx(float(c.pump.material), 10.0))
	c.pump.intake = Config.PUMP_REF
	c.pump.material = 50.0
	var before := float(s.progress)
	b.update(1.0)
	var full := EnemyStructures.rate(Config.PUMP_REF, 0.0, 0, g.hazards.nests.pressure())
	SmokeTest._check("stocked moat builds at the full rate", is_equal_approx(float(s.progress) - before, full), str(float(s.progress) - before))
	SmokeTest._check("the bonus is paid from pump stock", is_equal_approx(float(c.pump.material), 50.0 - (full - dry) * Config.ENEMY_MAT_PER))
	c.pump.jam = 5.0
	c.pump.material = 40.0
	before = float(s.progress)
	b.update(1.0)
	SmokeTest._check("a jam keeps the dry rate and the stock", is_equal_approx(float(s.progress) - before, dry) and is_equal_approx(float(c.pump.material), 40.0))
	c.pump.jam = 0.0
	c.pump.intake = 0.0
	var lay: Dictionary = g.castles.lays[c.id]
	StrongholdRules.set_owner(g.surface, c, lay, "player")
	before = float(s.progress)
	b.update(1.0)
	SmokeTest._check("capture freezes the site and sends the weavers home", is_equal_approx(float(s.progress), before) and b.weavers.is_empty())
	StrongholdRules.set_owner(g.surface, c, lay, "enemy")
	creep.set_depth(home.x, home.y, was)
	b.clear()


static func _shield(g, b: EnemyBuilder) -> void:
	b.clear()
	var cell := _cell(g, 12, 0)
	var dome := b.begin(_hub(g), "dome", cell, false, -1.0)
	EnemyBuildFight.grew(b, dome)
	var inside := b.shields(cell + Vector2i(8, 0)) and not b.shields(cell + Vector2i(9, 0))
	var ground: Vector3 = g.surface.grid.cell_ground(cell.x, cell.y)
	var away: Vector3 = g.surface.grid.cell_ground(cell.x, cell.y + 20)
	SmokeTest._check("shield covers 8 cells and halves the lance", inside and is_equal_approx(b.lance_scale(ground), 0.5) and is_equal_approx(b.lance_scale(away), 1.0))
	var was_land: bool = g.landing
	var was_down: bool = g.deploy.down
	var energy: float = g.economy.energy
	g.landing = false
	g.deploy.down = false
	g.economy.energy = 400.0
	var blocked: Dictionary = g.deploy.can_drop(cell)
	var open: Dictionary = g.deploy.can_drop(cell + Vector2i(0, 9))
	SmokeTest._check("dome blocks the drop", not blocked.ok and "Shield" in str(blocked.reason), blocked.reason)
	SmokeTest._check("a drop outside the dome is not blocked", "Shield" not in str(open.reason), open.reason)
	g.landing = was_land
	g.deploy.down = was_down
	g.economy.energy = energy
	b.clear()


static func _blight(g, b: EnemyBuilder) -> void:
	b.clear()
	var cell := _cell(g, 8, 8)
	var pylon := b.begin(_hub(g), "pylon", cell, false, -1.0)
	EnemyBuildFight.grew(b, pylon)
	var painted: Array = pylon.painted
	var marked: bool = painted.size() > 0 and g.surface.grid.zone_at(painted[0].x, painted[0].y) == Grid.Zone.BLIGHT
	SmokeTest._check("a pylon paints blight", marked, str(painted.size()))
	if marked:
		var why: Dictionary = Placement.can_place(g.structures, "collector", painted[0].x, painted[0].y)
		SmokeTest._check("blight rejects a building", not why.ok and "Blight" in str(why.reason), why.reason)
	var at := cell + Vector2i(2, 0)
	var col: Structure = g.structures.place("collector", at.x, at.y, true)
	var hp := col.hp
	b.update(1.0)
	SmokeTest._check("blight damages a structure inside", is_equal_approx(col.hp, hp - Config.ENEMY_BLIGHT_DPS), str(hp - col.hp))
	g.structures.remove(col)
	b.clear()


static func _leech(g, b: EnemyBuilder) -> void:
	b.clear()
	var cell := _cell(g, 6, 0)
	var saved: Array = g.level.get("deposits", []).duplicate()
	g.level["deposits"] = [{"kind": "ore", "x": cell.x, "z": cell.y}]
	var leech := b.begin(_hub(g), "leech", cell, false, -1.0)
	EnemyBuildFight.grew(b, leech)
	SmokeTest._check("a grown leech counts", b.leech_count() == 1)
	var miner: Structure = g.structures.place("collector", cell.x, cell.y, true)
	miner.type = "miner"
	SmokeTest._check("a miner denies that leech", b.denied(cell) and b.leech_count() == 0)
	g.structures.remove(miner)
	var pump_at := cell + Vector2i(3, 0)
	var pump := b.begin(_hub(g), "pump", pump_at, false, -1.0)
	EnemyBuildFight.grew(b, pump)
	var creep: CreeperSim = g.surface.creeper
	var was := creep.depth_at(pump_at.x, pump_at.y)
	creep.set_depth(pump_at.x, pump_at.y, 0.0)
	b.update(2.1)
	SmokeTest._check("a fed pump emits 1.0", is_equal_approx(creep.depth_at(pump_at.x, pump_at.y), 1.0))
	b.kill(leech, true)
	b.update(2.1)
	SmokeTest._check("a pump with no leech stays idle", is_equal_approx(creep.depth_at(pump_at.x, pump_at.y), 1.0))
	creep.set_depth(pump_at.x, pump_at.y, was)
	g.level["deposits"] = saved
	b.clear()


static func _rubble(g, b: EnemyBuilder) -> void:
	b.clear()
	var cell := _cell(g, 3, 0)
	var hub := _hub(g)
	var s := b.begin(hub, "spitter", cell, false, -1.0)
	b.kill(s, false)
	SmokeTest._check("destruction queues a half-cost rebuild", b.queue.size() == 1 and is_equal_approx(float(b.queue[0].cost), 0.5))
	var other := b.begin(hub, "lancer", cell + Vector2i(1, 0), false, -1.0)
	var salvage: float = g.stockpile.salvage
	other.channel = Config.MORTAR_SABOTAGE_TIME
	var done := b.apply_channel(other, other.pos, Config.MORTAR_SABOTAGE_TIME)
	SmokeTest._check("sabotage pays salvage and leaves no rubble", done and b.queue.size() == 1 and is_equal_approx(g.stockpile.salvage, salvage + Config.MORTAR_SALVAGE))
	b.clear()


static func _shots(g, b: EnemyBuilder) -> void:
	b.clear()
	var home: Vector2i = g.castles.lays[_hub(g).id].home
	var s := b.begin(_hub(g), "spitter", home, false, -1.0)
	b.update(0.05)
	var weaver := {}
	for raw in b.snipe_foes():
		var foe: Dictionary = raw
		if foe.has("sid"):
			weaver = foe
	SmokeTest._check("a sniper can see the weaver", not weaver.is_empty())
	if weaver.is_empty():
		b.clear()
		return
	weaver.enemy.hit.call(4.0)
	SmokeTest._check("the sniper shot hurts the weaver", is_equal_approx(float(weaver.hp), EnemyStructures.WEAVER_HP - 4.0))
	var hp := float(s.hp)
	var whp := float(weaver.hp)
	b.splash(s.pos, 5.0, 10.0)
	SmokeTest._check("a shell hurts the structure and not the weaver", is_equal_approx(float(s.hp), hp - 10.0) and is_equal_approx(float(weaver.hp), whp))
	b.clear()


static func _planner(g, b: EnemyBuilder) -> void:
	b.clear()
	b._cool.clear()
	var saved: float = g.hazards.nests.time
	g.hazards.nests.time = 0.0
	b.hold = false
	b.update(0.1)
	var started := 0
	var over := false
	for raw in g.castles.list:
		var c: Dictionary = raw
		if str(c.owner) != "enemy":
			continue
		var n := EnemyBuildWork.growing(b, str(c.id))
		started += n
		over = over or n > EnemyStructures.slots(0.0)
	SmokeTest._check("pressure 0 starts at most one job per hub", started >= 1 and not over, str(started))
	b.hold = true
	g.hazards.nests.time = saved
	b.clear()


static func _mortars(g, b: EnemyBuilder) -> void:
	var nests: SporeNests = g.hazards.nests
	var world: World = nests.world
	var grid: Grid = world.grid
	var hub := _hub(g)
	var saved_time: float = nests.time
	var saved_seal: float = nests.seal
	var saved_arm: float = nests.seal_arm
	nests.time = 0.0
	nests.seal = 0.0
	nests.seal_arm = 0.0
	SmokeTest._check("no castle mortar before the pressure gate", not EnemyBuildPlan._mortar_wanted(b, hub))
	nests.seal = Config.MORTAR_SEAL
	nests.seal_arm = Config.MORTAR_SEAL_BUILD
	SmokeTest._check("a sealed node still unlocks the castle mortar", EnemyBuildPlan._mortar_wanted(b, hub))
	nests.seal = 0.0
	nests.seal_arm = 0.0
	nests.time = 3000.0
	SmokeTest._check("pressure unlocks the castle mortar", EnemyBuildPlan._mortar_wanted(b, hub))
	var cap := EnemyBuildPlan._mortar_cap(b)
	SmokeTest._check("the mortar cap is 1 or 2", cap >= 1 and cap <= 2, str(cap))
	var built: Array = []
	for i in range(cap):
		var cell := _cell(g, 6, 10)
		var s := b.begin(hub, "mortar", cell, false, 0.0)
		EnemyBuildFight.grew(b, s)
		built.append(s)
	SmokeTest._check("finished castle mortars arm and register telegraphs",
		b.mortars.size() == cap and nests.hub_mortars.size() == cap, str(b.mortars.size()))
	SmokeTest._check("the cap stops further mortar builds", not EnemyBuildPlan._mortar_wanted(b, hub))
	var s0: Dictionary = built[0]
	var c0: Vector2i = s0.cell
	SmokeTest._check("the mortar sits on the ground",
		is_equal_approx(s0.pos.y, grid.cell_ground(c0.x, c0.y).y), str(s0.pos.y))
	# Shells fly as tracked hostile lobs.
	var m0: Dictionary = b.mortars[0]
	var tc := Vector2i(mini(c0.x + 10, grid.w - 7), c0.y)
	var ti := grid.idx(tc.x, tc.y)
	var floor_h := grid.base_height[ti]
	TerrainEdit.apply(world, [{ "x": tc.x, "z": tc.y, "height": floor_h + 2.0 }])
	var at := grid.cell_ground(tc.x, tc.y)
	m0.telegraph = { "at": at, "t": 0.0, "whistled": false }
	EnemyMortarFire.advance(nests, m0, Config.MORTAR_TELEGRAPH)
	var shell := {}
	for it in world.effects.lobs():
		if bool(it.get("mortar_shell", false)):
			shell = it
	SmokeTest._check("the shell flies as a tracked hostile lob",
		not shell.is_empty() and bool(shell.get("foe", false)))
	_drain_shells(world)
	SmokeTest._check("the shell detonates on arrival", grid.height[ti] < floor_h + 1.5, str(grid.height[ti]))
	# A swatted shell (dead = what Beam interception sets) never detonates.
	var tc2 := Vector2i(c0.x, mini(c0.y + 10, grid.h - 7))
	var ti2 := grid.idx(tc2.x, tc2.y)
	var floor2 := grid.base_height[ti2]
	TerrainEdit.apply(world, [{ "x": tc2.x, "z": tc2.y, "height": floor2 + 2.0 }])
	var at2 := grid.cell_ground(tc2.x, tc2.y)
	m0.telegraph = { "at": at2, "t": 0.0, "whistled": false }
	EnemyMortarFire.advance(nests, m0, Config.MORTAR_TELEGRAPH)
	var shell2 := {}
	for it in world.effects.lobs():
		if bool(it.get("mortar_shell", false)):
			shell2 = it
	SmokeTest._check("the second shell launched", not shell2.is_empty())
	if not shell2.is_empty():
		shell2.dead = true
	_drain_shells(world)
	SmokeTest._check("an intercepted shell never detonates",
		shell2.is_empty() or is_equal_approx(grid.height[ti2], floor2 + 2.0), str(grid.height[ti2]))
	# The player can destroy built mortars.
	for raw in b.list.duplicate():
		var s: Dictionary = raw
		if str(s.kind) == "mortar" and bool(s.alive):
			b.hurt(s, 99999.0)
	SmokeTest._check("player fire destroys castle mortars and unregisters them",
		b.mortars.is_empty() and nests.hub_mortars.is_empty(),
		"%d/%d" % [b.mortars.size(), nests.hub_mortars.size()])
	TerrainEdit.apply(world, [{ "x": tc.x, "z": tc.y, "height": floor_h }])
	TerrainEdit.apply(world, [{ "x": tc2.x, "z": tc2.y, "height": floor2 }])
	nests.time = saved_time
	nests.seal = saved_seal
	nests.seal_arm = saved_arm


static func _drain_shells(world: World) -> void:
	var guard := 0
	while guard < 40:
		var live := false
		for it in world.effects.lobs():
			if bool(it.get("mortar_shell", false)):
				live = true
				break
		if not live:
			return
		world.effects.update(0.25)
		guard += 1


static func _hub(g) -> Dictionary:
	for raw in g.castles.list:
		var c: Dictionary = raw
		if str(c.owner) == "enemy":
			return c
	return g.castles.list[0]


static func _cell(g, pad: int, gap: int) -> Vector2i:
	var grid: Grid = g.surface.grid
	var b: EnemyBuilder = g.builder
	for z in range(4, grid.h - pad):
		for x in range(4, grid.w - pad):
			if _quiet(g, b, grid, x, z, gap):
				return Vector2i(x, z)
	return Vector2i(4, 4)


static func _quiet(g, b: EnemyBuilder, grid: Grid, x: int, z: int, gap: int) -> bool:
	if b.occupies(x, z) or g.structures.structure_at(x, z) != null:
		return false
	if grid.material[grid.idx(x, z)] == Grid.Mat.SPIRE:
		return false
	if gap <= 0:
		return true
	for s in g.structures.list:
		if not s.dead and Vector2(s.x - x, s.z - z).length() <= float(gap):
			return false
	return true
