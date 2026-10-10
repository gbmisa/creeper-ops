class_name SmokeEnemyRules
## Playtest 3: enemy mortars die only to sabotage or a charge blast; spitter towers pay no Salvage
## and are not re-raised instantly.


static func run(g) -> void:
	_mortar(g)
	_spitter(g)


static func _mortar(g) -> void:
	var nests: SporeNests = g.hazards.nests
	nests.time = 0.0
	for n in nests.nests:
		Hives.sync(nests, n)
	var hive := SmokeEnemyMortar._named(nests, "Central knoll")
	EnemyMortars.clear(nests, hive)
	var m := SmokeEnemyMortar._plant(nests, hive, 20, 70)
	(m.target as Dictionary).on_hit.call(99999.0, m.pos)
	(m.enemy as Dictionary).hit.call(99999.0)
	SmokeTest._check("mortar survives heavy gun damage", m.alive and float(m.hp) > 0.0)
	DemoCharge.plant(nests.world, m.pos)
	DemoCharge.tick(nests.world, Config.DEMO_FUSE + 0.1)
	SmokeTest._check("a charge blast also destroys the mortar", not m.alive)
	EnemyMortars.clear(nests, hive)


static func _spitter(g) -> void:
	var b: EnemyBuilder = g.builder
	b.clear()
	b.hold = true
	var hub := SmokeEnemyBuild._hub(g)
	var cell := SmokeEnemyBuild._cell(g, 3, 0)
	var s := b.begin(hub, "spitter", cell, false, -1.0)
	var before: float = g.stockpile.salvage
	s.channel = Config.MORTAR_SABOTAGE_TIME
	var done := b.apply_channel(s, s.pos, Config.MORTAR_SABOTAGE_TIME)
	SmokeTest._check("sabotaged spitter tower credits 0 Salvage", done and is_equal_approx(g.stockpile.salvage, before))
	var t := b.begin(hub, "spitter", cell, false, -1.0)
	b.hurt(t, 9999.0)
	SmokeTest._check("destroyed spitter tower credits 0 Salvage", not t.alive and is_equal_approx(g.stockpile.salvage, before))
	b.hold = false
	for i in 58:  # 29 s
		b.update(0.5)
	var back := false
	for raw in b.list:
		if str(raw.kind) == "spitter" and raw.cell == cell and bool(raw.alive):
			back = true
	SmokeTest._check("destroyed spitter tower does not reappear within 30 s", not back)
	b.clear()
	b.hold = true
