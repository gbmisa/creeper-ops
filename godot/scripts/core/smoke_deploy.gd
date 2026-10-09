class_name SmokeDeploy
## Stage 10b checks: drop cost, recall cooldown, respawn wait, second-death multiplier.


static func run(g) -> void:
	_node_deploy(g)
	var grid: Grid = g.level.grid
	var origin := _line(grid, 20)
	SmokeTest._check("walkable recall line", origin.x >= 0, str(origin))
	if origin.x < 0:
		return
	var far := Vector2i(origin.x + 20, origin.y)
	g.economy.energy = 100.0
	var totem: Structure = g.structures.place("beacon", origin.x, origin.y)
	SmokeTest._check("totem: costs 5", int(StructureDefs.DEFS["beacon"].cost) == 5)
	SmokeTest._check("totem: no orbital flag", not StructureDefs.DEFS["beacon"].get("drop_pod", false) and bool(StructureDefs.DEFS["beacon"].get("self_build", false)))
	SmokeTest._check("totem: paid up front", totem != null and absf(g.economy.energy - 95.0) < 0.01, "energy %.0f" % g.economy.energy)
	SmokeTest._check("totem: builds over time", totem != null and not totem.is_built())
	if totem != null:
		var bt := 0.0
		while not totem.is_built() and bt < 6.0:
			StructureUpkeep.construction(g.structures, totem, 0.1)
			bt += 0.1
		SmokeTest._check("totem: self-builds", totem.is_built(), "t=%.1f" % bt)
		SmokeTest._check("totem: no packets used", totem.delivered == 0)
	else:
		return
	SmokeTest._check("totem label", totem.def.label == "Totem" and StructureDefs.MENU.Orbital.has("@drop"))
	g.economy.energy = 400.0
	var grew: bool = is_equal_approx(g.deploy.drop_cost(origin), Config.DROP_BASE) \
		and is_equal_approx(g.deploy.drop_cost(far), Config.DROP_BASE + floorf(20.0 / Config.DROP_PER_CELLS))
	SmokeTest._check("drop cost grows", grew, "near %.0f far %.0f" % [g.deploy.drop_cost(origin), g.deploy.drop_cost(far)])
	SmokeTest._check("drop cost capped", is_equal_approx(g.deploy.drop_cost_cells(10000.0), Config.DROP_MAX))
	var prev: Callable = g.deploy.drop_blocked
	g.deploy.drop_blocked = func(c): return c == far or prev.call(c)
	var blocked: Dictionary = g.deploy.can_drop(far)
	SmokeTest._check("shield blocks drop", not blocked.ok and "Shield" in str(blocked.reason), blocked.reason)
	g.deploy.drop_blocked = prev

	_recall(g, origin, far)
	_pod(g, far)
	_death(g, origin)


## T with no finished Totem falls back to the Command Node: free cell beside it.
## Also covers totem priority and the deploy deny paths.
static func _node_deploy(g) -> void:
	for s in g.structures.beacons():
		g.structures.remove(s)
	g.flow.to_command("")
	g.teleport_cooldown = 0.0
	SmokeTest._check("node deploy: no beacons", g.structures.beacons().is_empty())
	g.deploy.deploy_totem()
	var node: Structure = g.structures.command_node()
	SmokeTest._check("node deploy: on surface", g.mode == "surface" and g.fps.world == g.surface)
	var grid: Grid = g.level.grid
	var cell := grid.world_to_cell(g.fps.controller.pos.x, g.fps.controller.pos.z)
	var cheb := maxi(absi(cell.x - node.x), absi(cell.y - node.z))
	SmokeTest._check("node deploy: beside node", cheb >= 2 and cheb <= 5, "cheb=%d" % cheb)
	SmokeTest._check("node deploy: cell free", g.structures.structure_at(cell.x, cell.y) == null, str(cell))
	g.flow.to_command("")

	# A finished Totem takes priority over the node.
	var tb := _line(grid, 30)
	g.structures.place("beacon", tb.x, tb.y, true)
	g.deploy.deploy_totem()
	var tc := grid.world_to_cell(g.fps.controller.pos.x, g.fps.controller.pos.z)
	SmokeTest._check("totem priority", tc == Vector2i(tb.x, tb.y - 1), str(tc))
	g.structures.remove(g.structures.beacons().back())
	g.flow.to_command("")

	# Deny paths still fire.
	g.deploy.down = true
	g.deploy.deploy_totem()
	SmokeTest._check("deny while down", g.mode == "command")
	g.deploy.down = false
	g.deploy._pod = { "cell": Vector2i.ZERO, "t": 0.0, "tick": 0.0 }
	g.deploy.deploy_totem()
	SmokeTest._check("deny while pod falling", g.mode == "command")
	g.deploy._pod = {}
	g.landing = true
	g.deploy.deploy_totem()
	SmokeTest._check("deny while landing", g.mode == "command" and g.fps.world == null)
	g.landing = false


## Brief B1: the Operative's spawn camera must not sit inside (or hard against) world
## geometry. L1 runs the real totem-deploy path; L2 checks its engine meshes against the
## analogous spawn point.
static func _spawn_cam(g) -> void:
	var rift: Dictionary = g.level.rift
	var spawn := Vector2i(int(rift.x) + 16, int(rift.z) - 1)
	g.fps.enter(g.surface, spawn, PI / 2.0)
	var cam: Vector3 = g.fps.camera.global_position
	var bad := _near_meshes(g.surface, cam)
	SmokeTest._check("L1: spawn camera clear of world meshes", bad.is_empty(), str(bad).left(200))
	g.flow.to_command("")
	_spawn_cam_l2(g)


static func _spawn_cam_l2(g) -> void:
	var lvl := Levels.build(2)
	var grid: Grid = lvl.grid
	var rift: Dictionary = lvl.rift
	var spawn := Vector2i(int(rift.x) + 16, int(rift.z) - 1)
	var cam: Vector3 = grid.cell_ground(spawn.x, spawn.y) + Vector3(0, Config.EYE, 0)
	var holder := Node3D.new()
	holder.name = "SpawnCamCheck"
	g.add_child(holder)
	for row in lvl.engines:
		holder.add_child(EngineMeshes.model(row))
	var bad := _near_meshes(holder, cam)
	holder.queue_free()
	SmokeTest._check("L2: spawn camera clear of engine meshes", bad.is_empty(), str(bad).left(200))


## Visible meshes whose AABB contains cam, excluding the Operative viewmodel and
## terrain chunks (the camera always stands inside a terrain chunk's broad AABB).
static func _near_meshes(root: Node, cam: Vector3) -> Array:
	var bad := []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var n: Node = m
		var excluded := false
		while n != null and n != root:
			var nm := str(n.name)
			if nm == "Operative" or nm.begins_with("Chunk") or nm == "Terrain":
				excluded = true
				break
			n = n.get_parent()
		if excluded:
			continue
		var box: AABB = m.global_transform * m.get_aabb()
		if box.has_point(cam):
			var chain := []
			var n2: Node = m
			while n2 != null and chain.size() < 5:
				chain.append(str(n2.name))
				n2 = n2.get_parent()
			bad.append(" / ".join(chain))
	return bad


static func _line(grid: Grid, n: int) -> Vector2i:
	for z in range(1, grid.h):
		for x in range(0, grid.w - n):
			var ok := true
			var h := grid.height_at(x + n, z)
			for i in range(n - 1, -1, -1):
				var next := grid.height_at(x + i, z)
				if next - h > Config.CLIMB:
					ok = false
					break
				h = next
			if ok:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _recall(g, origin: Vector2i, far: Vector2i) -> void:
	g.fps.enter(g.surface, far, 0.0)
	var expect := Config.RECALL_COOLDOWN_MULT * (20.0 * Config.CELL) / Config.WALK
	var got: float = g.deploy.preview_recall()
	SmokeTest._check("recall 20 cells", absf(got - expect) < 0.05, "got %.3f want %.3f" % [got, expect])
	g.deploy.commit_recall()
	SmokeTest._check("recall sets cooldown", absf(g.teleport_cooldown - expect) < 0.05 and g.mode == "command")
	g.deploy.deploy_totem()
	SmokeTest._check("cooldown blocks totem", g.mode == "command")
	g.teleport_cooldown = 0.0
	g.deploy.deploy_totem()
	SmokeTest._check("totem deploy instant", g.mode == "surface")
	g.flow.to_command("")
	g.fps.enter(g.surface, origin, 0.0)
	g.fps.controller.pos.x += 2.5
	SmokeTest._check("recall within 3m", g.deploy.preview_recall() == 0.0)
	g.deploy.commit_recall()
	SmokeTest._check("totem recall no cooldown", g.teleport_cooldown == 0.0 and g.mode == "command")


static func _pod(g, far: Vector2i) -> void:
	g.economy.energy = 400.0
	var cost: float = g.deploy.drop_cost(far)
	g.deploy.start_drop(far)
	SmokeTest._check("drop paid", absf(g.economy.energy - (400.0 - cost)) < 0.01, "energy %.0f" % g.economy.energy)
	var t := 0.0
	while g.mode == "command" and t < Config.DROP_TIME + 1.0:
		g.deploy.update(0.05)
		t += 0.05
	SmokeTest._check("pod fall time", g.mode == "surface" and absf(t - Config.DROP_TIME) < 0.2, "t=%.2f" % t)
	g.flow.to_command("")


static func _death(g, origin: Vector2i) -> void:
	g.economy.energy = 500.0
	g.stockpile.salvage = 0.0
	g.deploy.carried_extractors = 2
	g.deploy.crafted_ammo = 4
	var seen := [-1]
	g.deploy.lose_crafted_ammo = func(): seen[0] = g.deploy.crafted_ammo
	g.fps.enter(g.surface, origin, 0.0)
	g.fps.since_hurt = 0.0
	g.fps.damage(Config.SUIT_MAX + 10.0)
	g.fps.update(0.05, g.input)
	var down: bool = g.deploy.down and g.mode == "command" and g.deploy.carried_extractors == 0 \
		and g.deploy.crafted_ammo == 0 and seen[0] == 4
	SmokeTest._check("death downs operative", down, "extractors %d ammo %d hook %d" % [g.deploy.carried_extractors, g.deploy.crafted_ammo, seen[0]])
	var left: float = g.deploy.respawn_left
	SmokeTest._sim(g, 1.0)
	SmokeTest._check("respawn waits without salvage", g.deploy.down and g.deploy.respawn_left >= left - 0.001 and "salvage" in g.deploy.status_text(), g.deploy.status_text())
	g.economy.energy = 500.0
	g.stockpile.salvage = g.deploy.bill_salvage
	var waited := 0.0
	while g.deploy.down and waited < Config.RESPAWN_TIME + 1.0:
		g.deploy.update(0.05)
		waited += 0.05
	var done: bool = not g.deploy.down and g.stockpile.salvage <= 0.001 and absf(waited - Config.RESPAWN_TIME) < 0.2
	SmokeTest._check("respawn completes", done, "waited %.2f salvage %.2f" % [waited, g.stockpile.salvage])
	g.economy.energy = 500.0
	g.fps.enter(g.surface, origin, 0.0)
	g.fps.since_hurt = 0.0
	g.fps.damage(Config.SUIT_MAX + 10.0)
	g.fps.update(0.05, g.input)
	SmokeTest._check("second death costs 1.5x", g.deploy.down \
		and is_equal_approx(g.deploy.bill_energy, Config.RESPAWN_ENERGY * Config.RESPAWN_GROWTH) \
		and is_equal_approx(g.deploy.bill_salvage, Config.RESPAWN_SALVAGE * Config.RESPAWN_GROWTH),
		"energy %.1f salvage %.1f" % [g.deploy.bill_energy, g.deploy.bill_salvage])
