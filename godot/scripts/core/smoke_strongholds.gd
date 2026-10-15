class_name SmokeStrongholds
## Stage 7 checks: castle shape, capture, counterattack, siege and retake, wall breach,
## gate break, the spire pump and the saveable state. Movement checks: SmokeCastleWalk.
## Called from SmokeTest.run. Leaves both castles hostile and whole.


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var grid: Grid = g.surface.grid
	var lay: Dictionary = castles.lays.ashmoat
	var c: Dictionary = castles.list[0]
	_shape(grid, lay, castles.lays.bastion)
	SmokeCastleWalk.run(g)
	SmokeCastleBuild.run(g)
	SmokeCastleTurrets.run(g)
	_capture(g, castles, c, lay)
	_siege(g, castles, c, lay)
	_assault(g, castles, c, lay)
	_breach(g, castles, c, lay)
	_gate(g, castles)
	_pump(g, castles, c, lay)
	_save(castles, c)
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	StrongholdMeshes.refresh(castles.views[c.id], c)


static func _shape(grid: Grid, lay: Dictionary, raised: Dictionary) -> void:
	var wall: Vector2i = lay.segments[0].cells[0]
	SmokeTest._check("castle: stone walls stand WALL_UP over the courtyard",
		grid.height_at(wall.x, wall.y) == lay.yard + CastleShape.WALL_UP and grid.material[grid.idx(wall.x, wall.y)] == Grid.Mat.STONE)
	var sp: Dictionary = raised.spire  # Stage 7 spire (Ashmoat's keep has no column since Stage 21)
	SmokeTest._check("castle: spire rises past MAX_LEVEL", grid.height_at(sp.centre.x, sp.centre.y) == sp.top
		and sp.top > Config.MAX_LEVEL and sp.top <= Config.SPIRE_MAX_LEVEL)
	var moat: Vector2i = lay.pump_cells[0]
	SmokeTest._check("castle: moat dug below the floor", grid.height_at(moat.x, moat.y) == lay.floor - CastleShape.MOAT_DEPTH)
	SmokeTest._check("castle: walls are part of base_height", grid.base_height[grid.idx(wall.x, wall.y)] == grid.height_at(wall.x, wall.y))
	var gate: Vector2i = lay.gates[0].cells[0]
	SmokeTest._check("castle: hostile gate belongs to the enemy", grid.gate[grid.idx(gate.x, gate.y)] == Grid.Faction.ENEMY)
	SmokeTest._check("castle: raised variant stands on a plateau", raised.yard == raised.floor + CastleShape.RAISE
		and not raised.bridge.is_empty() and raised.winch.x >= 0)


static func _crown_target(castles: Strongholds, c: Dictionary) -> Dictionary:
	var crown = castles.views[c.id].crown
	return castles.world.targets.filter(func(t): return t.node == crown)[0]


static func _op_at(castles: Strongholds, lay: Dictionary) -> PlayerController:
	var pc := PlayerController.new(null)
	pc.pos = castles.world.grid.cell_ground(lay.spire.centre.x, lay.spire.centre.y)
	castles.op = func(): return pc
	return pc


static func _capture(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	var before := raiders.list.filter(func(r): return r.get("mission", "") == "castle").size()
	var t := _crown_target(castles, c)
	CastleStages.set_stage(castles, c, lay.stages.size() - 1)  # concentric: gate and bailey taken first
	SmokeTest._check("castle: crown nest is an Operative target", t.alive.call())
	t.on_hit.call(1e6)
	SmokeTest._check("castle: crown dies -> capturing", c.state == "capturing" and not t.alive.call())
	var sent := raiders.list.filter(func(r): return r.get("mission", "") == "castle").size() - before
	SmokeTest._check("castle: nearest nest counterattacks", sent >= Config.CASTLE_COUNTER_BASE, "(%d sent)" % sent)
	for r in raiders.list.duplicate():  # keep the courtyard quiet for the timing checks
		raiders.kill(r)
	var old: Callable = castles.op
	_op_at(castles, lay)
	Upgrades.reset()
	SmokeTest._sim(g, Config.CAPTURE_TIME + 0.3)
	var gate: Vector2i = lay.gates[0].cells[0]
	SmokeTest._check("castle: holding the spire top captures it", c.state == "held" and c.owner == "player")
	SmokeTest._check("castle: captured gate is yours", g.surface.grid.gate[g.surface.grid.idx(gate.x, gate.y)] == Grid.Faction.PLAYER)
	castles.op = old
	SmokeTest._sim(g, 24.0)
	SmokeTest._check("castle: held castle pays Aether", Upgrades.aether >= floori(Config.CASTLE_AETHER_RATE * 24.0), "(%d in 24 s)" % Upgrades.aether)
	Upgrades.reset()


static func _siege(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	var ward: Vector2i = lay.get("ward", lay.courtyard)[0]  # concentric: only the ward retakes
	var camp := { "name": "test", "pos": g.surface.grid.cell_ground(ward.x, ward.y), "count": 0 }
	raiders.spawn(camp, RaiderDefs.named("Skitter"), true)
	var r: Dictionary = raiders.list.back()
	r.node.position = camp.pos
	SmokeTest._sim(g, 0.2)
	SmokeTest._check("castle: grace until the reprisal launches: raiders inside start no siege",
		c.raid.grace and c.state == "held" and c.capture.retake == 0.0)
	c.raid.grace = false  # the reprisal has now landed
	SmokeTest._sim(g, 0.2)
	SmokeTest._check("castle: raiders inside -> siege", c.state == "siege")
	SmokeTest._sim(g, Config.RETAKE_TIME + 0.5)
	SmokeTest._check("castle: unanswered siege retakes it", c.state == "hostile" and c.owner == "enemy"
		and absf(c.crown.hp - c.crown.max_hp * Config.CROWN_REGROW) < c.crown.max_hp * 0.1)
	SmokeTest._check("castle: the raiders inside become its garrison", r.alive and r.nest == castles.views[c.id].garrison)
	for x in raiders.list.duplicate():
		raiders.kill(x)


## Raiders sent at a sealed, held keep walk the castle field to its gate and break it.
static func _assault(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	StrongholdRules.to_held(g.surface, c, lay)
	g.castle_raids.update(0.0)
	c.raid.grace = false  # these are the reprisal's raiders: it has launched
	var front: Vector2i = lay.gates[0].outer.back() + (lay.gates[0].outer.back() - lay.gates[0].cells[0]).sign() * 3
	var camp := { "name": "test", "pos": g.surface.grid.cell_ground(front.x, front.y), "count": 0 }
	for i in 3:
		raiders.spawn(camp, RaiderDefs.named("Brute"), false)
		raiders.list.back()["mission"] = "castle"
	SmokeTest._sim(g, 20.0)
	SmokeTest._check("castle: raiders break a held castle's gate", c.gates[0].hp <= 0.0 and c.state == "siege",
		"(gate %.0f, %s)" % [c.gates[0].hp, c.state])
	for x in raiders.list.duplicate():
		raiders.kill(x)


static func _breach(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var grid: Grid = g.surface.grid
	StrongholdRules.to_held(g.surface, c, lay)
	var ward_n: int = lay.get("ward", lay.courtyard).size()
	SmokeTest._check("castle: sealed castle sends raiders to breach points", StrongholdRules.sealed(c, lay)
		and castles.castle_goals().size() > ward_n)
	var i := 1
	var seg: Dictionary = lay.segments[i]
	var prey: Array = castles.views[c.id].prey.filter(func(p): return p.node == castles.views[c.id].segs[i])
	SmokeTest._check("castle: moat walls aren't raider prey (out of reach)", prey.is_empty())
	StrongholdRules.damage(g.surface, c, lay, "walls", i, Config.CASTLE_WALL_HP + 1.0)
	var cell: Vector2i = seg.cells[0]
	SmokeTest._check("castle: a broken wall segment is breached terrain", c.walls[i].hp <= 0.0
		and grid.height_at(cell.x, cell.y) == lay.yard and not StrongholdRules.sealed(c, lay, "outer"))
	var inner := StrongholdHooks.breach_cells(c, lay, "inner").size() if lay.has("inner_rect") and StrongholdRules.sealed(c, lay, "inner") else 0
	SmokeTest._check("castle: breached castle isn't sealed", castles.castle_goals().size() == ward_n + inner)
	var edits := []  # rebuild it for the later checks (Stage 9a: Salvage repairs)
	for e in seg.cells:
		edits.append({ "x": e.x, "z": e.y, "height": lay.wall_top, "material": Grid.Mat.STONE })
	TerrainEdit.apply(g.surface, edits)
	c.walls[i].hp = c.walls[i].max_hp


static func _gate(g, castles: Strongholds) -> void:
	var c: Dictionary = castles.list[1]
	var lay: Dictionary = castles.lays.bastion
	var grid: Grid = g.surface.grid
	var gate_node = castles.views[c.id].gates[0]
	var t: Dictionary = castles.world.targets.filter(func(x): return x.node == gate_node)[0]
	var e: Array = castles.enemies().filter(func(x): return x.node == gate_node)
	SmokeTest._check("castle: enemy gate is a target for the Operative and units", t.alive.call() and e.size() == 1)
	t.on_hit.call(Config.CASTLE_GATE_HP + 1.0)
	var cell: Vector2i = lay.gates[0].cells[0]
	SmokeTest._check("castle: broken gate is open to everyone", grid.gate[grid.idx(cell.x, cell.y)] == Grid.Faction.NONE and not t.alive.call())
	StrongholdRules.set_owner(g.surface, c, lay, "enemy")
	SmokeTest._check("castle: gate re-hung on owner change", grid.gate[grid.idx(cell.x, cell.y)] == Grid.Faction.ENEMY)
	StrongholdMeshes.refresh(castles.views[c.id], c)


static func _pump(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var cr: CreeperSim = g.surface.creeper
	var total := func() -> float:
		var s := 0.0
		for cell in lay.pump_cells:
			s += cr.depth_at(cell.x, cell.y)
		return s
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	for cell in lay.pump_cells:
		cr.set_depth(cell.x, cell.y, 2.0)
	var t0: float = total.call()
	c.pump.material = 0.0
	for i in 4:
		SpirePump.update(g.surface, c, lay, SpirePump.TICK)
	SmokeTest._check("pump: enemy pump draws the moat into build material", c.pump.intake > 0.0 and c.pump.material > 0.0
		and total.call() < t0 - c.pump.material * 0.9, "(intake %.2f/s, drew %.2f)" % [c.pump.intake, c.pump.material])
	var it: Dictionary = castles.world.interactables.filter(func(x): return x.pos == castles.views[c.id].pump.position)[0]
	it.use.call()
	SpirePump.update(g.surface, c, lay, SpirePump.TICK)
	SmokeTest._check("pump: the Operative can jam it", c.pump.jam > 0.0 and c.pump.intake == 0.0 and it.prompt.call() == "")
	c.pump.jam = 0.0
	for cell in lay.pump_cells:
		cr.set_depth(cell.x, cell.y, 0.0)


static func _save(castles: Strongholds, c: Dictionary) -> void:
	var saved := castles.state()
	SmokeTest._check("castle: state is plain data", bytes_to_var(var_to_bytes(saved)) == saved)  # no Objects inside
	c.state = "siege"
	c.walls[0].hp = 7.0
	castles.load_state(bytes_to_var(var_to_bytes(saved)))
	SmokeTest._check("castle: state round-trips", castles.state() == saved and c.walls[0].hp == saved.castles[0].walls[0].hp)
