class_name SmokeRules
## Smoke checks for creeper contact, ammo requests, nest raiders and keybinds.
## Called from SmokeTest.run (shares its _check/_sim helpers).


static func run(g) -> void:
	_creeper_contact(g)
	_ammo_requests(g)
	_raiders(g)
	_keybinds()
	_balance(g)


static func _wet(g, x: int, z: int, depth: float) -> void:
	var c: CreeperSim = g.surface.creeper
	c.set_depth(x, z, depth)


static func _creeper_contact(g) -> void:
	var sm: StructureManager = g.structures
	var n := sm.command_node()
	var cx := n.x + 4
	var cz := n.z - 6
	_wet(g, cx, cz, 0.5)
	var res := Placement.can_place(sm, "collector", cx, cz)
	SmokeTest._check("can't build on creeper", not res.ok, res.reason)
	_check_no_creeper_build()
	_wet(g, cx, cz, 0.0)
	var unbuilt: Structure = sm.place("cannon", cx, cz)
	unbuilt.delivered = 10
	var built: Structure = sm.place("cannon", cx + 3, cz, true)
	built.hold_fire = true  # its CW3 area shot would clear the test cells
	var collector: Structure = sm.place("collector", cx + 6, cz, true)
	_wet(g, cx, cz, 1.0)  # a lone wet cell drains fast, so make it deep enough to last a tick
	_wet(g, cx + 6, cz, 1.0)
	g.update(0.05)
	_hold_wet(g, unbuilt, 1.0, 0.25)  # pinned: nearby guns would clear a lone cell
	SmokeTest._check("CW3: wet unbuilt cannon loses progress, not its life", not unbuilt.dead and unbuilt.lost > 0.0
		and PacketRequests.need(sm.network, unbuilt) == "", "(lost %.2f)" % unbuilt.lost)
	sm.remove(unbuilt)
	SmokeTest._check("creeper kills built collector instantly", collector.dead)
	var shallow: float = built.hp
	_hold_wet(g, built, 1.0, 0.25)  # pinned: one free cell drains away inside g.update before damage
	SmokeTest._check("built cannon survives a short soak", not built.dead and built.hp < shallow,
		"(%.1f -> %.1f)" % [shallow, built.hp])
	sm.remove(built)
	_wet(g, cx + 3, cz, 0.0)
	var charging: Structure = sm.place("nullifier", cx + 9, cz, true)
	charging.charge = Config.NULLIFY_TIME * 0.5
	var charged_hp: float = charging.hp
	_wet(g, cx + 9, cz, 4.0)
	g.update(0.05)
	SmokeTest._check("charging nullifier ignores deep creeper", not charging.dead and charging.hp == charged_hp)
	sm.remove(charging)
	_wet(g, cx + 9, cz, 0.0)
	_cannon_soak_times(g, sm, cx, cz - 3)
	_wet(g, n.x, n.z, 0.5)
	var hp := n.hp
	g.update(0.05)
	SmokeTest._check("node only loses HP", not n.dead and n.hp < hp)
	_wet(g, n.x, n.z, 0.0)
	_wet(g, cx, cz, 0.0)
	_wet(g, cx + 6, cz, 0.0)
	n.hp = n.def.hp


## Depth is pinned, so this measures the CW3 wet rule and not the fluid draining away:
## a cannon lasts WET_TIME (12 s) whatever the depth.
static func _cannon_soak_times(g, sm: StructureManager, x: int, z: int) -> void:
	for pair in [[0, 1.0], [3, 3.0]]:
		var c: Structure = sm.place("cannon", x + pair[0], z, true)
		_hold_wet(g, c, pair[1], Config.WET_TIME - 0.4)
		var alive: bool = not c.dead
		_hold_wet(g, c, pair[1], 0.8)
		SmokeTest._check("CW3: cannon dies after %.0f s at depth %.0f" % [Config.WET_TIME, pair[1]], alive and c.dead,
			"(alive before=%s)" % alive)
		_wet(g, x + pair[0], z, 0.0)


static func _hold_wet(g, s: Structure, depth: float, seconds: float) -> void:
	var t := 0.0
	while t < seconds and not s.dead:
		_wet(g, s.x, s.z, depth)
		StructureUpkeep.creeper_and_repair(g.structures, s, 0.05)
		t += 0.05


static func _check_no_creeper_build() -> void:
	var any := StructureDefs.DEFS.values().any(func(d): return d.has("build_on_creeper"))
	SmokeTest._check("nullifier has no creeper exemption", not any)


static func _ammo_requests(g) -> void:
	var sm: StructureManager = g.structures
	var c: Structure = sm.place("cannon", 44, 72, true)
	g.update(0.05)
	c.ammo = c.ammo_max()
	c.firing = 2.0  # firing hard on a long route still must not overfill
	SmokeTest._check("full weapon asks for nothing", sm.packets.need(c) == "", "(need=%s)" % sm.packets.need(c))
	c.ammo = c.ammo_max() - c.def.ammo.per_packet * 2.0
	c.firing = 0.0
	SmokeTest._check("low weapon asks for ammo", sm.packets.need(c) == "ammo")
	sm.remove(c)


static func _raiders(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	var target: Structure = g.structures.command_node()
	nests.raiders.field.rebuild(g.raider_goals())
	nests.raiders.spawn(nest, RaiderDefs.named("Skitter"), false)
	var r: Dictionary = nests.raiders.list.back()
	var d0: float = (r.node.position as Vector3).distance_to(target.pos)
	SmokeTest._sim(g, 12.0)
	var d1: float = (r.node.position as Vector3).distance_to(target.pos) if r.alive else 0.0
	SmokeTest._check("raider marches on the base", d1 < d0 - 20.0, "(%.0f m -> %.0f m)" % [d0, d1])
	var t0 := nests.tier
	nests.time = nests._tier_time(1)
	nests.update(0.01)
	SmokeTest._check("nests escalate with time", nests.tier == t0 + 1 and nests.spawn_interval() < Config.NEST_SPAWN_START)
	nests.time = 0.0
	nests.tier = 0
	for x in nests.raiders.list.duplicate():
		nests.raiders.kill(x)


static func _keybinds() -> void:
	Keybinds.persist = false
	Keybinds.load_binds()
	Keybinds.bind("cam_forward", 0, KEY_I)
	SmokeTest._check("rebind works", Keybinds.matches("cam_forward", KEY_I) and not Keybinds.matches("cam_forward", KEY_W))
	var lost := Keybinds.bind("move", 0, KEY_X)
	SmokeTest._check("rebind steals clashing key", not Keybinds.matches("recycle", KEY_X) and lost.has("Recycle selected"))
	SmokeTest._check("operative keys separate", Keybinds.matches("op_forward", KEY_W))
	Keybinds.load_binds()  # back to the player's saved layout (nothing was written)
	Keybinds.persist = true


static func _balance(g) -> void:
	var sniper_range := float(StructureDefs.DEFS["sniper"].range)
	for row in RaiderDefs.ROWS:
		var d: Dictionary = row
		if d.get("attack") == "acid":
			var reach := float(d.range) + float(d.get("splash", 0.0))
			SmokeTest._check("spitters: acid reach is inside sniper range",
				reach < sniper_range, "(%s: %.1f < %.1f)" % [d.name, reach, sniper_range])
