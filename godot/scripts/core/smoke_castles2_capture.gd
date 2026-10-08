class_name SmokeCastles2Capture
## Stage 21 staged capture: every transition of a concentric castle (gate -> bailey -> keep ->
## held -> siege -> hostile), contests, ring retakes, gate ownership per ring, bailey build
## rights and the saveable state. Runs on its own Level 2 World inside the smoke game.


## A Level 2 World with its castles and nests. Returns { w, castles, c, lay, op }.
static func rig(g) -> Dictionary:
	var lvl := Levels.build(2)
	var w := World.new()
	w.setup("L2c", lvl.grid, false)
	g.add_child(w)
	var castles := Strongholds.new(w, lvl.castles, SporeNests.new(w, lvl.nests, lvl.raid_schedule))
	var c: Dictionary = castles.list.filter(func(x): return castles.lays[x.id].get("plan", "") == "concentric")[0]
	var op := PlayerController.new(null)
	op.pos = Vector3(-100, 0, -100)
	castles.op = func(): return op
	for x in castles.list:
		x.garrison_timer = -1e6  # no garrison: raiders only where a test puts them
	return { "w": w, "castles": castles, "c": c, "lay": castles.lays[c.id], "op": op }


static func run(g) -> void:
	var r := rig(g)
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var grid: Grid = r.w.grid
	var op: PlayerController = r.op
	var outer: Vector2i = lay.gates.filter(func(x): return x.ring == "outer")[0].cells[0]
	var inner: Vector2i = lay.gates.filter(func(x): return x.ring == "inner")[0].cells[0]
	SmokeTest._check("castles2 capture: starts at the gate stage", CastleStages.current(c, lay) == "gate" and c.state == "hostile")
	var crown := _crown(castles, c)
	crown.on_hit.call(1e6)
	SmokeTest._check("castles2 capture: crown nest warded before the bailey", c.state == "hostile" and c.crown.hp > 0.0)
	# Gate stage: contested by a raider, then taken.
	_put(op, grid, lay.zones.gate.cells[4])
	var raider := _raider(castles, grid, lay.zones.gate.cells[1])
	_sim(castles, CastleDefs.GATE_TIME + 1.0)
	SmokeTest._check("castles2 capture: a raider in the gate hall contests it", c.stage == 0 and c.ring.progress == 0.0)
	castles.nests.raiders.kill(raider)
	_sim(castles, CastleDefs.GATE_TIME + 0.3)
	SmokeTest._check("castles2 capture: holding the gate hall takes the gatehouse", c.stage == 1)
	SmokeTest._check("castles2 capture: outer gate yours, inner still theirs", grid.gate[grid.idx(outer.x, outer.y)] == Grid.Faction.PLAYER
		and grid.gate[grid.idx(inner.x, inner.y)] == Grid.Faction.ENEMY)
	# Ring retake: raiders back in the gate hall with nobody there.
	_put(op, grid, lay.ward[0])
	raider = _raider(castles, grid, lay.zones.gate.cells[4])
	_sim(castles, CastleDefs.RING_RETAKE + 0.5)
	SmokeTest._check("castles2 capture: raiders retake an unguarded gatehouse", c.stage == 0
		and grid.gate[grid.idx(outer.x, outer.y)] == Grid.Faction.ENEMY)
	castles.nests.raiders.kill(raider)
	# Bailey stage: blocked while trebuchets stand.
	CastleStages.set_stage(castles, c, 1)
	_put(op, grid, lay.zones.bailey.cells[4])
	_sim(castles, CastleDefs.BAILEY_TIME + 1.0)
	SmokeTest._check("castles2 capture: no bailey while trebuchets stand", c.stage == 1 and CastleEngines.alive_count(c) > 0)
	for e in c.engines:
		e.hp = 0.0
	_sim(castles, CastleDefs.BAILEY_TIME + 0.3)
	var b: Vector2i = lay.bailey[0]
	var wd: Vector2i = lay.ward[0]
	SmokeTest._check("castles2 capture: bailey taken once the engines are down", c.stage == 2)
	SmokeTest._check("castles2 capture: bailey buildable, ward not", grid.blocked[grid.idx(b.x, b.y)] == 0 and grid.blocked[grid.idx(wd.x, wd.y)] == 1)
	# Keep: crown open, hold the hall.
	crown.on_hit.call(1e6)
	SmokeTest._check("castles2 capture: crown dies once the bailey is yours", c.state == "capturing")
	_put(op, grid, lay.zones.keep.cells[0])
	_sim(castles, Config.CAPTURE_TIME + 0.3)
	SmokeTest._check("castles2 capture: holding the keep hall takes the castle", c.state == "held" and c.owner == "player"
		and grid.gate[grid.idx(inner.x, inner.y)] == Grid.Faction.PLAYER and grid.blocked[grid.idx(wd.x, wd.y)] == 0)
	_siege(castles, c, lay, grid, op)
	_abandon(castles, c, lay, op)
	_save(castles, c)
	r.w.queue_free()


static func _siege(castles: Strongholds, c: Dictionary, lay: Dictionary, grid: Grid, op: PlayerController) -> void:
	op.pos = Vector3(-100, 0, -100)
	var raider := _raider(castles, grid, lay.bailey[lay.bailey.size() / 2])
	_sim(castles, Config.RETAKE_TIME + 1.0)
	SmokeTest._check("castles2 capture: raiders in the bailey only besiege", c.state == "siege" and c.capture.retake == 0.0)
	raider.node.position = grid.cell_ground(lay.ward[0].x, lay.ward[0].y)
	_sim(castles, Config.RETAKE_TIME + 0.5)
	SmokeTest._check("castles2 capture: raiders in the ward retake it, rings reset", c.state == "hostile" and c.stage == 0)
	for x in castles.nests.raiders.list.duplicate():
		castles.nests.raiders.kill(x)


## A capture nobody holds regrows the crown but keeps the outer rings.
static func _abandon(castles: Strongholds, c: Dictionary, lay: Dictionary, op: PlayerController) -> void:
	CastleStages.set_stage(castles, c, 2)
	_crown(castles, c).on_hit.call(1e6)
	op.pos = Vector3(-100, 0, -100)
	_sim(castles, Config.CAPTURE_ABANDON + 1.0 / Config.CAPTURE_DECAY)
	SmokeTest._check("castles2 capture: an abandoned keep regrows, outer rings kept", c.state == "hostile" and c.stage == 2)


static func _save(castles: Strongholds, c: Dictionary) -> void:
	CastleStages.set_stage(castles, c, 1)
	c.ring.progress = 0.4
	c.engines[0].hp = 7.0
	var saved := castles.state()
	c.stage = 0
	c.ring.progress = 0.0
	c.engines[0].hp = 99.0
	castles.load_state(saved)
	SmokeTest._check("castles2 capture: stage, ring and engines survive a save", c.stage == 1 and absf(c.ring.progress - 0.4) < 0.001
		and absf(c.engines[0].hp - 7.0) < 0.001)


static func _crown(castles: Strongholds, c: Dictionary) -> Dictionary:
	var node = castles.views[c.id].crown
	return castles.world.targets.filter(func(t): return t.node == node)[0]


static func _put(op: PlayerController, grid: Grid, cell: Vector2i) -> void:
	op.pos = grid.cell_center(cell.x, cell.y)


static func _raider(castles: Strongholds, grid: Grid, cell: Vector2i) -> Dictionary:
	var camp := { "name": "test", "pos": grid.cell_ground(cell.x, cell.y), "count": 0 }
	castles.nests.raiders.spawn(camp, RaiderDefs.named("Skitter"), true)
	var r: Dictionary = castles.nests.raiders.list.back()
	r.node.position = camp.pos
	r["speed_mult"] = 0.0
	return r


## Only the castles tick (raiders stay where the test puts them).
static func _sim(castles: Strongholds, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		castles.update(0.1)
		t += 0.1
