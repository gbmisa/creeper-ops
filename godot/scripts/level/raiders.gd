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
var time := 0.0


func _init(w: World) -> void:
	world = w
	field = RaiderField.new(w.grid)


func spawn(nest: Dictionary, tier: Dictionary, guard: bool) -> void:
	var node := mesh(tier)
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
			goal = field.next_step(p.x, p.z)
			if goal == null:
				target = _nearest_on_foot(p, prey)
				if target.is_empty():
					r.guard = true
					goal = _patrol(home, r)
	if not target.is_empty():
		var tp: Vector3 = target.node.position
		var reach: float = target.radius + r.size + 0.5
		if Vector2(tp.x - p.x, tp.z - p.z).length() <= reach:
			target.hit.call(r.tier.dps * dt)
			_face(r, Vector2(tp.x - p.x, tp.z - p.z))
			r.node.position.y = world.grid.smooth_y(p.x, p.z) + absf(sin(time * 12.0 + r.phase)) * 0.2
			return
		goal = Vector2(tp.x, tp.z)
	if goal == null:
		return
	_walk(r, goal, dt)


func _walk(r: Dictionary, goal: Vector2, dt: float) -> void:
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
	if _step_into(p.x, p.z, nx, p.z):
		p.x = nx
	if _step_into(p.x, p.z, p.x, nz):
		p.z = nz
	p.y = world.grid.smooth_y(p.x, p.z)
	r.node.position = p
	_face(r, v)


## True when the move stays in this cell or enters a neighbour one terrace away.
func _step_into(x0: float, z0: float, x1: float, z1: float) -> bool:
	var g := world.grid
	var a := g.world_to_cell(x0, z0)
	var b := g.world_to_cell(x1, z1)
	if a == b:
		return true
	if not g.in_bounds(b.x, b.y):
		return false
	if maxi(absi(b.x - a.x), absi(b.y - a.y)) > 1:
		return false
	return field.step_ok(a.x, a.y, b.x, b.y)


func _patrol(home: Vector3, r: Dictionary) -> Vector2:
	var a: float = time * 0.5 + r.phase
	return Vector2(home.x + cos(a) * 4.0, home.z + sin(a) * 4.0)


## Nearest prey that shares a one-terrace walking route, or {}.
func _nearest_on_foot(from: Vector3, prey: Array) -> Dictionary:
	var g := world.grid
	var start := g.world_to_cell(from.x, from.z)
	if not g.in_bounds(start.x, start.y):
		return {}
	var at := {}
	for q in prey:
		if not q.alive.call():
			continue
		var qp: Vector3 = q.node.position
		var c := g.world_to_cell(qp.x, qp.z)
		if not g.in_bounds(c.x, c.y):
			continue
		var i := g.idx(c.x, c.y)
		if not at.has(i):
			at[i] = []
		(at[i] as Array).append(q)
	var seen := PackedByteArray()
	seen.resize(g.w * g.h)
	var open := PackedInt32Array()
	open.append(g.idx(start.x, start.y))
	seen[g.idx(start.x, start.y)] = 1
	var best: Dictionary = {}
	var bd := INF
	var head := 0
	while head < open.size():
		var b := open[head]
		head += 1
		var bx := b % g.w
		var bz := int(b / g.w)
		if at.has(b):
			for q in at[b]:
				var qp: Vector3 = q.node.position
				var d := Vector2(qp.x - from.x, qp.z - from.z).length()
				if d < bd:
					bd = d
					best = q
		for dir in RaiderField.DIRS:
			var nx: int = bx + dir.x
			var nz: int = bz + dir.y
			if not g.in_bounds(nx, nz) or not field.step_ok(bx, bz, nx, nz):
				continue
			var ni := g.idx(nx, nz)
			if seen[ni] != 0:
				continue
			seen[ni] = 1
			open.append(ni)
	return best


func _face(r: Dictionary, d: Vector2) -> void:
	if d.length() > 0.001:
		r.node.rotation.y = atan2(-d.y, d.x)


## Six-legged bug facing +X, scaled by tier size, glowing in the tier colour.
static func mesh(tier: Dictionary) -> Node3D:
	var root := Node3D.new()
	var s: float = tier.size
	var shell := StructureMeshes.mat(Color("1e2414"), 0.2, 0.6)
	var glow := StructureMeshes.mat(tier.color, 0.0, 0.3, tier.color, 2.0)
	var body := StructureMeshes.ball(root, s * 0.55, shell, Vector3(0, s * 0.6, 0))
	body.scale = Vector3(1.5, 0.8, 1.0)
	StructureMeshes.ball(root, s * 0.32, glow, Vector3(s * 0.75, s * 0.65, 0))
	StructureMeshes.ball(root, s * 0.3, glow, Vector3(-s * 0.55, s * 0.85, 0))
	for i in 3:
		for side in [-1.0, 1.0]:
			var leg := StructureMeshes.box(root, Vector3(s * 0.12, s * 0.12, s * 0.9), shell,
				Vector3((i - 1) * s * 0.45, s * 0.35, side * s * 0.55))
			leg.rotation.x = side * 0.7
	return root
