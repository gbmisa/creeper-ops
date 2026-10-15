class_name RangeTestSkirmish
## Skirmish checks for `--range-test`: map builds, navmesh path spawn -> extract / upstairs / tower, roster counts,
## extract timer wins, end screen, loot, map switch default.

static func run(t: RangeTest, session: RangeSession, player: TacticalPlayer) -> void:
	t.check("RangeMaps defaults to the Firing Range", session.maps.selected == "range")
	var game := SkirmishGame.new()
	t.add_child(game)
	game.build_world()
	var rack := RangeRack.new()
	t.add_child(rack)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	weapons.setup(player, player.input, t.bal, rack, session)
	var log := RangeHitLog.new()
	t.add_child(log)
	game.start(player, weapons, t.bal, log, t, session)
	for i in 8:
		await t.get_tree().physics_frame
	var lay := game.layout
	t.check("skirmish builds: 5 buildings' worth of cover, loot crates and a patrol", lay.covers.size() > 60 and lay.loot_crates.size() >= 5 and SkirmishData.BUILDINGS.size() >= 5)
	var map := lay.region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	for i in 30:
		await t.get_tree().physics_frame
	t.check("navmesh path spawn -> extract", _reaches(map, SkirmishData.SPAWN, SkirmishData.EXTRACT))
	t.check("navmesh path up the hotel stairs to the second floor", _reaches(map, SkirmishData.SPAWN, SkirmishData.SPOTS[1], 0.8))
	t.check("navmesh path up the tower ramp to the platform", _reaches(map, SkirmishData.SPAWN, SkirmishData.SPOTS[0], 0.8))
	var kinds := {}
	for b in game.bots:
		kinds[b.kind] = kinds.get(b.kind, 0) + 1
	t.check("skirmish roster: 12 enemies (7 rifleman incl. 2 guards, 2 pistol, shotgunner, marksman, boss)",
		game.bots.size() == 12 and kinds.get("rifleman", 0) == 7 and kinds.get("pistol", 0) == 2 and kinds.get("shotgunner", 0) == 1 \
		and kinds.get("marksman", 0) == 1 and kinds.get("boss", 0) == 1, str(kinds))
	var boss: ScavBot
	for b in game.bots:
		if b.kind == "boss":
			boss = b
	var guards := 0
	for b in game.bots:
		if b.leader == boss and boss != null:
			guards += 1
	t.check("boss has 2 followers", guards == 2)
	var m: ScavBot
	for b in game.bots:
		if b.kind == "marksman":
			m = b
	t.check("marksman starts on the tower with two overwatch spots", m.global_position.y > 5.5 and m.patrol.size() == 2)
	for b in game.bots:
		b.queue_free()
	game.bots.clear()
	var out := SkirmishData.EXTRACT + Vector3(SkirmishData.EXTRACT_R + 2.0, 0, 0)
	var inside := SkirmishData.EXTRACT + Vector3(1, 0, 0)
	t.check("extract timer: outside the zone does not count", not game.tick_extract(20.0, out) and game.progress == 0.0)
	game.tick_extract(7.9, inside)
	var early := game.progress < SkirmishData.EXTRACT_TIME
	game.tick_extract(1.0, out)
	t.check("extract timer resets when leaving the zone", early and game.progress == 0.0)
	game.tick_extract(7.9, inside)
	t.check("extract timer wins after 8 s inside", game.tick_extract(0.2, inside))
	game.kills = 3
	game.finish(true)
	t.check("finish(true): EXTRACTED screen, player frozen", game.over and game.won and game.end_screen != null and not player.enabled)
	player.enabled = true
	var crate := {"pos": Vector3.ZERO, "loot": ["meds"], "taken": false}
	for z in BodyHealth.ZONES:
		player.body.hp[z] *= 0.4
	var before := player.body.total_frac()
	game.loot(crate)
	t.check("loot crate: meds heal once and the crate is taken", player.body.total_frac() > before and crate["taken"])
	game.end_screen.queue_free()
	game.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func _reaches(map: RID, from: Vector3, to: Vector3, tol := 1.2) -> bool:
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	return path.size() > 1 and path[path.size() - 1].distance_to(to) < tol
