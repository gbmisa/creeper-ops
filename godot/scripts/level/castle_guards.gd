class_name CastleGuards
extends RefCounted
## Sentinels: long-range guards posted on the tower tops and wall walk of HOSTILE castles
## (level rows with a `guards` count). They exist from the first second, never move, and
## outrange a Sniper (Config.GUARD_RANGE cells). Fair by design:
##  - a target needs line of sight (Grid.raycast), so hills and walls give cover
##  - each shot is announced by a glow that swells for GUARD_CHARGE seconds, then a slow
##    arcing bolt flies to the spot the target stood at the moment of firing, so anyone who
##    keeps moving is missed; whatever is still there when it lands takes the damage
## Killing the crown nest clears the garrison; a slot regrows after GUARD_RESPAWN while the
## castle is hostile again. They are Operative targets, unit enemies and sniper/Lance foes.

var world: World
var castles: Strongholds
var prey := func() -> Array: return []  # injected: { node, radius, alive, hit, kind? }
var list: Array[Dictionary] = []        # one slot per post
var time := 0.0


func _init(w: World, s: Strongholds, rows: Array) -> void:
	world = w
	castles = s
	for row in rows:
		if row.get("guards", 0) <= 0:
			continue
		var c: Dictionary = s.list.filter(func(x): return x.id == row.id)[0]
		for p in posts(w.grid, row.layout, row.guards):
			var slot := { "castle": c, "post": p, "alive": false, "hp": 0.0, "node": null, "timer": 0.0,
				"index": list.size(), "cd": 0.0, "charge": -1.0, "aim": null, "glow": null }
			list.append(slot)
			_spawn(slot)
	w.updaters.append(update)


## Tower tops first (concentric: not the war engines' corner towers; then the keep roof), then
## evenly spread points along the wall walk.
static func posts(g: Grid, lay: Dictionary, count: int) -> Array:
	var spots: Array[Vector2i] = []
	var engines: Array = lay.get("engine_posts", [])
	var towers: Array = lay.towers.filter(func(t): return not engines.has(t.centre))
	for k in lay.get("keep_posts", []):
		towers.append({ "centre": k })
	var from_towers := mini(count, towers.size())
	for i in from_towers:
		spots.append(towers[i * towers.size() / from_towers].centre)
	var segs: Array = lay.segments
	var rest := mini(count - from_towers, segs.size())
	for i in rest:
		var cells: Array = segs[i * segs.size() / rest].cells
		spots.append(cells[cells.size() / 2])
	var out := []
	for c in spots:
		out.append(g.cell_ground(c.x, c.y))
	return out


func enemies() -> Array:
	return list.filter(func(s): return s.alive).map(func(s): return s.enemy)  # engines come via Strongholds.enemies


## Live Sentinels and castle war engines (each has `node` and `enemy.hit`): what Snipers and
## the Lance may hit.
func foes() -> Array:
	return list.filter(func(s): return s.alive) + CastleEngines.foes(castles)


func alive_at(castle_id: String) -> int:
	return list.filter(func(s): return s.alive and s.castle.id == castle_id).size()


func _spawn(s: Dictionary) -> void:
	var node := HazardMeshes.raider(Config.SENTINEL)
	node.scale = Vector3.ONE * 1.5
	node.position = s.post
	var glow := StructureMeshes.ball(node, 0.45, StructureMeshes.mat(Config.SENTINEL.color, 0.0, 0.2, Config.SENTINEL.color, 3.0), Vector3(0, 2.1, 0))
	glow.scale = Vector3.ONE * 0.25
	world.add_child(node)
	s.node = node
	s.glow = glow
	s.alive = true
	s.hp = Config.SENTINEL.hp
	s.cd = 1.0 + randf() * 2.0
	s.charge = -1.0
	var size: float = Config.SENTINEL.size
	var hit := func(dmg: float, _p = null): _hurt(s, dmg)
	s["enemy"] = { "node": node, "oy": size * 1.2, "radius": size * 1.2, "alive": func(): return s.alive, "hit": hit }
	s["target"] = { "node": node, "oy": size * 1.2, "radius": size * 1.2, "alive": func(): return s.alive, "on_hit": hit }
	world.add_target(s.target)


func _hurt(s: Dictionary, dmg: float) -> void:
	if not s.alive:
		return
	s.hp -= dmg
	if s.hp <= 0.0:
		_remove(s, true)


func _remove(s: Dictionary, killed: bool) -> void:
	s.alive = false
	s.timer = 0.0
	s.charge = -1.0
	world.remove_target(s.target)
	if killed:
		world.effects.burst(s.post + Vector3.UP * 2.0, Config.SENTINEL.color, 3.0, 0.4)
		Sfx.play("pop", s.post)
	(s.node as Node3D).queue_free()
	s.node = null


func update(dt: float) -> void:
	time += dt
	for s in list:
		if s.castle.state != "hostile":
			if s.alive:
				_remove(s, true)  # the crown nest fell: the garrison with it
			s.timer = 0.0
		elif not s.alive:
			s.timer += dt
			if s.timer >= Config.GUARD_RESPAWN * (1.0 + 0.15 * (s.index % 4)):
				_spawn(s)
		else:
			_tick(s, dt)


func _tick(s: Dictionary, dt: float) -> void:
	var node: Node3D = s.node
	node.position.y = world.grid.smooth_y(s.post.x, s.post.z)  # follows the wall if it is breached
	if s.charge >= 0.0:
		s.charge -= dt
		var k: float = 1.0 - maxf(s.charge, 0.0) / Config.GUARD_CHARGE
		(s.glow as Node3D).scale = Vector3.ONE * lerpf(0.4, 2.2, k)
		if s.aim != null:
			_face(node, s.aim)
		if s.charge < 0.0:
			_fire(s)
		return
	(s.glow as Node3D).scale = Vector3.ONE * (0.3 + 0.05 * sin(time * 3.0 + s.index))
	s.cd -= dt
	if s.cd > 0.0:
		return
	var q := pick(s.node.position, prey.call())
	if q.is_empty():
		s.cd = 0.25
		return
	s["target_q"] = q
	s.aim = q.node.position
	s.charge = Config.GUARD_CHARGE
	Sfx.play("lift", node.position)


## Nearest prey in range with a clear line from a post at `at` (feet), or {}.
func pick(at: Vector3, prey_list: Array) -> Dictionary:
	var reach := Config.GUARD_RANGE * Config.CELL
	var cands := []
	for q in prey_list:
		if not q.alive.call():
			continue
		var d := Vector2(q.node.position.x - at.x, q.node.position.z - at.z).length()
		if d <= reach:
			cands.append([d, q])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	for i in mini(3, cands.size()):
		if line_clear(at, cands[i][1].node.position):
			return cands[i][1]
	return {}


## True when terrain does not hide `to` from a Sentinel's eye above `at`.
func line_clear(at: Vector3, to: Vector3) -> bool:
	var eye := at + Vector3(0, 2.4, 0)
	var goal := to + Vector3(0, 1.0, 0)
	var dist := eye.distance_to(goal)
	var hit = world.grid.raycast(eye, (goal - eye) / dist, dist)
	return hit == null or eye.distance_to(hit) >= dist - 1.0


func _fire(s: Dictionary) -> void:
	s.cd = Config.GUARD_INTERVAL
	var q: Dictionary = s.get("target_q", {})
	s.aim = null
	var node: Node3D = s.node
	var from := node.position + Vector3(0, 2.4, 0)
	if q.is_empty() or not q.alive.call():
		return
	var aim: Vector3 = q.node.position  # where it stands NOW; the bolt takes seconds to land
	var dist := from.distance_to(aim)
	if dist > Config.GUARD_RANGE * Config.CELL * 1.1:
		return
	world.effects.lob(from, aim, { "color": Config.SENTINEL.color, "size": 0.6, "time": maxf(dist / Config.GUARD_BOLT_SPEED, 1.0),
		"arc": clampf(dist * 0.22, 3.0, 14.0), "on_arrive": func(): impact(aim) })
	Sfx.play("mortar", from)


## A bolt lands at `at`: everything still within GUARD_BOLT_RADIUS takes its damage.
func impact(at: Vector3) -> void:
	world.effects.burst(at + Vector3.UP * 0.4, Config.SENTINEL.color, Config.GUARD_BOLT_RADIUS * 1.6, 0.4)
	Sfx.play("boom", at)
	for q in prey.call():
		if not q.alive.call():
			continue
		var p: Vector3 = q.node.position
		if Vector2(p.x - at.x, p.z - at.z).length() > Config.GUARD_BOLT_RADIUS + q.radius or absf(p.y - at.y) > 3.0:
			continue
		var dmg: float = { "operative": Config.GUARD_DMG_OPERATIVE, "unit": Config.GUARD_DMG_UNIT }.get(q.get("kind", ""), Config.GUARD_DMG_STRUCT)
		q.hit.call(dmg)


static func _face(node: Node3D, to: Vector3) -> void:
	var d := to - node.position
	node.rotation.y = atan2(-d.z, d.x)
