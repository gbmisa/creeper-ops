class_name SmokeCastleTurrets
## Castle turrets (pulled forward from 9a): sockets on the wall walk, Salvage from capture
## and holding, buy/upgrade, a Repeater hurting raiders, and turrets blocking a retake until
## they fall. Called from SmokeStrongholds. Leaves the castle hostile.


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var grid: Grid = g.surface.grid
	var c: Dictionary = castles.list[0]
	var lay: Dictionary = castles.lays[c.id]
	var v: Dictionary = castles.views[c.id]
	var on_wall: bool = c.sockets.all(func(s): return grid.material[grid.idx(s.cell.x, s.cell.y)] == Grid.Mat.STONE \
		and grid.height_at(s.cell.x, s.cell.y) >= lay.wall_top)  # concentric: on the tower tops
	SmokeTest._check("turrets: %d sockets, all on the wall walk" % c.sockets.size(), on_wall and c.sockets.size() >= 5)
	SmokeTest._check("turrets: hostile castle can't be armed", not CastleTurrets.check(c, 0, "repeater", 999.0).ok)
	g.stockpile.salvage = 0.0
	c.state = "capturing"
	c.capture = { "progress": 0.999, "away": 0.0, "retake": 0.0 }
	var zc: Vector2i = lay.zones.keep.cells[0]  # the spire top (Stage 7) or the keep hall
	var top := grid.cell_center(zc.x, zc.y)
	top.y = lay.zones.keep.y * Config.LEVEL_H
	castles._capturing(c, lay, top, 1.0)
	SmokeTest._check("turrets: capture pays Salvage", c.state == "held" and g.stockpile.salvage >= Config.CASTLE_CAPTURE_SALVAGE)
	g.stockpile.salvage = 100.0
	var why := CastleTurrets.buy(c, 0, "repeater", g.stockpile)
	why += CastleTurrets.buy(c, 0, "repeater", g.stockpile)
	SmokeTest._check("turrets: buy then upgrade a Repeater", why == "" and c.sockets[0].level == 2
		and absf(g.stockpile.salvage - 35.0) < 0.01, "(%s, salvage %.1f)" % [why, g.stockpile.salvage])
	SmokeTest._check("turrets: other types can't stack on a used socket", not CastleTurrets.check(c, 0, "flak", 999.0).ok)
	_fires(castles, c, v)
	_blocks_retake(g, castles, c, lay)
	StrongholdMeshes.refresh(v, c)


static func _fires(castles: Strongholds, c: Dictionary, v: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	raiders.spawn(v.garrison, RaiderDefs.named("Skitter"), true)
	var r: Dictionary = raiders.list.back()
	var t0 := grid_cell(castles, (v.turrets[0] as Node3D).position)
	var near: Vector2i = lay_of(castles, c).courtyard[0]
	for cell in lay_of(castles, c).courtyard:  # open ground just inside the walls, below the turret
		if (cell - t0).length_squared() < (near - t0).length_squared():
			near = cell
	r.node.position = castles.world.grid.cell_ground(near.x, near.y)
	var hp0: float = r.hp
	for i in 20:
		CastleTurretFire.tick(castles.world, c, v, raiders, 0.1)
	SmokeTest._check("turrets: Repeater shoots raiders", not r.alive or r.hp < hp0, "(hp %.1f of %.1f)" % [r.hp, hp0])
	if r.alive:
		raiders.kill(r)


static func lay_of(castles: Strongholds, c: Dictionary) -> Dictionary:
	return castles.lays[c.id]


static func grid_cell(castles: Strongholds, p: Vector3) -> Vector2i:
	return castles.world.grid.world_to_cell(p.x, p.z)


static func _blocks_retake(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	raiders.spawn(castles.views[c.id].garrison, RaiderDefs.named("Skitter"), true)
	var r: Dictionary = raiders.list.back()
	var yard: Vector2i = lay.get("ward", lay.courtyard)[0]
	r.node.position = g.surface.grid.cell_ground(yard.x, yard.y)
	r.hp = 99999.0
	for i in 40:  # 20 s with a turret standing
		castles._holding(c, lay, castles.views[c.id], null, 0.5)
	SmokeTest._check("turrets: a standing turret stops a retake", c.owner == "player" and c.capture.retake == 0.0)
	CastleTurretFire.hit(c, c.sockets[0], 9999.0)
	for i in 40:
		castles._holding(c, lay, castles.views[c.id], null, 0.5)
	SmokeTest._check("turrets: once they fall the castle is retaken and sockets cleared",
		c.owner == "enemy" and not CastleTurrets.any_alive(c) and c.sockets[0].level == 0)
	if r.alive:
		raiders.kill(r)
