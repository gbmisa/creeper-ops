class_name PerfProbe
## --perf-probe[=MIN]: fast-forward the loaded level MIN minutes (default 28) with the Node kept
## alive, printing sim ms per update along the way, then measure frame cost in command and
## Operative view while switching things off one at a time (sim, shadows, animation, the
## biggest mesh groups). Use with --level=2 --demo; add --probe-base to keep the whole base alive.
## Headless it stops after the sim numbers (HITCH lines, cost per system); frame costs need a
## real display. Nodes freed during the fast-forward only go away on the frames it yields.

const PHASE := 5.0   # wall seconds per measurement
const SKIP := 1.5    # settle time ignored at the start of each


static func run(g, args: Dictionary) -> void:
	var mins := float(args["perf-probe"]) if str(args.get("perf-probe", "")) != "" else 28.0
	var tree: SceneTree = g.get_tree()
	await tree.process_frame
	_counts(g, tree)
	await _forward(g, mins * 60.0, args.has("probe-base"))
	await tree.process_frame
	await tree.process_frame
	_split(g)
	_counts(g, tree)
	if DisplayServer.get_name() == "headless":  # sim numbers only (CPU creeper sim); no frame costs
		tree.quit()
		return
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


static func _forward(g, seconds: float, keep_base := false) -> void:
	var step := 0.05
	var t := 0.0
	var mark := 0.0
	var spent := 0
	var n := 0
	var worst := 0
	var edits := [0, 0]  # terrain_changed events, cells
	Bus.terrain_changed.connect(func(_w, cells):
		edits[0] += 1
		edits[1] += cells.size())
	var acc: Array = []  # ms per surface updater inside the current update
	var st = g.castles
	_time("castles: engine_prey", func(): st.engine_prey.call())
	_time("castles: per-castle tick", func():
		var o = st.op.call()
		var pp = o.pos if o != null else null
		for c in st.list:
			var lay: Dictionary = st.lays[c.id]
			var v: Dictionary = st.views[c.id]
			if c.state == "hostile":
				StrongholdTick.hostile(st, c, lay, v, pp, 0.05)
			elif c.state == "capturing":
				StrongholdTick.capturing(st, c, lay, pp, 0.05)
			else:
				StrongholdTick.holding(st, c, lay, v, pp, 0.05))
	_time("castles: engines", func():
		var tg: Array = st.engine_prey.call()
		for c in st.list:
			CastleEngines.tick(st, c, st.views[c.id], tg, 0.05))
	_time("castles: pump+turret+look", func():
		for c in st.list:
			SpirePump.update(st.world, c, st.lays[c.id], 0.05)
			CastleTurretFire.refresh(st.views[c.id], c)
			CastleSocketLook.update(st.views[c.id], c, st.time))
	_time("castles: animate", func():
		for c in st.list:
			StrongholdMeshes.animate(st.views[c.id], c, st.time))
	_time("guards: update", func(): g.guards.update(0.05))
	for i in g.surface.updaters.size():
		acc.append(0.0)
		var orig: Callable = g.surface.updaters[i]
		var owner: Object = orig.get_object()
		print("[probe] updater %d = %s" % [i, (owner.get_script() as Script).resource_path.get_file() if owner != null and owner.get_script() != null else "lambda"])
		g.surface.updaters[i] = func(dt: float) -> void:
			var u0 := Time.get_ticks_usec()
			orig.call(dt)
			acc[i] += (Time.get_ticks_usec() - u0) / 1000.0
	while t < seconds:
		acc.fill(0.0)
		var node: Structure = g.structures.command_node()
		if node != null:
			node.hp = maxf(node.hp, 1000.0)
		if keep_base:  # the whole base survives, so late-game player-side costs show up too
			for s in g.structures.list:
				s.hp = maxf(s.hp, s.def.get("hp", 1.0))
		g.over = false
		var e0: int = edits[0]
		var t0 := Time.get_ticks_usec()
		g.update(step)
		var d := Time.get_ticks_usec() - t0
		if d > 60000:
			print("[probe] HITCH %.0f ms at t=%.0fs  terrain edits in it: %d  updaters ms %s" % [d / 1000.0, t, edits[0] - e0, str(acc.map(func(x): return roundi(x)))])
		spent += d
		worst = maxi(worst, d)
		n += 1
		t += step
		if n % 100 == 0:
			await g.get_tree().process_frame  # let queue_free and the renderer catch up, as in real play
		if t - mark >= 240.0 or t >= seconds:
			print("[probe] t=%4.0fs  update avg %.2f ms  worst %.1f ms  raiders %d  flyers %d  structures %d" % [
				t, spent / 1000.0 / n, worst / 1000.0, g.hazards.nests.raiders.list.size(), g.hazards.nests.flyers.list.size(), g.structures.list.size()])
			print("[probe]          terrain edits so far %d (%d cells)  nodes %d" % [edits[0], edits[1], g.get_tree().get_node_count()])
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
	_time("structures.update", func(): g.structures.update(0.05, g.time))
	_time("packets.update", func(): g.structures.packets.update(0.05, g.structures.list, true))
	_time("network rebuild", func(): g.structures.network.rebuild(g.structures.list) if g.structures.network.has_method("rebuild") else null, 5)
	_time("hazards.nests.update", func(): g.hazards.nests.update(0.05))
	var nn = g.hazards.nests
	_time("nests: hives tick", func():
		for n in nn.nests:
			Hives.tick(nn, n, 0.05))
	_time("nests: mortars", func(): EnemyMortars.tick(nn, 0.05))
	_time("nests: flyers", func(): nn.flyers.update(0.05))
	_time("nests: prey list", func(): nn.prey.call())
	_time("nests: goal cells", func(): nn.goal_cells.call())
	var prey: Array = nn.prey.call()
	var goals: Array = nn.goal_cells.call()
	print("[probe] prey %d  goal cells %d  markers %d  targets %d  interactables %d  updaters %d" % [
		prey.size(), goals.size(), w.markers.size(), w.targets.size(), w.interactables.size(), w.updaters.size()])
	_time("nests: raiders", func(): nn.raiders.update(0.05, prey, goals))
	var rr: Raiders = nn.raiders
	_time("raiders: prey filter", func(): prey.filter(func(q): return q.alive.call()))
	_time("raiders: nearest all", func():
		for r in rr.list:
			rr._nearest(r.node.position, prey, Config.RAIDER_AGGRO))
	_time("raiders: route all", func():
		for r in rr.list:
			rr._route(r, r.node.position))
	_time("raiders: perch all", func():
		for r in rr.list:
			RaiderPerch.y(rr.world, r.node.position.x, r.node.position.z))
	rr._index()
	rr.in_update = true
	_time("raiders: walk all (dt 0)", func():
		for r in rr.list:
			var q: Vector3 = r.node.position
			RaiderMove.walk(rr, r, Vector2(q.x + 5, q.z), 0.0))
	rr.in_update = false
	_time("raiders: anim move all", func():
		for r in rr.list:
			CreatureAnim.move(r.node, 1.0))
	_time("raiders: group speed all", func():
		for r in rr.list:
			RaiderGroups.speed(rr, r))
	_time("nests: raider field", func(): nn.raiders.field.update(0.05, goals))
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
	var top: Array = _top_groups(tree, 1)
	if not top.is_empty():  # what the biggest group is made of: mesh class + size, and who owns the parent
		var kinds := {}
		var grp := _group(tree, top[0])
		for c in grp:
			var mi := c as MeshInstance3D
			var k := "?" if mi == null or mi.mesh == null else "%s %s %s" % [mi.mesh.get_class(), str(mi.mesh.get_aabb().size.snappedf(0.1)), "cast" if mi.cast_shadow != 0 else "nocast"]
			kinds[k] = int(kinds.get(k, 0)) + 1
		var ks := kinds.keys()
		ks.sort_custom(func(x, y): return kinds[x] > kinds[y])
		for k in ks.slice(0, 8):
			print("[probe]   in %s: %5d x %s" % [top[0], kinds[k], k])
		var par: Node = (grp[0] as Node).get_parent()
		print("[probe]   parent path %s  script %s  index %d" % [par.get_path(), par.get_script(), par.get_index()])


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
