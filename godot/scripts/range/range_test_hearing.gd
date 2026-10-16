class_name RangeTestHearing
## F87: a bot facing away hears a gunshot behind it: it turns to the shot, goes alert, heads for cover hidden from
## the shot, and reacts faster than an unalerted bot. Footsteps still only send it to investigate.

const O := Vector3(1000, 0, -1000)


static func run(t: RangeTest) -> void:
	var session := RangeSession.new(11)
	session.noise.reset()
	var floor_body := t._wall(O + Vector3(0, -0.5, 0), Vector3(60, 1, 60), "concrete", 0.5)
	var block := t._wall(O + Vector3(4, 0.75, 6), Vector3(3, 1.5, 0.6), "concrete", 0.6)
	var stub := RangeTestNoFire.Stub.new()
	stub.covers = [O + Vector3(4, 0, 7.2)]  # behind the block, seen from the shot at z = -25
	t.add_child(stub)
	var kind: String = BotDefs.ORDER[0]
	var bot := ScavBot.new()
	bot.setup(session, t.bal, stub, kind, 0, kind)
	t.add_child(bot)
	bot.set_physics_process(false)
	bot.global_position = O
	bot.rotation.y = PI  # facing +z, away from the shot
	for i in 3:
		await t.get_tree().physics_frame
	var shot := O + Vector3(0, 1.5, -25)
	session.noise.emit(O + Vector3(0, 0, 25), BotNoise.step_radius(false, false), "step", null)  # out of earshot
	t.check("hearing: a far footstep is not heard", not bot.percept.noise_new)
	session.noise.emit(shot, BotNoise.SHOT_R, "shot", null)
	var fwd := -bot.global_basis.z
	fwd.y = 0.0
	t.check("hearing: a shot behind turns the bot to face it", rad_to_deg(fwd.angle_to(Vector3(0, 0, -1))) < 5.0)
	t.check("hearing: a shot makes the bot alert", bot.percept.alerted())
	bot.think(1.0 / 60.0)
	t.check("hearing: alert bot takes cover from the shot (%s)" % bot.brain.state, bot.brain.state == BotBrain.COVER and bot.cover_pos.distance_to(stub.covers[0]) < 0.01)
	var calm := BotPerception.new()
	var alert := BotPerception.new()
	alert.alert_t = 10.0
	var rng := RandomNumberGenerator.new()
	var space := bot.get_world_3d().direct_space_state
	var pts := [O + Vector3(0, 1.6, -10), O + Vector3(0, 1.3, -10)]
	rng.seed = 5
	calm.update(0.0, O + Vector3(0, 1.6, 0), Vector3(0, 0, -1), space, pts, false, rng)
	rng.seed = 5
	alert.update(0.0, O + Vector3(0, 1.6, 0), Vector3(0, 0, -1), space, pts, false, rng)
	t.check("hearing: an alert bot's sight reaction is faster (%.2f < %.2f)" % [alert.react_left, calm.react_left], alert.react_left > 0.0 and alert.react_left < calm.react_left * 0.5)
	bot.queue_free()
	stub.queue_free()
	block.queue_free()
	floor_body.queue_free()
