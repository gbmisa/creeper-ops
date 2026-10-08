class_name SmokeCastles2Perks
## Stage 21 held-castle perks: reach (weapon range near a held castle), the ward (creeper drains
## inside held walls, nearby hives slow), the free Castle Barracks, and the vault/engine API.
## Range and muster use the live Level 1 game; ward and vaults a Level 2 rig.


static func run(g) -> void:
	_reach(g)
	_muster(g)
	var r := SmokeCastles2Capture.rig(g)
	_ward(r)
	_vaults(r)
	r.w.queue_free()


static func _reach(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = castles.list[0]
	var lay: Dictionary = castles.lays[c.id]
	var at := CastlePerks.centre(lay)
	var near := Vector2i(int(at.x), int(at.y))
	var far := Vector2i(near.x + int(CastleDefs.REACH_RADIUS) + 10, near.y)
	var before := CastlePerks.range_mult(castles, near.x, near.y)
	StrongholdRules.to_held(g.surface, c, lay)
	var inside := CastlePerks.range_mult(castles, near.x, near.y)
	var outside := CastlePerks.range_mult(castles, far.x, far.y)
	SmokeTest._check("castles2 perks: weapons near a held castle reach further", before == 1.0
		and absf(inside - (1.0 + CastleDefs.REACH_BONUS)) < 0.001 and outside == 1.0)
	var cannon := Structure.new("cannon", near.x, near.y)
	SmokeTest._check("castles2 perks: WeaponLogic reads the castle bonus", absf(WeaponLogic.range_cells(cannon) - WeaponLogic.def_range(cannon.def) * inside) < 0.001)
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	StrongholdMeshes.refresh(castles.views[c.id], c)


static func _muster(g) -> void:
	var castles: Strongholds = g.castles
	var rows := castles.list.filter(func(x): return castles.lays[x.id].get("plan", "") == "concentric")
	if rows.is_empty():  # Stage 7 courtyards are too tight for a 3x3 barracks
		SmokeTest._check("castles2 perks: muster (no concentric castle in this level)", true)
		return
	var c: Dictionary = rows[0]
	var lay: Dictionary = castles.lays[c.id]
	StrongholdRules.to_held(g.surface, c, lay)
	g.keeps.update()
	var b: Structure = g.keeps.musters.get(c.id)
	SmokeTest._check("castles2 perks: a held castle musters a free barracks", b != null and not b.dead and b.is_built()
		and lay.courtyard.has(Vector2i(b.x, b.z)))
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	g.keeps.update()
	SmokeTest._check("castles2 perks: the barracks goes when the castle falls", b == null or b.dead)
	StrongholdMeshes.refresh(castles.views[c.id], c)


static func _ward(r: Dictionary) -> void:
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var sim: CreeperSim = r.w.creeper
	var cell: Vector2i = lay.ward[0]
	StrongholdRules.to_held(r.w, c, lay)
	sim.set_depth(cell.x, cell.y, 1.0)
	for i in 20:
		CastlePerks.ward(castles, c, lay, 0.5)
	var left := sim.depth_at(cell.x, cell.y)
	SmokeTest._check("castles2 perks: creeper drains inside held walls", absf(left - (1.0 - CastleDefs.WARD_DRAIN * 10.0)) < 0.02, "(%.3f)" % left)
	var at := CastlePerks.centre(lay)
	SmokeTest._check("castles2 perks: hives near a held castle slow down", absf(CastlePerks.hive_factor(castles, at) - (1.0 - CastleDefs.WARD_HIVE_SLOW)) < 0.001
		and CastlePerks.hive_factor(castles, at + Vector2(CastleDefs.WARD_HIVE_RADIUS + 5.0, 0)) == 1.0)
	var raids := CastleRaids.new(castles, {})
	var hive: Dictionary = castles.nests.nests[0]
	var was := Vector2(hive.x, hive.z)
	hive.x = int(at.x)
	hive.z = int(at.y)
	raids._buff_nests()
	SmokeTest._check("castles2 perks: CastleRaids applies the hive slow", float(hive.rate) < 1.0, "(%.2f)" % float(hive.rate))
	hive.x = int(was.x)
	hive.z = int(was.y)


static func _vaults(r: Dictionary) -> void:
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	SmokeTest._check("castles2 perks: concentric castles have vault cells", not lay.vaults.is_empty()
		and CastleVaults.vault_cells(castles).has(lay.vaults[0]))
	var v: Vector2i = lay.vaults[0]
	StrongholdRules.to_held(r.w, c, lay)
	var held_ok := CastleVaults.ships(castles, v) and CastleVaults.inside_held(castles, v)
	StrongholdRules.to_hostile(r.w, c, lay, 1.0)
	SmokeTest._check("castles2 perks: a vault engine ships only while the castle is held", held_ok
		and not CastleVaults.ships(castles, v) and CastleVaults.ships(castles, Vector2i(1, 1)))
