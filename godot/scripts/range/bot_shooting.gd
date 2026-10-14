class_name BotShooting
## ScavBot helpers: firing (bursts under 25 m, semi beyond, warm-up aim error), brain facts and cover search.

const COVER_CHECK := 0.4


static func fire(b: ScavBot, point: Vector3) -> void:
	var dist := b.eye().distance_to(point)
	if b.gun.busy() or b.cd > 0.0:
		return
	var auto := dist < BotBrain.BURST_RANGE
	if auto and b.burst <= 0:
		b.burst = b.rng.randi_range(3, 5)
	if not auto:
		b.burst = 1
	var res := b.gun.fire(b.rng)
	if not res["fired"]:
		return
	b.burst -= 1
	b.cd = b.rng.randf_range(0.45, 0.9) if b.burst <= 0 else 0.0
	var dir := (point - b.eye()).normalized()
	var basis := Basis.looking_at(dir)
	var err := deg_to_rad(BotBrain.aim_error(b.percept.sight_t))
	var ang := b.rng.randf() * TAU
	var r := err * sqrt(b.rng.randf())
	dir = dir.rotated(basis.x, sin(ang) * r).rotated(basis.y, cos(ang) * r)
	var origin := b.eye() + dir * 0.4
	for d in b.gun.shot_dirs(Basis.looking_at(dir), res["ammo"], true, b.rng):
		b.bal.spawn(origin, d, res["ammo"], HitboxRig.rids(b.rig))
	b.mesh.fire()
	RangeSfx.shot(b.gun.def["class"], b.mesh.muzzle.global_position)
	b.flash.flash(Color(1.0, 0.8, 0.45), 0.1, 0.05, 2.0)


static func facts(b: ScavBot) -> Dictionary:
	var p := b.percept
	var ally := b.ally
	var ally_eng := ally != null and ally.is_engaged() and not b.is_engaged()
	if ally_eng and ally.percept.has_last:
		p.last_known = ally.percept.last_known
		p.has_last = true
	if b.cover_t <= 0.0 and p.has_last and b.brain.state in [BotBrain.ENGAGE, BotBrain.COVER]:
		find_cover(b)
	var alone := ally == null or ally.body.dead
	var outgunned := p.aware and ((alone and b.body.total_frac() < 0.7) or b.gun.rounds_total() < 3)
	return {"aware": p.aware, "seeing": p.seeing, "noise": p.noise_new, "since_seen": p.since_seen,
		"hp": b.body.total_frac(), "hurt": b.hurt_t > 0.0, "reloading": b.gun.busy_kind == "reload", "arrived": b._arrived(),
		"cover": b.has_cover, "outgunned": outgunned, "ally_engaged": ally_eng,
		"ally_flank": ally != null and not ally.body.dead and ally.brain.state == BotBrain.FLANK, "has_last": p.has_last}


## Nearest cover marker whose spot (crouched eye) cannot be seen from the last known player position.
static func find_cover(b: ScavBot) -> void:
	b.cover_t = COVER_CHECK
	b.has_cover = false
	var threat := b.percept.last_known + Vector3(0, 1.4, 0)
	var space := b.get_world_3d().direct_space_state
	var best := 1.0e9
	for c in b.covers:
		var d := b.global_position.distance_to(c)
		if d < best and not BotPerception.los(space, c + Vector3(0, 0.9, 0), [threat]):
			best = d
			b.cover_pos = c
			b.has_cover = true
