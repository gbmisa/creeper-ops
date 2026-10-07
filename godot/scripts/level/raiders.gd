class_name Raiders
extends RefCounted
## Ground creatures bred by Spore Nests. Creeper-born, so creeper doesn't hurt them.
##  - guards stay leashed to their nest and jump anything that comes close
##  - raiders walk the RaiderField toward your structures and chew through them; anything
##    within RAIDER_AGGRO on the way (units, the Operative, a structure) is attacked first
## They only step one terrace at a time. With no walking route they attack the nearest prey
## they can reach on foot, or else return to the nest and guard it. Melee still reaches
## across a cliff edge. Tiers (Config.RAIDER_TIERS) get tougher as the level's schedule
## unlocks them. Snipers, units, the Operative and the Lance kill them. Mortar splash only nicks them.

var world: World
var list: Array[Dictionary] = []
var field: RaiderField
## Raiders with mission "castle" follow this field to held castles (Strongholds sets goals).
var castle_field: RaiderField
var castle_goals := func() -> Array: return []
var on_march := func(_r: Dictionary) -> void: pass  # injected: may give a marcher a mission
var time := 0.0


func _init(w: World) -> void:
	world = w
	field = RaiderField.new(w.grid)
	castle_field = RaiderField.new(w.grid)
	Bus.terrain_changed.connect(func(cw, _cells):
		if cw == world:
			field.invalidate()
			castle_field.invalidate())


func spawn(nest: Dictionary, tier: Dictionary, guard: bool) -> void:
	var node := HazardMeshes.raider(tier)
	var a := randf() * TAU
	node.position = nest.pos + Vector3(cos(a) * 1.8, 0, sin(a) * 1.8)
	world.add_child(node)
	var r := { "tier": tier, "node": node, "hp": tier.hp, "alive": true, "nest": nest, "guard": guard,
		"phase": randf() * TAU, "size": tier.size }
	var hit := func(dmg: float, _p = null):
		r.hp -= dmg
		if r.hp <= 0.0:
			kill(r)
	r["enemy"] = { "node": node, "oy": tier.size * 0.6, "radius": tier.size, "alive": func(): return r.alive, "hit": hit }
	r["target"] = { "node": node, "radius": tier.size, "oy": tier.size * 0.6, "alive": func(): return r.alive, "on_hit": hit }
	world.add_target(r.target)
	list.append(r)
	nest.count += 1
	if not guard:
		on_march.call(r)


func kill(r: Dictionary) -> void:
	if not r.alive:
		return
	r.alive = false
	r.nest.count -= 1
	var p: Vector3 = r.node.position
	world.effects.burst(p + Vector3.UP * r.size, r.tier.color, 1.0 + r.size, 0.3)
	Sfx.play("pop", p)
	r.node.queue_free()
	world.remove_target(r.target)
	list.erase(r)


func update(dt: float, prey: Array, goal_cells: Array) -> void:
	time += dt
	field.update(dt, goal_cells)
	castle_field.update(dt, castle_goals.call())
	var reachable := prey.filter(func(q): return q.alive.call() and _grounded(q))
	for r in list.duplicate():
		_think(r, dt, reachable)


## Raiders can't reach hovering Thors or structures in flight.
func _grounded(q: Dictionary) -> bool:
	var p: Vector3 = q.node.position
	return p.y - world.grid.smooth_y(p.x, p.z) < 3.0


func _nearest(from: Vector3, prey: Array, max_d: float, leash_home = null) -> Dictionary:
	var best: Dictionary = {}
	var bd := max_d
	for q in prey:
		var qp: Vector3 = q.node.position
		if leash_home != null and qp.distance_to(leash_home) > Config.NEST_LEASH:
			continue
		var d := Vector2(qp.x - from.x, qp.z - from.z).length()
		if d < bd:
			bd = d
			best = q
	return best


func _think(r: Dictionary, dt: float, prey: Array) -> void:
	var p: Vector3 = r.node.position
	var home: Vector3 = r.nest.pos
	var goal = null  # Vector2 XZ
	var target: Dictionary
	if r.guard:
		target = _nearest(p, prey, Config.NEST_AGGRO, home)
		if target.is_empty():
			goal = _patrol(home, r)
	else:
		target = _nearest(p, prey, Config.RAIDER_AGGRO)
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
			target.hit.call(r.tier.dps * dt)
			_face(r, Vector2(tp.x - p.x, tp.z - p.z))
			r.node.position.y = world.grid.stand_y(p.x, p.z, Grid.Faction.ENEMY) + absf(sin(time * 12.0 + r.phase)) * 0.2
			return
		# Straight at the target; if a wall is in the way (a garrison inside its castle,
		# a cliff), follow the flow field round it instead of pressing into the wall.
		r["detour"] = r.get("detour", 0.0) - dt
		if r.detour <= 0.0:
			if _walk(r, Vector2(tp.x, tp.z), dt):
				return
			r.detour = Config.RAIDER_DETOUR_TIME
		goal = _route(r, p)
	if goal == null:
		return
	_walk(r, goal, dt)


## Castle raiders follow the castle field while it has a route for them; everyone else
## (and castle raiders with no route) follows the field to your structures.
func _route(r: Dictionary, p: Vector3) -> Variant:
	if r.get("mission", "") == "castle" and castle_field.has_goals:
		var s = castle_field.next_step(p.x, p.z)
		if s != null:
			return s
	return field.next_step(p.x, p.z)


## Returns false when the raider couldn't move at all (blocked on both axes).
func _walk(r: Dictionary, goal: Vector2, dt: float) -> bool:
	var p: Vector3 = r.node.position
	var v: Vector2 = goal - Vector2(p.x, p.z)
	if v.length() > 0.001:
		v = v.normalized()
	for o in list:  # separation so a pack doesn't merge into one mesh
		if o == r:
			continue
		var op: Vector3 = o.node.position
		var d := Vector2(p.x - op.x, p.z - op.z)
		var mn: float = r.size + o.size
		if d.length() > 0.001 and d.length() < mn:
			v += d.normalized() * (mn - d.length())
	var step: float = r.tier.speed * dt
	var nx := p.x + v.x * step
	var nz := p.z + v.y * step
	var ws := world.grid.world_size()
	nx = clampf(nx, 0.5, ws.x - 0.5)
	nz = clampf(nz, 0.5, ws.y - 0.5)
	# Per axis, so a cliff blocks that axis and the raider slides along it.
	var moved := false
	if _step_into(p.x, p.z, nx, p.z):
		moved = moved or absf(nx - p.x) > 0.001
		p.x = nx
	if _step_into(p.x, p.z, p.x, nz):
		moved = moved or absf(nz - p.z) > 0.001
		p.z = nz
	p.y = world.grid.stand_y(p.x, p.z, Grid.Faction.ENEMY)
	r.node.position = p
	_face(r, v)
	return moved


## True when the move stays in this cell or enters a neighbour one terrace away.
func _step_into(x0: float, z0: float, x1: float, z1: float) -> bool:
	var g := world.grid
	var a := g.world_to_cell(x0, z0)
	var b := g.world_to_cell(x1, z1)
	if not g.in_bounds(b.x, b.y):
		return false
	# Stay off the sloped foot of a tall wall: the ground there is already partway up it.
	var off := _off_floor(x1, z1, b)
	if off > Config.RAIDER_CLIMB and off > _off_floor(x0, z0, a):
		return false
	if a == b:
		return true
	if maxi(absi(b.x - a.x), absi(b.y - a.y)) > 1:
		return false
	return field.step_ok(a.x, a.y, b.x, b.y)


## How far (levels) the drawn ground at a point sits from its own cell's floor.
func _off_floor(x: float, z: float, c: Vector2i) -> float:
	var g := world.grid
	return absf(g.stand_y(x, z, Grid.Faction.ENEMY) / Config.LEVEL_H - g.walk_height(c.x, c.y, Grid.Faction.ENEMY))


func _patrol(home: Vector3, r: Dictionary) -> Vector2:
	var a: float = time * 0.5 + r.phase
	return Vector2(home.x + cos(a) * 4.0, home.z + sin(a) * 4.0)


func _face(r: Dictionary, d: Vector2) -> void:
	if d.length() > 0.001:
		r.node.rotation.y = atan2(-d.y, d.x)
