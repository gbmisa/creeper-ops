class_name UnitPaths
extends RefCounted
## Path-request bookkeeping for UnitManager: a per-update time budget for bulk searches (group
## orders, terrain re-paths), a queue for what did not fit, and a cooldown on goals that
## turned out unreachable so nobody re-searches them every second.

var mgr: UnitManager
var queue := {}        # Unit -> Vector2 goal, served in insertion order
var spent_ms := 0.0    # search time used since the last update began
var _fails := {}       # "type:goalIdx" -> game-clock second when the cooldown ends
var _clock := 0.0      # game seconds (sim time, not wall time, so fast headless runs agree)
var searches := 0      # searches run since the last update began (stats/tests)


func _init(m: UnitManager) -> void:
	mgr = m


func begin_update(dt: float) -> void:
	_clock += dt
	spent_ms = 0.0
	searches = 0


func over_budget() -> bool:
	return spent_ms >= Config.PATH_FRAME_MS


func enqueue(u: Unit, goal: Vector2) -> void:
	queue[u] = goal


func clear_fails() -> void:
	_fails.clear()


func forget(u: Unit) -> void:
	queue.erase(u)


## Serve queued requests until the budget is spent (always at least one).
func serve() -> void:
	while not queue.is_empty() and (searches == 0 or not over_budget()):
		var u: Unit = queue.keys()[0]
		var goal: Vector2 = queue[u]
		queue.erase(u)
		u.wait = false
		if u.alive:
			plan(u, goal)


func plan(u: Unit, goal: Vector2) -> void:
	var g := mgr.world.grid
	var world := mgr.world
	var from := g.world_to_cell(u.pos.x, u.pos.z)
	var gc := g.world_to_cell(goal.x, goal.y)
	if world.occupied.call(gc.x, gc.y):
		# Goal inside a structure (e.g. rally set on the barracks): step to the
		# nearest free cell instead of pushing against the wall forever.
		var nc := mgr._free_cell(gc)
		goal = Vector2((nc.x + 0.5) * Config.CELL, (nc.y + 0.5) * Config.CELL)
	var start := from
	var prefix: Array[Vector2] = []
	if world.occupied.call(from.x, from.y):
		# Pathfind can't start inside a solid block (every neighbour is solid):
		# step out to the nearest free cell first. _move allows leaving an
		# occupied cell, so the prefix walks out through the wall.
		var nc := mgr._free_cell(from)
		if nc == from:
			u.path = []
			return
		prefix = [Vector2((nc.x + 0.5) * Config.CELL, (nc.y + 0.5) * Config.CELL)]
		start = nc
	var goal_cell := g.world_to_cell(goal.x, goal.y)
	if failed_recently(u, goal_cell, g.w):
		return   # known unreachable: keep whatever path it has
	var t0 := Time.get_ticks_usec()
	var found := Pathfind.find(g, world.creeper, start, goal_cell, u.def, Config.PATH_MAX_NODES, world.occupied_set)
	note(u, goal_cell, g.w, Pathfind.last_reached, (Time.get_ticks_usec() - t0) / 1000.0)
	u.path = prefix
	u.path.append_array(found)
	if not u.path.is_empty():
		u.path[u.path.size() - 1] = goal


func failed_recently(u: Unit, gc: Vector2i, w: int) -> bool:
	var k := _key(u, gc, w)
	return _fails.has(k) and _clock < _fails[k]


func note(u: Unit, gc: Vector2i, w: int, reached: bool, ms: float) -> void:
	spent_ms += ms
	searches += 1
	var k := _key(u, gc, w)
	if reached:
		_fails.erase(k)
	else:
		_fails[k] = _clock + Config.PATH_FAIL_COOLDOWN
		if _fails.size() > 200:
			_prune()


func _key(u: Unit, gc: Vector2i, w: int) -> String:
	return "%s:%d" % [u.type, gc.y * w + gc.x]


func _prune() -> void:
	var now := _clock
	for k in _fails.keys():
		if _fails[k] <= now:
			_fails.erase(k)
