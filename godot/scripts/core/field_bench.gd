class_name FieldBench
## --bench-field: times one RaiderField rebuild, area labelling and on-foot search on the
## loaded level, prints "[bench] ..." and quits. PT3-G measurement hook.

static func run(g) -> void:
	await g.get_tree().process_frame
	var r: Raiders = g.hazards.nests.raiders
	var f: RaiderField = r.field
	var goals: Array = g.raider_goals()
	var from: Vector3 = g.surface.grid.cell_ground(2, 2)
	var t := {}
	for k in ["rebuild", "label", "on_foot"]:
		var best := INF
		for i in 5:
			var t0 := Time.get_ticks_usec()
			match k:
				"rebuild": f.rebuild(goals)
				"label": f._label_areas()
				"on_foot": f.nearest_on_foot(from, [])
			best = minf(best, (Time.get_ticks_usec() - t0) / 1000.0)
		t[k] = best
	f.timer = 0.0  # sliced rebuild through update(): worst frame and frames taken
	var worst := 0.0
	var frames := 0
	while true:
		var t0 := Time.get_ticks_usec()
		f.update(1.0 / 60.0, goals)
		worst = maxf(worst, (Time.get_ticks_usec() - t0) / 1000.0)
		frames += 1
		if f._job == null:
			break
	var reach := 0
	for d in f.dist:
		if d >= 0:
			reach += 1
	print("[bench] field %dx%d rebuild %.2f ms  label %.2f ms  on_foot %.2f ms  reached %d  sliced worst %.2f ms over %d frames" % [
		g.surface.grid.w, g.surface.grid.h, t.rebuild, t.label, t.on_foot, reach, worst, frames])
	g.get_tree().quit()
