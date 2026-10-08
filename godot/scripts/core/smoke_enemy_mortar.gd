class_name SmokeEnemyMortar
## Stage 8 enemy mortars: range, Spotter line of sight, Earth, sabotage, the sealed Node (§4.3).


static func run(g) -> void:
	var nests: SporeNests = g.hazards.nests
	nests.time = 0.0
	for n in nests.nests:
		Hives.sync(nests, n)
	var hive := _named(nests, "Central knoll")
	_aiming(g, nests, hive)
	_earth(g, nests)
	_sabotage(g, nests, hive)
	_stages(nests, hive)
	_seal(g, nests, hive)
	nests.time = 0.0
	for n in nests.nests:
		Hives.sync(nests, n)
		EnemyMortars.clear(nests, n)
	if g.fps.world != null:
		g.fps.leave()


static func _named(nests: SporeNests, who: String) -> Dictionary:
	for n in nests.nests:
		if str(n.name) == who:
			return n
	return {}


static func _plant(nests: SporeNests, hive: Dictionary, x: int, z: int) -> Dictionary:
	var m: Dictionary = EnemyMortars._make(nests, hive, (hive.mortars as Array).size())
	(hive.mortars as Array).append(m)
	var pos := nests.world.grid.cell_ground(x, z)
	(m.node as Node3D).position = pos
	m.pos = pos
	(m.interact as Dictionary).pos = pos
	EnemyMortars.ready(nests, m)
	m.cd = 0.0
	return m


static func _aiming(g, nests: SporeNests, hive: Dictionary) -> void:
	EnemyMortars.clear(nests, hive)
	var m := _plant(nests, hive, 6, 72)
	var sm: StructureManager = g.structures
	var near := sm.place("collector", 10, 72, true)
	var saved_prey: Callable = nests.prey
	var rows: Array = []
	nests.prey = func() -> Array: return rows
	rows.append(_band(near))
	SmokeTest._check("mortar ignores inside minimum range", EnemyMortars.aim(nests, m).is_empty())
	var relay := sm.place("relay", 12, 72, true)
	var cannon := sm.place("cannon", 20, 72, true)
	rows.append(_band(relay))
	rows.append(_band(cannon))
	var picked := EnemyMortars.aim(nests, m)
	SmokeTest._check("mortar prefers a weapon in range", picked.get("type", "") == "cannon")
	g.fps.reset_suit()
	g.fps.enter(g.surface, Vector2i(16, 72), 0.0)
	rows.append(g.fps.prey)
	nests.raiders.kill(m.spotter)
	picked = EnemyMortars.aim(nests, m)
	SmokeTest._check("operative untargeted without a spotter", str(picked.get("kind", "")) != "operative")
	EnemyMortarFire.spotter(nests, m)
	picked = EnemyMortars.aim(nests, m)
	SmokeTest._check("operative targeted while a spotter has line of sight", str(picked.get("kind", "")) == "operative")
	g.fps.controller.pos = g.surface.grid.cell_ground(10, 72)
	g.fps.body.position = g.fps.controller.pos
	picked = EnemyMortars.aim(nests, m)
	SmokeTest._check("operative inside minimum range is not the target", str(picked.get("kind", "")) != "operative"
		and str(picked.get("type", "")) == "cannon")
	var spot: Dictionary = m.spotter
	nests.raiders.kill(spot)
	m.cd = 100.0
	EnemyMortars.tick(nests, 29.0)
	var back := false
	var respawned := false
	for r in nests.raiders.list:
		if str(r.get("mid", "")) == str(m.mid) and r.alive:
			back = true
	SmokeTest._check("spotter stays dead before 30s", not back)
	EnemyMortars.tick(nests, 2.0)
	for r in nests.raiders.list:
		if str(r.get("mid", "")) == str(m.mid) and r.alive:
			respawned = true
	SmokeTest._check("spotter respawns 30s after dying", respawned)
	nests.prey = saved_prey
	g.fps.leave()
	sm.remove(near, "destroyed")
	sm.remove(relay, "destroyed")
	sm.remove(cannon, "destroyed")
	EnemyMortars.clear(nests, hive)


static func _band(s: Structure) -> Dictionary:
	var row := s.prey.duplicate() as Dictionary
	row["type"] = s.type
	row["weapon"] = bool(s.def.get("weapon", false))
	return row


static func _earth(g, nests: SporeNests) -> void:
	var grid: Grid = g.surface.grid
	var saved: String = g.mode
	g.mode = "surface"
	g.fps.reset_suit()
	g.fps.enter(g.surface, Vector2i(2, 2), 0.0)
	var i := grid.idx(2, 2)
	var floor_h := grid.base_height[i]
	TerrainEdit.apply(g.surface, [{ "x": 2, "z": 2, "height": floor_h + 2.0 }])
	EnemyMortarHit.detonate(nests, grid.cell_ground(2, 2))
	SmokeTest._check("earth drops one level", is_equal_approx(grid.height[i], floor_h + 1.0))
	SmokeTest._check("shell centre takes 70% of the suit", is_equal_approx(g.fps.suit, Config.SUIT_MAX * 0.3))
	TerrainEdit.apply(g.surface, [{ "x": 2, "z": 2, "height": floor_h }])
	var s := grid.idx(3, 2)
	var spire_h := grid.height[s] + 4.0
	grid.material[s] = Grid.Mat.SPIRE
	grid.height[s] = spire_h
	EnemyMortarHit.detonate(nests, grid.cell_ground(2, 2))
	SmokeTest._check("earth never drops below base height", is_equal_approx(grid.height[i], floor_h))
	SmokeTest._check("spire cells are skipped", grid.material[s] == Grid.Mat.SPIRE and is_equal_approx(grid.height[s], spire_h))
	grid.material[s] = Grid.Mat.NATURAL
	grid.height[s] = spire_h - 4.0
	g.mode = saved
	g.fps.leave()


static func _sabotage(g, nests: SporeNests, hive: Dictionary) -> void:
	var m := _plant(nests, hive, 20, 70)
	var before: float = g.stockpile.salvage
	(m.interact as Dictionary).use.call()
	SmokeTest._check("sabotage use starts the channel", is_equal_approx(float(m.channel), Config.MORTAR_SABOTAGE_TIME))
	var far: Vector3 = m.pos + Vector3(8, 0, 0)
	SmokeTest._check("leaving range cancels sabotage", not EnemyMortars.sabotage(nests, m, far, 1.0) and m.alive)
	(m.interact as Dictionary).use.call()
	SmokeTest._check("sabotage needs the full 3s", not EnemyMortars.sabotage(nests, m, m.pos, 2.9) and m.alive)
	var down := EnemyMortars.sabotage(nests, m, m.pos, 0.2)
	SmokeTest._check("sabotage destroys the mortar and pays salvage", down and not m.alive
		and is_equal_approx(g.stockpile.salvage, before + Config.MORTAR_SALVAGE))
	EnemyMortars.clear(nests, hive)


static func _stages(nests: SporeNests, hive: Dictionary) -> void:
	EnemyMortars.clear(nests, hive)
	Hives.unlock_to(nests, hive, 3)
	EnemyMortars.reconcile(nests, hive)
	SmokeTest._check("stage 3 builds one mortar", (hive.mortars as Array).size() == 1)
	Hives.unlock_to(nests, hive, 4)
	EnemyMortars.reconcile(nests, hive)
	var list: Array = hive.mortars
	SmokeTest._check("stage 4 builds a second mortar", list.size() == 2
		and is_equal_approx(float(list[0].max_hp), Config.HIVE_MORTAR_HP * Config.HIVE_STAGE4_HP)
		and is_equal_approx(float(list[1].max_hp), Config.HIVE_MORTAR_HP * Config.HIVE_STAGE4_HP))
	EnemyMortars.clear(nests, hive)


static func _seal(g, nests: SporeNests, hive: Dictionary) -> void:
	EnemyMortars.clear(nests, hive)
	nests.time = 0.0
	Hives.sync(nests, hive)
	EnemyMortars.note_route(nests, 30.0)
	SmokeTest._check("an open route does not seal the node", nests.seal == 0.0)
	var node: Structure = g.structures.command_node()
	var y := node.pos.y
	node.pos.y = y + 80.0
	EnemyMortars.note_route(nests, 50.0)
	var early := is_equal_approx(nests.seal, 50.0) and nests.seal_arm == 0.0 and (hive.mortars as Array).is_empty()
	EnemyMortars.note_route(nests, 80.0)
	EnemyMortars.reconcile(nests, hive)
	SmokeTest._check("sixty seconds sealed does not build yet", early)
	SmokeTest._check("the sealed node builds one mortar", (hive.mortars as Array).size() == 1)
	node.pos.y = y
	EnemyMortars.note_route(nests, 0.2)
	SmokeTest._check("a route again clears the seal timer", nests.seal == 0.0)
