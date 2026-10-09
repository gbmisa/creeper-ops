class_name UnitPatrol
## Patrol orders: a unit loops through a list of world xz points forever. It walks the path
## to the current point; attack-move (UnitManager.update) pauses the walk to fight anything in
## gun range, so the route simply continues afterwards. Resupply trips keep the route and
## resume it from the nearest point. UnitManager.order (any move order) clears it.


## Give every unit the loop `pts`. One point patrols between the unit's own spot and that point.
static func assign(mgr: UnitManager, units: Array, pts: Array) -> void:
	for u in units:
		var route: Array[Vector2] = []
		route.assign(pts)
		if route.size() == 1:
			route.push_front(Vector2(u.pos.x, u.pos.z))
		u.patrol = route
		u.patrol_laps = 0
		u.patrol_wait = 0.0
		if u.state != "resupply":
			resume(mgr, u)


## Head for the point nearest the unit (start, or back from resupply).
static func resume(mgr: UnitManager, u: Unit) -> void:
	var here := Vector2(u.pos.x, u.pos.z)
	var best := 0
	for i in u.patrol.size():
		if here.distance_squared_to(u.patrol[i]) < here.distance_squared_to(u.patrol[best]):
			best = i
	u.patrol_i = best
	_go(mgr, u)


## Reached the current point: aim for the next one.
static func advance(mgr: UnitManager, u: Unit, dt: float) -> void:
	u.patrol_wait -= dt
	if u.patrol.is_empty() or u.patrol_wait > 0.0:
		return
	u.patrol_i = (u.patrol_i + 1) % u.patrol.size()
	if u.patrol_i == 0:
		u.patrol_laps += 1
	_go(mgr, u)


static func _go(mgr: UnitManager, u: Unit) -> void:
	u.state = "patrol"
	u.post = u.patrol[u.patrol_i]
	mgr.walk_to(u, u.post)
	u.patrol_wait = 0.0 if not u.path.is_empty() else 1.0  # unreachable point: retry later


## A unit from a barracks inside a held castle garrisons its courtyard without orders.
static func auto_castle(mgr: UnitManager, u: Unit, at: Vector3) -> void:
	if mgr.castles == null:
		return
	var c := CastleVaults.castle_at(mgr.castles, mgr.world.grid.world_to_cell(at.x, at.z))
	if c.is_empty() or c.owner != "player":
		return
	var route := courtyard_loop(mgr.castles.lays[c.id])
	if route.size() >= 2:
		assign(mgr, [u], route)


## Four corners of the courtyard's bounding box, pulled in and snapped to open yard cells.
static func courtyard_loop(lay: Dictionary) -> Array[Vector2]:
	var yard: Array = lay.courtyard
	var out: Array[Vector2] = []
	if yard.is_empty():
		return out
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for c in yard:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var ins := mini(Config.PATROL_INSET, mini(hi.x - lo.x, hi.y - lo.y) / 2)
	var seen := {}
	for corner in [Vector2i(lo.x + ins, lo.y + ins), Vector2i(hi.x - ins, lo.y + ins),
			Vector2i(hi.x - ins, hi.y - ins), Vector2i(lo.x + ins, hi.y - ins)]:
		var best: Vector2i = yard[0]
		for c in yard:
			if (c - corner).length_squared() < (best - corner).length_squared():
				best = c
		if not seen.has(best):
			seen[best] = true
			out.append(Vector2((best.x + 0.5) * Config.CELL, (best.y + 0.5) * Config.CELL))
	return out
