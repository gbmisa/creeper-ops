class_name Strongholds
extends RefCounted
## Castles (design §3.1, §3.4). Terrain comes from CastleShape during the level build; each
## castle then has a plain, saveable state (StrongholdRules) and a view of decoration Nodes
## (StrongholdMeshes). States:
##   hostile    enemy gates and bridge; the crown nest (spire top / keep hall) breeds a garrison
##   capturing  crown dead: the Operative holds its zone for CAPTURE_TIME while the
##              nearest nest counterattacks. Abandon it and the nest regrows.
##   held       your gates; pays Aether and Salvage; turrets on its sockets (CastleTurrets).
##              Raiders target it and break walls, gates, the winch or turrets
##   siege      raiders in the courtyard: RETAKE_TIME of that, with the Operative off the
##              top and no turret standing, flips it back to hostile
## Concentric castles (Stage 21) are taken ring by ring first (CastleStages) and fire war
## engines while hostile (CastleEngines). Replaces the old Aether Towers.

var world: World
var nests: SporeNests
var list: Array[Dictionary] = []  # saveable states
var lays := {}                     # id -> CastleShape layout (rebuilt from level data)
var views := {}                    # id -> StrongholdMeshes view + Node refs
var op := func() -> Variant: return null  # injected: PlayerController in THIS world, or null
var on_lost := func(_cells: Array) -> void: pass  # injected: destroy your structures in a lost courtyard
var stockpile: Stockpile = null  # injected: Salvage for turrets, the castle trickle and capture bounty
var engine_prey := func() -> Array: return []  # injected: what war engines may hit (Game.surface_prey)
var time := 0.0
var ban_cache := PackedVector4Array()  # last build-ban rings sent to the terrain shader


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
		v["garrison"] = { "name": c.name, "castle": c.id, "pos": w.grid.cell_ground(lay.home.x, lay.home.y), "count": 0 }
		views[c.id] = v
		StrongholdHooks.attach(self, c, lay, v)
		CastleEngines.attach(self, c, v)
		_trebuchet_markers(w, c, lay, v)
		StrongholdMeshes.refresh(v, c)
	nests.raiders.castle_goals = castle_goals
	nests.raiders.on_march = _assign
	nests.raiders.castle_posts = func() -> Array: return CastleLancers.posts(self)
	w.updaters.append(update)


## Minor markers on live trebuchets while the bailey stage is the objective, so the
## "destroy the trebuchets" blocker is findable, not just a nag line.
func _trebuchet_markers(w: World, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	for i in c.engines.size():
		var idx: int = i
		var node: Node3D = v.engines[idx]
		w.markers.append({ "pos": node.position + Vector3(0, 3, 0), "label": "Trebuchet",
			"color": Color("ffb347"), "minor": true,
			"visible": func(): return c.state == "hostile" and CastleStages.current(c, lay) == "bailey" and CastleEngines.alive(c.engines[idx]) })


func held() -> int:
	return list.filter(func(c): return c.owner == "player").size()


## Everything raiders may attack here: walls, gates and winches of castles you hold.
func prey() -> Array:
	var out := []
	for v in views.values():
		out.append_array(v.prey)
	return out


## Gates and winches of enemy castles and their war engines, for units to shoot.
func enemies() -> Array:
	var out := []
	for v in views.values():
		out.append_array(v.enemies)
	for f in CastleEngines.foes(self):
		out.append(f.enemy)
	return out


## Cells raiders sent at castles walk to: courtyards, plus breach points while sealed.
func castle_goals() -> Array:
	var out := []
	for c in list:
		if c.state == "hostile":
			continue
		var lay: Dictionary = lays[c.id]
		out.append_array(lay.get("ward", lay.courtyard))
		if c.state == "capturing":
			continue
		for ring in ["outer", "inner"]:  # one breach line per sealed ring
			if (ring == "outer" or lay.has("inner_rect")) and StrongholdRules.sealed(c, lay, ring):
				out.append_array(StrongholdHooks.breach_cells(c, lay, ring))
	return out


func _assign(r: Dictionary) -> void:
	if list.any(func(c): return c.state != "hostile") and randf() < Config.CASTLE_RAID_SHARE:
		r["mission"] = "castle"


func _hit_crown(c: Dictionary, dmg: float) -> void:
	if c.state != "hostile":
		return
	if not CastleStages.crown_open(c, lays[c.id]):  # concentric: warded until the bailey is yours
		CastleStages._nag(self, c, "%s: the crown nest is warded. Take the gatehouse and the bailey first." % c.name)
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
	Loot.drop(world, p, Config.LOOT_CROWN, stockpile, op)
	var where := "keep hall" if lays[c.id].stages.size() > 1 else "top of the spire"
	Bus.say("Crown nest destroyed. Hold the %s for %ds to take %s." % [where, Config.CAPTURE_TIME, c.name], "good")
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
	var targets: Array = engine_prey.call()
	CastleEngines.rings.clear()
	for c in list:
		var lay: Dictionary = lays[c.id]
		var v: Dictionary = views[c.id]
		match c.state:
			"hostile": StrongholdTick.hostile(self, c, lay, v, p, dt)
			"capturing": StrongholdTick.capturing(self, c, lay, p, dt)
			_: StrongholdTick.holding(self, c, lay, v, p, dt)
		CastleEngines.tick(self, c, v, targets, dt)
		SpirePump.update(world, c, lay, dt)
		CastleTurretFire.refresh(v, c)
		if o != null and not lay.spire.pad.is_empty():
			StrongholdTick.pad(lay, o)
		if o != null and c.state == "hostile":
			StrongholdRules.crown_push(v, o)
		StrongholdMeshes.animate(v, c, time)
	EnemyMortarFire.extra = CastleEngines.rings  # trebuchet rings share the mortar-ring shader slots


## Older callers (smoke tests) use the per-state ticks by these names.
func _capturing(c: Dictionary, lay: Dictionary, p, dt: float) -> void:
	StrongholdTick.capturing(self, c, lay, p, dt)


func _holding(c: Dictionary, lay: Dictionary, v: Dictionary, p, dt: float) -> void:
	StrongholdTick.holding(self, c, lay, v, p, dt)


func _pad(lay: Dictionary, o) -> void:
	StrongholdTick.pad(lay, o)


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
