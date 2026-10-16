class_name BotMotion
## ScavBot movement: NavigationAgent3D steering, facing (toward the target while shooting) and gravity.


static func speed(b: ScavBot) -> float:
	return base_speed(b) * b.def["speed"]


static func base_speed(b: ScavBot) -> float:
	match b.brain.state:
		BotBrain.PATROL:
			return ScavBot.WALK
		BotBrain.COVER:
			return ScavBot.RUN
		BotBrain.HEAL, BotBrain.SUPPRESS:
			return 0.0
	return ScavBot.MOVE


## The point to steer at. F88: the agent advances along its path by 3D distance, and the navmesh sits up to 0.5 m
## above the ground, so a waypoint straight over the bot's feet never counted as reached and the bot stood still
## with a path (or walked back to it). Then steer at the waypoint after the nearest one, by ground distance.
static func next_point(b: ScavBot) -> Vector3:
	var nxt := b.nav.get_next_path_position()
	var path := b.nav.get_current_navigation_path()
	var j := -1
	var best := INF
	for i in range(maxi(0, b.nav.get_current_navigation_path_index()), path.size()):
		var d := b._flat(path[i] - b.global_position).length()
		if d < best:
			best = d
			j = i
	if j < 0:
		return nxt
	for i in range(j + 1, path.size()):  # the first waypoint past the nearest one that is not on top of the bot
		if b._flat(path[i] - b.global_position).length() > 0.3:
			return path[i]
	return path[path.size() - 1]


static func move(b: ScavBot, dt: float) -> void:
	if b.body.dead or b._dying:
		return
	var v := Vector3.ZERO
	var face := Vector3.ZERO
	if b._has_target and not b._arrived():
		var d := b._flat(next_point(b) - b.global_position)
		if d.length() > 0.05:
			v = d.normalized() * speed(b)
			face = d
	BotUnstick.track(b, v, dt)  # F91: snagged on a prop -> sidestep + fresh path
	if b.unstick_t > 0.0 and v.length() > 0.05:
		v = BotUnstick.steer(b) * v.length()
	if b.brain.state == BotBrain.ENGAGE and b.percept.seeing or b.brain.state == BotBrain.SUPPRESS and b.percept.has_last:
		face = b._flat(b.percept.last_known - b.global_position)
	if face.length() <= 0.05 and b.percept.alerted() and not b.percept.seeing:  # F87: idle and alert: watch the shot
		face = b._flat(b.percept.noise_pos - b.global_position)
	if face.length() > 0.05:
		b.rotation.y = lerp_angle(b.rotation.y, atan2(-face.x, -face.z), minf(1.0, ScavBot.TURN * dt))
	b.velocity.x = v.x
	b.velocity.z = v.z
	b.velocity.y = -1.0 if b.is_on_floor() else b.velocity.y - 20.0 * dt
	b.move_and_slide()
	b.mesh.walk(dt, v.length())
