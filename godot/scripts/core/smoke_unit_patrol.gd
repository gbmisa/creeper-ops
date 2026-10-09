class_name SmokeUnitPatrol
## Patrol orders: a unit loops its points in order forever, stops to shoot a Skitter in range
## then carries on, a move order cancels the loop, and a unit from a barracks in a held castle
## garrisons the courtyard on its own.

const X0 := 40
const Z0 := 40
const X1 := 70
const Z1 := 50


static func run(g) -> void:
	var cells := [Vector2i(46, 43), Vector2i(62, 43), Vector2i(62, 48)]
	var pts: Array = cells.map(func(c): return Vector2((c.x + 0.5) * Config.CELL, (c.y + 0.5) * Config.CELL))
	SmokeAttackMove._pad(g, X0, Z0, X1, Z1)
	SmokeAttackMove._clear(g)
	var u: Unit = g.units.spawn("soldier", pts[0].x, pts[0].y)
	UnitPatrol.assign(g.units, [u], pts)
	var order := _visits(g, u, 6, 80.0)
	SmokeTest._check("patrol: visits every point in order and loops",
		order == [1, 2, 0, 1, 2, 0] and u.patrol_laps >= 1, "(visited %s, laps %d)" % [order, u.patrol_laps])

	# A Skitter beside the route: the patrol engages it, then keeps looping.
	var r := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(54, 44), false)
	var engaged := false
	var t := 0.0
	while t < 40.0 and u.alive and r.alive:
		_step(g)
		engaged = engaged or u.engaged
		t += 0.05
	var laps := u.patrol_laps
	var i0 := u.patrol_i
	_visits(g, u, 3, 40.0)
	SmokeTest._check("patrol: engages a Skitter in range, kills it, resumes",
		u.alive and not r.alive and engaged and u.state == "patrol" and (u.patrol_laps > laps or u.patrol_i != i0),
		"(engaged %s, dead %s, state %s)" % [engaged, not r.alive, u.state])

	# One click: patrol between the unit's own spot and that point.
	var v: Unit = g.units.spawn("soldier", pts[0].x, pts[0].y + 2.0)
	UnitPatrol.assign(g.units, [v], [pts[1]])
	SmokeTest._check("patrol: one point loops between the unit and the point", v.patrol.size() == 2 and v.state == "patrol")
	g.units.kill(v)

	# A new move order cancels the patrol.
	g.units.order([u], pts[1], true)
	_visits(g, u, 0, 20.0)
	SmokeTest._check("patrol: a move order cancels it", u.patrol.is_empty() and u.state != "patrol",
		"(state %s)" % u.state)
	if u.alive:
		g.units.kill(u)
	SmokeAttackMove._clear(g)
	_castle(g)
	_crawler_towers(g)


## Steps the sim until `n` point changes were seen (or `limit` s); returns the indices visited.
static func _visits(g, u: Unit, n: int, limit: float) -> Array:
	var seen := [u.patrol_i] if not u.patrol.is_empty() else []
	var last := u.patrol_i
	var t := 0.0
	while t < limit and u.alive and (n == 0 or seen.size() < n + 1):
		_step(g)
		t += 0.05
		if not u.patrol.is_empty() and u.patrol_i != last:
			last = u.patrol_i
			seen.append(last)
	return seen.slice(1) if not seen.is_empty() and n > 0 else seen


static func _step(g) -> void:
	SmokeAttackMove._clear_creeper(g, X0, Z0, X1, Z1)
	g.update(0.05)


static func _castle(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var w: World = r.w
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var um := UnitManager.new()
	w.add_child(um)
	um.setup(w, null)
	um.castles = r.castles
	var cell: Vector2i = lay.courtyard[lay.courtyard.size() / 2]
	var at := w.grid.cell_ground(cell.x, cell.y)
	var a: Unit = um.spawn("soldier", at.x, at.z)
	UnitPatrol.auto_castle(um, a, at)
	SmokeTest._check("patrol: hostile castle gives no auto-patrol", a.patrol.is_empty())
	StrongholdRules.to_held(w, c, lay)
	var b: Unit = um.spawn("soldier", at.x, at.z)
	UnitPatrol.auto_castle(um, b, at)
	SmokeTest._check("patrol: barracks unit in a held castle patrols the courtyard",
		b.patrol.size() >= 2 and b.state == "patrol" and not b.path.is_empty(), "(%d points)" % b.patrol.size())
	var inside := b.patrol.all(func(p): return (lay.rect as Rect2i).has_point(w.grid.world_to_cell(p.x, p.y)))
	SmokeTest._check("patrol: castle route stays inside the walls", inside)
	um.order([b], Vector2(at.x, at.z), true)
	SmokeTest._check("patrol: player order overrides the castle patrol", b.patrol.is_empty())
	w.queue_free()


## Crawlers (big bodies) must squeeze past a staggered cluster of towers to their target.
static func _crawler_towers(g) -> void:
	SmokeAttackMove._pad(g, X0, Z0, X1, Z1)
	SmokeAttackMove._clear(g)
	var sm: StructureManager = g.structures
	var towers := []
	for c in [Vector2i(52, 41), Vector2i(52, 43), Vector2i(52, 46), Vector2i(52, 48), Vector2i(55, 42), Vector2i(55, 44), Vector2i(55, 47), Vector2i(58, 43), Vector2i(58, 46), Vector2i(58, 48)]:
		var s = sm.place("cannon", c.x, c.y, true)
		if s:
			towers.append(s)
	var dest := Vector2(64.5 * Config.CELL, 44.5 * Config.CELL)
	var u: Unit = g.units.spawn("crawler", 46.5 * Config.CELL, 44.5 * Config.CELL)
	g.units.order([u], dest, true)
	var t := 0.0
	while t < 40.0 and u.alive and not (u.path.is_empty() and t > 1.0):
		_step(g)
		t += 0.05
	var d := Vector2(u.pos.x - dest.x, u.pos.z - dest.y).length()
	SmokeTest._check("crawler: walks past a cluster of towers to its target", u.alive and d < 4.0 * Config.CELL,
		"(%d towers, %.1f m short after %.1f s)" % [towers.size(), d, t])
	if u.alive:
		g.units.kill(u)
	for s in towers:
		sm.remove(s)
