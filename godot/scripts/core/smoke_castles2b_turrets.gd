class_name SmokeCastles2bTurrets
## Stage 21b P5: the Ballista (long-range anti-raider) and the Ward Lamp (doubles the
## ward drain, fires nothing). Buys/upgrades both through CastleTurrets.buy, checks the
## Castle tab actions and ghost-ring keys, a Ballista hitting a raider at 24 cells (and
## not at 27), and the Ward Lamp doubling CastlePerks.ward's drain. Leaves castle[0]
## hostile with clear sockets and no raiders.


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = castles.list[0]
	var lay: Dictionary = castles.lays[c.id]
	var v: Dictionary = castles.views[c.id]
	for r in castles.nests.raiders.list.duplicate():  # strays from earlier smokes must not draw fire
		castles.nests.raiders.kill(r)
	_tab()
	_capture(g, castles, c, lay)
	_buy(g, c)
	_ballista(g, castles, c, v)
	_upgrade(g, c)
	_lamp(g, castles, c, lay, v)
	# First-person E on an empty socket still arms a Repeater.
	var lbl := CastleTurrets.use_label(c, 3, 999.0)
	SmokeTest._check("castles2b turrets: E on an empty socket still arms a Repeater", lbl.contains("Repeater"), lbl)
	_cleanup(g, castles, c, lay, v)


static func _tab() -> void:
	var menu: Array = StructureDefs.MENU["Castle"]
	var ok := menu.has("@ballista") and menu.has("@ward_lamp")
	var ba: Dictionary = StructureDefs.ACTIONS["@ballista"]
	var wa: Dictionary = StructureDefs.ACTIONS["@ward_lamp"]
	ok = ok and ba.label == "Ballista" and ba.cost_text.contains("35/55/90") and ba.desc != ""
	ok = ok and wa.label == "Ward Lamp" and wa.cost_text.contains("30/45/70") and wa.desc != ""
	SmokeTest._check("castles2b turrets: the Castle tab shows the Ballista and the Ward Lamp", ok)
	var lamp: Dictionary = CastleTurrets.DEFS["ward_lamp"]
	SmokeTest._check("castles2b turrets: the Ward Lamp is rangeless and fires nothing",
		float(lamp.get("range", -1.0)) == 0.0 and str(lamp.targets) == "none")


static func _capture(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	g.stockpile.salvage = 0.0
	c.state = "capturing"
	c.capture = { "progress": 0.999, "away": 0.0, "retake": 0.0 }
	var zc: Vector2i = lay.zones.keep.cells[0]
	var top: Vector3 = g.surface.grid.cell_center(zc.x, zc.y)
	top.y = lay.zones.keep.y * Config.LEVEL_H
	castles._capturing(c, lay, top, 1.0)
	SmokeTest._check("castles2b turrets: captured for the buy test", c.state == "held")


static func _buy(g, c: Dictionary) -> void:
	g.stockpile.salvage = 1000.0
	var why := CastleTurrets.buy(c, 0, "ballista", g.stockpile)
	why += CastleTurrets.buy(c, 2, "ward_lamp", g.stockpile)
	SmokeTest._check("castles2b turrets: buy Ballista I and Ward Lamp I",
		why == "" and c.sockets[0].turret == "ballista" and c.sockets[0].level == 1
		and c.sockets[2].turret == "ward_lamp" and c.sockets[2].level == 1, "(%s)" % why)
	c.sockets[0].cd = 0.0  # deterministic first shots (an earlier smoke may leave cd mid-cycle)


## The range test runs with only one Ballista armed: a second one on another corner
## would be closer to the test raider than 26 cells and draw the shot.
static func _upgrade(g, c: Dictionary) -> void:
	var why := CastleTurrets.buy(c, 0, "ballista", g.stockpile)
	why += CastleTurrets.buy(c, 1, "ballista", g.stockpile)
	SmokeTest._check("castles2b turrets: upgrade Ballista to II, arm a second socket",
		why == "" and c.sockets[0].level == 2 and c.sockets[1].turret == "ballista"
		and c.sockets[1].level == 1, "(%s)" % why)


static func _raider_at(castles: Strongholds, v: Dictionary, socket_i: int, cells: float) -> Dictionary:
	var raiders: Raiders = castles.nests.raiders
	raiders.spawn(v.garrison, RaiderDefs.named("Skitter"), true)
	var r: Dictionary = raiders.list.back()
	var at := (v.turrets[socket_i] as Node3D).position
	var tc: Vector2i = castles.world.grid.world_to_cell(at.x, at.z)
	var cell := Vector2i(tc.x + int(cells), tc.y)
	if not castles.world.grid.in_bounds(cell.x, cell.y):
		cell = Vector2i(tc.x - int(cells), tc.y)
	r.node.position = castles.world.grid.cell_ground(cell.x, cell.y)
	return r


static func _ballista(g, castles: Strongholds, c: Dictionary, v: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	CastleTurretFire.refresh(v, c)
	var r24 := _raider_at(castles, v, 0, 24.0)  # in Ballista range (26), out of Repeater range (18)
	var hp0: float = r24.hp
	for i in 4:  # 0.4 s: the Ballista's first shot lands (2.5 s interval, cd starts at 0)
		CastleTurretFire.tick(castles.world, c, v, raiders, 0.1)
	var hit: bool = r24.hp < hp0
	SmokeTest._check("castles2b turrets: a Ballista hits a raider at 24 cells",
		hit, "(hp %.1f of %.1f)" % [r24.hp, hp0])
	if r24.alive:
		raiders.kill(r24)
	# Out of range: 27 cells, nothing fires.
	var r27 := _raider_at(castles, v, 0, 27.0)
	hp0 = r27.hp
	c.sockets[0].cd = 0.0
	for i in 30:  # 3 s: more than one interval, so a miss would have fired
		CastleTurretFire.tick(castles.world, c, v, raiders, 0.1)
	SmokeTest._check("castles2b turrets: the Ballista stays silent at 27 cells", r27.alive and r27.hp == hp0)
	if r27.alive:
		raiders.kill(r27)
	# The lamp model built without error (Glow node for the pulse) and fires nothing.
	var glow := (v.turrets[2] as Node3D).get_node_or_null("Glow")
	SmokeTest._check("castles2b turrets: the Ward Lamp builds a pulsing glow", glow != null)


static func _lamp(g, castles: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	SmokeTest._check("castles2b turrets: a standing Ward Lamp doubles the ward drain",
		absf(CastleTurrets.ward_mult(c) - CastleDefs.WARD_LAMP_MULT) < 0.001)
	var sim: CreeperSim = castles.world.creeper
	var cell: Vector2i = lay.courtyard[0]
	c["ward_t"] = 0.0  # an earlier smoke's _sim may leave the accumulator mid-tick
	sim.set_depth(cell.x, cell.y, 1.0)
	CastlePerks.ward(castles, c, lay, CastleDefs.WARD_TICK)
	var with_lamp := 1.0 - sim.depth_at(cell.x, cell.y)
	CastleTurretFire.hit(c, c.sockets[2], 9999.0)  # the lamp falls
	SmokeTest._check("castles2b turrets: the drain multiplier dies with the lamp",
		absf(CastleTurrets.ward_mult(c) - 1.0) < 0.001)
	c["ward_t"] = 0.0
	sim.set_depth(cell.x, cell.y, 1.0)
	CastlePerks.ward(castles, c, lay, CastleDefs.WARD_TICK)
	var without_lamp := 1.0 - sim.depth_at(cell.x, cell.y)
	SmokeTest._check("castles2b turrets: CastlePerks.ward removes twice as much with the lamp",
		with_lamp > 0.0 and absf(with_lamp - 2.0 * without_lamp) < 0.004,
		"(lamp %.4f, no lamp %.4f)" % [with_lamp, without_lamp])
	CastleTurretFire.refresh(v, c)


static func _cleanup(g, castles: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	for r in castles.nests.raiders.list.duplicate():
		castles.nests.raiders.kill(r)
	CastleTurrets.clear(c)
	StrongholdMeshes.refresh(v, c)
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	StrongholdMeshes.refresh(v, c)
