class_name SmokeCastles2Engines
## Stage 21 war engines: trebuchets on a hostile concentric castle pick targets in range
## (weapons first, the Operative only in sight), telegraph a ring, and hit whatever stayed;
## an Operative who walks out of the ring takes nothing. They die, respawn, and stop for good
## once the bailey is taken. Runs on its own Level 2 World (SmokeCastles2Capture.rig).


class Dummy:
	var node := Node3D.new()
	var damage := 0.0


static func _prey(d: Dummy, kind := "", weapon := false) -> Dictionary:
	return { "node": d.node, "radius": 0.5, "kind": kind, "weapon": weapon,
		"alive": func(): return true, "hit": func(x, _p = null): d.damage += x }


static func run(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var grid: Grid = r.w.grid
	var v: Dictionary = castles.views[c.id]
	SmokeTest._check("castles2 engines: two trebuchets on the corner towers", c.engines.size() == CastleDefs.ENGINES_DEFAULT
		and r.lay.engine_posts.has(c.engines[0].post))
	var e: Dictionary = c.engines[0]
	c.engines[1].cd = 1e6  # only the first engine shoots in these checks
	var from: Vector3 = (v.engines[0] as Node3D).position
	var out := (from - grid.cell_center(r.lay.rect.get_center().x, r.lay.rect.get_center().y)).normalized()
	out.y = 0.0
	out = out.normalized()
	var spot := _ground(grid, from + out * 20.0 * Config.CELL)
	var op := Dummy.new()
	op.node.position = spot
	var gun := Dummy.new()
	gun.node.position = _ground(grid, from + out * 24.0 * Config.CELL)
	var far := Dummy.new()
	far.node.position = _ground(grid, from + out * (CastleDefs.ENGINE.range + 4.0) * Config.CELL)
	var list := [_prey(op, "operative"), _prey(gun, "", true), _prey(far, "", true)]
	var q := CastleEngines.pick(grid, from, list)
	SmokeTest._check("castles2 engines: weapons first, nothing out of range", not q.is_empty() and q.node == gun.node)
	var q2 := CastleEngines.pick(grid, from, [list[0], list[2]])
	SmokeTest._check("castles2 engines: the Operative in sight is a target", not q2.is_empty() and q2.node == op.node)
	var hall: Vector2i = r.lay.zones.gate.cells[4]
	var hidden := Dummy.new()
	hidden.node.position = grid.cell_center(hall.x, hall.y)
	SmokeTest._check("castles2 engines: no shot at an Operative under a roof", CastleEngines.pick(grid, from, [_prey(hidden, "operative")]).is_empty())
	# Fair: a shot at a standing target lands; one that walks 6 m away during the telegraph doesn't.
	var stay := Dummy.new()
	stay.node.position = spot
	_shoot(castles, c, v, [_prey(stay, "operative")])
	SmokeTest._check("castles2 engines: a target that stays is hit", absf(stay.damage - CastleDefs.ENGINE.dmg_operative) < 0.01, "(%.1f)" % stay.damage)
	var mover := Dummy.new()
	mover.node.position = spot
	var moved := false
	e.cd = 0.0
	var t := 0.0
	var rows := [_prey(mover, "operative")]
	while t < CastleDefs.ENGINE.telegraph + 0.5:
		CastleEngines.rings.clear()
		CastleEngines.tick(castles, c, v, rows, 0.1)
		if not e.shot.is_empty() and not moved and e.shot.t > 0.5:
			moved = true
			SmokeTest._check("castles2 engines: the telegraph ring is up", not CastleEngines.rings.is_empty())
			mover.node.position += Vector3(6.0, 0, 0)  # a sidestep: under 1.5 s of walking
		t += 0.1
	SmokeTest._check("castles2 engines: an Operative who walks out takes nothing", moved and mover.damage == 0.0)
	# Death, respawn, and silence once the bailey is taken.
	for i in c.engines.size():
		(v.engine_foes[i].enemy.hit as Callable).call(CastleDefs.ENGINE.hp + 1.0)
	SmokeTest._check("castles2 engines: can be destroyed", CastleEngines.alive_count(c) == 0 and v.engine_foes.all(func(f): return not f.alive.call()))
	CastleEngines.tick(castles, c, v, [], CastleDefs.ENGINE.respawn + 1.0)
	SmokeTest._check("castles2 engines: rebuilt while the bailey is hostile", CastleEngines.alive_count(c) == c.engines.size())
	CastleStages.set_stage(castles, c, 2)
	for x in c.engines:
		x.hp = 0.0
	CastleEngines.tick(castles, c, v, [], CastleDefs.ENGINE.respawn + 1.0)
	SmokeTest._check("castles2 engines: gone for good once the bailey is yours", CastleEngines.alive_count(c) == 0 and not CastleEngines.active(c))
	for d in [op, gun, far, hidden, stay, mover]:
		d.node.free()
	r.w.queue_free()


static func _ground(grid: Grid, p: Vector3) -> Vector3:
	return Vector3(p.x, grid.smooth_y(p.x, p.z), p.z)


## One full shot at the first engine: fire now, wait out the telegraph.
static func _shoot(castles: Strongholds, c: Dictionary, v: Dictionary, rows: Array) -> void:
	c.engines[0].cd = 0.0
	var t := 0.0
	while t < CastleDefs.ENGINE.telegraph + 0.5:
		CastleEngines.tick(castles, c, v, rows, 0.1)
		t += 0.1
