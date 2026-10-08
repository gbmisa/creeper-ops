class_name SmokeLoot
## Salvage pickups (§4.4): raider rolls, walk-up collection, the 90s lifetime,
## a hive part and a crown nest. The Core drop is checked in SmokeHives.


static func run(g) -> void:
	_rolls()
	_pickup(g)
	_part(g)
	_crown(g)
	if g.fps.world != null:
		g.fps.leave()


static func _rolls() -> void:
	var sk := RaiderDefs.named("Skitter")
	var br := RaiderDefs.named("Brute")
	SmokeTest._check("loot: skitter drops 1 on a low roll", is_equal_approx(Loot.amount_for(sk, 0.0), 1.0)
		and is_equal_approx(Loot.amount_for(sk, 0.099), 1.0))
	SmokeTest._check("loot: skitter misses on a high roll", Loot.amount_for(sk, 0.1) == 0.0 and Loot.amount_for(sk, 0.9) == 0.0)
	SmokeTest._check("loot: brute always drops 2", is_equal_approx(Loot.amount_for(br, 0.999), 2.0))


static func _pickup(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var hive: Dictionary = nests.nests[0]
	nests.raiders.spawn(hive, RaiderDefs.named("Brute"), true)
	var r: Dictionary = nests.raiders.list.back()
	var at: Vector3 = (r.node as Node3D).position
	nests.raiders.kill(r)
	var dropped: Dictionary = Loot.live.back() if not Loot.live.is_empty() else {}
	var marked: bool = not dropped.is_empty() and (dropped.pos as Vector3).distance_to(at) < 0.01 and bool(dropped.marker.minor) and str(dropped.marker.label).begins_with("Salvage")
	SmokeTest._check("loot: a dead brute leaves a minor marker", marked)
	var salvage: float = g.stockpile.salvage
	if not marked:
		SmokeTest._check("loot: it waits for the Operative", false)
		SmokeTest._check("loot: the Operative picks it up within 1.5 m", false)
		return
	if g.fps.world != null:
		g.fps.leave()
	(dropped.tick as Callable).call(1.0)
	SmokeTest._check("loot: it waits for the Operative", bool(dropped.alive) and is_equal_approx(g.stockpile.salvage, salvage))
	g.fps.enter(g.surface, Vector2i(int(hive.x), int(hive.z)), 0.0)
	g.fps.controller.pos = at
	g.fps.body.position = at
	(dropped.tick as Callable).call(0.05)
	SmokeTest._check("loot: the Operative picks it up within 1.5 m", not bool(dropped.alive)
		and is_equal_approx(g.stockpile.salvage, salvage + 2.0))
	g.fps.leave()
	var gone := Loot.drop(g.surface, at + Vector3(30, 0, 0), 9.0, g.stockpile, nests.operative)
	salvage = g.stockpile.salvage
	(gone.tick as Callable).call(Config.LOOT_LIFE + 0.1)
	SmokeTest._check("loot: a pickup fades after 90 s", not bool(gone.alive) and is_equal_approx(g.stockpile.salvage, salvage))


static func _part(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var hive := _active(nests)
	if hive.is_empty():
		SmokeTest._check("loot: a live pit to break", false)
		return
	var pit := Hives.find(hive, "pit")
	if pit.is_empty():
		SmokeTest._check("loot: a live pit to break", false)
		return
	var salvage: float = g.stockpile.salvage
	HiveParts.hurt(nests, hive, pit, 9999.0, "unit")
	SmokeTest._check("loot: a hive part drops 5", Loot.holding(pit.pos, Config.LOOT_PART) and is_equal_approx(g.stockpile.salvage, salvage))


static func _crown(g) -> void:
	var castles: Strongholds = g.castles
	var c := {}
	for item in castles.list:
		var row: Dictionary = item
		if str(row.state) == "hostile":
			c = row
			break
	if c.is_empty():
		SmokeTest._check("loot: a hostile crown to break", false)
		return
	var crown: Node3D = castles.views[c.id].crown
	var hits: Array = castles.world.targets.filter(func(t): return t.node == crown)
	if hits.is_empty():
		SmokeTest._check("loot: crown target", false)
		return
	var salvage: float = g.stockpile.salvage
	hits[0].on_hit.call(1e6)
	SmokeTest._check("loot: a crown nest drops 15", str(c.state) == "capturing" and Loot.holding(crown.position, Config.LOOT_CROWN)
		and is_equal_approx(g.stockpile.salvage, salvage))


static func _active(nests: SporeNests) -> Dictionary:
	for n in nests.nests:
		var hive: Dictionary = n
		if str(hive.state) == "active" and not Hives.find(hive, "pit").is_empty():
			return hive
	return {}
