class_name SmokeCw3
## Stage 17 checks: the CW3 creeper rules from docs/CREEPER_SPEC.md (flow clamp and volume,
## top-up emitters with start delays, weapon removal patterns, heal) and the roaming Thor.
## Called from SmokeTest.run.


static func run(g) -> void:
	_flow()
	_anti()
	_emitters()
	_strikes()
	_heal(g)
	_thor(g)


static func _flat(n := 24) -> CreeperSim:
	return CreeperSim.new(Grid.new(n, n))


static func _total(sim: CreeperSim) -> float:
	var t := 0.0
	for d in sim.depth:
		t += d
	return t


static func _flow() -> void:
	var sim := _flat()
	sim.set_depth(12, 12, 5.0)
	sim._flow()
	var centre := sim.depth_at(12, 12)
	SmokeTest._check("CW3 flow: a cell loses at most 16% per tick", centre >= 5.0 * (1.0 - 4.0 * Config.FLOW_RATE) - 0.0001,
		"(%.3f)" % centre)
	# Moves are exact; only films under CREEPER_DRY at the spreading front evaporate (CW3 too).
	var box := _flat(6)
	box.set_depth(3, 3, 5.0)
	for i in 120:
		box._flow()
	SmokeTest._check("CW3 flow: volume kept apart from thin-film evaporation", absf(_total(box) - 5.0) < 0.1,
		"(%.4f)" % _total(box))
	var hill := _flat(4)
	hill.grid.set_height(1, 0, 2.0)  # a two-level step east of a shallow pool
	hill.set_depth(0, 0, 1.0)
	for i in 30:
		hill._flow()
	SmokeTest._check("CW3 flow: creeper doesn't climb a step taller than its head", hill.depth_at(1, 0) == 0.0)


static func _anti() -> void:
	var sim := _flat()
	sim.set_depth(2, 2, 4.0)
	sim.anti_add(2, 2, 1.5)
	sim._annihilate()
	SmokeTest._check("anti-creeper annihilates creeper 1:1",
		is_equal_approx(sim.depth_at(2, 2), 2.5) and is_equal_approx(sim.anti_at(2, 2), 0.0),
		"(creeper %.2f anti %.2f)" % [sim.depth_at(2, 2), sim.anti_at(2, 2)])
	sim.set_depth(3, 3, 1.0)
	sim.anti_add(3, 3, 3.0)
	sim._annihilate()
	SmokeTest._check("annihilation leaves the remainder of the larger fluid",
		sim.depth_at(3, 3) == 0.0 and is_equal_approx(sim.anti_at(3, 3), 2.0))
	# Anti-creeper flows with the same CW3 rule and persists without creeper around.
	var box := _flat(8)
	box.anti_add(4, 4, 6.0)
	for i in 60:
		box.update(Config.CREEPER_TICK)
	var spread := box.anti_at(5, 4) + box.anti_at(3, 4) + box.anti_at(4, 5) + box.anti_at(4, 3)
	var total := 0.0
	for a in box.anti:
		total += a
	SmokeTest._check("anti-creeper spreads to neighbours and keeps its volume",
		spread > 0.5 and absf(total - 6.0) < 0.3, "(spread %.2f total %.2f)" % [spread, total])


static func _emitters() -> void:
	var sim := _flat()
	sim.set_depth(5, 5, 2.5)
	sim.raise(5, 5, 3.0)
	var topped := sim.depth_at(5, 5)
	sim.set_depth(6, 6, 4.0)
	sim.raise(6, 6, 3.0)
	SmokeTest._check("CW3 emitter tops up to its burst depth", is_equal_approx(topped, 3.0) and sim.depth_at(6, 6) == 4.0)
	var late := _flat()
	late.add_source({ "x": 3, "z": 3, "amount": 2.0, "interval": 0.5, "start": 1.0 })
	late.update(0.9)
	var before := _total(late)
	late.update(0.3)
	SmokeTest._check("emitter waits for its start delay", before == 0.0 and _total(late) > 1.5,
		"(%.2f then %.2f)" % [before, _total(late)])


static func _strikes() -> void:
	var sim := _flat()
	for c in sim.grid.cells_in_radius(12, 12, 7):
		sim.set_depth(c.x, c.y, 0.5)
	sim.grid.set_height(13, 12, 1.0)  # above the impact ground: a cannon skips it
	var got := CreeperStrike.hits(sim, 12, 12, 6.0, 12, 1.0)
	SmokeTest._check("CW3 cannon: 12 hits clear 12 shallow cells, never above the impact",
		is_equal_approx(got, 6.0) and sim.depth_at(12, 12) == 0.0 and sim.depth_at(13, 12) == 0.5, "(removed %.2f)" % got)
	var m := _flat()
	for c in m.grid.cells_in_radius(12, 12, 6):
		m.set_depth(c.x, c.y, 5.0)
	CreeperStrike.disk(m, 12, 12, 4.0, 3.5)
	SmokeTest._check("CW3 mortar: open disk, impact hit twice",
		is_equal_approx(m.depth_at(15, 12), 1.5) and m.depth_at(16, 12) == 5.0 and m.depth_at(12, 12) == 0.0)
	var b := _flat(40)
	b.set_depth(22, 20, 3.0)
	b.set_depth(30, 20, 1.0)
	var t = b.deepest_wet(20, 20, 200.0, -1.0, 0.0, 5)
	SmokeTest._check("CW3 Bertha: never fires within 5 cells", t != null and t == Vector2i(30, 20))


static func _heal(g) -> void:
	var sm: StructureManager = g.structures
	var nd := sm.command_node()
	var c: Structure = sm.place("cannon", nd.x - 3, nd.z - 4, true)
	c.hp = c.def.hp * 0.5
	StructureUpkeep.creeper_and_repair(sm, c, 1.0)
	SmokeTest._check("CW3: a dry structure heals to full over HEAL_TIME",
		is_equal_approx(c.hp, c.def.hp * (0.5 + 1.0 / Config.HEAL_TIME)), "(hp %.2f)" % c.hp)
	sm.remove(c)


## Thor carries its magazine: it fires off-network and while relocating.
static func _thor(g) -> void:
	var sm: StructureManager = g.structures
	var w: World = g.surface
	var x := w.grid.w - 6
	var z := 6
	var t: Structure = sm.place("thor", x, z, true)
	t.ammo = t.ammo_max()
	sm.network.rebuild(sm.list)
	for c in w.grid.cells_in_radius(x, z, 4):
		w.creeper.set_depth(c.x, c.y, 1.0)
	g.update(0.3)
	var off := t.ammo < t.ammo_max()
	SmokeTest._check("Thor fires from its magazine off-network", not t.connected and off, "(ammo %.1f)" % t.ammo)
	Mover.start(sm, t, x - 12, z + 12)
	var before := t.ammo
	g.update(0.5)
	SmokeTest._check("Thor fires in flight", t.is_flying() and t.ammo < before, "(ammo %.1f -> %.1f)" % [before, t.ammo])
	for c in w.grid.cells_in_radius(x, z, 4):
		w.creeper.set_depth(c.x, c.y, 0.0)
	sm.remove(t)
