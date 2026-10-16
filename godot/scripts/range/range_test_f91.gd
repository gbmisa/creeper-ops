class_name RangeTestF91
## F91: bots snagged on props. A bot driven from one side of the motor-pool truck (-10, 6) to the other gets round
## it; a bot that wants to move but doesn't starts unsticking after one window and drops its target after
## TacticalConfig.BOT_STUCK_GIVE_UP windows.


static func run(t: RangeTest, game: SkirmishGame) -> void:
	var b: ScavBot = null
	for x in game.bots:
		if x.kind == "rifleman" and not x.body.dead:
			b = x
			break
	if b == null:
		t.check("f91: a live rifleman to drive", false)
		return
	b.set_physics_process(false)  # brain off: only BotMotion (steering + BotUnstick) moves it
	b.brain.state = BotBrain.PATROL
	var from := Vector3(-7.4, 0.1, 6.0)
	var to := Vector3(-13.0, 0.0, 6.0)
	b.global_position = from
	b.velocity = Vector3.ZERO
	b._go(to)
	var unstuck := 0
	for i in 600:
		await t.get_tree().physics_frame
		BotMotion.move(b, 1.0 / 60.0)
		if b.unstick_t > 0.0:
			unstuck += 1
		if b._flat(b.global_position - to).length() < 1.5:
			break
	var left := b._flat(b.global_position - to).length()
	t.check("f91: bot gets round the truck to the far side (%.1f m left, %d unstick frames)" % [left, unstuck], left < 1.5)
	# logic: wanting to move without moving
	b._go(to)
	b.stuck_win = 0.0
	b.stuck_count = 0
	b.stuck_from = b.global_position
	var want := Vector3(1, 0, 0)
	BotUnstick.track(b, want, TacticalConfig.BOT_STUCK_WINDOW + 0.01)
	t.check("f91: one window without progress starts a sidestep", b.unstick_t > 0.0 and b.unstick_dir.length() > 0.5)
	for _i in TacticalConfig.BOT_STUCK_GIVE_UP - 1:
		BotUnstick.track(b, want, TacticalConfig.BOT_STUCK_WINDOW + 0.01)
	t.check("f91: %d windows stuck in a row drops the move target" % TacticalConfig.BOT_STUCK_GIVE_UP, not b._has_target)
	BotUnstick.track(b, Vector3.ZERO, 0.1)
	t.check("f91: standing still on purpose is never stuck", b.stuck_count == 0 and b.stuck_win == 0.0)
	b.set_physics_process(true)
