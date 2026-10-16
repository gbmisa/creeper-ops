class_name BotUnstick
## F91: bots snagged on props. A bot that wants to move but covers less than BOT_STUCK_DIST in BOT_STUCK_WINDOW s is
## stuck: for BOT_UNSTICK_TIME it sidesteps away from what it hit and steers at the agent's own next waypoint (no
## F88 look-ahead corner cut), and its path is re-queried. After BOT_STUCK_GIVE_UP stuck windows in a row it drops
## the move target, so the brain picks its next point.


## Called every physics frame with the bot's wanted velocity (zero = not trying to move).
static func track(b: ScavBot, want: Vector3, dt: float) -> void:
	b.unstick_t = maxf(0.0, b.unstick_t - dt)
	if want.length() < 0.05:
		b.stuck_win = 0.0
		b.stuck_from = b.global_position
		b.stuck_count = 0
		return
	b.stuck_win += dt
	if b.stuck_win < TacticalConfig.BOT_STUCK_WINDOW:
		return
	var moved := b._flat(b.global_position - b.stuck_from).length()
	b.stuck_win = 0.0
	b.stuck_from = b.global_position
	if moved >= TacticalConfig.BOT_STUCK_DIST:
		b.stuck_count = 0
		return
	b.stuck_count += 1
	if b.stuck_count >= TacticalConfig.BOT_STUCK_GIVE_UP:
		b.stuck_count = 0
		b._has_target = false
		return
	var away := Vector3.ZERO
	for i in b.get_slide_collision_count():
		away += b._flat(b.get_slide_collision(i).get_normal())
	var side := want.normalized().cross(Vector3.UP)  # perpendicular to where it wants to go
	if away.length() > 0.01 and side.dot(away) < 0.0:
		side = -side
	elif away.length() <= 0.01 and b.stuck_count % 2 == 0:
		side = -side
	b.unstick_dir = (side + away.normalized() * 0.5).normalized()
	b.unstick_t = TacticalConfig.BOT_UNSTICK_TIME
	if b.nav != null:  # re-query: a changed target forces a fresh path
		var tgt := b.nav.target_position
		b.nav.target_position = b.global_position
		b.nav.target_position = tgt


## The steering direction while unsticking: the sidestep blended with the agent's own next waypoint.
static func steer(b: ScavBot) -> Vector3:
	var to := b._flat(b.nav.get_next_path_position() - b.global_position) if b.nav != null else Vector3.ZERO
	return (b.unstick_dir + (to.normalized() if to.length() > 0.05 else Vector3.ZERO) * 0.5).normalized()
