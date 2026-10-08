class_name CastleEngines
## War engines of a hostile concentric castle (docs/CASTLES2_DESIGN.md §4): trebuchets on the
## outer corner tower roofs. Each picks a target in range (weapons first, then structures, the
## Operative when it can see it, units), marks the spot with a growing ground ring for
## ENGINE.telegraph seconds, then a stone lands there: whatever is still inside the blast is hit.
## Kill them (Operative, Snipers, Lance) to unlock the bailey stage; once the bailey is yours
## they are gone for good, until the castle falls again. State per castle (saveable):
##   c.engines = [{ post: Vector2i, hp, max_hp, cd, dead, shot: {} | { at: Vector3, t, whistled } }]

const E := CastleDefs.ENGINE
const POST_ORDER := [0, 3, 1, 2]  # opposite corners first

static var rings: Array = []  # this frame's telegraph rings, Vector4(x, z, radius m, 1)


static func new_state(row: Dictionary, lay: Dictionary) -> Array:
	var out := []
	var posts: Array = lay.get("engine_posts", [])
	var n: int = mini(posts.size(), row.get("engines", CastleDefs.ENGINES_DEFAULT if not posts.is_empty() else 0))
	for i in n:
		out.append({ "post": posts[POST_ORDER[i % 4]], "hp": E.hp, "max_hp": E.hp, "cd": 3.0 + 2.0 * i, "dead": 0.0, "shot": {} })
	return out


## Engines fire while the castle is hostile and its bailey still the enemy's.
static func active(c: Dictionary) -> bool:
	return c.state == "hostile" and int(c.get("stage", 0)) < 2


static func alive(e: Dictionary) -> bool:
	return e.hp > 0.0


static func alive_count(c: Dictionary) -> int:
	return c.get("engines", []).filter(func(e): return alive(e)).size()


## Models, Operative targets and foe rows (units, Snipers, the Lance) for one castle.
static func attach(s: Strongholds, c: Dictionary, v: Dictionary) -> void:
	v["engines"] = []
	v["engine_foes"] = []
	for i in c.engines.size():  # closures read c.engines[i] live, so load_state keeps working
		var post: Vector2i = c.engines[i].post
		var node := CastleEngineMeshes.trebuchet()
		node.position = s.world.grid.cell_ground(post.x, post.y)
		node.rotation.y = randf() * TAU
		s.world.add_child(node)
		v.engines.append(node)
		var hit := func(d, _p = null): _hurt(s, c, c.engines[i], node, d)
		var live := func(): return alive(c.engines[i]) and active(c)
		s.world.add_target({ "node": node, "radius": 1.6, "oy": 1.5, "alive": live, "on_hit": hit })
		var foe := { "node": node, "oy": 1.5, "radius": 1.6, "alive": live, "hit": hit }
		v.engine_foes.append({ "node": node, "enemy": foe, "alive": live })


static func _hurt(s: Strongholds, c: Dictionary, e: Dictionary, node: Node3D, d: float) -> void:
	if not alive(e) or not active(c):
		return
	e.hp -= d
	if e.hp > 0.0:
		return
	e.hp = 0.0
	e.dead = 0.0
	e.shot = {}
	s.world.effects.burst(node.position + Vector3.UP * 2.0, Color("ffb347"), 5.0, 0.7)
	Sfx.play("boom", node.position)
	var left := alive_count(c)
	Bus.say("%s: trebuchet destroyed (%d left)." % [c.name, left] + (" The bailey can be taken." if left == 0 else ""), "good")


static func tick(s: Strongholds, c: Dictionary, v: Dictionary, prey: Array, dt: float) -> void:
	var on := active(c)
	for i in c.engines.size():
		var e: Dictionary = c.engines[i]
		var node: Node3D = v.engines[i]
		node.visible = alive(e) and on
		if not alive(e):
			e.dead += dt
			if on and int(c.get("stage", 0)) < 2 and e.dead >= E.respawn:
				e.hp = e.max_hp
				e.cd = E.interval
			continue
		if not on:
			e.shot = {}
			continue
		if not e.shot.is_empty():
			_flight(s, e, prey, dt)
			continue
		e.cd -= dt
		if e.cd > 0.0:
			continue
		var q := pick(s.world.grid, node.position, prey)
		if q.is_empty():
			e.cd = 1.0
			continue
		e.cd = E.interval
		e.shot = { "at": (q.node as Node3D).position, "t": 0.0, "whistled": false }
		CastleEngineMeshes.throw(node, q.node.position)
		Sfx.play("thump", node.position)
	for e in c.engines:
		if alive(e) and on and not e.shot.is_empty():
			var k: float = clampf(e.shot.t / E.telegraph, 0.0, 1.0)
			rings.append(Vector4(e.shot.at.x, e.shot.at.z, lerpf(0.6, E.blast * Config.CELL, k), 1.0))


static func _flight(s: Strongholds, e: Dictionary, prey: Array, dt: float) -> void:
	var shot: Dictionary = e.shot
	shot.t += dt
	if shot.t >= E.telegraph - E.whistle and not shot.whistled:
		shot.whistled = true
		Sfx.play("whistle", shot.at)
	if shot.t < E.telegraph:
		return
	e.shot = {}
	impact(s.world, shot.at, prey)


## Nearest prey in the best band within [min_range, range] cells of `from`, or {}.
static func pick(g: Grid, from: Vector3, prey: Array) -> Dictionary:
	var best := {}
	var band := 0
	var near := INF
	for q in prey:
		if not q.alive.call() or q.get("wall", false):
			continue
		var p: Vector3 = (q.node as Node3D).position
		var cells := Vector2(p.x - from.x, p.z - from.z).length() / Config.CELL
		if cells < E.min_range or cells > E.range:
			continue
		var kind: String = q.get("kind", "")
		var b := 1 if kind == "unit" else (3 if q.get("weapon", false) else 2)
		if kind == "operative" and not _sees(g, from, p):
			continue
		if b > band or (b == band and cells < near):
			best = q
			band = b
			near = cells
	return best


static func _sees(g: Grid, from: Vector3, to: Vector3) -> bool:
	var eye := from + Vector3(0, 3.0, 0)
	var goal := to + Vector3(0, 1.2, 0)
	var dist := eye.distance_to(goal)
	if dist > E.sight * Config.CELL:
		return false
	var hit = g.raycast(eye, (goal - eye) / dist, dist)
	return hit == null or eye.distance_to(hit) >= dist - 1.0


## A stone lands at `at`: everything still inside the blast takes its damage.
static func impact(world: World, at: Vector3, prey: Array) -> void:
	world.effects.burst(at + Vector3.UP * 0.5, Color("c8b089"), E.blast * Config.CELL, 0.5)
	Sfx.play("boom", at)
	var r: float = E.blast * Config.CELL
	for q in prey:
		if not q.alive.call():
			continue
		var p: Vector3 = (q.node as Node3D).position
		if Vector2(p.x - at.x, p.z - at.z).length() > r + float(q.get("radius", 0.5)) or absf(p.y - at.y) > 3.0:
			continue
		var kind: String = q.get("kind", "")
		q.hit.call(E.dmg_operative if kind == "operative" else (E.dmg_unit if kind == "unit" else E.dmg_struct))


static func foes(s: Strongholds) -> Array:
	var out := []
	for v in s.views.values():
		for f in v.get("engine_foes", []):
			if f.alive.call():
				out.append(f)
	return out
