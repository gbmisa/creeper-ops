class_name RangeTestContact
## F97 phase A: contact memory. Heard shots give a fuzzy contact (never the exact spot), lost sight
## grows the error, the contact is forgotten after CONTACT_FORGET, and the bot then holds a
## defensive post until calm instead of patrolling straight back.


static func run(t: RangeTest) -> void:
	_unit(t)
	await _integration(t)


static func _unit(t: RangeTest) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var c := BotContact.new()
	c.shot(Vector3(100, 0, 0), 100.0, rng)
	t.check("contact: heard shot at 100 m has 15 m error", is_equal_approx(c.err, 15.0), str(c.err))
	var off := c.pos.distance_to(Vector3(100, 0, 0))
	t.check("contact: shot position is offset, never exact", off > 0.001 and off <= 15.0, str(off))
	t.check("contact: shot source recorded", c.source == BotContact.SRC_SHOT and c.has())
	c.shot(Vector3.ZERO, 10.0, rng)
	t.check("contact: heard-shot error clamps to 2 m close up", is_equal_approx(c.err, 2.0), str(c.err))
	c.sight(Vector3(50, 0, 0))
	t.check("contact: seen contact is exact", c.err == 0.0 and c.pos == Vector3(50, 0, 0))
	c.lose_sight()
	c.tick(3.0)
	t.check("contact: lost-sight error grows at 3 m/s", is_equal_approx(c.err, 9.0), str(c.err))
	c.tick(30.0)
	t.check("contact: lost-sight error caps at 25 m", is_equal_approx(c.err, 25.0), str(c.err))
	c.sight(Vector3(60, 0, 0))
	t.check("contact: re-seeing resets error and age", c.err == 0.0 and c.age == 0.0)
	c.lose_sight()
	c.tick(BotTacticsDefs.CONTACT_FORGET)
	t.check("contact: forgotten after CONTACT_FORGET with no new info", c.forgotten and not c.has())
	c.shot(Vector3.ZERO, 50.0, rng)
	t.check("contact: new info after forgetting revives it", c.has() and c.age == 0.0)
	t.check("brain: forgotten contact in Search -> Hold", BotBrain.next(BotBrain.SEARCH, {"forgotten": true}) == BotBrain.HOLD)
	t.check("brain: Hold, calm and arrived -> Patrol", BotBrain.next(BotBrain.HOLD, {"arrived": true, "calm": true}) == BotBrain.PATROL)
	t.check("brain: Hold, aware -> Engage", BotBrain.next(BotBrain.HOLD, {"aware": true}) == BotBrain.ENGAGE)
	t.check("brain: Hold under fire -> TakeCover", BotBrain.next(BotBrain.HOLD, {"shot": true, "cover": true}) == BotBrain.COVER)
	t.check("brain: Hold hears noise -> Investigate", BotBrain.next(BotBrain.HOLD, {"noise": true}) == BotBrain.INVESTIGATE)


static func _integration(t: RangeTest) -> void:
	var o := Vector3(2000, 0, 2000)
	var session := RangeSession.new(31)
	session.noise.reset()
	var floor_body := t._wall(o + Vector3(0, -0.5, 0), Vector3(60, 1, 60), "concrete", 0.5)
	var wall := t._wall(o + Vector3(0, 2, -10), Vector3(30, 4, 1), "concrete", 0.5)
	var stub := RangeTestNoFire.Stub.new()
	stub.covers = [o + Vector3(5, 0, 5), o + Vector3(-6, 0, 3)]
	t.add_child(stub)
	var bot := ScavBot.new()
	bot.setup(session, t.bal, stub, "rifleman", 0, "rifleman")
	t.add_child(bot)
	bot.set_physics_process(false)
	bot.global_position = o
	for i in 3:
		await t.get_tree().physics_frame
	var shot := o + Vector3(0, 1.5, -30)
	session.noise.emit(shot, BotNoise.SHOT_R, "shot", null)
	bot.think(0.03)
	t.check("contact: bot takes cover from a heard shot (%s)" % bot.brain.state, bot.brain.state == BotBrain.COVER)
	t.check("contact: last_known mirrors the fuzzy contact", bot.percept.has_last and bot.percept.last_known == bot.percept.contact.pos)
	var cerr := bot.percept.contact.pos.distance_to(Vector3(o.x, 0, o.z - 30))
	t.check("contact: heard-shot contact is not the exact shot spot", cerr > 0.001 and cerr <= 20.0, str(cerr))
	# age the contact out while searching: the bot gives up and holds a defensive post
	bot.brain.state = BotBrain.SEARCH
	bot.percept.contact.tick(BotTacticsDefs.CONTACT_FORGET)
	bot.think(0.03)
	t.check("contact: forgotten contact in Search -> Hold (%s)" % bot.brain.state, bot.brain.state == BotBrain.HOLD)
	var want := o + Vector3(-6, 0, 3)  # nearer marker
	t.check("contact: hold post is the nearest cover marker", bot._target.distance_to(want) < 0.01, str(bot._target))
	# after the calm period, and arrived, the bot patrols again
	bot._has_target = false
	bot.percept.contact.tick(BotTacticsDefs.CALM_PERIOD)
	bot.think(0.03)
	t.check("contact: calm holding bot resumes Patrol (%s)" % bot.brain.state, bot.brain.state == BotBrain.PATROL)
	bot.queue_free()
	stub.queue_free()
	wall.queue_free()
	floor_body.queue_free()
