class_name EnemyBuildPlan
## Picks the next structure for one enemy-held castle (§4.5).
## The spec names the structures and the site rules, not the build order. Order here:
## seal mortar, shield this castle, shield a hive in reach, leech an ore deposit,
## creeper pump, then spitter / blight pylon / lancer, repeating the last three.
## Ore deposits are Stage 9a, so leeches and pumps wait until a deposit exists.


static func pick(b, hub: Dictionary) -> Dictionary:
	for kind in _kinds(b, hub):
		if kind == "":
			continue
		var cell := _cell(b, hub, kind)
		if cell.x >= 0:
			var built: String = "dome" if kind == "hive_dome" else kind
			return {"kind": built, "cell": cell}
	return {}


static func _kinds(b, hub: Dictionary) -> Array:
	var out: Array = []
	if _sealed(b) and not b.has(str(hub.id), "mortar"):
		out.append("mortar")
	if not b.has(str(hub.id), "dome"):
		out.append("dome")
	if _hive_cell(b, hub).x >= 0:
		out.append("hive_dome")
	if _ore(b, hub).x >= 0:
		out.append("leech")
	if not b.has(str(hub.id), "pump") and _leech_near(b, hub):
		out.append("pump")
	for kind in ["spitter", "pylon", "lancer"]:
		if not b.has(str(hub.id), kind):
			out.append(kind)
	var few := _fewest(b, hub)
	if few != "":
		out.append(few)
	return out


## Live + queued structures of a kind for one hub (rubble rebuilds count: a destroyed
## tower re-queues instead of opening a new site).
static func _kind_total(b, hub: Dictionary, kind: String) -> int:
	var n: int = b.count_kind(str(hub.id), kind)
	for raw in b.queue:
		if str(raw.hub) == str(hub.id) and str(raw.kind) == kind:
			n += 1
	return n


## Per-kind cap grows with pressure: base at pressure 0, +2 at full pressure.
static func _kind_cap(b, hub: Dictionary, kind: String) -> int:
	var base: int = int(Config.ENEMY_BUILD_MAX_PER_KIND.get(kind, 99))
	return base + int(b.nests.pressure() * 2.0)


static func _cell(b, hub: Dictionary, kind: String) -> Vector2i:
	match kind:
		"dome":
			return _pad(b, hub)
		"hive_dome":
			return _hive_cell(b, hub)
		"leech":
			return _ore(b, hub)
		_:
			return _edge(b, hub, kind)


static func _sealed(b) -> bool:
	return float(b.nests.seal) >= Config.MORTAR_SEAL and float(b.nests.seal_arm) >= Config.MORTAR_SEAL_BUILD


static func _fewest(b, hub: Dictionary) -> String:
	var best := ""
	var n := 999
	for kind in ["spitter", "pylon", "lancer"]:
		if _kind_total(b, hub, kind) >= _kind_cap(b, hub, kind):
			continue
		var count: int = b.count_kind(str(hub.id), kind)
		if count < n:
			n = count
			best = kind
	return best


static func _pad(b, hub: Dictionary) -> Vector2i:
	var lay: Dictionary = b.castles.lays[hub.id]
	var centre: Vector2i = lay.spire.centre
	var best := Vector2i(-1, -1)
	var bd := INF
	# Taken ground is yours: never site a dome in a bailey you took (Stage 21b P8).
	var taken := {}
	if CastleStages.bailey_open(hub, lay):
		for cell in lay.get("bailey", []):
			taken[cell] = true
	for raw in lay.courtyard:
		var cell: Vector2i = raw
		if taken.has(cell):
			continue
		if not _open(b, cell, false):
			continue
		var d := Vector2(cell.x - centre.x, cell.y - centre.y).length()
		if d < bd:
			bd = d
			best = cell
	return best


static func _hive_cell(b, hub: Dictionary) -> Vector2i:
	var centre := _centre(b, hub)
	var best := Vector2i(-1, -1)
	var bd := INF
	for raw in b.nests.nests:
		var hive: Dictionary = raw
		if str(hive.get("state", "active")) != "active":
			continue
		var cell := Vector2i(int(hive.x), int(hive.z))
		if cell.distance_to(centre) > Config.ENEMY_BUILD_REACH or _covered(b, cell):
			continue
		if not _open(b, cell, true) or not _reachable(b, hub, cell):
			continue
		var d := float(cell.distance_to(centre))
		if d < bd:
			bd = d
			best = cell
	return best


static func _ore(b, hub: Dictionary) -> Vector2i:
	var centre := _centre(b, hub)
	for raw in b.nests.level.get("deposits", []):
		var dep: Dictionary = raw
		if str(dep.get("kind", "")) != "ore":
			continue
		var cell: Vector2i = dep.cell if dep.get("cell") is Vector2i else Vector2i(int(dep.get("x", -1)), int(dep.get("z", -1)))
		if cell.x < 0 or cell.distance_to(centre) > Config.ENEMY_BUILD_REACH:
			continue
		if b.denied(cell) or b.leech_at(cell) or not _open(b, cell, true) or not _reachable(b, hub, cell):
			continue
		return cell
	return Vector2i(-1, -1)


static func _leech_near(b, hub: Dictionary) -> bool:
	var centre := _centre(b, hub)
	for s in b.list:
		if not bool(s.alive) or not bool(s.grown) or str(s.kind) != "leech" or b.denied(s.cell):
			continue
		var cell: Vector2i = s.cell
		if cell.distance_to(centre) <= Config.ENEMY_BUILD_REACH:
			return true
	return false


static func _edge(b, hub: Dictionary, kind: String) -> Vector2i:
	var centre := _centre(b, hub)
	var aim := _nearest_player(b, centre)
	var to := aim - Vector2(centre)
	if to.length() < 0.01:
		to = Vector2.RIGHT
	to = to.normalized()
	var weapons := _weapons(b)
	var far := Vector2i(-1, -1)
	var any := Vector2i(-1, -1)
	var far_s := -INF
	var any_s := -INF
	var grid: Grid = b.world.grid
	for raw in grid.cells_in_radius(centre.x, centre.y, Config.ENEMY_BUILD_REACH):
		var cell: Vector2i = raw
		if cell.distance_to(centre) < 2.0 or not _open(b, cell, true) or not _is_edge(b, cell):
			continue
		if not _reachable(b, hub, cell):
			continue
		if kind == "spitter" and not _fair_spitter_site(b, cell):
			continue
		var along := Vector2(cell.x - centre.x, cell.y - centre.y).dot(to)
		var score := along * 2.0 - Vector2(cell.x - aim.x, cell.y - aim.y).length()
		if score > any_s:
			any_s = score
			any = cell
		if score > far_s and _clear_of_weapons(cell, weapons):
			far_s = score
			far = cell
	return far if far.x >= 0 else any


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


static func _is_edge(b, cell: Vector2i) -> bool:
	var grid: Grid = b.world.grid
	if grid.zone_at(cell.x, cell.y) == Grid.Zone.BLIGHT:
		return true
	var wet: bool = b.world.creeper.depth_at(cell.x, cell.y) > Config.MIN_DEPTH
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var n: Vector2i = cell + d
		if not grid.in_bounds(n.x, n.y):
			continue
		var nw: bool = b.world.creeper.depth_at(n.x, n.y) > Config.MIN_DEPTH
		if wet != nw:
			return true
	return false


static func _covered(b, cell: Vector2i) -> bool:
	var radius := float(EnemyStructures.DEFS["dome"].radius)
	for s in b.list:
		if bool(s.alive) and str(s.kind) == "dome" and (s.cell as Vector2i).distance_to(cell) <= radius:
			return true
	for q in b.queue:
		if str(q.kind) == "dome" and (q.cell as Vector2i).distance_to(cell) <= radius:
			return true
	return false


static func _open(b, cell: Vector2i, field: bool) -> bool:
	var grid: Grid = b.world.grid
	if not grid.in_bounds(cell.x, cell.y):
		return false
	var i := grid.idx(cell.x, cell.y)
	if grid.material[i] == Grid.Mat.SPIRE or grid.roof[i] > 0.0:  # never under a castle roof
		return false
	if field and grid.blocked[i] != 0:
		return false
	if b.occupies(cell.x, cell.y) or b.structures.structure_at(cell.x, cell.y) != null:
		return false
	return true


static func _reachable(b, hub: Dictionary, cell: Vector2i) -> bool:
	var lay: Dictionary = b.castles.lays[hub.id]
	var home: Vector2i = lay.home
	var grid: Grid = b.world.grid
	return b.nests.raiders.field.reachable(grid.cell_ground(home.x, home.y), grid.cell_ground(cell.x, cell.y), 1.5)


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


static func _centre(b, hub: Dictionary) -> Vector2i:
	return b.castles.lays[hub.id].spire.centre
