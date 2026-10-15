class_name RaiderMove
extends RefCounted
## Raider walking: separation, per-axis terrace stepping, stuck handling (Raiders._walk).
## During Raiders.update the separation pass reads a bucket grid (RAIDER_SEP_BUCKET m) built
## once per frame, so a pack costs a few neighbours each instead of the whole roster.

## Stuck handling: a raider that can only crawl far from its goal for STUCK_TIME
## stops chasing and idles STUCK_REST instead of orbiting it (e.g. a patrol
## point circling behind a wall). Full-speed movement clears it.
const STUCK_TIME := 1.5  # s of crawling before the raider gives up chasing
const STUCK_REST := 2.0  # s of idling before it tries again
const STUCK_ARRIVE := 0.6  # m: close enough to the goal to count as arrived

## Returns false when the raider couldn't move at all (blocked on both axes)
## or is resting after getting stuck.
static func walk(host: Raiders, r: Dictionary, goal: Vector2, dt: float) -> bool:
	var p: Vector3 = r.node.position
	var sx := p.x
	var sz := p.z
	# Resting after getting stuck: idle in place, don't chase.
	var rest: float = maxf(0.0, float(r.get("_stuck_rest", 0.0)) - dt)
	r["_stuck_rest"] = rest
	if rest > 0.0:
		CreatureAnim.move(r.node, 0.0)
		return false
	var v: Vector2 = goal - Vector2(sx, sz)
	if v.length() > 0.001:
		v = v.normalized()
	for o in _neighbours(host, sx, sz):  # separation so a pack doesn't merge into one mesh
		if o == r or not o.alive:
			continue
		var op: Vector3 = o.node.position
		var d := Vector2(sx - op.x, sz - op.z)
		var mn: float = r.size + o.size
		if d.length() > 0.001 and d.length() < mn:
			v += d.normalized() * (mn - d.length())
	v = v.limit_length(1.0)  # separation steers; it must not add speed (a packed group would outrun its slowest)
	var speed: float = RaiderGroups.speed(host, r)
	var step: float = speed * dt
	var nx := sx + v.x * step
	var nz := sz + v.y * step
	var ws := host.world.grid.world_size()
	nx = clampf(nx, 0.5, ws.x - 0.5)
	nz = clampf(nz, 0.5, ws.y - 0.5)
	# Per axis, so a cliff blocks that axis and the raider slides along it.
	var moved := false
	if _step_into(host, sx, sz, nx, sz):
		moved = moved or absf(nx - sx) > 0.001
		p.x = nx
	if _step_into(host, p.x, sz, p.x, nz):
		moved = moved or absf(nz - sz) > 0.001
		p.z = nz
	p.y = RaiderPerch.y(host.world, p.x, p.z)
	r.node.position = p
	host._face(r, v)
	# A stuck raider idles instead of chasing an unreachable point in circles.
	# Stuck = crawling far from the goal (blocked, wall-sliding, hopeless pack
	# jostling). Full-speed chases (kiting targets) and arrived raiders never
	# count as stuck.
	var actual := Vector2(p.x - sx, p.z - sz).length() / maxf(dt, 0.0001)
	var d_after := Vector2(p.x, p.z).distance_to(goal)
	var stuck: float = float(r.get("_stuck_t", 0.0))
	if actual < speed * 0.25 and d_after >= STUCK_ARRIVE:
		stuck += dt
	else:
		stuck = 0.0
	r["_stuck_t"] = stuck
	if stuck > STUCK_TIME:
		r["_stuck_t"] = 0.0
		r["_stuck_rest"] = STUCK_REST
		CreatureAnim.move(r.node, 0.0)
		return false
	# Animate at the speed actually travelled: wall-slides and pack jostling
	# must not play the walk clip at full sprint.
	CreatureAnim.move(r.node, actual if moved else 0.0)
	return moved


## True when the move stays in this cell or enters a neighbour one terrace away.
static func _step_into(host: Raiders, x0: float, z0: float, x1: float, z1: float) -> bool:
	var g := host.world.grid
	var a := g.world_to_cell(x0, z0)
	var b := g.world_to_cell(x1, z1)
	if not g.in_bounds(b.x, b.y):
		return false
	# Stay off the sloped foot of a tall wall: the ground there is already partway up it.
	var off := _off_floor(host, x1, z1, b)
	if off > Config.RAIDER_CLIMB and off > _off_floor(host, x0, z0, a):
		return false
	if a == b:
		return true
	if maxi(absi(b.x - a.x), absi(b.y - a.y)) > 1:
		return false
	return host.field.step_ok(a.x, a.y, b.x, b.y)


## How far (levels) the drawn ground at a point sits from its own cell's floor.
static func _off_floor(host: Raiders, x: float, z: float, c: Vector2i) -> float:
	var g := host.world.grid
	return absf(g.stand_y(x, z, Grid.Faction.ENEMY) / Config.LEVEL_H - g.walk_height(c.x, c.y, Grid.Faction.ENEMY))


## Raiders that could be within separation range: the 3x3 buckets around (x, z), or the whole
## list when called outside Raiders.update (tests).
static func _neighbours(host: Raiders, x: float, z: float) -> Array:
	if not host.in_update:
		return host.list
	var out: Array = []
	var bx := floori(x / Config.RAIDER_SEP_BUCKET)
	var bz := floori(z / Config.RAIDER_SEP_BUCKET)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var b: Variant = host.buckets.get(Vector2i(bx + dx, bz + dz))
			if b != null:
				out.append_array(b)
	return out
