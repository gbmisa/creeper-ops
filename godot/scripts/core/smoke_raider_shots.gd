class_name SmokeRaiderShots
## Brief R phase 2: lock on to a moving target (few field builds), shooters keep their pick,
## a Spitter fires only along a clear lob. Prey here are plain dicts fed through nests.prey.

const X0 := 40
const Z0 := 50


static func run(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var saved: Callable = nests.prey
	var spire_timer: float = g.hazards.spire.timer
	g.hazards.spire.timer = -1.0e9
	_moving(g, false)
	_moving(g, true)
	_keeps_pick(g)
	_lob(g, true)
	_lob(g, false)
	nests.prey = saved
	g.hazards.spire.timer = spire_timer
	SmokeAttackMove._pad(g, X0, Z0, X0 + 30, Z0 + 26)


static func _flat(g) -> void:
	SmokeAttackMove._pad(g, X0, Z0, X0 + 30, Z0 + 26)
	SmokeAttackMove._clear(g)
	g.hazards.nests.raiders.paths.fields.clear()


static func _row(g, cell: Vector2i, hits: Array) -> Dictionary:
	var n := Node3D.new()
	n.position = g.surface.grid.cell_ground(cell.x, cell.y)
	return { "node": n, "oy": 0.5, "radius": 0.5, "kind": "unit", "alive": func(): return true,
		"hit": func(d): hits.append(d) }


static func _feed(g, rows: Array) -> void:
	g.hazards.nests.prey = func() -> Array: return rows


static func _moving(g, walled: bool) -> void:
	_flat(g)
	if walled:  # a wall between them: the raider walks the target's field, rebuilt only on real moves
		var cells := []
		for z in range(Z0 + 6, Z0 + 15):
			cells.append(Vector2i(X0 + 9, z))
		TerrainEdit.raise(g.surface, cells, 2.0)
	var hits := []
	var q := _row(g, Vector2i(X0 + 11, Z0 + 10), hits)
	_feed(g, [q])
	var r := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(X0 + 8, Z0 + 10), false)
	r["hp"] = 1e6
	var first = null
	var switched := false
	var t := 0.0
	while t < 10.0:
		(q.node as Node3D).position.z = (Z0 + 10.5) * Config.CELL + 3.0 * sin(t * 0.5) if walled else (q.node as Node3D).position.z + 1.5 * 0.05
		SmokeTest._sim(g, 0.05)
		t += 0.05
		var cur: Dictionary = r.get("_tgt", {})
		if first == null and not cur.is_empty():
			first = cur
		elif not cur.is_empty() and not is_same(cur, first):
			switched = true
	var nb: int = g.hazards.nests.raiders.paths.builds_for(r)
	SmokeTest._check("raider lock-on%s: a target" % (" behind a wall" if walled else "") + " moved every tick is chased, hit, never swapped, <= 3 field builds",
		hits.size() > 0 and first != null and not switched and nb <= 3,
		"(hits %d, switched %s, builds %d, %d total)" % [hits.size(), switched, nb, g.hazards.nests.raiders.paths.total_builds])
	(q.node as Node3D).free()
	_end(g, r)


static func _keeps_pick(g) -> void:
	_flat(g)
	var hits := []
	var a := _row(g, Vector2i(X0 + 16, Z0 + 10), hits)
	var rows := [a]
	_feed(g, rows)
	var s := SmokeAttackMove._spawn_raider_at(g, "Spitter", Vector2i(X0 + 6, Z0 + 10), true)
	s["hp"] = 1e6
	SmokeTest._sim(g, 1.0)
	var b := _row(g, Vector2i(X0 + 8, Z0 + 13), hits)  # nearer than A
	rows.append(b)
	var same := true
	var t := 0.0
	while t < 5.0:
		SmokeTest._sim(g, 0.05)
		t += 0.05
		if not is_same(s.get("_pick", {}), a):
			same = false
	SmokeTest._check("raider shots: a shooter keeps its pick for 5 s after a nearer prey appears", same,
		"(kept %s)" % same)
	(a.node as Node3D).free()
	(b.node as Node3D).free()
	_end(g, s)


## A wall two levels high two cells in front of the aim point: the flat arc cannot clear it.
static func _lob(g, walled: bool) -> void:
	_flat(g)
	var hits := []
	var q := _row(g, Vector2i(X0 + 16, Z0 + 10), hits)
	_feed(g, [q])
	if walled:
		var cells := []
		for z in range(Z0 + 6, Z0 + 15):
			cells.append(Vector2i(X0 + 14, z))
		TerrainEdit.raise(g.surface, cells, 2.0)
	var s := SmokeAttackMove._spawn_raider_at(g, "Spitter", Vector2i(X0 + 8, Z0 + 10), true)
	s["hp"] = 1e6
	var p0: Vector3 = s.node.position
	var last := 0.0
	var fires := 0
	var first_at := -1.0
	var ok_at_fire := false
	var moved := 0.0
	var t := 0.0
	while t < 40.0 and (fires == 0 or t < 1.0):
		SmokeTest._sim(g, 0.05)
		t += 0.05
		var cd: float = float(s.get("shot_cd", 0.0))
		if cd > last + 0.1:
			fires += 1
			if first_at < 0.0:
				first_at = t
				ok_at_fire = bool(s.get("_lob", {}).get("ok", false))
				moved = (s.node.position - p0).length()
		last = cd
	if walled:
		SmokeTest._check("spitter clear shot: a 2-level wall blocks the lob, it moves, then fires once clear",
			fires > 0 and first_at > 1.0 and moved > 2.0 and ok_at_fire,
			"(fires %d, first at %.1f s, moved %.1f m, clear at fire %s)" % [fires, first_at, moved, ok_at_fire])
	else:
		SmokeTest._check("spitter clear shot: with no wall it fires at once", fires > 0 and first_at <= 0.5 and ok_at_fire,
			"(fires %d, first at %.1f s)" % [fires, first_at])
	(q.node as Node3D).free()
	_end(g, s)


static func _end(g, r: Dictionary) -> void:
	if r.alive:
		g.hazards.nests.raiders.kill(r)
	SmokeAttackMove._clear(g)
