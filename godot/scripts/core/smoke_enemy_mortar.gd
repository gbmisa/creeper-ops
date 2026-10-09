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
	m.cd = 0.0
	m.spotted = false
	EnemyMortarFire.volley(nests, hive, 0.0)
	var mode := str(g.mode)
	g.mode = "surface"
	g.hud.refresh(g, 0.05)
	SmokeTest._check("HUD shows SPOTTED while a mortar has the Operative", bool(m.spotted) and g.hud.fps.spotted_lit() and g.hud.log_has("SPOTTED"))
	g.mode = mode
	g.hud.set_mode(mode)
	m.telegraph = null
	m.cd = 0.0
	m.spotted = false
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
	var it: Dictionary = m.interact
	var w: World = nests.world
	var before: float = g.stockpile.salvage
	OperativeUpgrades.reset()
	DemoCharge.clear()
	SmokeTest._check("mortar prompt without a charge points to the Armoury",
		"Armoury" in String(it.prompt.call()) and not it.ready.call())
	it.use.call()
	DemoCharge.tick(w, Config.DEMO_FUSE + 1.0)
	SmokeTest._check("E without a charge does not harm the mortar", m.alive and DemoCharge.list.is_empty())
	OperativeUpgrades.charges = 2
	SmokeTest._check("mortar prompt offers planting", "Plant demolition charge" in String(it.prompt.call()) and it.ready.call())
	it.use.call()
	SmokeTest._check("planting consumes one charge and arms a fuse", OperativeUpgrades.charges == 1 and DemoCharge.list.size() == 1 and m.alive)
	it.use.call()
	SmokeTest._check("a mortar takes only one charge", OperativeUpgrades.charges == 1 and DemoCharge.list.size() == 1)
	DemoCharge.tick(w, Config.DEMO_FUSE - 0.5)
	SmokeTest._check("mortar survives until the fuse runs out", m.alive)
	DemoCharge.tick(w, 0.6)
	SmokeTest._check("the planted charge destroys the mortar and pays no Salvage",
		not m.alive and is_equal_approx(g.stockpile.salvage, before))
	OperativeUpgrades.reset()
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
