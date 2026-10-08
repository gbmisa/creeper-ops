class_name SmokeTest
## Scripted mechanics checks (run: godot --headless --path godot -- --smoke).
## Prints PASS/FAIL per check and a summary. Uses the live game objects; no rendering needed.

static var _fails := 0


static func _check(name: String, ok: bool, detail := "") -> void:
	print("[smoke] %s %s %s" % ["PASS" if ok else "FAIL", name, detail])
	if not ok:
		_fails += 1


static func _sim(g, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		g.update(0.05)
		t += 0.05


static func run(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	g.economy.energy = 60.0

	# CW3 packets: no launch cap. 12 unbuilt relays at once should all be served at REQ_BUILD.
	var relays := []
	for i in 12:
		relays.append(sm.place("collector", 34 + (i % 4) * 3, 60 + (i / 4) * 3))
	_sim(g, 1.0)
	var in_air := 0
	for r in relays:
		in_air += r.in_flight + r.delivered
	_check("packets uncapped", in_air >= 24, "(%d packets in 1 s for 12 builds; old cap ~7/s)" % in_air)
	for r in relays:
		sm.remove(r)

	# Terraces: flat at cell centres and between equal cells, whole levels only.
	var hc := grid.height_at(40, 70)
	_check("terrace flat top", absf(grid.smooth_y(81.0, 141.0) - hc * Config.LEVEL_H) < 0.001
		and absf(grid.smooth_y(81.9, 141.0) - grid.smooth_y(80.2, 141.0)) < 0.001)
	var fractional := 0
	for v in grid.height:
		if v != roundf(v):
			fractional += 1
	_check("whole levels", fractional == 0, "(%d fractional cells)" % fractional)

	# CW3 build tool stays armed, and planned collectors extend placement range.
	var n0 := sm.command_node()
	var cm: CommandMode = g.command
	cm.set_tool("collector")
	cm.hover = { "cell": Vector2i(n0.x, n0.z - 9), "point": grid.cell_ground(n0.x, n0.z - 9) }
	cm._click(false)
	_check("build tool stays armed", cm.tool == "collector")
	cm.set_tool("")
	_check("chain off a planned collector", Placement.can_place(sm, "collector", n0.x, n0.z - 14).ok,
		Placement.can_place(sm, "collector", n0.x, n0.z - 14).reason)
	var planned := sm.structure_at(n0.x, n0.z - 9)
	if planned:
		sm.remove(planned)

	# Weapons move: lift, fly, land, reconnect, keep ammo.
	var c: Structure = sm.place("cannon", 37, 61, true)
	_sim(g, 0.5)
	var ammo_before := c.ammo
	var res: Dictionary = sm.move(c, 43, 61)
	_check("cannon move accepted", res.ok, res.reason)
	_sim(g, 0.6)
	_check("cannon airborne", c.is_flying() and c.node.position.y > grid.cell_ground(37, 61).y + 1.0)
	_sim(g, 6.0)
	_check("cannon landed at target", not c.is_flying() and c.x == 43 and c.node.position.distance_to(grid.cell_ground(43, 61)) < 0.1)
	_check("cannon reconnected", c.connected)
	_check("cannon kept ammo", c.ammo >= minf(ammo_before, c.ammo_max()) - 0.01, "(%.0f -> %.0f)" % [ammo_before, c.ammo])
	_check("old cells freed", sm.structure_at(37, 61) == null and sm.structure_at(43, 61) == c)

	# Nullifier never moves.
	g.economy.energy = 60.0
	var n := Structure.new("nullifier", 0, 0)
	n.def = StructureDefs.DEFS.nullifier
	_check("nullifier not movable", not Placement.can_move(sm, n, 40, 60).ok)

	# Thor hovers; Bertha has titan range.
	var thor: Structure = sm.place("thor", 46, 66, true)
	_check("thor hovers", absf(thor.node.position.y - grid.cell_ground(46, 66).y - Mover.HOVER) < 0.01)
	_check("thor immune to creeper", (func():
		g.surface.creeper.add(46, 66, 3.0)
		var hp: float = thor.hp
		_sim(g, 0.5)
		return thor.hp >= hp).call())
	_check("bertha range is titan-scale", StructureDefs.DEFS.bertha.range >= 40.0)

	# Orbital Lance: up-front cost, delayed strike, cooldown.
	g.economy.energy = 100.0
	g.surface.creeper.add(30, 40, 5.0)
	var before: float = g.surface.creeper.depth_at(30, 40)
	g.orbital.fire(grid.cell_ground(30, 40))
	_check("lance paid up front", g.economy.energy <= 100.0 - Config.LANCE_COST + 0.01)
	_sim(g, Config.LANCE_DELAY + 0.2)
	_check("lance removed creeper", g.surface.creeper.depth_at(30, 40) < before - 3.0,
		"(%.1f -> %.1f)" % [before, g.surface.creeper.depth_at(30, 40)])
	_check("lance on cooldown", not g.orbital.can_fire().ok)

	# Command Node relocation: no production while flying, resumes after.
	var node: Structure = sm.command_node()
	var mv: Dictionary = sm.move(node, 40, 72)
	_check("node move accepted", mv.ok, mv.reason)
	_sim(g, 1.0)
	_check("node produces nothing in flight", g.economy.income < Config.NODE_INCOME)
	_sim(g, 10.0)
	_check("node landed + producing", not node.is_flying() and g.economy.income >= Config.NODE_INCOME)

	# Barracks population cap.
	var b: Structure = sm.place("barracks", 37, 72, true)  # on the mesa (Ashmoat's apron took x 31-34)
	var queued := 0
	for i in 6:
		if StructureBehaviors.queue_unit(b, "soldier", g.units.living_for(b)):
			queued += 1
	_check("barracks unit cap", queued == Config.UNITS_PER_BARRACKS, "(%d queued)" % queued)

	# Units go home when dry and come back restocked.
	b.ammo = b.ammo_max()
	var u: Unit = g.units.spawn("soldier", b.pos.x + 12.0, b.pos.z)
	u.home = b
	u.post = Vector2(b.pos.x + 12.0, b.pos.z)
	u.ammo = 0.0
	_sim(g, 0.2)
	_check("dry unit heads home", u.state == "resupply")
	_sim(g, 15.0)
	_check("unit restocked", u.ammo >= u.def.ammo - 0.5 and u.state in ["return", "idle"], "(%s %.0f ammo)" % [u.state, u.ammo])

	_forge_and_operative(g)
	SmokeRules.run(g)
	SmokeRaiders.run(g)
	SmokeTerrain.run(g)
	SmokeStrongholds.run(g)
	SmokeCastleRaids.run(g)
	SmokeSenders.run(g)
	SmokeDeploy.run(g)
	SmokeTraps.run(g)
	SmokeGroupSelect.run(g)
	SmokeSupplyRules.run(g)
	SmokeTraversal.run(g)
	SmokeCw3.run(g)
	SmokeLevel02.run(g)
	SmokeKeeps.run(g)
	SmokeTerp.run(g)
	SmokeArmoury.run(g)
	SmokeHud.run(g)
	SmokeDragbuild.run(g)
	SmokeRoster.run(g)
	SmokeHives.run(g)
	SmokeEnemyMortar.run(g)
	SmokeEconomy.run(g)
	SmokeEnemyBuild.run(g)
	SmokeLoot.run(g)
	SmokeCastles2Shape.run(g)
	SmokeCastles2Walk.run(g)
	SmokeCastles2Capture.run(g)
	SmokeCastles2Engines.run(g)
	SmokeCastles2Perks.run(g)
	print("[smoke] %s: %d failure(s)" % ["OK" if _fails == 0 else "FAILED", _fails])


static func _forge_and_operative(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var creeper: CreeperSim = g.surface.creeper

	# Square collector fields (7x7) and thin creeper is a valid target.
	_check("square collector field", CollectorField.field_cells(grid, 40, 40).size() == 49)
	creeper.set_depth(20, 20, Config.MIN_DEPTH * 1.5)
	_check("weapons see thin creeper", creeper.nearest_wet(20, 20, 1.0) != null)
	creeper.set_depth(20, 20, 0.0)

	# Forge: Aether buys upgrades only with a finished Forge; energy efficiency applies.
	_check("node lands with no energy", Config.START_ENERGY == 0.0)
	Upgrades.reset()
	Upgrades.aether = 100
	_check("no forge, no upgrade", Upgrades.buy("energy", false) != "")
	var f: Structure = sm.place("forge", 46, 75, true)
	_check("forge placed", f != null and not Placement.can_place(sm, "forge", 34, 76).ok)
	_check("forge buys energy", Upgrades.buy("energy", true) == "" and Upgrades.level("energy") == 1 and Upgrades.aether == 80)
	_sim(g, 0.2)
	_check("energy efficiency applies", g.economy.income >= Config.NODE_INCOME * 1.19)
	Upgrades.reset()
	Bus.objective_done.emit("e1")
	_check("objective pays Aether", Upgrades.aether >= Upgrades.REWARDS.e1)
	Upgrades.reset()

	# Rocket: bursts on the creeper surface and guts a deep pool.
	for c in grid.cells_in_radius(22, 22, 2.0):
		creeper.set_depth(c.x, c.y, 5.0)
	var rl := RocketLauncher.new()
	var aim := grid.cell_ground(22, 22) + Vector3(0, 5.0 * Config.LEVEL_H, 0)
	var from := aim + Vector3(0, 12, 8)
	rl.fire(g.surface, from, aim - from)
	for i in 60:
		rl.update(0.05, g.surface)
	_check("rocket clears creeper", creeper.depth_at(22, 22) < 1.0 and rl.rockets.is_empty() and rl.loaded == Config.ROCKET.mag - 1,
		"(%.1f left)" % creeper.depth_at(22, 22))

	# The Rift is reachable on foot (no jumps): flood-fill with the Operative's climb limit.
	var rift := Vector2i(g.level.rift.x, g.level.rift.z)
	var start := Vector2i(24, 45)
	var seen := { start: true }
	var open := [start]
	var reached := false
	while not open.is_empty() and not reached:
		var a: Vector2i = open.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var b: Vector2i = a + d
			if grid.in_bounds(b.x, b.y) and not seen.has(b) and grid.height_at(b.x, b.y) - grid.height_at(a.x, a.y) <= Config.CLIMB:
				seen[b] = true
				open.append(b)
				reached = reached or b == rift
	_check("rift reachable on foot", reached)
