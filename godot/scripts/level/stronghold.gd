class_name Strongholds
extends RefCounted
## Castles (design §3.1, §3.4). Terrain comes from CastleShape during the level build; each
## castle then has a plain, saveable state (StrongholdRules) and a view of decoration Nodes
## (StrongholdMeshes). States:
##   hostile    enemy gates and bridge; the crown nest on the spire top breeds a garrison
##   capturing  crown dead: the Operative holds the spire top for CAPTURE_TIME while the
##              nearest nest counterattacks. Abandon it and the nest regrows.
##   held       your gates; pays Aether and Salvage; turrets on its sockets (CastleTurrets).
##              Raiders target it and break walls, gates, the winch or turrets
##   siege      raiders in the courtyard: RETAKE_TIME of that, with the Operative off the
##              top and no turret standing, flips it back to hostile
## Replaces the old Aether Towers.

var world: World
var nests: SporeNests
var list: Array[Dictionary] = []  # saveable states
var lays := {}                     # id -> CastleShape layout (rebuilt from level data)
var views := {}                    # id -> StrongholdMeshes view + Node refs
var op := func() -> Variant: return null  # injected: PlayerController in THIS world, or null
var on_lost := func(_cells: Array) -> void: pass  # injected: destroy your structures in a lost courtyard
var stockpile: Stockpile = null  # injected: Salvage for turrets, the castle trickle and capture bounty
var time := 0.0


func _init(w: World, castles: Array, sn: SporeNests) -> void:
	world = w
	nests = sn
	for row in castles:
		var lay: Dictionary = row.layout
		var c := StrongholdRules.new_state(row, lay)
		list.append(c)
		lays[c.id] = lay
		var v := StrongholdMeshes.build(w, lay)
		CastleTurretFire.build_views(w, c, v)
		v["garrison"] = { "name": c.name, "pos": w.grid.cell_ground(lay.home.x, lay.home.y), "count": 0 }
		views[c.id] = v
		StrongholdHooks.attach(self, c, lay, v)
		StrongholdMeshes.refresh(v, c)
	nests.raiders.castle_goals = castle_goals
	nests.raiders.on_march = _assign
	w.updaters.append(update)


func held() -> int:
	return list.filter(func(c): return c.owner == "player").size()


## Everything raiders may attack here: walls, gates and winches of castles you hold.
func prey() -> Array:
	var out := []
	for v in views.values():
		out.append_array(v.prey)
	return out


## Gates and winches of enemy castles, for units to shoot.
func enemies() -> Array:
	var out := []
	for v in views.values():
		out.append_array(v.enemies)
	return out


## Cells raiders sent at castles walk to: courtyards, plus breach points while sealed.
func castle_goals() -> Array:
	var out := []
	for c in list:
		if c.state == "hostile":
			continue
		var lay: Dictionary = lays[c.id]
		out.append_array(lay.courtyard)
		if c.state != "capturing" and StrongholdRules.sealed(c, lay):
			out.append_array(StrongholdHooks.breach_cells(c, lay))
	return out


func _assign(r: Dictionary) -> void:
	if list.any(func(c): return c.state != "hostile") and randf() < Config.CASTLE_RAID_SHARE:
		r["mission"] = "castle"


func _hit_crown(c: Dictionary, dmg: float) -> void:
	if c.state != "hostile":
		return
	c.crown.hp -= dmg
	if c.crown.hp > 0.0:
		return
	c.crown.hp = 0.0
	c.state = "capturing"
	c.capture = { "progress": 0.0, "away": 0.0, "retake": 0.0 }
	var p: Vector3 = (views[c.id].crown as Node3D).position
	world.effects.burst(p + Vector3.UP * 2.0, Color("a8ff5a"), 8.0, 0.9)
	Sfx.play("boom", p)
	Bus.say("Crown nest destroyed. Hold the top of the spire for %ds to take %s." % [Config.CAPTURE_TIME, c.name], "good")
	_counterattack(c)
	StrongholdMeshes.refresh(views[c.id], c)


func _hit(c: Dictionary, lay: Dictionary, part: String, i: int, dmg: float) -> void:
	if not StrongholdRules.damage(world, c, lay, part, i, dmg):
		return
	var what: String = { "walls": "a wall", "gates": "the gate", "winch": "the drawbridge winch" }[part]
	var node: Node3D = views[c.id].winch if part == "winch" else views[c.id][{ "walls": "segs", "gates": "gates" }[part]][i]
	world.effects.burst(node.position, Color("ffb347"), 4.0, 0.6)
	Sfx.play("boom", node.position)
	Bus.say("%s: %s is down." % [c.name, what.capitalize()], "warn" if c.owner == "enemy" else "bad")
	StrongholdMeshes.refresh(views[c.id], c)


func _counterattack(c: Dictionary) -> void:
	var lay: Dictionary = lays[c.id]
	var centre := Vector2(lay.spire.centre)
	var live := nests.nests.filter(func(n): return n.alive)
	if live.is_empty():
		return
	live.sort_custom(func(a, b): return centre.distance_to(Vector2(a.x, a.z)) < centre.distance_to(Vector2(b.x, b.z)))
	var count: int = Config.CASTLE_COUNTER_BASE + Config.CASTLE_COUNTER_PER_TIER * nests.tier
	RaiderGroups.spawn(nests.raiders, live[0], RaiderGroups.compose(count, nests.pressure(), int(c.get("x", 0))), "castle")
	Sfx.play("alarm")
	Bus.say("Counterattack: %d raiders from the %s nest are coming for %s." % [count, live[0].name, c.name], "bad")


func update(dt: float) -> void:
	time += dt
	var o = op.call()
	var p = o.pos if o != null else null
	for c in list:
		var lay: Dictionary = lays[c.id]
		var v: Dictionary = views[c.id]
		match c.state:
			"hostile": _hostile(c, v, dt)
			"capturing": _capturing(c, lay, p, dt)
			_: _holding(c, lay, v, p, dt)
		SpirePump.update(world, c, lay, dt)
		CastleTurretFire.refresh(v, c)
		if o != null and not lay.spire.pad.is_empty():
			_pad(lay, o)
		if o != null and c.state == "hostile":
			StrongholdRules.crown_push(v, o)
		StrongholdMeshes.animate(v, c, time)


func _hostile(c: Dictionary, v: Dictionary, dt: float) -> void:
	var growth := 1.0 + nests.minutes() * 0.1
	c.crown.max_hp = Config.CROWN_HP * growth
	c.crown.hp = minf(c.crown.max_hp, c.crown.hp + Config.CROWN_HP * Config.NEST_HP_GROWTH / 60.0 * dt)
	c.garrison_timer += dt
	if c.garrison_timer >= nests.spawn_interval() and v.garrison.count < Config.CASTLE_GARRISON \
			and nests.raiders.list.size() < Config.RAIDER_MAX_TOTAL:
		c.garrison_timer = 0.0
		nests.raiders.spawn(v.garrison, nests.pick_tier(), true)
		nests.raiders.list.back().node.position = v.garrison.pos  # not on the wall


func _capturing(c: Dictionary, lay: Dictionary, p, dt: float) -> void:
	var cap: Dictionary = c.capture
	if StrongholdRules.in_zone(lay, p):
		cap.away = 0.0
		cap.progress = minf(1.0, cap.progress + dt / Config.CAPTURE_TIME)
		if cap.progress >= 1.0:
			StrongholdRules.to_held(world, c, lay)
			if stockpile:
				stockpile.add("salvage", Config.CASTLE_CAPTURE_SALVAGE)
			Sfx.play("good")
			Bus.say("%s is yours: +%.0f Aether/min while you hold it. Raiders will come for it." % [c.name, Config.CASTLE_AETHER_RATE * 60.0 * c.get("yield", 1.0)], "good")
			StrongholdMeshes.refresh(views[c.id], c)
		return
	cap.away += dt
	cap.progress = maxf(0.0, cap.progress - Config.CAPTURE_DECAY * dt)
	if cap.progress <= 0.0 and cap.away >= Config.CAPTURE_ABANDON:
		StrongholdRules.to_hostile(world, c, lay, Config.CROWN_REGROW)
		Bus.say("%s: the crown nest regrew. Nobody held the spire." % c.name, "bad")
		StrongholdMeshes.refresh(views[c.id], c)


func _holding(c: Dictionary, lay: Dictionary, v: Dictionary, p, dt: float) -> void:
	Upgrades.trickle(Config.CASTLE_AETHER_RATE * c.get("yield", 1.0) * dt)
	if stockpile:
		stockpile.add("salvage", Config.CASTLE_SALVAGE_RATE * c.get("yield", 1.0) * dt)
	CastleTurretFire.tick(world, c, v, nests.raiders, dt)
	var inside := nests.raiders.list.filter(func(r): return StrongholdRules.in_courtyard(lay, r.node.position))
	if inside.is_empty():
		if c.state == "siege":
			c.state = "held"
			Bus.say("%s: courtyard cleared." % c.name, "good")
		c.capture.retake = maxf(0.0, c.capture.retake - dt)
		return
	if c.state == "held":
		c.state = "siege"
		Sfx.play("alarm")
		Bus.say("Raiders are inside %s! Clear the courtyard or hold the spire top." % c.name, "bad")
	if not StrongholdRules.in_zone(lay, p) and not CastleTurrets.any_alive(c):
		c.capture.retake += dt
	if c.capture.retake < Config.RETAKE_TIME:
		return
	StrongholdRules.to_hostile(world, c, lay, Config.CROWN_REGROW)
	on_lost.call(lay.courtyard)
	for r in inside:  # the raiders inside become its new garrison
		r.nest.count -= 1
		r.nest = v.garrison
		r.guard = true
		r.erase("mission")
		v.garrison.count += 1
	Sfx.play("lost")
	Bus.say("%s has fallen. The crown nest is growing back." % c.name, "bad")
	StrongholdMeshes.refresh(v, c)


## Jump pad on the last ramp step: throws the Operative up onto the column top.
func _pad(lay: Dictionary, o) -> void:
	var cell := Vector2i(floori(o.pos.x / Config.CELL), floori(o.pos.z / Config.CELL))
	if o.on_ground and cell in lay.spire.pad:
		o.vel_y = sqrt(2.0 * Config.GRAVITY * (lay.spire.pad_levels + Config.JUMP_PAD_MARGIN) * Config.LEVEL_H)
		o.on_ground = false
		Sfx.play("lift")


func state() -> Dictionary:
	return { "castles": list.map(func(c): return c.duplicate(true)) }


## Restores castle states into the existing dictionaries (hooks keep their references).
func load_state(d: Dictionary) -> void:
	for s in d.castles:
		for c in list:
			if c.id != s.id:
				continue
			for k in s:
				c[k] = s[k].duplicate(true) if s[k] is Dictionary or s[k] is Array else s[k]
			var lay: Dictionary = lays[c.id]
			for i in c.walls.size():
				if c.walls[i].hp <= 0.0:
					StrongholdRules.breach(world, c, lay, i)
			StrongholdRules.sync_grid(world, c, lay)
			StrongholdMeshes.refresh(views[c.id], c)
