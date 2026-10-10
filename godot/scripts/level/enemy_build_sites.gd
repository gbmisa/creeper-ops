class_name EnemyBuildSites
## Edge-site search for enemy towers (§4.5). Candidates are scored cheaply, then the
## costly fair-spitter test runs best-first under a time budget, with results cached
## until the terrain changes (b.fair_cache), so one pass never freezes a frame.


static func edge(b, hub: Dictionary, kind: String) -> Vector2i:
	var centre: Vector2i = b.castles.lays[hub.id].spire.centre
	var aim := _nearest_player(b, centre)
	var to := aim - Vector2(centre)
	if to.length() < 0.01:
		to = Vector2.RIGHT
	to = to.normalized()
	var weapons := _weapons(b)
	var cands: Array = []
	var edges: Variant = EnemyBuildScan.edge_cells(b, str(hub.id), centre)
	if edges == null:
		return Vector2i(-1, -1)
	for raw in edges:
		var cell: Vector2i = raw
		if not EnemyBuildPlan.open(b, cell, true):
			continue
		var along := Vector2(cell.x - centre.x, cell.y - centre.y).dot(to)
		cands.append([along * 2.0 - Vector2(cell.x - aim.x, cell.y - aim.y).length(), cell])
	cands.sort_custom(func(a, c): return a[0] > c[0])
	var far := Vector2i(-1, -1)
	var any := Vector2i(-1, -1)
	for raw in cands:
		var cell: Vector2i = raw[1]
		if not EnemyBuildPlan.reachable(b, hub, cell):
			continue
		if kind == "spitter" and not _fair(b, cell):
			if b.plan_more:
				break
			continue
		if any.x < 0:
			any = cell
		if _clear_of_weapons(cell, weapons):
			far = cell
			break
	return far if far.x >= 0 else any


## Cached, budgeted fair-spitter test. Over budget: flags b.plan_more and answers false
## without caching, so the next attempt resumes where the cache leaves off.
static func _fair(b, cell: Vector2i) -> bool:
	if b.fair_cache.has(cell):
		return b.fair_cache[cell]
	if b.fair_new > 0 and Time.get_ticks_usec() - b.plan_t0 > Config.ENEMY_PLAN_BUDGET_US:  # always make progress: one test per pass
		b.plan_more = true
		return false
	b.fair_new += 1
	var ok := _fair_spitter_site(b, cell)
	b.fair_cache[cell] = ok
	return ok


## Fair spitter sites (Q): the player must always have an answer. A spitter only goes
## where at least one terrain-buildable cell within sniper range has line of sight to
## it, using the same WeaponLogic.sees the sniper itself uses. Snipers are movable, so
## only the ground rules are checked here, not the player's current network.
static func _fair_spitter_site(b, cell: Vector2i) -> bool:
	var grid: Grid = b.world.grid
	var eye := grid.cell_ground(cell.x, cell.y) + Vector3(0, 1.0, 0)
	var rng := Config.ENEMY_SPITTER_FAIR_RANGE
	for raw in grid.cells_in_radius(cell.x, cell.y, rng):
		var c: Vector2i = raw
		if Vector2(c.x - cell.x, c.y - cell.y).length() > rng:
			continue
		if Placement._ground_rules(b.structures, "sniper", c.x, c.y, null) != "":
			continue
		var from := grid.cell_ground(c.x, c.y) + Vector3(0, 1.8, 0)
		if WeaponLogic.sees(grid, from, eye):
			return true
	return false


static func _clear_of_weapons(cell: Vector2i, weapons: Array) -> bool:
	for raw in weapons:
		var st: Structure = raw
		if Vector2(st.x - cell.x, st.z - cell.y).length() < Config.ENEMY_WEAPON_GAP:
			return false
	return true



static func _nearest_player(b, centre: Vector2i) -> Vector2:
	var best := Vector2(centre.x + 1, centre.y)
	var bd := INF
	for raw in b.structures.list:
		var st: Structure = raw
		if st.dead:
			continue
		var d := Vector2(st.x - centre.x, st.z - centre.y).length()
		if d < bd:
			bd = d
			best = Vector2(st.x, st.z)
	return best


static func _weapons(b) -> Array:
	var out: Array = []
	for raw in b.structures.list:
		var st: Structure = raw
		if not st.dead and bool(st.def.get("weapon", false)):
			out.append(st)
	return out
