class_name SmokeTuning
## Stage 9b P5/P6 (Stage 13): the Sniper rule changes that fixed the L1 demo, and the new
## counters behind the sim report fields.


static func run(g) -> void:
	_sniper(g)
	_counters(g)


static func _spawn(g, tier: String, at: Vector3) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	nests.raiders.spawn(nests.nests[0], RaiderDefs.named(tier), true)
	var r: Dictionary = nests.raiders.list.back()
	(r.node as Node3D).position = at
	return r


static func _sniper(g) -> void:
	var raiders: Raiders = g.hazards.nests.raiders
	for r in raiders.list.duplicate():
		raiders.kill(r)
	var sm: StructureManager = g.structures
	var s: Structure = sm.place("sniper", 46, 74, true)
	var at: Vector3 = s.pos
	var skit := _spawn(g, "Skitter", at + Vector3(8, 0, 0))
	var spit := _spawn(g, "Spitter", at + Vector3(0, 0, -30))
	WeaponLogic._snipe(s, sm)
	SmokeTest._check("tuning: a Sniper shoots a ranged raider before a nearer melee one",
		spit.hp < RaiderDefs.named("Spitter").hp and is_equal_approx(skit.hp, RaiderDefs.named("Skitter").hp),
		"(spitter %.1f, skitter %.1f)" % [spit.hp, skit.hp])
	raiders.kill(skit)
	raiders.kill(spit)
	var high := _spawn(g, "Brute", at + Vector3(38, 25, 0))  # 38 m away on the ground, 25 m above
	var hp: float = high.hp
	WeaponLogic._snipe(s, sm)
	SmokeTest._check("tuning: Sniper range is measured on the ground (height does not shorten it)", high.hp < hp, "(%.1f)" % high.hp)
	(high.node as Node3D).position = at + Vector3(42, 0, 0)
	hp = high.hp
	s.cooldown = 0.0
	WeaponLogic._snipe(s, sm)
	SmokeTest._check("tuning: ... and a target beyond the range is still safe", is_equal_approx(high.hp, hp))
	raiders.kill(high)
	sm.remove(s)


static func _counters(g) -> void:
	var stock: Stockpile = g.stockpile
	var e := stock.earned_salvage
	var o := stock.earned_ore
	stock.add("salvage", 4.0)
	stock.add("ore", 3.0)
	stock.spend("salvage", 2.0)
	SmokeTest._check("tuning: the stockpile counts what was earned, not what was spent",
		is_equal_approx(stock.earned_salvage - e, 4.0) and is_equal_approx(stock.earned_ore - o, 3.0))
	stock.spend("salvage", 2.0)
	stock.spend("ore", 3.0)
	Bus.objective_done.emit("tuning_probe")
	SmokeTest._check("tuning: objective completion times are recorded", g.objective_times.has("tuning_probe"))
	g.objective_times.erase("tuning_probe")
	SmokeTest._check("tuning: the engines report salvage left and sockets hooked", g.engines.salvage_left() > 0.0 and g.engines.total_hooked() >= 0)
