class_name RangeTestFbb
## FB-B checks for `--range-test`: F25 prop colliders, F5 muzzle line-of-sight gate.
## (F18/F19/F26 checks live in the same file, added in phase 2.)

static var t: RangeTest
static var session: RangeSession


static func run(test: RangeTest) -> void:
	t = test
	session = RangeSession.new(777)
	session.noise.reset()
	_collider_specs()
	await _sandbag_blocks_player()
	await _f5_no_fire_through_wall()
	await _bullet_stops_on_barrel()
	_f18_spread_grows()
	await _f18_reaction_gate()
	await _f19_pause_freezes()
	_f26_fixtures()


static func _collider_specs() -> void:
	var ok := true
	var why := ""
	for id in LookPropDefs.COLLISION:
		var spec: Dictionary = LookPropDefs.COLLISION[id]
		var kind := str(spec.get("kind", ""))
		if kind != "box" and kind != "cyl":
			ok = false
			why = id + " bad kind"
		elif kind == "box" and ((spec["size"] as Vector3).x <= 0.0 or (spec["size"] as Vector3).y <= 0.0 or (spec["size"] as Vector3).z <= 0.0):
			ok = false
			why = id + " bad size"
		elif kind == "cyl" and (float(spec["radius"]) <= 0.0 or float(spec["height"]) <= 0.0):
			ok = false
			why = id + " bad radius/height"
		elif not MaterialDefs.ROWS.has(str(spec["mat"])):
			ok = false
			why = id + " unknown mat"
		elif float(spec["thick"]) <= 0.0:
			ok = false
			why = id + " bad thick"
	t.check("F25 prop collision specs are sane", ok, why)


## A sandbag collider on LAYER_WORLD blocks a walking player body.
static func _sandbag_blocks_player() -> void:
	var root := Node3D.new()
	t.add_child(root)
	LookProps.build(root, [["sandbags", 0.0, 0.0, 0.0, 1.0]], false, true)
	var sb: StaticBody3D = null
	for c in root.find_children("*", "StaticBody3D", true, false):
		sb = c
		break
	var ok := sb != null and (sb.collision_layer & TacticalConfig.LAYER_WORLD) != 0
	var shape_ok := false
	if sb != null:
		for c in sb.find_children("*", "CollisionShape3D", true, false):
			shape_ok = (c as CollisionShape3D).shape is BoxShape3D
			break
	t.check("F25 sandbag gets a StaticBody3D on LAYER_WORLD", ok and shape_ok)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	var player := TacticalPlayer.new()
	player.input = InputState.new()
	player.session = session
	session.add_player(1, true).node = player
	t.add_child(player)
	t.add_child(player.input)
	player.global_position = Vector3(0, 0.1, -2.0)
	var hit := player.move_and_collide(Vector3(0, 0, 5.0))
	t.check("F25 player cannot walk through a sandbag", hit != null)
	player.queue_free()
	root.queue_free()


static func _bot(local: Vector3, house: KillHouse, yaw_deg := 0.0) -> ScavBot:
	var b := ScavBot.new()
	b.setup(session, t.bal, house, "Fbb", 0)
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = house.to_global(local)
	b.rotation_degrees.y = yaw_deg
	# force the gun ready and the aim fully warmed up
	b.cd = 0.0
	b.percept.aware = true
	b.percept.sight_t = 99.0
	return b


## BotShooting.fire must not spawn shots when a wall blocks muzzle -> target.
static func _f5_no_fire_through_wall() -> void:
	var house := KillHouse.new()
	t.add_child(house)
	house.build()
	house.bake()
	for i in 8:
		await t.get_tree().physics_frame
	var player := TacticalPlayer.new()
	player.input = InputState.new()
	player.session = session
	session.add_player(1, true).node = player
	t.add_child(player)
	t.add_child(player.input)
	# brick wall between (2,-2) and (8,-2); clear doorway between (2,3.8) and (8,3.8)
	var bot := _bot(Vector3(2, 0, -2), house, -90.0)
	player.global_position = house.to_global(Vector3(8, 0, -2))
	var chest := player.global_position + Vector3(0, 1.3, 0)
	var n0 := t.bal.shots.size()
	BotShooting.fire(bot, chest)
	t.check("F5 bot does not fire through a wall (muzzle LOS blocked)", t.bal.shots.size() == n0)
	bot.global_position = house.to_global(Vector3(2, 0, 3.8))
	player.global_position = house.to_global(Vector3(8, 0, 3.8))
	chest = player.global_position + Vector3(0, 1.3, 0)
	bot.cd = 0.0
	n0 = t.bal.shots.size()
	BotShooting.fire(bot, chest)
	t.check("F5 bot fires when the muzzle line is clear", t.bal.shots.size() > n0)
	bot.queue_free()
	player.queue_free()
	house.queue_free()


## A rifle round fired into a barrel (drum) registers a world impact and stops.
static func _bullet_stops_on_barrel() -> void:
	var root := Node3D.new()
	t.add_child(root)
	LookProps.build(root, [["drum", 0.0, 0.0, 0.0, 1.0]], false, true)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t._impacts.clear()
	t._hits.clear()
	t.bal.spawn(Vector3(0, 0.5, -5.0), Vector3(0, 0, 1), "762_ps")
	for i in 600:
		if t.bal.shots.is_empty():
			break
		t.bal.step(1.0 / 60.0)
	var hit_drum := false
	for im in t._impacts:
		var p: Vector3 = im["pos"]
		if absf(p.x) < 0.35 and absf(p.z) < 0.35 and p.y < 1.0:
			hit_drum = true
	t.check("F25 bullet into a barrel hits the drum and stops", hit_drum and t.bal.shots.is_empty() and t._hits.is_empty(),
		"impacts %d" % t._impacts.size())
	root.queue_free()


class HouseStub extends Node3D:
	var covers: Array[Vector3] = []
	var patrol: Array[Vector3] = [Vector3.ZERO]


static func _open_bot(kind := "rifleman") -> Array:
	# Open flat ground, a player at the origin and a bot 10 m south facing it. Returns [ground, player, bot].
	var ground := StaticBody3D.new()
	ground.collision_layer = TacticalConfig.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	cs.shape = box
	ground.add_child(cs)
	ground.position = Vector3(0, -0.5, 5)
	t.add_child(ground)
	var player := TacticalPlayer.new()
	player.input = InputState.new()
	player.session = session
	session.add_player(1, true).node = player
	t.add_child(player)
	t.add_child(player.input)
	player.global_position = Vector3.ZERO
	var bot := ScavBot.new()
	bot.setup(session, t.bal, HouseStub.new(), kind, 0, kind, [])
	t.add_child(bot)
	bot.set_physics_process(false)
	bot.global_position = Vector3(0, 0.1, 10)
	bot.rotation.y = PI
	bot.rng.seed = 31337
	return [ground, player, bot]


## F18: spread grows with distance for every kind (rifleman had aim_far 0).
static func _f18_spread_grows() -> void:
	var parts: Array = _open_bot()
	var bot: ScavBot = parts[2]
	bot.percept.sight_t = 10.0   # fully warmed up: worst-case steady-state accuracy
	var s10 := BotShooting.aim_spread_deg(bot, 10.0)
	var s50 := BotShooting.aim_spread_deg(bot, 50.0)
	var s100 := BotShooting.aim_spread_deg(bot, 100.0)
	t.check("F18 aim spread grows with distance (10/50/100 m)", s50 > s10 * 1.5 and s100 >= s50,
		"%.2f %.2f %.2f deg" % [s10, s50, s100])
	for n in parts:
		(n as Node).queue_free()


## F18: no aimed shot before the reaction delay; suppressing fire (not seeing) is exempt.
static func _f18_reaction_gate() -> void:
	var parts: Array = _open_bot()
	var player: TacticalPlayer = parts[1]
	var bot: ScavBot = parts[2]
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	var chest := player.global_position + Vector3(0, 1.3, 0)
	bot.cd = 0.0
	bot.react_t = 1.0
	bot.percept.seeing = true
	bot.percept.sight_t = 0.5
	var n0 := t.bal.shots.size()
	bot.gun.fire_cd = 0.0
	bot.gun.busy_t = 0.0
	BotShooting.fire(bot, chest)
	t.check("F18 bot holds fire before its reaction delay", t.bal.shots.size() == n0)
	bot.percept.sight_t = 2.0
	bot.cd = 0.0
	bot.gun.fire_cd = 0.0
	bot.gun.busy_t = 0.0
	n0 = t.bal.shots.size()
	BotShooting.fire(bot, chest)
	t.check("F18 bot fires once the reaction delay has passed", t.bal.shots.size() > n0)
	bot.cd = 0.0
	bot.gun.fire_cd = 0.0
	bot.gun.busy_t = 0.0
	bot.percept.seeing = false   # suppressing at last-known: no reaction gate
	bot.percept.sight_t = 0.0
	n0 = t.bal.shots.size()
	BotShooting.fire(bot, chest)
	t.check("F18 suppressing fire is not gated by the reaction delay", t.bal.shots.size() > n0)
	for n in parts:
		(n as Node).queue_free()


## F19: opening the Esc menu pauses the tree; a bot mid-burst deals 0 damage over 3 s; closing resumes.
static func _f19_pause_freezes() -> void:
	var parts: Array = _open_bot()
	var player: TacticalPlayer = parts[1]
	var bot: ScavBot = parts[2]
	# _open_bot leaves the bot rotated PI (logical forward +Z, away from the player);
	# perception recomputes `seeing` from actual facing every frame, so turn it to face
	# the player (-Z toward the origin) or the brain never engages and never shoots.
	bot.rotation.y = 0.0
	bot.set_physics_process(true)   # driven by the tree, so the pause actually freezes it
	bot.percept.aware = true
	bot.percept.seeing = true
	bot.percept.sight_t = 99.0
	bot.react_t = 0.0
	bot.percept.last_known = player.global_position + Vector3(0, 1.3, 0)
	bot.brain.state = BotBrain.ENGAGE
	bot.cd = 0.0
	var on_hit := func(r):
		var o: Object = r.get("owner")
		if o is TacticalPlayer or o is ScavBot:
			o.on_hit(r)
	t.bal.body_hit.connect(on_hit)
	var menu := RangeMenu.new()
	t.add_child(menu)
	menu.setup(session)
	for i in 90:
		await t.get_tree().physics_frame
		t.bal.step(1.0 / 60.0)   # the harness runs bal with auto_step=false: advance shots manually
	var hp_before: float = player.body.total_frac()
	t.check("F19 bot bursts and damages the player while unpaused", hp_before < 1.0, "hp %.3f" % hp_before)
	menu.open()
	t.check("F19 opening the menu pauses the tree", t.get_tree().paused)
	await t.get_tree().create_timer(3.0, true, false, true).timeout
	var hp_paused: float = player.body.total_frac()
	t.check("F19 bot mid-burst deals 0 damage over 3 s while paused", is_equal_approx(hp_paused, hp_before),
		"hp %.4f -> %.4f" % [hp_before, hp_paused])
	menu.close()
	t.check("F19 closing the menu resumes the tree", not t.get_tree().paused)
	# The phase-1 burst can kill the player (head/thorax at 0 HP = dead by game rules).
	# Death also zeroes the hitbox collision layers via tick_body, so a plain body.reset()
	# is not enough: restore the hitbox layers too, then re-establish a fresh engagement.
	player.body.reset()
	for z in player.rig:
		(player.rig[z] as CollisionObject3D).collision_layer = TacticalConfig.LAYER_HITBOX
	bot.global_position = Vector3(0, 0.1, 10)
	bot.rotation.y = 0.0
	bot.brain.state = BotBrain.ENGAGE
	bot.percept.seeing = true
	bot.percept.aware = true
	bot.percept.sight_t = 99.0
	bot.react_t = 0.0
	bot.percept.last_known = player.global_position + Vector3(0, 1.3, 0)
	bot.cd = 0.0
	for i in 90:
		await t.get_tree().physics_frame
		t.bal.step(1.0 / 60.0)   # the harness runs bal with auto_step=false: advance shots manually
	var hp_after: float = player.body.total_frac()
	t.check("F19 damage resumes after the menu closes", hp_after < 1.0, "hp %.4f" % hp_after)
	t.bal.body_hit.disconnect(on_hit)
	for n in parts:
		(n as Node).queue_free()
	menu.queue_free()


## F26: interiors get real fixtures (mesh + light, shadows off), not a bare floating light.
static func _f26_fixtures() -> void:
	var layout := SkirmishLayout.new()
	layout._ceiling_light(0.0, 3.0, 0.0)
	var mesh_ok := false
	var light_ok := false
	for c in layout.get_children():
		if c is MeshInstance3D:
			mesh_ok = true
		if c is OmniLight3D and not (c as OmniLight3D).shadow_enabled:
			light_ok = true
	t.check("F26 ceiling fixture is a mesh plus an OmniLight3D with shadows off", mesh_ok and light_ok)
	layout.queue_free()
