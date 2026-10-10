class_name PerfProbe
## --perf-probe[=MIN]: fast-forward the loaded level MIN minutes (default 28) with the Node kept
## alive, printing sim ms per update along the way, then measure frame cost in command and
## Operative view while switching things off one at a time (sim, shadows, animation, the
## biggest mesh groups). Needs a real display. Use with --level=2 --demo.

const PHASE := 5.0   # wall seconds per measurement
const SKIP := 1.5    # settle time ignored at the start of each


static func run(g, args: Dictionary) -> void:
	var mins := float(args["perf-probe"]) if str(args.get("perf-probe", "")) != "" else 28.0
	var tree: SceneTree = g.get_tree()
	await tree.process_frame
	_forward(g, mins * 60.0)
	_split(g)
	_counts(g, tree)
	for view in ["command", "operative"]:
		if view == "operative":
			var n: Structure = g.structures.command_node()
			g.fps.enter(g.surface, Vector2i(n.x + 3, n.z + 3), 0.5)
			g.flow.set_mode("surface")
		g.paused = false
		g.fps_paused = false
		_frame_split(g, view)
		await _measure(g, tree, view + ": normal")
		g.paused = true
		g.fps_paused = true
		await _measure(g, tree, view + ": sim frozen")
		var lights := _nodes(tree, func(c): return c is Light3D and (c as Light3D).shadow_enabled)
		for l in lights:
			(l as Light3D).shadow_enabled = false
		await _measure(g, tree, view + ": + shadows off (%d lights)" % lights.size())
		var anims := _nodes(tree, func(c): return c is AnimationPlayer and (c as AnimationPlayer).active)
		for a in anims:
			(a as AnimationPlayer).active = false
		await _measure(g, tree, view + ": + animation off (%d players)" % anims.size())
		var hidden: Array = []
		for key in _top_groups(tree, 5):
			for c in _group(tree, key):
				(c as Node3D).visible = false
				hidden.append(c)
			await _measure(g, tree, view + ": + hide %s" % key)
		for c in hidden:
			(c as Node3D).visible = true
		for a in anims:
			(a as AnimationPlayer).active = true
		for l in lights:
			(l as Light3D).shadow_enabled = true
	tree.quit()


static func _forward(g, seconds: float) -> void:
	var step := 0.05
	var t := 0.0
	var mark := 0.0
	var spent := 0
	var n := 0
	var worst := 0
	while t < seconds:
		var node: Structure = g.structures.command_node()
		if node != null:
			node.hp = maxf(node.hp, 1000.0)
		g.over = false
		var t0 := Time.get_ticks_usec()
		g.update(step)
		var d := Time.get_ticks_usec() - t0
		spent += d
		worst = maxi(worst, d)
		n += 1
		t += step
		if t - mark >= 240.0 or t >= seconds:
			print("[probe] t=%4.0fs  update avg %.2f ms  worst %.1f ms  raiders %d  flyers %d  structures %d" % [
				t, spent / 1000.0 / n, worst / 1000.0, g.hazards.nests.raiders.list.size(), g.hazards.nests.flyers.list.size(), g.structures.list.size()])
			mark = t
			spent = 0
			n = 0
			worst = 0


## Sim cost by system: each one stepped alone 40 times.
static func _split(g) -> void:
	var foes: Array = g.hazards.nests.enemies() + g.castles.enemies() + g.guards.enemies() + g.builder.enemies()
	var parts := {
		"surface world": func(): g.surface.update(0.05),
		"cave world": func(): g.cave.update(0.05),
		"structures": func(): g.structures.update(0.05, g.time),
		"units": func(): g.units.update(0.05, foes),
		"enemy lists": func(): return g.hazards.nests.enemies() + g.castles.enemies() + g.guards.enemies() + g.builder.enemies(),
	}
	for k in parts:
		var t0 := Time.get_ticks_usec()
		for i in 40:
			(parts[k] as Callable).call()
		print("[probe] sim %-14s %.2f ms" % [k, (Time.get_ticks_usec() - t0) / 40000.0])
	var w: World = g.surface
	_time("world creeper.update", func(): w.creeper.update(0.05))
	_time("world terrain.update", func(): w.terrain.update())
	_time("world effects.update", func(): w.effects.update(0.05))
	_time("hazards.nests.update", func(): g.hazards.nests.update(0.05))
	for i in g.surface.updaters.size():
		var t0 := Time.get_ticks_usec()
		for j in 40:
			(g.surface.updaters[i] as Callable).call(0.05)
		var ms := (Time.get_ticks_usec() - t0) / 40000.0
		if ms >= 0.1:
			print("[probe] sim surface.updaters[%d] %.2f ms  %s" % [i, ms, (g.surface.updaters[i] as Callable).get_method()])


static func _time(label: String, fn: Callable, reps := 40) -> void:
	var t0 := Time.get_ticks_usec()
	for i in reps:
		fn.call()
	print("[probe] cost %-26s %.2f ms" % [label, (Time.get_ticks_usec() - t0) / 1000.0 / reps])


## Per-frame work that runs even when the sim is frozen, in the current view.
static func _frame_split(g, view: String) -> void:
	var world: World = g.surface
	var cam: Camera3D = g.command.cam if g.mode == "command" else g.fps.camera
	_time(view + " refresh_visuals", func(): world.refresh_visuals())
	_time(view + " ambience", func(): g.ambience.update(g, 0.016))
	_time(view + " CreatureLod", func(): CreatureLod.tick(g.get_tree(), g.get_viewport().get_camera_3d(), 0.016))
	_time(view + " hud.refresh", func(): g.hud.refresh(g, 0.016))
	_time(view + " hud markers", func(): g.hud.markers.refresh(world, cam, g.mode != "command"))
	_time(view + " hud objectives", func(): g.hud.objectives.refresh(0.016, g.input, g.mode != "command"))
	if g.mode != "command":
		_time(view + " fps.update", func(): g.fps.update(0.016, g.input))
		_time(view + " hud fps panel", func(): g.hud.fps.refresh(g.fps, false))


static func _counts(g, tree: SceneTree) -> void:
	var all := _nodes(tree, func(_c): return true)
	var geo := _nodes(tree, func(c): return c is GeometryInstance3D)
	var vis := geo.filter(func(c): return (c as Node3D).is_visible_in_tree())
	var sk := _nodes(tree, func(c): return c is Skeleton3D)
	var lights := _nodes(tree, func(c): return c is Light3D)
	print("[probe] nodes %d  geometry %d (visible %d)  skeletons %d  lights %d  mission time %.0f s" % [
		all.size(), geo.size(), vis.size(), sk.size(), lights.size(), g.time])
	for key in _top_groups(tree, 12):
		print("[probe] geo %5d  %s" % [_group(tree, key).size(), key])


static func _measure(_g, tree: SceneTree, label: String) -> void:
	var t := 0.0
	var n := 0
	var sum := 0.0
	var worst := 0.0
	var calls := 0.0
	var prims := 0.0
	var proc := 0.0
	var last := Time.get_ticks_usec()
	while t < PHASE:
		await tree.process_frame
		var now := Time.get_ticks_usec()
		var ft := (now - last) / 1000.0
		last = now
		t += ft / 1000.0
		if t < SKIP:
			continue
		n += 1
		sum += ft
		worst = maxf(worst, ft)
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	print("[probe] %-52s %5.0f fps  %5.1f ms (worst %5.1f)  script %4.1f ms  draws %5.0f  tris %4.1fM" % [
		label, 1000.0 * n / sum, sum / n, worst, proc / n, calls / n, prims / n / 1000000.0])


static func _key(c: Node) -> String:
	var par := c.get_parent()
	return "%s>%s" % [par.get_parent().name if par.get_parent() else "", str(par.name).rstrip("0123456789@")]


static func _top_groups(tree: SceneTree, count: int) -> Array:
	var geo := {}
	for c in _nodes(tree, func(x): return x is GeometryInstance3D and (x as Node3D).is_visible_in_tree()):
		var k := _key(c)
		geo[k] = int(geo.get(k, 0)) + 1
	var keys := geo.keys()
	keys.sort_custom(func(a, b): return geo[a] > geo[b])
	return keys.slice(0, count)


static func _group(tree: SceneTree, key: String) -> Array:
	return _nodes(tree, func(x): return x is GeometryInstance3D and _key(x) == key)


static func _nodes(tree: SceneTree, want: Callable) -> Array:
	var out: Array = []
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if want.call(c):
			out.append(c)
		stack.append_array(c.get_children())
	return out
