class_name EnemyBuildScan
## Time-sliced scan for wet/dry edge cells around a hub (enemy tower sites). The scan
## resumes across updates under Config.ENEMY_PLAN_BUDGET_US, and a finished list is
## reused for Config.ENEMY_SCAN_TTL seconds (b.scans, cleared on terrain change).


## Edge cells near `centre`, or null while the scan is still running (b.plan_more set).
static func edge_cells(b, hub_id: String, centre: Vector2i) -> Variant:
	var job: Dictionary = b.scans.get(hub_id, {})
	if job.is_empty() or (bool(job.done) and b.time - float(job.at) > Config.ENEMY_SCAN_TTL):
		job = {"cells": b.world.grid.cells_in_radius(centre.x, centre.y, Config.ENEMY_BUILD_REACH), "i": 0, "out": [], "done": false, "at": 0.0}
		b.scans[hub_id] = job
	if bool(job.done):
		return job.out
	var cells: Array = job.cells
	var i: int = job.i
	while i < cells.size():
		var cell: Vector2i = cells[i]
		i += 1
		if cell.distance_to(centre) >= 2.0 and is_edge(b, cell):
			job.out.append(cell)
		if (i & 31) == 0 and Time.get_ticks_usec() - b.plan_t0 > Config.ENEMY_PLAN_BUDGET_US:
			break
	job.i = i
	if i < cells.size():
		b.plan_more = true
		return null
	job.done = true
	job.at = b.time
	return job.out


static func is_edge(b, cell: Vector2i) -> bool:
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
