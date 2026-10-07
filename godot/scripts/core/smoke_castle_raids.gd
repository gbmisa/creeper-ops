class_name SmokeCastleRaids
## Stage 7b checks: reprisal timing and size, stacking with castles held, Level 1 numbers,
## the siege interval and warning, cancel on loss, the hostile-castle nest buff and the
## saved state. Leaves both castles hostile and kills the raiders it sent.


static func run(g) -> void:
	var raids: CastleRaids = g.castle_raids
	var castles: Strongholds = g.castles
	var raiders: Raiders = castles.nests.raiders
	var a: Dictionary = castles.list[0]
	var b: Dictionary = castles.list[1]
	var before := raiders.list.duplicate()
	raids.update(0.0)  # sync last-seen states after the Stage 7 checks
	var L: Dictionary = Level01.CASTLE_RULES
	SmokeTest._check("raids: Level 1 rules merge over Config", raids.rules.aggression == L.aggression
		and raids.rules.reprisal_warn == L.reprisal_warn and raids.rules.siege_warn == Config.CASTLE_RULES.siege_warn)
	_nest_buff(raids, castles, a, b)
	_reprisal(raids, castles, a, raiders)
	_stack(raids, castles, b)
	_siege(raids, a)
	_save(castles, a)
	for c in [a, b]:
		StrongholdRules.to_hostile(castles.world, c, castles.lays[c.id], 1.0)
		StrongholdMeshes.refresh(castles.views[c.id], c)
	raids.update(0.0)
	SmokeTest._check("raids: losing a castle cancels its raid", a.raid.kind == "" and b.raid.kind == "")
	for r in raiders.list.duplicate():
		if not r in before:
			raiders.kill(r)


static func _expected(raids: CastleRaids, kind: String, held: int) -> int:
	var R := raids.rules
	var base: float = R[kind + "_base"] + R[kind + "_per_tier"] * raids.nests.tier
	return maxi(1, roundi(base * R.aggression * (1.0 + R.held_stack * (held - 1))))


static func _near(raids: CastleRaids, c: Dictionary) -> Dictionary:
	var centre := Vector2(raids.castles.lays[c.id].spire.centre)
	for n in raids.nests.nests:
		if centre.distance_to(Vector2(n.x, n.z)) <= raids.rules.nest_buff_range:
			return n
	return {}


static func _nest_buff(raids: CastleRaids, castles: Strongholds, a: Dictionary, b: Dictionary) -> void:
	var n := _near(raids, a)
	SmokeTest._check("raids: a Level 1 nest sits near Ashmoat", not n.is_empty())
	if n.is_empty():
		return
	var k := 0
	for c in [a, b]:
		if Vector2(castles.lays[c.id].spire.centre).distance_to(Vector2(n.x, n.z)) <= raids.rules.nest_buff_range:
			k += 1
	SmokeTest._check("raids: hostile castles speed up nearby nests", is_equal_approx(n.rate, 1.0 + raids.rules.nest_buff * k))
	StrongholdRules.to_held(castles.world, a, castles.lays[a.id])
	raids.update(0.0)
	SmokeTest._check("raids: taking the castle removes its nest buff", is_equal_approx(n.rate, 1.0 + raids.rules.nest_buff * (k - 1)))


static func _reprisal(raids: CastleRaids, castles: Strongholds, a: Dictionary, raiders: Raiders) -> void:
	SmokeTest._check("raids: capture starts a reprisal warning", a.raid.kind == "reprisal"
		and is_equal_approx(a.raid.warn, raids.rules.reprisal_warn))
	var marching := func(): return raiders.list.filter(func(r): return r.get("mission", "") == "castle").size()
	var m0: int = marching.call()
	var want := _expected(raids, "reprisal", 1)
	SmokeTest._check("raids: Level 1 reprisal size", raids.size("reprisal") == want)
	raids.update(raids.rules.reprisal_warn - 1.0)
	SmokeTest._check("raids: nothing marches during the warning", a.raid.kind == "reprisal" and marching.call() == m0)
	var room := Config.RAIDER_MAX_TOTAL - raiders.list.size()
	raids.update(2.0)
	SmokeTest._check("raids: the reprisal marches after the warning", a.raid.kind == ""
		and marching.call() - m0 == mini(want, room) and is_equal_approx(a.raid.next, raids.interval()))


static func _stack(raids: CastleRaids, castles: Strongholds, b: Dictionary) -> void:
	var one := raids.interval()
	SmokeTest._check("raids: Level 1 siege interval", is_equal_approx(one,
		maxf(Config.CASTLE_SIEGE_MIN, raids.rules.siege_interval / raids.rules.aggression)))
	StrongholdRules.to_held(castles.world, b, castles.lays[b.id])
	raids.update(0.0)
	SmokeTest._check("raids: a second castle stacks raid size", raids.size("reprisal") == _expected(raids, "reprisal", 2)
		and raids.size("reprisal") > _expected(raids, "reprisal", 1))
	SmokeTest._check("raids: a second castle shortens sieges", raids.interval() < one)


static func _siege(raids: CastleRaids, a: Dictionary) -> void:
	var lead: float = a.raid.next - raids.rules.siege_warn
	raids.update(lead - 1.0)
	SmokeTest._check("raids: no siege warning too early", a.raid.kind == "")
	raids.update(1.5)
	SmokeTest._check("raids: siege warns siege_warn seconds ahead", a.raid.kind == "siege"
		and a.raid.warn <= raids.rules.siege_warn and a.raid.warn > raids.rules.siege_warn - 1.0)


static func _save(castles: Strongholds, a: Dictionary) -> void:
	var snap := castles.state()
	var warn: float = a.raid.warn
	a.raid.warn = 1.0
	a.raid.kind = ""
	castles.load_state(snap)
	SmokeTest._check("raids: raid state survives save and load", a.raid.kind == "siege" and is_equal_approx(a.raid.warn, warn))
