class_name StrongholdTick
## Per-state castle updates for Strongholds (static; the state lives in each castle dict).
##   hostile    the crown nest grows and breeds a garrison; concentric rings (CastleStages)
##   capturing  the Operative holds the final zone (spire top or keep hall)
##   held/siege pays out, turrets fire; raiders inside the ward with nobody answering retake it


static func hostile(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary, p, dt: float) -> void:
	var nests := s.nests
	var growth := 1.0 + nests.minutes() * 0.1
	c.crown.max_hp = Config.CROWN_HP * growth
	c.crown.hp = minf(c.crown.max_hp, c.crown.hp + Config.CROWN_HP * Config.NEST_HP_GROWTH / 60.0 * dt)
	c.garrison_timer += dt
	if c.garrison_timer >= nests.spawn_interval() and v.garrison.count < Config.CASTLE_GARRISON \
			and nests.raiders.list.size() < Config.RAIDER_MAX_TOTAL:
		c.garrison_timer = 0.0
		nests.raiders.spawn(v.garrison, nests.pick_tier(), true)
		nests.raiders.list.back().node.position = v.garrison.pos  # not on the wall
		if lay.stages.size() > 1:
			CastlePatrols.on_garrison_tick(s, c, lay, v)
	if lay.stages.size() > 1:
		CastleStages.tick(s, c, lay, p, dt)
		CastlePatrols.ensure(s, c, lay, v)


static func capturing(s: Strongholds, c: Dictionary, lay: Dictionary, p, dt: float) -> void:
	var cap: Dictionary = c.capture
	if StrongholdRules.in_zone(lay, p):
		cap.away = 0.0
		cap.progress = minf(1.0, cap.progress + dt / Config.CAPTURE_TIME)
		if cap.progress >= 1.0:
			StrongholdRules.to_held(s.world, c, lay)
			CastlePatrols.clear(s, s.views[c.id])  # the wall patrols and the hall guard are gone
			if s.stockpile:
				s.stockpile.add("salvage", Config.CASTLE_CAPTURE_SALVAGE)
			Sfx.play("good")
			Bus.say("%s is yours: +%.0f Aether/min while you hold it. Raiders will come for it — select troops and right-click to garrison the courtyard." % [c.name, Config.CASTLE_AETHER_RATE * 60.0 * c.get("yield", 1.0)], "good")
			StrongholdMeshes.refresh(s.views[c.id], c)
		return
	cap.away += dt
	cap.progress = maxf(0.0, cap.progress - Config.CAPTURE_DECAY * dt)
	if cap.progress <= 0.0 and cap.away >= Config.CAPTURE_ABANDON:
		StrongholdRules.to_hostile(s.world, c, lay, Config.CROWN_REGROW)
		CastlePatrols.release(s.views[c.id])
		if lay.stages.size() > 1:  # the outer rings stay yours: only the keep is lost
			CastleStages.set_stage(s, c, lay.stages.size() - 1)
		Bus.say("%s: the crown nest regrew. Nobody held the %s." % [c.name, "keep hall" if lay.stages.size() > 1 else "spire"], "bad")
		StrongholdMeshes.refresh(s.views[c.id], c)


static func holding(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary, p, dt: float) -> void:
	var nests := s.nests
	Upgrades.trickle(Config.CASTLE_AETHER_RATE * c.get("yield", 1.0) * dt)
	if s.stockpile:
		s.stockpile.add("salvage", Config.CASTLE_SALVAGE_RATE * c.get("yield", 1.0) * dt)
	CastleTurretFire.tick(s.world, c, v, nests.raiders, dt)
	CastlePerks.ward(s, c, lay, dt)
	var inside := nests.raiders.list.filter(func(r): return StrongholdRules.in_courtyard(lay, r.node.position))
	if inside.is_empty():
		if c.state == "siege":
			c.state = "held"
			Bus.say("%s: courtyard cleared." % c.name, "good")
		c.capture.retake = maxf(0.0, c.capture.retake - dt)
		return
	if c.state == "held":
		c.state = "siege"
		Bus.metric.emit("castle_siege", { "name": c.name })
		Sfx.play("alarm")
		Bus.say("Raiders are inside %s! Clear them or hold the %s." % [c.name, "keep hall" if lay.stages.size() > 1 else "spire top"], "bad")
	var ward := inside.filter(func(r): return StrongholdRules.in_ward(lay, r.node.position))
	if not ward.is_empty() and not StrongholdRules.in_zone(lay, p) and not CastleTurrets.any_alive(c):
		c.capture.retake += dt
	if c.capture.retake < Config.RETAKE_TIME:
		return
	StrongholdRules.to_hostile(s.world, c, lay, Config.CROWN_REGROW)
	CastlePatrols.release(v)  # old patrols stand down; fresh ones spawn on the wall
	s.on_lost.call(lay.courtyard)
	for r in inside:  # the raiders inside become its new garrison
		r.nest.count -= 1
		r.nest = v.garrison
		r.guard = true
		r.erase("mission")
		v.garrison.count += 1
	CastleStages.set_stage(s, c, 0)
	Sfx.play("lost")
	Bus.say("%s has fallen. The crown nest is growing back." % c.name, "bad")
	StrongholdMeshes.refresh(v, c)


## Jump pad on the last ramp step: throws the Operative up onto the column top.
static func pad(lay: Dictionary, o) -> void:
	var cell := Vector2i(floori(o.pos.x / Config.CELL), floori(o.pos.z / Config.CELL))
	if o.on_ground and cell in lay.spire.pad:
		o.vel_y = sqrt(2.0 * Config.GRAVITY * (lay.spire.pad_levels + Config.JUMP_PAD_MARGIN) * Config.LEVEL_H)
		o.on_ground = false
		Sfx.play("lift")
