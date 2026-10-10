class_name Raiders
extends RefCounted
## Ground creatures bred by Spore Nests. Creeper-born, so creeper doesn't hurt them.
##  - guards stay leashed to their nest and jump anything that comes close
##  - raiders walk the RaiderField toward your structures and chew through them; anything
##    within RAIDER_AGGRO on the way (units, the Operative, a structure) is attacked first
## They only step one terrace at a time. With no walking route they attack the nearest prey
## they can reach on foot, or else return to the nest and guard it. Melee still reaches
## across a cliff edge. Tiers (RaiderDefs) unlock with pressure. Brutes and Behemoths hit
## walls three times harder. Snipers, units, the Operative and the Lance kill them. Mortar splash only nicks them.

var world: World
var list: Array[Dictionary] = []
var field: RaiderField
## Raiders with mission "castle" follow this field to held castles (Strongholds sets goals).
var castle_field: RaiderField
var castle_goals := func() -> Array: return []
## Lancer posts: returns garrison dicts of hostile castles, or null when no castles exist.
var castle_posts := func() -> Variant: return null
var on_march := func(_r: Dictionary) -> void: pass  # injected: may give a marcher a mission
var time := 0.0
var next_group := 1
var seen := {}  # tier name -> how many have spawned this mission
var in_update := false  # true inside update(): buckets and group speeds are fresh
var buckets := {}  # Vector2i (RAIDER_SEP_BUCKET m) -> raiders, for separation
var group_slow := {}  # group id -> slowest member speed
var paths: RaiderPaths  # committed routes to targets
var loot_host = null  # SporeNests, so a death can drop its Salvage pickup


func _init(w: World) -> void:
	world = w
	field = RaiderField.new(w.grid)
	castle_field = RaiderField.new(w.grid)
	paths = RaiderPaths.new(self)
	Bus.terrain_changed.connect(func(cw, _cells):
		if cw == world:
			field.invalidate()
			castle_field.invalidate())


func spawn(nest: Dictionary, tier: Dictionary, guard: bool) -> void:
	var post: Variant = null
	if CastleLancers.is_lancer(tier):
		post = CastleLancers.post(self, nest)
		if post is Dictionary and post.is_empty():
			tier = RaiderDefs.named("Spitter")  # every castle has its Lancers
			post = null
	var node := HazardMeshes.raider(tier)
	var a := randf() * TAU
	node.position = nest.pos + Vector3(cos(a) * 1.8, 0, sin(a) * 1.8)
	world.add_child(node)
	var r := { "tier": tier, "node": node, "hp": tier.hp, "alive": true, "nest": nest, "guard": guard,
		"phase": randf() * TAU, "size": tier.size }
	var attack := str(tier.get("attack", ""))
	if attack == "aura" or attack == "burrow":
		RaiderBurrow.setup(r)
	var hit := func(dmg: float, _p = null):
		var dealt: float = RaiderBurrow.filter(self, r, dmg)
		if dealt < 0.0:
			return
		r.hp -= dealt
		if r.hp <= 0.0:
			kill(r)
		else:
			CreatureAnim.hit(r.node)
	r["enemy"] = { "node": node, "oy": tier.size * 0.6, "radius": tier.size, "alive": func(): return r.alive, "hit": hit, "tier": tier,
		"targetable": func(): return str(r.get("burrow", "")) != "down" }
	r["target"] = { "node": node, "radius": tier.size, "oy": tier.size * 0.6, "alive": func(): return r.alive, "on_hit": hit, "tier": tier }
	world.add_target(r.target)
	list.append(r)
	nest.count += 1
	if CastleLancers.is_lancer(tier):
		CastleLancers.hold(self, r, post if post is Dictionary else nest)
		guard = true
	seen[tier.name] = int(seen.get(tier.name, 0)) + 1
	if not guard:
		on_march.call(r)


func kill(r: Dictionary) -> void:
	if not r.alive:
		return
	r.alive = false
	r.nest.count -= 1
	var p: Vector3 = r.node.position
	if loot_host != null:
		Loot.from_raider(loot_host, r)
	world.effects.burst(p + Vector3.UP * r.size, r.tier.color, 1.0 + r.size, 0.3)
	Sfx.play("pop", p)
	world.remove_target(r.target)
	list.erase(r)
	# Out of targeting and collision at once; the node plays its death clip
	# (max 1.5 s) before it is freed. Procedural fallback frees immediately.
	var node := r.node as Node3D
	CreatureAnim.die(node, func() -> void: node.queue_free())


func update(dt: float, prey: Array, goal_cells: Array) -> void:
	time += dt
	field.update(dt, goal_cells)
	castle_field.update(dt, castle_goals.call())
	var reachable: Array = []
	for q in prey:
		if q.alive.call() and _grounded(q):
			reachable.append(q)
	_index()
	paths.begin_update()
	paths.serve()
	in_update = true
	for r in list.duplicate():
		_think(r, dt, reachable)
	in_update = false


## Per-frame lookups shared by every raider: separation buckets and group speeds.
func _index() -> void:
	buckets.clear()
	group_slow.clear()
	for r in list:
		var p: Vector3 = r.node.position
		var k := Vector2i(floori(p.x / Config.RAIDER_SEP_BUCKET), floori(p.z / Config.RAIDER_SEP_BUCKET))
		if buckets.has(k):
			buckets[k].append(r)
		else:
			buckets[k] = [r]
		var gid := int(r.get("group", -1))
		if gid >= 0 and r.alive:
			group_slow[gid] = minf(float(group_slow.get(gid, INF)), float(r.tier.speed))


## Raiders can't reach hovering Thors or structures in flight.
func _grounded(q: Dictionary) -> bool:
	var p: Vector3 = q.node.position
	return p.y - world.grid.smooth_y(p.x, p.z) < 3.0


## Nearest prey in range that the raider can walk to (never one up a cliff).
func _nearest(from: Vector3, prey: Array, max_d: float, leash_home = null) -> Dictionary:
	var best: Dictionary = {}
	var bd := max_d
	for q in prey:
		var qp: Vector3 = q.node.position
		if leash_home != null and qp.distance_to(leash_home) > Config.NEST_LEASH:
			continue
		var d := Vector2(qp.x - from.x, qp.z - from.z).length()
		if d < bd and field.reachable(from, qp, q.radius):
			bd = d
			best = q
	return best


## A raider keeps its target until it dies, leaves the ground, becomes unwalkable-to (checked when
## the field is invalidated), a moving one gets past RAIDER_LOSE, or a guard's passes NEST_LEASH.
## Only a raider with no target scans (staggered RAIDER_ACQUIRE_MIN..MAX); a nearer prey never
## steals the pick. Movement still runs every frame (RaiderPaths).
func _acquire(r: Dictionary, prey: Array, max_d: float, leash_home = null) -> Dictionary:
	var held: Dictionary = r.get("_tgt", {})
	if not held.is_empty():
		if _keep(r, held, leash_home):
			return held
		r["_tgt"] = {}
		r["_tgt_at"] = 0.0
		paths.forget(r)
	if time < float(r.get("_tgt_at", 0.0)):
		return {}
	r["_tgt_at"] = time + randf_range(Config.RAIDER_ACQUIRE_MIN, Config.RAIDER_ACQUIRE_MAX)
	held = _nearest(r.node.position, prey, max_d, leash_home)
	r["_tgt"] = held
	r["_tgt_ver"] = field.version
	return held


func _keep(r: Dictionary, q: Dictionary, leash_home) -> bool:
	if not q.alive.call() or not _grounded(q):
		return false
	var qp: Vector3 = q.node.position
	if leash_home != null and qp.distance_to(leash_home) > Config.NEST_LEASH:
		return false
	var p: Vector3 = r.node.position
	if leash_home == null and not q.has("struct") and Vector2(qp.x - p.x, qp.z - p.z).length() > Config.RAIDER_LOSE:
		return false
	if int(r.get("_tgt_ver", -1)) != field.version:
		if not field.reachable(p, qp, q.radius):
			return false
		r["_tgt_ver"] = field.version
	return true


func _think(r: Dictionary, dt: float, prey: Array) -> void:
	if r.has("guard_post") and not CastleLancers.tend(self, r):
		return
	if float(r.get("gather", 0.0)) > 0.0:
		r["gather"] = float(r.gather) - dt
		_walk(r, _patrol(r.nest.pos, r), dt)
		return
	var tier := r.tier as Dictionary
	var attack := str(tier.get("attack", "melee"))
	if attack == "burrow":
		RaiderBurrow.step(self, r, dt, prey)
		return
	if attack == "acid" or attack == "beam":
		RaiderShots.step(self, r, dt, prey)
		return
	var p: Vector3 = r.node.position
	var home: Vector3 = r.nest.pos
	if str(tier.get("special", "")) == "spotter" and r.has("post"):
		var post: Vector3 = r.post
		_walk(r, Vector2(post.x, post.z), dt)
		return
	var goal = null  # Vector2 XZ
	var target: Dictionary
	if r.guard:
		target = _acquire(r, prey, Config.NEST_AGGRO, home)
		if target.is_empty():
			goal = CastlePatrols.waypoint(r) if r.has("wall_patrol") else _patrol(home, r)
	else:
		target = _acquire(r, prey, Config.RAIDER_AGGRO)
		if target.is_empty():
			goal = _route(r, p)
			if goal == null:
				target = field.nearest_on_foot(p, prey)
				if target.is_empty():
					r.guard = true
					goal = _patrol(home, r)
	if not target.is_empty():
		var tp: Vector3 = target.node.position
		var reach: float = target.radius + r.size + 0.5
		if Vector2(tp.x - p.x, tp.z - p.z).length() <= reach and absf(tp.y - p.y) <= reach + 2.5:
			var dmg: float = float(tier.dps) * dt
			if target.get("wall", false):
				dmg *= float(tier.get("wall_mult", 1.0))
			if target.get("kind", "") == "operative":
				HitFeel.note_source(p)
			if target.has("struct"):
				(target.struct as Structure).last_hit_by = str(tier.get("name", "raider"))
			target.hit.call(dmg)
			CreatureAnim.attack(r.node)
			_face(r, Vector2(tp.x - p.x, tp.z - p.z))
			r.node.position.y = RaiderPerch.y(world, p.x, p.z) + absf(sin(time * 12.0 + r.phase)) * 0.2
			return
		# One committed route: straight when clear, else the A* waypoints (RaiderPaths);
		# the flow field only while a search waits.
		goal = paths.goal(r, target, dt)
		if goal == null:
			goal = _route(r, p)
	if goal == null:
		return
	_walk(r, goal, dt)


## Castle raiders follow the castle field while it has a route for them; everyone else
## (and castle raiders with no route) follows the field to your structures.
func _route(r: Dictionary, p: Vector3) -> Variant:
	if r.get("overrun", false):
		var rush: Vector3 = r.get("rush", r.nest.pos)
		return Vector2(rush.x, rush.z)
	if r.get("mission", "") == "castle" and castle_field.has_goals:
		var s = castle_field.next_step(p.x, p.z)
		if s != null:
			return s
	return field.next_step(p.x, p.z)


func _walk(r: Dictionary, goal: Vector2, dt: float) -> bool:
	return RaiderMove.walk(self, r, goal, dt)


func _patrol(home: Vector3, r: Dictionary) -> Vector2:
	var a: float = time * 0.5 + r.phase
	return Vector2(home.x + cos(a) * 4.0, home.z + sin(a) * 4.0)


func _face(r: Dictionary, d: Vector2) -> void:
	if d.length() > 0.001:
		r.node.rotation.y = atan2(-d.y, d.x)
