class_name L2Bench
## --bench-l2[=S]: play the loaded level for S wall seconds (default 90, use with --level=2
## --autostart), then print average/worst frame, draw calls, objects and creatures over the
## last third. PT3-G before/after numbers; needs a real display for GPU numbers.

static func run(g, args: Dictionary) -> void:
	var total := float(args.get("bench-l2", "90")) if str(args.get("bench-l2", "")) != "" else 90.0
	var tree: SceneTree = g.get_tree()
	var t := 0.0
	var n := 0
	var sum := 0.0
	var worst := 0.0
	var proc := 0.0
	var calls := 0.0
	var objs := 0.0
	var last := Time.get_ticks_usec()
	while t < total:
		await tree.process_frame
		var now := Time.get_ticks_usec()
		var ft := (now - last) / 1000.0
		last = now
		t += ft / 1000.0
		if t < total * 2.0 / 3.0:
			continue
		n += 1
		sum += ft
		worst = maxf(worst, ft)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var anims := 0
	var geo := {}  # "parent/class" -> visible geometry count
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is AnimationPlayer:
			anims += 1
		if c is GeometryInstance3D and (c as Node3D).is_visible_in_tree():
			var par := c.get_parent()
			var key := "%s>%s" % [par.get_parent().name if par.get_parent() else "", par.name.rstrip("0123456789@")]
			geo[key] = geo.get(key, 0) + 1
		stack.append_array(c.get_children())
	var keys := geo.keys()
	keys.sort_custom(func(a, b): return geo[a] > geo[b])
	for k in keys.slice(0, 12):
		print("[bench-l2] geo %5d  %s" % [geo[k], k])
	print("[bench-l2] process %.1f ms" % (proc / n))
	print("[bench-l2] %.0f fps avg (%.1f ms, worst %.1f ms)  draw calls %.0f  objects %.0f  anim players %d" % [
		1000.0 * n / sum, sum / n, worst, calls / n, objs / n, anims])
	tree.quit()
