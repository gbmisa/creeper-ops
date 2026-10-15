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
