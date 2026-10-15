class_name RaiderPaths
extends RefCounted
## A melee raider's committed route to its chosen target (state in r["_pt"]). Taking a target
## tests the straight line once; if a cliff or gate blocks it, the raider steps down a walking-
## distance field built for that target (RaiderFieldBuild, time-sliced, shared by every raider
## committed to it, cached per target) until its straight line is clear. Rebuilt only when the
## ground changed (RaiderField.version) or the stuck handling fired. While a field is still
## building, goal() returns null and the caller follows the shared flow field.

const DIRS := RaiderFieldBuild.DIRS

enum { STRAIGHT, WAIT, FIELD }

var host: Raiders
var fields := {}          # target node instance id -> {tgt, dist, build, cell, ver, bver, used, builds, ms, slices, peak}
var spent_ms := 0.0       # field build time used since the last update began
var total_builds := 0     # all target-field builds (tests)
var log = null            # probe only: one {ms, slices, peak} per finished build
var _rr := 0


func _init(h: Raiders) -> void:
	host = h


func begin_update() -> void:
	spent_ms = 0.0


func forget(r: Dictionary) -> void:
	r.erase("_pt")


## Advance target-field builds under RAIDER_TARGET_FIELD_BUDGET_MS (always at least one slice).
func serve() -> void:
	if fields.is_empty():
		return
	var left := int(Config.RAIDER_TARGET_FIELD_BUDGET_MS * 1000.0)
	var ids := fields.keys()
	for k in ids.size():
		var id = ids[(k + _rr) % ids.size()]
		var e: Dictionary = fields[id]
		if not e.tgt.alive.call():
			fields.erase(id)
			continue
		if e.build == null:
			continue
		if e.bver != host.field.version:
			_start(e)
		var t0 := Time.get_ticks_usec()
		var done: bool = e.build.step(maxi(left, 1))
		var us := Time.get_ticks_usec() - t0
		e.ms += us / 1000.0
		e.slices += 1
		e.peak = maxf(e.peak, us / 1000.0)
		spent_ms += us / 1000.0
		left -= us
		if done:
			e.dist = e.build.dist
			e.build = null
			e.ver = e.bver
			if log != null:
				log.append({ "ms": e.ms, "slices": e.slices, "peak": e.peak })
		if left <= 0:
			break
	_rr += 1


## XZ to walk toward `target`, or null to follow the flow field (field building / no route).
func goal(r: Dictionary, target: Dictionary, dt: float) -> Variant:
	var st: Dictionary = r.get("_pt", {})
	var tp: Vector3 = target.node.position
	var tc := host.world.grid.world_to_cell(tp.x, tp.z)
	if st.is_empty() or not is_same(st.tgt, target):
		st = { "tgt": target, "mode": STRAIGHT, "cell": Vector2i(-9, -9), "ver": -1, "stk": false,
			"nostr": false, "here": Vector2i(-9, -9), "next": null, "fver": -2, "rc": Vector2i(-9, -9) }
		r["_pt"] = st
	var p: Vector3 = r.node.position
	if st.ver != host.field.version:
		st.ver = host.field.version
		if st.mode == STRAIGHT:
			st.cell = Vector2i(-9, -9)  # force the straight test below
		elif st.mode == FIELD and not _still_ok(st, p):
			_request(st, target, false)  # ground changed under the route: rebuild, keep stepping the old field meanwhile
	var rest := float(r.get("_stuck_rest", 0.0)) > 0.0
	if rest and not st.stk:
		st.stk = true
		st.nostr = true  # the stuck handling fired: the straight line does not work
		st.here = Vector2i(-9, -9)
		_request(st, target, true)
	elif not rest:
		st.stk = false
	var moving := not target.has("struct")  # units and the Operative: lock on, test per cell change
	if st.mode == STRAIGHT:
		var rc := Vector2i(-9, -9)
		if moving:
			rc = host.world.grid.world_to_cell(p.x, p.z)
		if tc != st.cell or rc != st.rc:
			st.cell = tc
			st.rc = rc
			if not _clear(Vector2(p.x, p.z), Vector2(tp.x, tp.z), _reach(r, target)):
				_request(st, target, false)
				return null
		return Vector2(tp.x, tp.z)
	var e: Dictionary = fields.get(target.node.get_instance_id(), {})
	if e.is_empty() or e.dist.is_empty():
		return null  # still building the first field
	if st.mode == WAIT:
		st.mode = FIELD
		st.here = Vector2i(-9, -9)
	e.used = host.time
	if moving and e.build == null:
		_request(st, target, false)  # rebuilds only past RAIDER_REPATH_CELLS and RAIDER_REPATH_MIN
	var c := host.world.grid.world_to_cell(p.x, p.z)
	if c != st.here or e.ver != st.fver:
		st.here = c
		st.fver = e.ver
		if not st.nostr and _clear(Vector2(p.x, p.z), Vector2(tp.x, tp.z), _reach(r, target)):
			st.mode = STRAIGHT
			st.cell = tc
			return Vector2(tp.x, tp.z)
		st.next = _descend(e.dist, c)
	if st.next == null:
		return Vector2(tp.x, tp.z)  # on the goal cell, or no walking route: press toward it (as integ did)
	return st.next


## Remaining steps (cells * CELL, m) along the field for a raider walking one, else -1. Tests.
func remaining(r: Dictionary) -> float:
	var st: Dictionary = r.get("_pt", {})
	if st.is_empty() or st.mode != FIELD:
		return -1.0
	var e: Dictionary = fields.get(st.tgt.node.get_instance_id(), {})
	if e.is_empty() or e.dist.is_empty():
		return -1.0
	var p: Vector3 = r.node.position
	var c := host.world.grid.world_to_cell(p.x, p.z)
	return float(e.dist[host.world.grid.idx(c.x, c.y)]) * Config.CELL


## Field builds so far for the raider's current target (tests; other raiders have their own).
func builds_for(r: Dictionary) -> int:
	var st: Dictionary = r.get("_pt", {})
	if st.is_empty():
		return 0
	return int(fields.get(st.tgt.node.get_instance_id(), {}).get("builds", 0))


func _request(st: Dictionary, target: Dictionary, force: bool) -> void:
	if st.mode == STRAIGHT:
		st.mode = WAIT
	var tp: Vector3 = target.node.position
	var tc := host.world.grid.world_to_cell(tp.x, tp.z)
	var id: int = target.node.get_instance_id()
	var e: Dictionary = fields.get(id, {})
	if e.is_empty():
		e = { "tgt": target, "dist": PackedInt32Array(), "build": null, "cell": tc, "ver": -1, "bver": -1,
			"used": host.time, "t_build": -1.0e9, "builds": 0, "ms": 0.0, "slices": 0, "peak": 0.0 }
		fields[id] = e
		_evict()
	e.used = host.time
	var stale: bool = e.ver != host.field.version
	if not stale:
		if target.has("struct"):
			stale = e.cell != tc
		else:  # a moving target: keep the old field until it is well away from the field's goal, and not too often
			var off := Vector2(tc - e.cell).length()
			stale = off > Config.RAIDER_REPATH_CELLS and host.time - float(e.t_build) >= Config.RAIDER_REPATH_MIN
	if e.build == null and (force or stale):
		e.cell = tc
		_start(e)


func _start(e: Dictionary) -> void:
	var tp: Vector3 = e.tgt.node.position
	e.cell = host.world.grid.world_to_cell(tp.x, tp.z)
	e.build = RaiderFieldBuild.new(host.world.grid, host.field.walk_heights(), [e.cell])
	e.bver = host.field.version
	e.t_build = host.time
	e.ms = 0.0
	e.slices = 0
	e.peak = 0.0
	e.builds += 1
	total_builds += 1


## After a terrain change: do the next few steps down the field still pass step_ok?
func _still_ok(st: Dictionary, p: Vector3) -> bool:
	var e: Dictionary = fields.get(st.tgt.node.get_instance_id(), {})
	if e.is_empty() or e.dist.is_empty():
		return false
	var g := host.world.grid
	var c := g.world_to_cell(p.x, p.z)
	for k in Config.RAIDER_FIELD_CHECK_STEPS:
		var bd: int = e.dist[g.idx(c.x, c.y)]
		if bd == 0:
			return true
		var nxt = _descend(e.dist, c)
		if nxt == null:
			return false
		c = g.world_to_cell(nxt.x, nxt.y)
	return true


func _evict() -> void:
	while fields.size() > Config.RAIDER_TARGET_FIELDS:
		var oldest = null
		for id in fields:
			if oldest == null or fields[id].used < fields[oldest].used:
				oldest = id
		fields.erase(oldest)


func _reach(r: Dictionary, target: Dictionary) -> float:
	return float(target.radius) + float(r.size) + 0.5


## Centre (world XZ) of the lowest-distance neighbour, the same rule as RaiderField.next_step.
func _descend(dist: PackedInt32Array, c: Vector2i) -> Variant:
	var g := host.world.grid
	if not g.in_bounds(c.x, c.y):
		return null
	var bd := dist[g.idx(c.x, c.y)]
	if bd <= 0:
		return null  # no route (-1) or already on the goal cell
	var best := c
	for d in DIRS:
		var n: Vector2i = c + d
		if not g.in_bounds(n.x, n.y) or not host.field.step_ok(c.x, c.y, n.x, n.y):
			continue
		var v := dist[g.idx(n.x, n.y)]
		if v >= 0 and v < bd:
			bd = v
			best = n
	if best == c:
		return null
	return Vector2((best.x + 0.5) * Config.CELL, (best.y + 0.5) * Config.CELL)


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
