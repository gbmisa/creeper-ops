class_name SmokeCastles2bGuards
## Stage 21b P6: wall patrols and the hall guard on hostile concentric castles. Two
## raiders walk the outer wall walk (waypoints from the outer segments + tower doors),
## a Warden stands in the keep hall beside the crown; both fight with the normal
## raider combat AI. They respawn on the garrison timer and are gone after capture.
## Uses the Level 2 capture rig (fresh world); the Stage 7 garrison checks run in the
## full suite.


static func run(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var v: Dictionary = castles.views[c.id]
	var grid: Grid = r.w.grid
	c.garrison_timer = 0.0  # the rig disables it; the patrols need it
	castles.update(0.1)  # first hostile tick: CastlePatrols.ensure spawns the guards
	_spawned(v, lay, grid)
	_patrol_walk(castles, v, lay, grid)
	_hall_guard(v, lay, grid)
	_respawn(castles, v, lay)
	_capture_clears(castles, c, v, lay, r.w)
	r.w.queue_free()


static func _spawned(v: Dictionary, lay: Dictionary, grid: Grid) -> void:
	var ok := v.has("patrol")
	var p: Dictionary = v.get("patrol", {})
	ok = ok and (p.get("wall", []) as Array).size() == 2
	var walk := int(lay.wall_top)
	for pr in p.get("wall", []):
		ok = ok and pr.alive and pr.has("wall_patrol")
		var cell := grid.world_to_cell(pr.node.position.x, pr.node.position.z)
		ok = ok and grid.height_at(cell.x, cell.y) == walk
	var w: Dictionary = p.get("warden", {})
	ok = ok and w.alive and str(w.tier.name) == "Warden" and w.has("hall_guard")
	SmokeTest._check("castles2b guards: 2 wall patrols and a Warden spawn on a hostile castle", ok)
	var route: Array = p.get("route", [])
	var route_ok := not route.is_empty() and route.all(
		func(cell): return grid.height_at(cell.x, cell.y) == walk)
	SmokeTest._check("castles2b guards: the patrol route is all outer wall walk", route_ok,
		"(%d cells)" % route.size())


static func _patrol_walk(castles: Strongholds, v: Dictionary, lay: Dictionary, grid: Grid) -> void:
	var raiders: Raiders = castles.nests.raiders
	var walk := int(lay.wall_top)
	var wall: Array = (v.patrol as Dictionary).wall
	var seen: Array = []
	for i in wall.size():
		seen.append({})
	var on_walk := true
	for i in 600:  # 60 s of sim, no prey: pure patrol
		raiders.update(0.1, [], [])
		if i % 10 != 0:
			continue
		for k in wall.size():
			var cell := grid.world_to_cell(
				(wall[k] as Dictionary).node.position.x, (wall[k] as Dictionary).node.position.z)
			(seen[k] as Dictionary)[cell] = true
			if grid.height_at(cell.x, cell.y) != walk:
				on_walk = false
	SmokeTest._check("castles2b guards: patrols stay on the wall walk for 60 s", on_walk)
	var moved := seen.any(func(s): return (s as Dictionary).size() >= 3)
	SmokeTest._check("castles2b guards: the patrols walk the route (not stuck)", moved)


static func _hall_guard(v: Dictionary, lay: Dictionary, grid: Grid) -> void:
	var w: Dictionary = (v.patrol as Dictionary).warden
	var wcell := grid.world_to_cell(w.node.position.x, w.node.position.z)
	var crown := v.get("crown") as Node3D
	var ccell := grid.world_to_cell(crown.position.x, crown.position.z)
	var in_hall: bool = (lay.zones.keep.cells as Array).has(wcell)
	var beside := Vector2(wcell - ccell).length() <= 4.0
	SmokeTest._check("castles2b guards: the Warden stands in the keep hall beside the crown",
		w.alive and in_hall and beside, "(hall %s, crown %s)" % [wcell, ccell])


static func _respawn(castles: Strongholds, v: Dictionary, lay: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	var p: Dictionary = v.patrol
	raiders.kill((p.wall as Array)[0])
	raiders.kill(p.warden)
	CastlePatrols.on_garrison_tick(castles, {}, lay, v)
	var q: Dictionary = v.patrol
	SmokeTest._check("castles2b guards: patrols and the Warden respawn on the garrison timer",
		(q.wall as Array).size() == 2 and (q.wall as Array).all(func(pr): return pr.alive)
		and (q.warden as Dictionary).alive and str((q.warden as Dictionary).tier.name) == "Warden")


static func _capture_clears(castles: Strongholds, c: Dictionary, v: Dictionary, lay: Dictionary, w: World) -> void:
	var p: Dictionary = v.patrol
	var dead := []
	dead.append_array(p.wall)
	dead.append(p.warden)
	StrongholdRules.to_held(w, c, lay)
	CastlePatrols.clear(castles, v)  # the game calls this on the capturing -> held transition
	SmokeTest._check("castles2b guards: the hall guard and patrols are gone after capture",
		not v.has("patrol") and dead.all(func(pr): return not pr.alive))
