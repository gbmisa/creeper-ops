class_name RangeTestBots
## Bot checks for `--range-test`: navmesh, line of sight, hearing, brain transitions, warm-up accuracy,
## shooting the player, player death / respawn. Bots run with physics_process off and are stepped by hand.

static var t: RangeTest
static var house: KillHouse
static var player: TacticalPlayer


static func run(test: RangeTest) -> void:
	t = test
	BotNoise.reset()
	house = KillHouse.new()
	t.add_child(house)
	house.build()
	house.bake()
	player = TacticalPlayer.new()
	player.input = InputState.new()
	t.add_child(player)
	t.add_child(player.input)
	for i in 8:  # the navigation map syncs every other physics frame
		await t.get_tree().physics_frame
	_pure()
	_nav()
	_loadout()
	_los()
	_hearing()
	_cover_heal()
	await _combat()
	await RangeTestRoster.run(t, house, player)
	await RangeTestBotMesh.run(t, house, player)


static func _bot(local: Vector3, yaw_deg := 0.0, name := "Test") -> ScavBot:
	var b := ScavBot.new()
	b.setup(player, t.bal, house, name, 0)
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = house.to_global(local)
	b.rotation_degrees.y = yaw_deg
	return b


static func _pure() -> void:
	var e0 := BotBrain.aim_error(0.0)
	var e3 := BotBrain.aim_error(BotBrain.AIM_WARM)
	t.check("bot aim error shrinks with time on target", e0 > e3 * 4.0 and BotBrain.aim_error(1.5) < e0 and BotBrain.aim_error(1.5) > e3, "%f %f" % [e0, e3])
	var near := BotPerception.reaction_delay(5.0, false, 0.5)
	var far := BotPerception.reaction_delay(100.0, false, 0.5)
	var still := BotPerception.reaction_delay(5.0, true, 0.5)
	t.check("reaction delay: longer far away and when the target is still", far > near and still > near and BotPerception.reaction_delay(1.0, false, 0.0) >= 0.35, "%f %f %f" % [near, far, still])
	var s := BotBrain.new()
	var seq := [
		[{"noise": true}, 0.1, "Investigate"],
		[{"aware": true, "seeing": true}, 0.1, "Engage"],
		[{"aware": true, "seeing": true, "hurt": true, "hp": 0.6, "cover": true}, 0.1, "TakeCover"],
		[{"arrived": true, "hp": 0.4, "seeing": false}, 0.1, "Heal"],
		[{"hp": 0.4}, 5.2, "Search"],
		[{"arrived": true}, 4.5, "Patrol"],
		[{"ally_engaged": true, "has_last": true}, 0.1, "Flank"],
		[{"aware": true, "seeing": true}, 0.1, "Engage"],
		[{"seeing": false, "since_seen": 3.0, "ally_flank": true}, 0.1, "Suppress"],
	]
	var ok := true
	var why := ""
	for row in seq:
		s.update(row[1], (row[0] as Dictionary).duplicate())
		if s.state != row[2]:
			ok = false
			why = "expected %s got %s" % [row[2], s.state]
			break
	t.check("brain transitions on a scripted sequence (Patrol..Suppress)", ok, why)
	t.check("engage -> TakeCover also when reloading", BotBrain.next("Engage", {"reloading": true, "cover": true}) == "TakeCover")
	t.check("no cover available -> stays in Engage", BotBrain.next("Engage", {"reloading": true, "cover": false, "seeing": true}) == "Engage")


static func _nav() -> void:
	var map := house.region.get_navigation_map()
	var a := house.to_global(Vector3(-20, 0, 0))
	var b := house.to_global(Vector3(10, 0, 8))
	var path := NavigationServer3D.map_get_path(map, a, b, true)
	var len := 0.0
	for i in range(1, path.size()):
		len += path[i].distance_to(path[i - 1])
	var ok := path.size() > 2 and path[path.size() - 1].distance_to(b) < 1.0 and len > a.distance_to(b) * 1.05
	t.check("navmesh routes through the doorways to the far room", ok, "points %d len %.1f" % [path.size(), len])


static func _loadout() -> void:
	var b := _bot(Vector3(10, 0, 8))
	t.check("scav carries an AK-47 with PS ammo", b.gun.def["id"] == "ak47" and b.gun.loaded_ammo() == "762_ps")
	t.check("scav wears a class 2 vest (thorax + stomach)", b.body.armor.has("thorax") and b.body.armor.has("stomach") and b.body.armor["thorax"]["id"] == "vest2")
	b.queue_free()


static func _los() -> void:
	var space := house.get_world_3d().direct_space_state
	var eye := house.to_global(Vector3(2, 1.6, -2))
	t.check("LOS blocked by the brick wall", not BotPerception.los(space, eye, [house.to_global(Vector3(8, 1.6, -2))]))
	var eye2 := house.to_global(Vector3(2, 1.6, 3.8))
	t.check("LOS clear through the doorway", BotPerception.los(space, eye2, [house.to_global(Vector3(8, 1.6, 3.8))]))
	var bot := _bot(Vector3(2, 0, -2), -90.0)
	player.global_position = house.to_global(Vector3(8, 0, -2))
	var rng := RandomNumberGenerator.new()
	for i in 90:
		bot._sense(1.0 / 30.0)
	t.check("bot does not see the player behind a brick wall", not bot.percept.seeing and not bot.percept.aware)
	bot.global_position = house.to_global(Vector3(2, 0, 3.8))
	player.global_position = house.to_global(Vector3(8, 0, 3.8))
	for i in 90:
		bot._sense(1.0 / 30.0)
	t.check("bot sees the player through the doorway after the reaction delay", bot.percept.aware and bot.percept.seeing)
	bot.rotation_degrees.y = 90.0  # facing away
	bot.percept.aware = false
	bot.percept.react_left = -1.0
	for i in 90:
		bot._sense(1.0 / 30.0)
	t.check("bot does not see the player outside its 110 degree view cone", not bot.percept.seeing)
	bot.queue_free()
	player.global_position = house.to_global(Vector3(-30, 0, 0))
	rng.randomize()


static func _hearing() -> void:
	var b := _bot(Vector3(-10, 0, 8))
	t.check("scav starts on Patrol", b.brain.state == "Patrol")
	BotNoise.emit(b.global_position + Vector3(0, 0, 100), BotNoise.SHOT_R, "shot", player)
	b.think(0.03)
	t.check("a shot 100 m away triggers Investigate", b.brain.state == "Investigate")
	var c := _bot(Vector3(-10, 0, 8), 0.0, "Test2")
	BotNoise.emit(c.global_position + Vector3(0, 0, 30), BotNoise.step_radius(false, false), "step", player)
	c.think(0.03)
	t.check("walking footsteps 30 m away are not heard", c.brain.state == "Patrol")
	BotNoise.emit(c.global_position + Vector3(0, 0, 15), BotNoise.step_radius(true, false), "step", player)
	c.think(0.03)
	t.check("sprint footsteps 15 m away are heard", c.brain.state == "Investigate")
	b.queue_free()
	c.queue_free()


static func _cover_heal() -> void:
	var b := _bot(Vector3(-9, 0, -8))
	b.percept.last_known = house.to_global(Vector3(-14, 0, -4))
	b.percept.has_last = true
	b._find_cover()
	var ok := b.has_cover and b.covers.has(b.cover_pos)
	if ok:
		var space := house.get_world_3d().direct_space_state
		ok = not BotPerception.los(space, b.cover_pos + Vector3(0, 0.9, 0), [b.percept.last_known + Vector3(0, 1.4, 0)])
	t.check("bot picks a cover marker that breaks LOS", ok)
	b.brain.state = "TakeCover"
	b.brain.t = 2.0
	var before := b.body.total_frac()
	for z in BodyHealth.ZONES:
		b.body.hp[z] *= 0.3
	var low := b.body.total_frac()
	var over := {"arrived": true, "seeing": false, "aware": false, "reloading": false, "noise": false}
	b.think(0.03, over)
	t.check("low HP in cover triggers Heal", b.brain.state == "Heal", b.brain.state)
	for i in 55:
		b.think(0.1, over)
	t.check("Heal ends after 5 s with more HP, then Search", b.brain.state == "Search" and b.body.total_frac() > low + 0.1 and before > low, "%s %f" % [b.brain.state, b.body.total_frac()])
	b.queue_free()


static func _combat() -> void:
	var hits := []
	var cues := []
	t.bal.body_hit.connect(func(r):
		var o: Object = r.get("owner")
		if o is TacticalPlayer or o is ScavBot:
			o.on_hit(r)
		if o is TacticalPlayer:
			hits.append(r))
	player.hit_taken.connect(func(from, _r): cues.append(from))
	var bot := _bot(Vector3(2, 0, 3.8), -90.0)
	var states := []
	bot.state_changed.connect(func(_b, _f, to): states.append(to))
	player.global_position = house.to_global(Vector3(8, 0, 3.8))
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	for i in 900:
		bot.think(1.0 / 60.0)
		t.bal.step(1.0 / 60.0)
		player.body.tick(0.0)
		if player.body.dead:
			break
	t.check("bot detects, engages and shoots the player", "Engage" in states and not hits.is_empty(), str(states))
	t.check("player hit raises a damage-direction cue and lowers body HP", not cues.is_empty() and player.body.total_frac() < 1.0)
	player.body.hit("head", 999.0)
	player.tick_body(0.1)
	t.check("player death disables movement, then respawns with full health", player.dead_t > 0.0 and not player.enabled)
	player.tick_body(4.0)
	t.check("respawn restores health and control", player.enabled and player.body.alive() and is_equal_approx(player.body.total_frac(), 1.0))
	bot.queue_free()
