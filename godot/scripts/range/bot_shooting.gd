class_name BotShooting
## ScavBot helpers: firing (bursts under 25 m, semi beyond, warm-up aim error), brain facts and cover search.

const COVER_CHECK := 0.4


## F18: aim spread in degrees. Warm-up error shrinks with time on target; every kind gains spread
## with distance (at least 1.0 growth at 50 m+, plus its aim_far), so long shots stay inaccurate.
static func aim_spread_deg(b: ScavBot, dist: float) -> float:
	var df := b.def
	var warm := b.percept.sight_t + (BotPerception.ALERT_AIM_HEAD if b.percept.alerted() else 0.0)
	return BotBrain.aim_error(warm) * float(df["aim_mult"]) * b.body.arm_loss("sway") \
		* (1.0 + maxf(1.0, float(df["aim_far"])) * clampf(dist / 50.0, 0.0, 1.0))


## Test hook: when `trace_on`, every fire() call counts its outcome ("fired", "cd", "los", "busy:<kind>", ...).
static var trace_on := false
static var trace := {}


static func fire(b: ScavBot, point: Vector3) -> void:
	var why := _fire(b, point)
	if trace_on:
		trace[why] = int(trace.get(why, 0)) + 1


## Returns "fired" or the reason it returned early.
static func _fire(b: ScavBot, point: Vector3) -> String:
	var dist := b.eye().distance_to(point)
	if b.gun.busy():
		return "busy:" + b.gun.busy_kind
	if b.cd > 0.0:
		return "cd"
	# F5: only fire with a clear line to the target. The ray runs on LAYER_WORLD, so the bot's own body
	# (LAYER_BODY) never blocks it; cover, walls and props do. F84: it starts at the eye, not the muzzle
	# (0.4 m out): a bot pressed against a wall has its muzzle inside or past it, and a ray that starts
	# inside a solid never hits it, so the shot went through concrete.
	var space := b.get_world_3d().direct_space_state
	if not BotPerception.los(space, b.eye(), [point]):
		# BOT-P0: sight accepts head OR chest, so a target hiding behind half cover is shot in the head.
		var head := _visible_head(b, point, space)
		if head == Vector3.INF:
			return "los"
		point = head
		dist = b.eye().distance_to(point)
	# F18: reaction delay before the first aimed shot after spotting. Only gates aimed fire at a
	# seen target; suppressing fire at last-known (not seeing) still goes out.
	if b.percept.seeing and b.percept.sight_t < b.react_t * b.body.arm_loss("ads"):
		return "react"
	var df := b.def
	var wu: float = df["windup"]
	if wu > 0.0:  # marksman: scope glint first, shot after the wind-up
		if not b.winding:
			b.winding = true
			b.wind = wu
			b.mesh.glint(true)
			return "windup"
		if b.wind > 0.0:
			return "windup"
		b.winding = false
		b.mesh.glint(false)
	var auto: bool = dist < BotBrain.BURST_RANGE and "auto" in b.gun.def["modes"]
	if auto and b.burst <= 0:
		b.burst = b.rng.randi_range(3, 5)
	if not auto:
		b.burst = 1
	var res := b.gun.fire(b.rng)
	if not res["fired"]:
		return "refused:" + str(res["reason"])
	b.burst -= 1
	b.cd = b.rng.randf_range(df["cd"][0], df["cd"][1]) if b.burst <= 0 else 0.0
	var dir := (point - b.eye()).normalized()
	var basis := Basis.looking_at(dir)
	var err := deg_to_rad(aim_spread_deg(b, dist))
	var ang := b.rng.randf() * TAU
	var r := err * sqrt(b.rng.randf())
	dir = dir.rotated(basis.x, sin(ang) * r).rotated(basis.y, cos(ang) * r)
	var origin := b.eye() + dir * 0.4
	for d in b.gun.shot_dirs(Basis.looking_at(dir), res["ammo"], true, b.rng):
		b.bal.spawn(origin, d, res["ammo"], HitboxRig.rids(b.rig))
	b.mesh.fire()
	if df["overwatch"]:
		b.shots_since += 1
		if b.shots_since >= int(df["relocate"]):
			BotEngage.relocate(b)
	RangeAudio.event({"kind": "shot", "item": b.gun.id, "pos": b.mesh.muzzle.global_position, "cal": b.gun.def["cal"], "cls": b.gun.def["class"]})
	b.flash.flash(Color(1.0, 0.8, 0.45), 0.1, 0.05, 2.0)
	return "fired"


## The nearest player's head when the bot sees them, `point` is their chest and the head line is clear; else INF.
static func _visible_head(b: ScavBot, point: Vector3, space: PhysicsDirectSpaceState3D) -> Vector3:
	if not b.percept.seeing or b.session == null:
		return Vector3.INF
	var target := b.session.nearest_player(b.global_position)
	if target == null or target.node == null:
		return Vector3.INF
	var head: Vector3 = target.node.eye_pos()
	if head.distance_to(point) > 1.5:
		return Vector3.INF
	return head if BotPerception.los(space, b.eye(), [head]) else Vector3.INF


static func facts(b: ScavBot) -> Dictionary:
	var p := b.percept
	var ally := b.ally
	var ally_eng := ally != null and ally.is_engaged() and not b.is_engaged()
	if ally_eng and ally.percept.has_last:
		p.contact.ally(ally.percept.contact.pos, ally.percept.contact.err)
		p.tick(0.0)  # re-sync last_known / has_last from the shared contact
	if b.cover_t <= 0.0 and p.has_last and b.brain.state in [BotBrain.ENGAGE, BotBrain.COVER] and not b.combat.active:
		find_cover(b)
	var alone := ally == null or ally.body.dead
	var outgunned := p.aware and ((alone and b.body.total_frac() < 0.7) or b.gun.rounds_total() < 3)
	return {"aware": p.aware, "seeing": p.seeing, "noise": p.noise_new, "shot": p.shot_new, "shot_cover": b.shot_cover, "since_seen": p.since_seen,
		"hp": b.body.total_frac(), "hurt": b.hurt_t > 0.0, "reloading": b.gun.busy_kind == "reload", "arrived": b._arrived(),
		"cover": b.has_cover and not b.def["rush"], "outgunned": outgunned, "flank_eager": b.def["flank_eager"], "ally_engaged": ally_eng,
		"ally_flank": ally != null and not ally.body.dead and ally.brain.state == BotBrain.FLANK, "has_last": p.has_last,
		"forgotten": p.contact.forgotten, "calm": p.contact.age >= BotTacticsDefs.CALM_PERIOD}


## F97 phase B: scored cover pick + per-session reservation (replaces nearest-hidden).
## Phase C: the pick also enforces squad spacing and the line-of-fire rule.
static func find_cover(b: ScavBot) -> void:
	b.cover_t = COVER_CHECK
	b.has_cover = false
	var pos := BotCover.pick(b, b.squad)
	if pos != BotCover.NO_COVER:
		b.cover_pos = pos
		b.has_cover = true
		BotCover.claim(b.session, b, pos, BotCover.threat_pos(b))
