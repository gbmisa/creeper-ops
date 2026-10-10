class_name RaiderPaths
extends RefCounted
## A melee raider's committed route to its chosen target (state in r["_pt"]). Taking a target
## tests the straight line once; if a cliff or gate blocks it, one A* search (budgeted queue,
## like UnitPaths) gives waypoints that are then followed, not re-picked. Re-plans only when the
## route is broken (terrain or gate change), the raider got stuck, or the path ended short of
## the target. While a search waits, goal() returns null and the caller follows the flow field.

const DEF := { "climb": Config.RAIDER_CLIMB, "drop": Config.RAIDER_DROP,
	"faction": Grid.Faction.ENEMY, "ignore_creeper": true, "corners": true }
const ARRIVE := 0.8  # m: a waypoint counts as reached

enum { STRAIGHT, WAIT, PATH }

var host: Raiders
var queue: Array = []   # raiders waiting for a search, first in first out (flag r._pq; never a dict key: raiders mutate)
var spent_ms := 0.0     # search time used since the last update began
var searches := 0       # searches since the last update began
var total_searches := 0  # all searches (tests)


func _init(h: Raiders) -> void:
	host = h


func begin_update() -> void:
	spent_ms = 0.0
	searches = 0


func forget(r: Dictionary) -> void:
	r.erase("_pt")
	r.erase("_pq")


## Serve queued searches until the budget is spent (always at least one).
func serve() -> void:
	while not queue.is_empty() and (searches == 0 or spent_ms < Config.RAIDER_PATH_FRAME_MS):
		var r: Dictionary = queue.pop_front()
		if r.erase("_pq") and r.alive and r.has("_pt"):
			_plan(r)


## XZ to walk toward `target`, or null to follow the flow field (search pending / path spent).
func goal(r: Dictionary, target: Dictionary, dt: float) -> Variant:
	var st: Dictionary = r.get("_pt", {})
	var tp: Vector3 = target.node.position
	var tc := host.world.grid.world_to_cell(tp.x, tp.z)
	if st.is_empty() or not is_same(st.tgt, target):
		st = { "tgt": target, "mode": STRAIGHT, "wps": [], "i": 0, "cell": Vector2i(-9, -9),
			"ver": -1, "stk": false, "next": 0.0 }
		r["_pt"] = st
	var p: Vector3 = r.node.position
	var broken := false
	if st.ver != host.field.version:
		st.ver = host.field.version
		broken = st.mode != WAIT and (st.mode == STRAIGHT or not _route_clear(st, p, target))
		if st.mode == STRAIGHT:
			st.cell = Vector2i(-9, -9)  # force the straight test below
			broken = false
	var rest := float(r.get("_stuck_rest", 0.0)) > 0.0
	if rest and not st.stk:
		st.stk = true
		broken = true  # the stuck handling fired: the route we are on does not work
	elif not rest:
		st.stk = false
	if broken:
		_request(r, st)
	if st.mode == STRAIGHT:
		if tc != st.cell:
			st.cell = tc
			if not _clear(Vector2(p.x, p.z), Vector2(tp.x, tp.z), _reach(r, target)):
				_request(r, st)
				return null
		return Vector2(tp.x, tp.z)
	if st.mode == WAIT:
		return null
	var wps: Array = st.wps
	var i: int = st.i
	var here := Vector2(p.x, p.z)
	while i < wps.size() and here.distance_to(wps[i]) < ARRIVE:
		i += 1
	st.i = i
	if i >= wps.size():
		if host.time >= st.next:  # ended short of striking distance
			st.next = host.time + Config.RAIDER_REPLAN_MIN
			_request(r, st)
		return null
	return wps[i]


func _request(r: Dictionary, st: Dictionary) -> void:
	st.mode = WAIT
	if not r.has("_pq"):
		r["_pq"] = true
		queue.append(r)


func _plan(r: Dictionary) -> void:
	var st: Dictionary = r._pt
	var target: Dictionary = st.tgt
	if not target.alive.call():
		return
	var g := host.world.grid
	var p: Vector3 = r.node.position
	var tp: Vector3 = target.node.position
	var gc := g.world_to_cell(tp.x, tp.z)
	var t0 := Time.get_ticks_usec()
	var found := Pathfind.find(g, host.world.creeper, g.world_to_cell(p.x, p.z), gc, DEF, Config.RAIDER_PATH_MAX_NODES)
	spent_ms += (Time.get_ticks_usec() - t0) / 1000.0
	searches += 1
	total_searches += 1
	st.wps = found
	st.i = 0
	st.cell = gc
	st.ver = host.field.version
	st.mode = PATH
	r["_searches"] = int(r.get("_searches", 0)) + 1
	st.next = host.time + Config.RAIDER_REPLAN_MIN


func _reach(r: Dictionary, target: Dictionary) -> float:
	return float(target.radius) + float(r.size) + 0.5


## Is the rest of the committed path (from here through the remaining waypoints) still walkable?
func _route_clear(st: Dictionary, p: Vector3, target: Dictionary) -> bool:
	var wps: Array = st.wps
	var a := Vector2(p.x, p.z)
	for k in range(st.i, wps.size()):
		if not _clear(a, wps[k], 0.0):
			return false
		a = wps[k]
	return true


## Walk the cells under the segment a->b (quarter-cell samples); every cell change must pass
## RaiderField.step_ok. Stops early, as success, once within `reach` of b (melee strikes across).
func _clear(a: Vector2, b: Vector2, reach: float) -> bool:
	var g := host.world.grid
	var n := maxi(1, ceili(a.distance_to(b) / (Config.CELL * 0.25)))
	var cur := g.world_to_cell(a.x, a.y)
	for k in range(1, n + 1):
		var s := a.lerp(b, float(k) / n)
		if reach > 0.0 and s.distance_to(b) <= reach:
			return true
		var c := g.world_to_cell(s.x, s.y)
		if c == cur:
			continue
		if not host.field.step_ok(cur.x, cur.y, c.x, c.y):
			return false
		cur = c
	return true
