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


static func move(b: ScavBot, dt: float) -> void:
	if b.body.dead or b._dying:
		return
	var v := Vector3.ZERO
	var face := Vector3.ZERO
	if b._has_target and not b._arrived():
		var d := b._flat(b.nav.get_next_path_position() - b.global_position)
		if d.length() > 0.05:
			v = d.normalized() * speed(b)
			face = d
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
