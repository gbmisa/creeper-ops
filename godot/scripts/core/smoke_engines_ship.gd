class_name SmokeEnginesShip
## Stage 9b P2: hooking (also through the first-person hold-E path), Salvage return packets,
## shipping rate per socket, clamps raiders cut, creeper pauses, hive and castle guards.


static func run(g) -> void:
	var sm: StructureManager = g.structures
	var eng: SalvageEngines = g.engines
	var node := sm.command_node()
	var made: Array[Structure] = []
	made.append(sm.place("relay", node.x + 9, node.z - 1, true))
	made.append(sm.place("relay", 55, 64, true))
	for m in made:
		m.hp = 1.0e9  # volleys and creeper are not what this checks
	var calm := _calm(g)
	SmokeTest._sim(g, 0.3)
	var e: Dictionary = eng.list[0]
	var top: Dictionary = e.sockets[0]
	var side: Dictionary = e.sockets[1]
	SmokeTest._check("ship: a relay chain puts the engine in reach", eng.anchor_for(top) != null and eng.anchor_for(side) != null)
	_hold(g, e, side)
	SmokeTest._check("ship: hooking the second socket works", eng.hook(e, top) and top.hooked and top.cable != null)
	SmokeTest._check("ship: hooked sockets are raider prey", eng.prey().size() == 2 and eng.prey()[0].alive.call())
	eng.unhook(side, "test")
	var s0: float = g.stockpile.salvage
	var r0: float = e.reserve
	SmokeTest._sim(g, 20.0)
	SmokeTest._check("ship: Salvage arrives at the Node", g.stockpile.salvage >= s0 + 1.0 and e.reserve <= r0 - 1.0,
		"(%.0f -> %.0f, reserve %.0f -> %.0f)" % [s0, g.stockpile.salvage, r0, e.reserve])
	var a := eng.shipped
	SmokeTest._sim(g, 48.0)
	var one := eng.shipped - a
	eng.hook(e, side)
	a = eng.shipped
	SmokeTest._sim(g, 48.0)
	var two := eng.shipped - a
	SmokeTest._check("ship: two sockets ship twice as fast", one >= 7.0 and two / maxf(one, 1.0) > 1.8 and two / maxf(one, 1.0) < 2.2,
		"(%d vs %d in 48 s)" % [int(one), int(two)])
	SmokeTest._check("ship: sockets_hooked counts them", eng.total_hooked() == 2)
	side.prey.hit.call(EngineDefs.CLAMP_HP + 1.0)
	SmokeTest._check("ship: a raider can cut a clamp", not side.hooked and eng.total_hooked() == 1 and eng.prey().size() == 1)
	a = eng.shipped
	SmokeTest._sim(g, 48.0)
	SmokeTest._check("ship: shipping drops after the cut", eng.shipped - a < two * 0.7 and eng.shipped - a > 6.0, "(%d)" % int(eng.shipped - a))
	top.acc = EngineDefs.RATE - 0.5  # about to ship: only creeper can stop it
	a = eng.shipped
	var wet_always := true
	for i in 100:  # 5 s with creeper held over the socket's cell (weapons nearby may zap it between ticks)
		g.surface.creeper.set_depth(top.cell.x, top.cell.y, 0.3)
		wet_always = wet_always and eng.is_wet(top)
		g.update(0.05)
	SmokeTest._check("ship: a wet engine pauses", wet_always and eng.shipped == a and top.acc < EngineDefs.RATE,
		"(shipped %d vs %d, acc %.2f)" % [eng.shipped, a, top.acc])
	_dry(g)
	SmokeTest._check("ship: a dry engine resumes", not eng.is_wet(top))
	eng.unhook(top, "test end")
	_guards(g, e, top)
	for s in made:
		sm.remove(s)
	_restore(g, calm)
	SmokeTest._sim(g, 0.2)


## Emitters, spire volleys and hive launchers off for the length of the test (see _restore).
static func _calm(g) -> Dictionary:
	var on: Array = g.surface.creeper.sources.filter(func(x): return x.active)
	for src in on:
		src.active = false
	var saved := { "sources": on, "timer": g.hazards.spire.timer, "structures": g.hazards.nests.structures,
		"prey": g.hazards.nests.prey }
	g.hazards.nests.prey = func() -> Array: return []  # raiders and Weavers see nothing to attack
	_dry(g)
	g.hazards.spire.timer = -1.0e9
	g.hazards.nests.structures = null
	return saved


static func _dry(g) -> void:
	var grid: Grid = g.surface.grid
	for z in grid.h:
		for x in grid.w:
			g.surface.creeper.set_depth(x, z, 0.0)


static func _restore(g, saved: Dictionary) -> void:
	for src in saved.sources:
		src.active = true
	g.hazards.spire.timer = saved.timer
	g.hazards.nests.structures = saved.structures
	g.hazards.nests.prey = saved.prey


## Walk the Operative up to the socket and hold the use key through FpsMode, as a player does.
static func _hold(g, e: Dictionary, s: Dictionary) -> void:
	var cell: Vector2i = s.cell
	g.fps.enter(g.surface, cell, 0.0)
	g.fps.controller.pos = g.level.grid.cell_ground(cell.x, cell.y)
	g.fps.body.position = g.fps.controller.pos
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_E
	ev.keycode = KEY_E
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	for i in 12:  # 1.2 s: not done yet
		g.fps._interact(g.input, 0.1)
	SmokeTest._check("ship: holding E shows progress and does not hook early", not s.hooked and g.fps.hold_frac > 0.0 and g.fps.hold_frac < 1.0, "%s %.2f" % [g.fps.prompt, g.fps.hold_frac])
	for i in 16:
		g.fps._interact(g.input, 0.1)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	SmokeTest._check("ship: holding E for 2.5 s hooks the socket", s.hooked and e.sockets.has(s), str(s.hp))
	g.fps.leave()


static func _guards(g, e: Dictionary, s: Dictionary) -> void:
	# No hive or castle condition: a hooked engine ships even beside a live hive and a hostile castle.
	var eng: SalvageEngines = g.engines
	var hive: Dictionary = g.hazards.nests.nests[0]
	var was: bool = hive.alive
	hive.alive = true
	var c: Dictionary = g.castles.list[0]
	var owner: String = c.owner
	c.owner = "enemy"
	SmokeTest._check("ship: an engine beside a live hive and hostile castle hooks", eng.hook(e, s))
	s.hp = 1.0e9
	var a := eng.shipped
	SmokeTest._sim(g, 22.0)
	SmokeTest._check("ship: ... and ships with no hive or castle condition", eng.shipped > a, "(%d)" % int(eng.shipped - a))
	hive.alive = was
	c.owner = owner
	eng.unhook(s, "test end")
