class_name SmokeCastleGuard
## Playtest 3 items 12/14: nothing is built near a castle you do not hold, and Lancers belong
## to a hostile castle (they stay at their post and are dismissed when it is taken).


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = castles.list[0]
	var lay: Dictionary = castles.lays[c.id]
	var was := [c.owner, c.state]
	for r in castles.nests.raiders.list.duplicate():
		castles.nests.raiders.kill(r)
	CastlePerks.attach(castles)
	c.owner = "enemy"
	c.state = "hostile"
	_placement(g, castles, c, lay)
	_lancer(g, castles, c)
	c.owner = was[0]
	c.state = was[1]
	CastleExclusion.refresh(castles)


static func _placement(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var mid := Vector2i(CastlePerks.centre(lay))
	var near := Vector2i(mid.x + int(CastleDefs.BUILD_BAN_RADIUS) - 2, mid.y)
	var far := Vector2i(mid.x + int(CastleDefs.BUILD_BAN_RADIUS) + 3, mid.y)
	var why: String = Placement.castle_ban.call(near.x, near.y)
	SmokeTest._check("guard: building near a hostile castle is refused", why == CastleExclusion.REASON, why)
	var res := Placement.can_place(g.structures, "collector", near.x, near.y)
	SmokeTest._check("guard: can_place reports the enemy castle", not res.ok and (res.reason == CastleExclusion.REASON or res.reason != ""), str(res.reason))
	SmokeTest._check("guard: outside the radius is not banned", Placement.castle_ban.call(far.x, far.y) == "")
	c.state = "capturing"
	SmokeTest._check("guard: a castle still being captured stays banned", Placement.castle_ban.call(near.x, near.y) != "")
	c.owner = "player"
	c.state = "held"
	SmokeTest._check("guard: land is free once the castle is held", Placement.castle_ban.call(near.x, near.y) == "")
	c.owner = "enemy"
	c.state = "hostile"


static func _lancer(g, castles: Strongholds, c: Dictionary) -> void:
	var nests: SporeNests = castles.nests
	var host: Raiders = nests.raiders
	var post: Vector3 = castles.views[c.id].garrison.pos
	host.spawn(nests.nests[0], RaiderDefs.named("Lancer"), false)
	var r: Dictionary = host.list.back()
	SmokeTest._check("guard: a Lancer is posted at a hostile castle",
		r.has("guard_post") and r.guard_post.castle == c.id and r.node.position.distance_to(post) < 3.0)
	var base: Vector3 = g.structures.command_node().pos
	for i in 100:
		host.update(0.1, [], [Vector2i(int(base.x / Config.CELL), int(base.z / Config.CELL))])
	SmokeTest._check("guard: the Lancer stays at its castle instead of marching",
		r.alive and Vector2(r.node.position.x - post.x, r.node.position.z - post.z).length() < 8.0)
	c.state = "capturing"
	host.update(0.1, [], [])
	SmokeTest._check("guard: its Lancers are dismissed when the castle falls", not r.alive)
	c.state = "hostile"
	for i in CastleDefs.LANCERS_PER_CASTLE + 1:
		host.spawn(nests.nests[0], RaiderDefs.named("Lancer"), false)
	var n := host.list.filter(func(x): return x.has("guard_post") and x.guard_post.castle == c.id).size()
	SmokeTest._check("guard: a castle posts at most LANCERS_PER_CASTLE", n <= CastleDefs.LANCERS_PER_CASTLE, str(n))
	for x in host.list.duplicate():
		host.kill(x)
