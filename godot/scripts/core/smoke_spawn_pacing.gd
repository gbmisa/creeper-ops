class_name SmokeSpawnPacing
## Spawn-pacing checks (fix/spawn-pacing): the Behemoth flooded late-game spawns
## (~50% of pick() and ~25% of raid groups at the 0.85 unlock), outpacing a maxed
## arsenal. RaiderDefs.BEHEMOTH_WEIGHT_CAP reins it in. Pure distribution math over
## explicit rolls, so the checks are deterministic and need no live game.


static func _pick_share(p: float, name: String) -> float:
	var n := 20000
	var hit := 0
	for i in n:
		var row: Dictionary = RaiderDefs.pick(p, float(i) / float(n))
		if str(row.get("name", "")) == name:
			hit += 1
	return float(hit) / float(n)


static func _group_share(p: float, name: String) -> float:
	var size: int = RaiderGroups.size_for(p)
	var hit := 0
	var n := 0
	for salt in 40:
		for t in RaiderGroups.compose(size, p, salt):
			if str((t as Dictionary).get("name", "")) == name:
				hit += 1
			n += 1
	return float(hit) / float(maxi(n, 1))


static func run(_g) -> void:
	var beh := RaiderDefs.named("Behemoth")
	SmokeTest._check("pacing: behemoth stats untouched",
		is_equal_approx(float(beh.hp), 120.0) and is_equal_approx(float(beh.unlock), 0.85),
		"(hp %.0f, unlock %.2f)" % [float(beh.hp), float(beh.unlock)])
	SmokeTest._check("pacing: spawn curve untouched",
		is_equal_approx(float(Config.NEST_SPAWN_START), 20.0)
		and is_equal_approx(float(Config.NEST_SPAWN_MIN), 5.0)
		and Config.NEST_CAP_MAX == 10 and Config.RAIDER_MAX_TOTAL == 60)

	var early := _pick_share(0.2, "Skitter")
	SmokeTest._check("pacing: early game unchanged (exact 2^order at 0.2)",
		absf(early - 1.0 / 7.0) < 0.005
		and absf(_pick_share(0.2, "Spitter") - 2.0 / 7.0) < 0.005
		and absf(_pick_share(0.2, "Brute") - 4.0 / 7.0) < 0.005
		and _pick_share(0.2, "Behemoth") == 0.0,
		"(skitter %.1f%%)" % (early * 100.0))
	SmokeTest._check("pacing: mid game has no behemoth (0.5)",
		_pick_share(0.5, "Behemoth") == 0.0 and _group_share(0.5, "Behemoth") == 0.0)

	var pick85 := _pick_share(0.85, "Behemoth")
	SmokeTest._check("pacing: behemoth pick share at 0.85 below 10% (was ~50%)",
		pick85 < 0.10, "(%.1f%%)" % (pick85 * 100.0))
	SmokeTest._check("pacing: behemoth still spawns at 0.85",
		pick85 > 0.0, "(%.1f%%)" % (pick85 * 100.0))
	var group85 := _group_share(0.85, "Behemoth")
	SmokeTest._check("pacing: behemoth group share at 0.85 below 20% (was ~25%)",
		group85 < 0.20, "(%.1f%%)" % (group85 * 100.0))
	# Front pool is half the group: group share x2 = front-pool share.
	SmokeTest._check("pacing: behemoth still leads the front pool at 0.85",
		group85 * 2.0 >= 0.30, "(front-pool %.0f%%)" % (group85 * 200.0))
