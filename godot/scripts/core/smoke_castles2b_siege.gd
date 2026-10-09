class_name SmokeCastles2bSiege
## Stage 21b P7: castle-only production. The player Trebuchet (Weapons tab, cost 80,
## castle_only, range 40) is refused outside a held castle, places inside a held bailey,
## and lobs stones at the nearest enemy structure in range (never at creeper). Leaves
## castle[0] hostile again with the bailey clear, like the turrets smoke.


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = castles.list[0]
	var lay: Dictionary = castles.lays[c.id]
	var sm: StructureManager = g.structures
	for r in castles.nests.raiders.list.duplicate():  # strays must not draw fire
		castles.nests.raiders.kill(r)
	_wiring(g, castles)
	_refused_outside(g, sm, castles)
	_capture(g, castles, c, lay)
	var keep: Structure = _keep(g, castles, c, lay)
	var treb := _placed(g, sm, castles, c, lay, keep)
	_fires(g, sm, castles, treb)
	_cleanup(g, sm, castles, c, lay, keep, treb)


## CastlePerks.attach wires Placement.inside_held to CastleVaults.inside_held.
static func _wiring(g, castles: Strongholds) -> void:
	CastlePerks.attach(castles)
	SmokeTest._check("castles2b siege: CastlePerks.attach wires the castle_only guard",
		Placement.inside_held.is_valid())
	SmokeTest._check("castles2b siege: inside_held is false outside every castle",
		not Placement.inside_held.call(Vector2i(40, 40)))
	var menu: Array = StructureDefs.MENU["Weapons"]
	var d: Dictionary = StructureDefs.DEFS["trebuchet"]
	SmokeTest._check("castles2b siege: the Weapons tab lists the Trebuchet (cost 80, castle_only)",
		menu.has("trebuchet") and int(d.cost) == 80 and bool(d.get("castle_only", false))
		and float(d.get("range", 0.0)) == 40.0 and str(d.get("targets", "")) == "siege")


## Open ground outside any castle: the guard refuses before the network check.
static func _refused_outside(g, sm: StructureManager, castles: Strongholds) -> void:
	var n0: Structure = sm.command_node()
	var spot := Vector2i(-1, -1)
	for dz in range(-6, 7):
		for dx in range(-6, 7):
			var at := Vector2i(n0.x + dx, n0.z + dz)
			if CastleVaults.castle_at(castles, at).is_empty() \
					and Placement.ground_reason(sm, "trebuchet", at.x, at.y) == "":
				spot = at
				break
		if spot.x >= 0:
			break
	var res: Dictionary = Placement.can_place(sm, "trebuchet", spot.x, spot.y)
	SmokeTest._check("castles2b siege: refused outside a held castle",
		spot.x >= 0 and not res.ok and str(res.reason).contains("castle you hold"),
		"(%s)" % res.get("reason", "no open cell"))


## Same capture shortcut as the turrets smoke: hostile -> held.
static func _capture(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	g.stockpile.salvage = 0.0
	c.state = "capturing"
	c.capture = { "progress": 0.999, "away": 0.0, "retake": 0.0 }
	var zc: Vector2i = lay.zones.keep.cells[0]
	var top: Vector3 = g.surface.grid.cell_center(zc.x, zc.y)
	top.y = lay.zones.keep.y * Config.LEVEL_H
	castles._capturing(c, lay, top, 1.0)
	SmokeTest._check("castles2b siege: captured for the placement test", c.state == "held")


## The keep sender gives the bailey network coverage (link 10).
static func _keep(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> Structure:
	g.keeps.update()
	var keep: Structure = g.keeps.keeps.get(c.id)
	g.structures.network.rebuild(g.structures.list)
	var ok := keep != null and not keep.dead
	SmokeTest._check("castles2b siege: the held castle raises its keep sender", ok)
	return keep


## A bailey cell near the keep: ground rules pass, the guard passes, network passes.
static func _placed(g, sm: StructureManager, castles: Strongholds, c: Dictionary,
		lay: Dictionary, keep: Structure) -> Structure:
	var cell := Vector2i(-1, -1)
	for bc in lay.bailey:
		var b: Vector2i = bc
		if Vector2(b.x - keep.x, b.y - keep.z).length() <= 8.0:
			g.surface.creeper.set_depth(b.x, b.y, 0.0)
			if Placement.ground_reason(sm, "trebuchet", b.x, b.y) == "":
				cell = b
				break
	var res: Dictionary = Placement.can_place(sm, "trebuchet", cell.x, cell.y)
	SmokeTest._check("castles2b siege: placed inside the held bailey",
		cell.x >= 0 and res.ok, "(%s)" % res.get("reason", ""))
	var treb: Structure = sm.place("trebuchet", cell.x, cell.y, true)
	SmokeTest._check("castles2b siege: the Trebuchet builds with the player-coloured engine model",
		treb != null and treb.body.get_node_or_null("Trebuchet/Glow") != null)
	return treb


## A synthetic enemy structure 20 cells out; the stone lands, its hp drops, creeper stays.
static func _fires(g, sm: StructureManager, castles: Strongholds, treb: Structure) -> void:
	var grid: Grid = g.surface.grid
	var sim: CreeperSim = g.surface.creeper
	var dir := Vector2(1, 0)
	var ecell := Vector2i(treb.x + int(20.0 * dir.x), treb.z + int(20.0 * dir.y))
	var epos: Vector3 = grid.cell_ground(ecell.x, ecell.y)
	var enode := Node3D.new()
	enode.position = epos
	g.surface.add_child(enode)
	var entry := { "id": -4242, "kind": "spitter", "cell": ecell, "pos": epos,
		"alive": true, "grown": true, "hp": 200.0, "max_hp": 200.0 }
	entry["enemy"] = { "node": enode, "oy": 1.0, "radius": 1.0,
		"alive": func(): return bool(entry.alive),
		"hit": func(d): entry.hp = float(entry.hp) - float(d) }
	(sm.enemy_build as EnemyBuilder).list.append(entry)
	sim.set_depth(ecell.x, ecell.y, 2.0)
	treb.cooldown = 0.0
	treb.ammo = treb.ammo_max()
	WeaponLogic.update(treb, 0.1, sm)
	var lobbed: bool = castles.world.effects.lobs().size() > 0
	SmokeTest._check("castles2b siege: the Trebuchet lobs at the enemy structure",
		lobbed and treb.ammo < treb.ammo_max())
	for i in 30:  # 3 s: the 2.2 s lob lands
		castles.world.effects.update(0.1)
	SmokeTest._check("castles2b siege: the stone hurts the structure, never the creeper",
		float(entry.hp) < 200.0 and is_equal_approx(sim.depth_at(ecell.x, ecell.y), 2.0),
		"(hp %.1f)" % float(entry.hp))
	(sm.enemy_build as EnemyBuilder).list.erase(entry)
	enode.queue_free()


static func _cleanup(g, sm: StructureManager, castles: Strongholds, c: Dictionary,
		lay: Dictionary, keep: Structure, treb: Structure) -> void:
	for r in castles.nests.raiders.list.duplicate():
		castles.nests.raiders.kill(r)
	if treb != null:
		sm.remove(treb)
	if keep != null and not keep.dead:
		sm.remove(keep, "destroyed")
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	StrongholdMeshes.refresh(castles.views[c.id], c)
	SmokeTest._check("castles2b siege: castle[0] is hostile again", c.state == "hostile")
