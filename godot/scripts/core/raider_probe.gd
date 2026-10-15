class_name RaiderProbe
## --raider-probe (use with --level=2): six marching Skitters on the Southern Barrows plateau
## target a Collector at the foot of its east cliff. Prints [rprobe] lines: cells, terrain levels,
## per target-field build slices / ms, time to first damage, longest "distance increased" stretch per
## raider, and the largest path-work time in one frame. --raider-probe=dump prints a height map.

const SECONDS := 90.0
const STEP := 0.05


static func run(g, args: Dictionary) -> void:
	_run(g, args)
	g.get_tree().quit()


static func _run(g, args: Dictionary) -> void:
	var grid: Grid = g.surface.grid
	if str(args["raider-probe"]) == "dump":
		_dump(grid)
		return
	var spot := _find(grid, raiders_of(g).field.walk_heights())
	if spot.is_empty():
		print("[rprobe] no matching spot")
		return
	var tc: Vector2i = spot.target
	var sc: Vector2i = spot.start
	print("[rprobe] target cell %s level %d, start cell %s level %d, detour ~%d cells, straight %.1f m" % [
		tc, int(grid.height_at(tc.x, tc.y)), sc, int(grid.height_at(sc.x, sc.y)), spot.detour,
		Vector2(tc - sc).length() * Config.CELL])
	SmokeAttackMove._clear_creeper(g, tc.x - 25, tc.y - 25, tc.x + 25, tc.y + 25)
	SmokeAttackMove._clear(g)
	var raiders: Raiders = raiders_of(g)
	var paths: RaiderPaths = raiders.paths
	paths.log = []
	var rs: Array = []
	var near := grid.cells_in_radius(sc.x, sc.y, 2.5)
	for i in 6:
		var r := SmokeAttackMove._spawn_raider_at(g, "Skitter", near[i % near.size()], false)
		r["hp"] = 1e6
		rs.append(r)
	var s: Structure = g.structures.place("collector", tc.x, tc.y, true)
	if s == null:
		print("[rprobe] could not place the Collector")
		return
	var hp0 := s.hp
	var t := 0.0
	var hit_at := -1.0
	var worst_frame := 0.0
	var last := []
	var rising := []
	var worst := []
	for r in rs:
		last.append(-1.0)
		rising.append(0.0)
		worst.append(0.0)
	while t < SECONDS:
		g.update(STEP)
		t += STEP
		worst_frame = maxf(worst_frame, paths.spent_ms)
		if hit_at < 0.0 and (s.hp < hp0 or s.dead):
			hit_at = t
		for i in rs.size():
			var d := _walk_left(g, rs[i])
			if d >= 0.0 and last[i] >= 0.0 and d > last[i] + 0.05:
				rising[i] += STEP
				worst[i] = maxf(worst[i], rising[i])
			else:
				rising[i] = 0.0
			last[i] = d
	var worst_ms := 0.0
	for e in paths.log:
		worst_ms = maxf(worst_ms, e.peak)
		print("[rprobe] build: %d slices, %.2f ms total, largest slice %.2f ms" % [e.slices, e.ms, e.peak])
	print("[rprobe] total builds %d (finished %d), largest single slice %.2f ms" % [paths.total_builds, paths.log.size(), worst_ms])
	print("[rprobe] collector first damaged at %s" % (("%.1f s" % hit_at) if hit_at >= 0.0 else "never"))
	for i in rs.size():
		print("[rprobe] raider %d alive %s longest distance-increase %.2f s" % [
			i, rs[i].alive, worst[i]])
	print("[rprobe] largest path work in one frame %.2f ms" % worst_frame)


## Distance still to walk along the committed path (-1 when not on a path).
static func raiders_of(g) -> Raiders:
	return g.hazards.nests.raiders


static func _walk_left(g, r: Dictionary) -> float:
	return raiders_of(g).paths.remaining(r)


## Spot per the dump: plateau (level 6) x28..40, z145..157; its east cliff drops to level 3.
static func _find(grid: Grid, wh: PackedFloat32Array) -> Dictionary:
	# Preferred: start on the plateau by its east edge, target a few cells east at the cliff foot.
	for sz in [150, 151, 149, 152, 148, 153]:
		for sx in [38, 37, 39, 36]:
			for dx in [5, 4, 6, 3]:
				var sc := Vector2i(sx, sz)
				var tc := Vector2i(sx + dx, sz)
				if grid.height_at(sx, sz) - grid.height_at(tc.x, tc.y) < 2.0:
					continue
				var b := RaiderFieldBuild.new(grid, wh, [tc])
				b.step(0)
				var steps := b.dist[grid.idx(sc.x, sc.y)]
				if steps >= 25:
					return { "start": sc, "target": tc, "detour": steps }
	return {}


static func _dump(grid: Grid) -> void:
	for z in range(135, 165):
		var row := ""
		for x in range(20, 62):
			row += "%X" % clampi(int(grid.height_at(x, z)), 0, 15)
		print("[rprobe] z%3d %s" % [z, row])
