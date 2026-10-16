class_name RangeTestNoFire
## BOT-P0: every roster kind must fire at a player it can see and hit. Cases: open 15 m, open 40 m, crouched behind a
## 1.1 m barrier (head up), standing behind it. Logs every early return of BotShooting.fire() per kind and case.

class Stub extends Node3D:
	var covers: Array[Vector3] = []
	var patrol: Array[Vector3] = [Vector3.ZERO]

const O := Vector3(1000, 0, 1000)
const CASES := ["open15", "open40", "crouch_barrier", "stand_barrier"]
const LIMIT := 6.0
static var t: RangeTest


static func run(test: RangeTest) -> void:
	t = test
	var session := RangeSession.new(99)
	session.noise.reset()
	var root := Node3D.new()
	t.add_child(root)
	t._wall(O + Vector3(0, -0.5, 0), Vector3(300, 1, 300), "concrete", 0.5)
	var barrier := t._wall(O + Vector3(0, 0.55, -9.2), Vector3(6, 1.1, 0.3), "concrete", 0.3)
	var player := TacticalPlayer.new()
	player.input = InputState.new()
	player.session = session
	session.add_player(1, true).node = player
	t.add_child(player)
	t.add_child(player.input)
	var stub := Stub.new()
	t.add_child(stub)
	for i in 4:
		await t.get_tree().physics_frame
	BotShooting.trace_on = true
	var bad := []
	var loops := []
	for kind in BotDefs.ORDER:
		for c in CASES:
			var r := await _case(session, stub, player, kind, c)
			print("[nofire] %-10s %-14s topups=%d first=%s shots=%d seen=%.1fs state=%s %s" % [kind, c, r["topups"], r["first"], r["shots"], r["seen"], r["state"], r["trace"]])
			if int(r["topups"]) > 1:
				loops.append("%s x%d" % [kind, r["topups"]])
			if c != "stand_barrier" and r["expect"] and (r["first"] < 0.0 or r["first"] > 3.0):
				bad.append("%s/%s" % [kind, c])
	await _skirmish(session, player)
	BotShooting.trace_on = false
	t.check("every kind fires within 3 s at a visible player it can hit (open 15/40 m, crouched head over a barrier)", bad.is_empty(), str(bad))
	t.check("idle bots do not reload a full magazine over and over (8 s on Patrol, at most 1 top-up)", loops.is_empty(), str(loops))
	t.bal.shots.clear()
	player.queue_free()
	barrier.queue_free()
	stub.queue_free()
	root.queue_free()


## One bot, one scenario. `first` = seconds from becoming aware to the first shot (-1 never); `expect` = the shot is
## expected (player in the bot's `fire` range and a hit point is visible).
static func _case(session: RangeSession, stub: Stub, player: TacticalPlayer, kind: String, c: String) -> Dictionary:
	var dist := 40.0 if c == "open40" else 15.0
	var bot := ScavBot.new()
	bot.setup(session, t.bal, stub, kind, 0, kind)
	t.add_child(bot)
	bot.set_physics_process(false)
	bot.global_position = O + Vector3(0, 0, 0)
	if kind == "marksman":
		bot.reloc_t = 0.0
	var barrier := c.ends_with("barrier")
	var pz := -dist
	if barrier:
		pz = -10.0  # 0.8 m behind the barrier front face
	player.body.heal_all() if player.body.has_method("heal_all") else null
	for z in BodyHealth.ZONES:
		player.body.hp[z] = 1000.0
	player.crouching = c == "crouch_barrier"
	player._eye = TacticalPlayer.EYE_CROUCH if player.crouching else TacticalPlayer.EYE_STAND
	# settle first: 8 s on Patrol with the player out of sight, counting top-up reloads (a full mag must not reload)
	player.global_position = O + Vector3(0, 0.05, 500.0)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	var topups := 0
	var prev_t := 0.0
	for i in 480:
		bot.think(1.0 / 60.0)
		if bot.gun.busy_kind == "reload" and bot.gun.busy_t > prev_t:  # busy_t jumps up when a reload starts
			topups += 1
		prev_t = bot.gun.busy_t
	bot.cd = 0.0
	player.global_position = O + Vector3(0, 0.05, pz)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	player.global_position = O + Vector3(0, 0.05, pz)
	BotShooting.trace.clear()
	var shots := 0
	var first := -1.0
	var aware_t := -1.0
	var seen := 0.0
	var states := {}
	var head := player.eye_pos()
	var space := bot.get_world_3d().direct_space_state
	var vis_head := BotPerception.los(space, bot.eye(), [head])
	var vis_chest := BotPerception.los(space, bot.eye(), [player.global_position + Vector3(0, 0.85 if player.crouching else 1.3, 0)])
	var n := int(LIMIT * 60.0)
	for i in n:
		var before := t.bal.shots.size()
		bot.think(1.0 / 60.0)
		if bot.percept.aware and aware_t < 0.0:
			aware_t = i / 60.0
		if bot.percept.seeing:
			seen += 1.0 / 60.0
		states[bot.brain.state] = true
		if t.bal.shots.size() > before:
			shots += 1
			if first < 0.0:
				first = i / 60.0 - maxf(aware_t, 0.0)
		t.bal.shots.clear()
	var df := BotDefs.of(kind)
	var expect := (vis_head or vis_chest) and bot.eye().distance_to(player.global_position + Vector3(0, 1.3, 0)) <= float(df["fire"])
	var tr := BotShooting.trace.duplicate()
	bot.queue_free()
	return {"topups": topups, "first": snappedf(first, 0.01), "shots": shots, "seen": seen, "state": ",".join(states.keys()), "expect": expect,
		"trace": "vis(h=%s,c=%s) %s" % [vis_head, vis_chest, tr]}


## The Skirmish roster, one bot at a time: the player is put in the open in front of it (15 m, else 25 / 8 m) and the
## bot runs its AI (think, no movement) for 5 s. Logs shots per bot and fire() reasons; checks every bot fires.
static func _skirmish(session: RangeSession, player: TacticalPlayer) -> void:
	player.crouching = false
	player._eye = TacticalPlayer.EYE_STAND
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
	for i in 30:
		await t.get_tree().physics_frame
	var silent := []
	for b in game.bots:
		b.set_physics_process(false)
	for b in game.bots:
		var space := b.get_world_3d().direct_space_state
		player.global_position = O + Vector3(0, 0.05, 900.0)  # settle: let the spawn-time reload finish first
		b.set_physics_process(false)
		for i in 300:
			b.think(1.0 / 60.0)
		var placed := false
		for d in [15.0, 25.0, 8.0]:
			for k in 12:
				var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 12.0)
				var pos: Vector3 = b.global_position + dir * d
				pos.y = b.global_position.y + 0.05
				if BotPerception.los(space, b.eye(), [pos + Vector3(0, 1.3, 0), pos + Vector3(0, 1.62, 0)]):
					player.global_position = pos
					b.look_at(pos + Vector3(0, b.global_position.y - pos.y, 0), Vector3.UP)
					placed = true
					break
			if placed:
				break
		if not placed:
			print("[nofire] skirmish %s: no clear spot" % b.label_name)
			continue
		for z in BodyHealth.ZONES:
			player.body.hp[z] = 1000.0
		await t.get_tree().physics_frame
		b.set_physics_process(true)
		BotShooting.trace.clear()
		var shots := 0
		var first := -1.0
		var seen := 0.0
		for i in 300:
			var before := t.bal.shots.size()
			b.think(1.0 / 60.0)
			seen += 1.0 / 60.0 if b.percept.seeing else 0.0
			if t.bal.shots.size() > before:
				shots += 1
				if first < 0.0:
					first = i / 60.0
			t.bal.shots.clear()
		b.set_physics_process(false)
		print("[nofire] skirmish %-10s %-12s shots=%d first=%.2f seen=%.1fs state=%s %s" % [b.kind, b.label_name, shots, first, seen, b.brain.state, BotShooting.trace])
		if shots == 0:
			silent.append("%s %s" % [b.kind, b.label_name])
	t.check("every Skirmish roster bot fires within 5 s at a player standing in the open in front of it", silent.is_empty(), str(silent))
	for b in game.bots:
		b.queue_free()
	game.bots.clear()
	game.queue_free()
	weapons.queue_free()
	rack.queue_free()
	log.queue_free()
