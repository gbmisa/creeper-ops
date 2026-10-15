class_name RangeTestRoster
## Roster checks for `--range-test`: each BotDefs row spawns with the right gun / armor, marksman sight, wind-up glint,
## relocation, shotgunner closing in, boss followers staying near. Reuses the kill house and player from RangeTestBots.

static var t: RangeTest
static var session: RangeSession


static func run(test: RangeTest, s: RangeSession, house: Node3D, player: TacticalPlayer) -> void:
	t = test
	session = s
	_rows(house, player)
	_marksman(house, player)
	await _shotgunner(house, player)
	await _boss(house, player)
	await RangeTestSkirmish.run(t, session, player)


static func make(s: RangeSession, house: Node3D, player: TacticalPlayer, kind: String, local: Vector3, yaw := 0.0, route: Array[Vector3] = []) -> ScavBot:
	var b := ScavBot.new()
	b.setup(s, t.bal, house, kind, 0, kind, route)
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = house.to_global(local)
	b.rotation_degrees.y = yaw
	return b


static func _rows(house: Node3D, player: TacticalPlayer) -> void:
	var ok := true
	var why := ""
	for k in BotDefs.ORDER:
		var b := make(session, house, player, k, Vector3(-10, 0, 8))
		var d := BotDefs.of(k)
		if b.gun.def["id"] != d["gun"]:
			ok = false
			why += " %s gun %s" % [k, b.gun.def["id"]]
		for a in d["armor"]:
			for z in ArmorDefs.of(a)["zones"]:
				if not b.body.armor.has(z) or b.body.armor[z]["id"] != a and not (b.body.armor[z]["id"] in d["armor"]):
					ok = false
					why += " %s armor %s" % [k, z]
		if d["armor"].is_empty() and not b.body.armor.is_empty():
			ok = false
			why += " %s should be unarmored" % k
		b.queue_free()
	t.check("each roster row spawns with its gun and armor", ok, why)
	var boss := BotDefs.of("boss")
	t.check("boss: P90, class 4 plates + helmet, 2 rifleman followers, no extra HP",
		boss["gun"] == "p90" and "plate4" in boss["armor"] and "helmet3" in boss["armor"] and boss["followers"] == 2 and not boss.has("hp"))
	var r := BotDefs.of("rifleman")
	t.check("rifleman row is the original Scav numbers", r["gun"] == "ak47" and r["armor"] == ["vest2"] and r["speed"] == 1.0 and r["sight"] == 120.0 \
		and r["hold"] == 30.0 and r["cd"] == [0.45, 0.9] and r["aim_mult"] == 1.0 and r["aim_far"] == 0.0)
	t.check("pistol runs 15% faster, engages under 20 m, flanks eagerly", BotDefs.of("pistol")["speed"] == 1.15 and BotDefs.of("pistol")["fire"] == 20.0 and BotDefs.of("pistol")["flank_eager"])
	t.check("pistol losing sight goes to Flank, rifleman to Search",
		BotBrain.next("Engage", {"seeing": false, "since_seen": 3.0, "has_last": true, "flank_eager": true}) == "Flank" \
		and BotBrain.next("Engage", {"seeing": false, "since_seen": 3.0, "has_last": true}) == "Search")


static func _marksman(house: Node3D, player: TacticalPlayer) -> void:
	var spots: Array[Vector3] = [house.to_global(Vector3(-10, 0, 8)), house.to_global(Vector3(-10, 0, -8))]
	var m := make(session, house, player, "marksman", Vector3(-10, 0, 8), 0.0, spots)
	var r := make(session, house, player, "rifleman", Vector3(-10, 0, 8))
	t.check("marksman sight range is longer than a rifleman's (>= 120 m)", m.percept.range_m > r.percept.range_m and m.percept.range_m >= 120.0)
	var eye := Vector3.ZERO
	t.check("marksman sees a target at 150 m, rifleman does not", BotPerception.in_view(eye, Vector3.FORWARD, Vector3(0, 0, -150), m.percept.range_m) \
		and not BotPerception.in_view(eye, Vector3.FORWARD, Vector3(0, 0, -150), r.percept.range_m))
	var pt := m.global_position + Vector3(0, 1.3, -40)
	var before := m.gun.rounds_total()
	m.cd = 0.0
	BotShooting.fire(m, pt)
	t.check("marksman shows a scope glint first and does not fire yet", m.mesh.scope_glint.visible and m.gun.rounds_total() == before)
	m.wind = 0.0
	BotShooting.fire(m, pt)
	t.check("marksman fires after the wind-up, glint off", m.gun.rounds_total() == before - 1 and not m.mesh.scope_glint.visible and m.shots_since == 1)
	for i in 2:
		m.gun.release()
		m.gun.update(5.0)
		m.cd = 0.0
		m.wind = 0.0
		BotShooting.fire(m, pt)
		m.wind = 0.0
		BotShooting.fire(m, pt)
	t.check("marksman relocates to another overwatch spot after 2 shots", m.shots_since < 2 and m.reloc_t > 0.0 and m.patrol_i == 1 or m.patrol_i == 0 and m.reloc_t > 0.0, "i %d reloc %f" % [m.patrol_i, m.reloc_t])
	m.reloc_t = 0.0
	var i0 := m.patrol_i
	m.on_hit({})
	t.check("marksman relocates when hit", m.patrol_i != i0 and m.reloc_t > 0.0)
	m.queue_free()
	r.queue_free()


static func _shotgunner(house: Node3D, player: TacticalPlayer) -> void:
	player.god = true
	player.global_position = house.to_global(Vector3(14, 0, 3.8))
	var sg := make(session, house, player, "shotgunner", Vector3(-3, 0, 3.8), -90.0)
	var rf := make(session, house, player, "rifleman", Vector3(-3, 0, 3.8), -90.0)
	sg.percept.alert(player.global_position)
	rf.percept.alert(player.global_position)
	var start := sg.global_position.distance_to(player.global_position)
	for i in 420:
		for b in [sg, rf]:
			b.think(1.0 / 60.0)
			b._move(1.0 / 60.0)
		t.bal.step(1.0 / 60.0)
		if player.body.dead:
			player.body.reset()
	var d_sg := sg._flat(sg.global_position - player.global_position).length()
	var d_rf := rf._flat(rf.global_position - player.global_position).length()
	t.check("shotgunner closes to under 10 m while the rifleman holds", d_sg < 10.0 and d_rf > 12.0, "sg %.1f rf %.1f from %.1f" % [d_sg, d_rf, start])
	player.god = false
	sg.queue_free()
	rf.queue_free()


static func _boss(house: Node3D, player: TacticalPlayer) -> void:
	player.global_position = house.to_global(Vector3(-30, 0, 0))
	var boss := make(session, house, player, "boss", Vector3(-10, 0, -8))
	var fs: Array[ScavBot] = []
	for i in BotDefs.of("boss")["followers"]:
		var f := make(session, house, player, "rifleman", Vector3(-10 + i, 0, -9))
		f.leader = boss
		fs.append(f)
	for i in 900:
		for b in [boss] + fs:
			b.think(1.0 / 60.0)
			b._move(1.0 / 60.0)
	var far := 0.0
	for f in fs:
		far = maxf(far, f.global_position.distance_to(boss.global_position))
	t.check("boss followers stay within 15 m while he patrols", far < BotDefs.FOLLOWER_LEASH and boss.global_position.distance_to(house.to_global(Vector3(-10, 0, -8))) > 3.0, "far %.1f" % far)
	boss.queue_free()
	for f in fs:
		f.queue_free()
