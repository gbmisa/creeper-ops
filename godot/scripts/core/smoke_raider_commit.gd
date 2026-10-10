class_name SmokeRaiderCommit
## Brief R phase 1: a melee raider commits to one target and one route. Synthetic terrain: a
## plateau two levels up whose only ramp is on its west side; the target sits at the foot of the
## east cliff, inside RAIDER_AGGRO but not walkable straight.

const X0 := 40
const Z0 := 50
const BASE := 2.0


static func run(g) -> void:
	_cliff_commit(g)
	_nearer_later(g)
	_wall_replan(g)
	SmokeAttackMove._pad(g, X0, Z0, X0 + 30, Z0 + 26)


## Flat BASE over (X0..X0+30, Z0..Z0+26); plateau x+4..x+12, z+10..z+20 at BASE+2; ramp x+2..x+3.
static func _terrain(g) -> void:
	var e := []
	for z in range(Z0, Z0 + 27):
		for x in range(X0, X0 + 31):
			var h := BASE
			if z >= Z0 + 10 and z <= Z0 + 20:
				if x >= X0 + 4 and x <= X0 + 12:
					h = BASE + 2.0
				elif x >= X0 + 2 and x <= X0 + 3:
					h = BASE + 1.0
			e.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, e)
	SmokeAttackMove._clear_creeper(g, X0, Z0, X0 + 30, Z0 + 26)
	SmokeAttackMove._clear(g)
	g.hazards.nests.raiders.paths.queue.clear()


static func _setup(g, foot_x: int) -> Array:
	_terrain(g)
	var r := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(X0 + 11, Z0 + 11), false)
	r["hp"] = 1e6  # the full smoke world has turrets and creeper about; this raider must survive
	var s: Structure = g.structures.place("collector", X0 + foot_x, Z0 + 11, true)
	return [r, s]


static func _remaining(r: Dictionary) -> float:
	var st: Dictionary = r.get("_pt", {})
	if st.is_empty() or st.mode != RaiderPaths.PATH:
		return -1.0
	var p: Vector3 = r.node.position
	var here := Vector2(p.x, p.z)
	var d := 0.0
	for k in range(st.i, st.wps.size()):
		d += here.distance_to(st.wps[k])
		here = st.wps[k]
	return d


static func _cliff_commit(g) -> void:
	var rs := _setup(g, 15)
	var r: Dictionary = rs[0]
	var s: Structure = rs[1]
	var hp0 := s.hp
	var t := 0.0
	var hit_at := -1.0
	var worst := 0.0
	var rising := 0.0
	var last := -1.0
	var switched := false
	var first = null
	while t < 40.0 and r.alive and s.hp >= hp0 and not s.dead:
		SmokeTest._sim(g, 0.05)
		t += 0.05
		var cur: Dictionary = r.get("_tgt", {})
		if first == null and not cur.is_empty():
			first = cur
		elif not cur.is_empty() and not is_same(cur, first):
			switched = true
		var rem := _remaining(r)
		if rem >= 0.0 and last >= 0.0 and rem > last + 0.05:
			rising += 0.05
			worst = maxf(worst, rising)
		else:
			rising = 0.0
		last = rem
	var ok_hit: bool = s.hp < hp0 or s.dead
	SmokeTest._check("raider commit (a): reaches a cliff-foot target by the ramp, no backtracking, target kept",
		ok_hit and worst <= 0.5 and not switched and first != null,
		"(hit %s after %.1f s, rising %.2f s, switched %s)" % [ok_hit, t, worst, switched])
	SmokeTest._check("raider commit (d): exactly one search for the commit (a)", int(r.get("_searches", 0)) == 1,
		"(%d searches)" % (int(r.get("_searches", 0))))
	_end(g, r, [s])


static func _nearer_later(g) -> void:
	var rs := _setup(g, 15)
	var r: Dictionary = rs[0]
	var a: Structure = rs[1]
	SmokeTest._sim(g, 1.0)
	var b: Structure = g.structures.place("collector", X0 + 13, Z0 + 11, true)  # nearer, at the cliff foot
	var t := 0.0
	var kept := true
	var took_b := false
	while t < 50.0 and r.alive and not took_b:
		SmokeTest._sim(g, 0.05)
		t += 0.05
		var cur: Dictionary = r.get("_tgt", {})
		if cur.is_empty():
			continue
		if (not a.dead) and cur.get("struct") == b:
			kept = false
		if a.dead and cur.get("struct") == b:
			took_b = true
	SmokeTest._check("raider commit (b): a nearer structure does not steal the target until the first dies",
		kept and took_b and a.dead, "(kept %s, took B %s, A alive %s, %.1f s)" % [kept, took_b, (not a.dead), t])
	SmokeTest._check("raider commit (d): one search per commit (b)", int(r.get("_searches", 0)) == 1,
		"(%d searches)" % (int(r.get("_searches", 0))))
	_end(g, r, [a, b])


static func _wall_replan(g) -> void:
	var rs := _setup(g, 15)
	var r: Dictionary = rs[0]
	var s: Structure = rs[1]
	var hp0 := s.hp
	var t := 0.0
	var walled := false
	while t < 60.0 and r.alive and not s.dead and s.hp >= hp0:
		SmokeTest._sim(g, 0.05)
		t += 0.05
		var p: Vector3 = r.node.position
		if not walled and p.x < (X0 + 4) * Config.CELL and p.y < (BASE + 1.5) * Config.LEVEL_H:
			walled = true  # down the ramp: wall off the south corridor it is following
			var cells := []
			for z in range(Z0, Z0 + 10):
				for x in range(X0 + 6, X0 + 8):
					cells.append(Vector2i(x, z))
			TerrainEdit.raise(g.surface, cells, 3.0)
	var arrived: bool = s.hp < hp0 or s.dead
	SmokeTest._check("raider commit (c): a wall across the path causes one re-plan, then it arrives",
		walled and arrived and int(r.get("_searches", 0)) == 2,
		"(walled %s, arrived %s, raider alive %s, struct dead %s, %d searches, %.1f s)" % [walled, arrived, r.alive, s.dead, int(r.get("_searches", 0)), t])
	_end(g, r, [s])


static func _end(g, r: Dictionary, structs: Array) -> void:
	for s in structs:
		if not s.dead:
			g.structures.remove(s)
	if r.alive:
		g.hazards.nests.raiders.kill(r)
