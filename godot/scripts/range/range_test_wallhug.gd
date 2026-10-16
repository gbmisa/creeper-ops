class_name RangeTestWallHug
## F84: a bot pressed against concrete must not shoot through it. Its muzzle point (0.4 m out) sits inside the
## wall, and a ray that starts inside a solid never hits it, so the old muzzle-based sight check let the shot out.

const O := Vector3(-1000, 0, 1000)


static func run(t: RangeTest) -> void:
	var session := RangeSession.new(7)
	var floor_body := t._wall(O + Vector3(0, -0.5, 0), Vector3(20, 1, 20), "concrete", 0.5)
	var wall := t._wall(O + Vector3(0, 1.5, -0.35), Vector3(4, 3, 0.3), "concrete", 0.3)  # faces at z -0.2 and -0.5
	var bot := ScavBot.new()
	var kind: String = BotDefs.ORDER[0]
	var stub := RangeTestNoFire.Stub.new()
	t.add_child(stub)
	bot.setup(session, t.bal, stub, kind, 0, kind)
	t.add_child(bot)
	bot.set_physics_process(false)
	bot.global_position = O
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	bot.cd = 0.0
	t.bal.shots.clear()
	var target := O + Vector3(0, 1.3, -1.5)  # a standing player's chest, fully behind the wall
	var why := BotShooting._fire(bot, target)
	t.check("wall hug: a bot against concrete does not fire through it (%s)" % why, why == "los" and t.bal.shots.is_empty())
	wall.queue_free()
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	bot.cd = 0.0
	t.check("wall hug: same shot fires once the wall is gone", BotShooting._fire(bot, target) != "los")
	t.bal.shots.clear()
	bot.queue_free()
	stub.queue_free()
	floor_body.queue_free()
