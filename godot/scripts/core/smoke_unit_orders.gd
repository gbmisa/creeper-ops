class_name SmokeUnitOrders
## Playtest 4 unit behaviour: attack order, retaliation, auto-patrol of new units.


static func run(g) -> void:
	SmokeAttackMove._pad(g, 40, 40, 70, 50)
	SmokeAttackMove._clear(g)
	_attack_order(g)
	_retaliation(g)
	_auto_patrol(g)
	_immune_mortar(g)
	_move_beats_fire(g)
	_mortar_rows(g)
	SmokeAttackMove._clear(g)


static func _attack_order(g) -> void:
	var near := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(60, 45), false)
	var far := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(62, 45), false)
	var p: Vector3 = (near.node as Node3D).position
	var foe := UnitAttack.enemy_near([near.enemy, far.enemy], p + Vector3(0.5, 0, 0))
	SmokeTest._check("attack order: picks nearest enemy to click", foe == near.enemy)
	SmokeTest._check("attack order: ground click picks nothing",
		UnitAttack.enemy_near([near.enemy], p + Vector3(20, 0, 0)).is_empty())
	var u: Unit = g.units.spawn("soldier", 44 * Config.CELL, 45 * Config.CELL)
	UnitAttack.order(g.units, [u], far.enemy)
	var t := 0.0
	while t < 40.0 and u.alive and far.alive:
		SmokeTest._sim(g, 0.5)
		t += 0.5
	SmokeTest._check("attack order: closes in and kills the chosen target", not far.alive, "(%.1f s)" % t)
	SmokeTest._check("attack order: holds after kill", u.state == "idle" and u.target.is_empty(), "(%s)" % u.state)
	g.units.kill(u)
	SmokeAttackMove._clear(g)


static func _retaliation(g) -> void:
	var a: Unit = g.units.spawn("soldier", 45 * Config.CELL, 47 * Config.CELL)
	var b: Unit = g.units.spawn("soldier", 46 * Config.CELL, 47 * Config.CELL)
	var c: Unit = g.units.spawn("soldier", 80 * Config.CELL, 47 * Config.CELL)  # too far to help
	var r := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(58, 47), false)
	g.units.enemies = [r.enemy]
	a.prey.hit.call(1.0)
	SmokeTest._check("retaliate: victim and idle ally attack, far ally does not",
		a.state == "attack" and b.state == "attack" and c.state == "idle")
	g.units.order([a], Vector2(a.pos.x, a.pos.z), true)
	SmokeTest._check("retaliate: player order overrides", a.state == "move" and a.target.is_empty())
	for u in [a, b, c]:
		g.units.kill(u)
	SmokeAttackMove._clear(g)


static func _auto_patrol(g) -> void:
	var bar: Structure = g.structures.place("barracks", 50, 42, true)
	g.units._on_trained("soldier", bar)
	var u: Unit = g.units.list.back()
	SmokeTest._check("auto-patrol: new unit patrols", u.state == "patrol" and u.patrol.size() == 4,
		"(%s %d pts)" % [u.state, u.patrol.size()])
	g.units.order([u], Vector2(u.pos.x, u.pos.z), true)
	SmokeTest._check("auto-patrol: order cancels it", u.patrol.is_empty())
	g.units.kill(u)
	g.structures.remove(bar)


## Enemy mortars die only to charges: units must neither shoot them nor accept an attack order.
static func _immune_mortar(g) -> void:
	var u: Unit = g.units.spawn("soldier", 50 * Config.CELL, 45 * Config.CELL)
	var mt := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(53, 45), false)
	mt.enemy["immune"] = true
	var ammo0 := u.ammo
	UnitSupply._fight(g.units, u, 1.0, [mt.enemy])
	SmokeTest._check("immune: unit does not shoot a charge-only target", u.ammo == ammo0 and UnitSupply.acquire(u, [mt.enemy]).is_empty())
	UnitAttack.order(g.units, [u], mt.enemy)
	SmokeTest._check("immune: attack order refused", u.state != "attack")
	g.units.enemies = [mt.enemy]
	u.prey.hit.call(1.0)
	SmokeTest._check("immune: no retaliation against it", u.state != "attack")
	g.units.kill(u)
	SmokeAttackMove._clear(g)


## A unit firing at an enemy obeys a move order: it walks, and does not fire en route.
static func _move_beats_fire(g) -> void:
	var u: Unit = g.units.spawn("soldier", 45 * Config.CELL, 45 * Config.CELL)
	var r := SmokeAttackMove._spawn_raider_at(g, "Skitter", Vector2i(51, 45), false)
	g.units.enemies = [r.enemy]
	var dest := Vector2(42 * Config.CELL, 45 * Config.CELL)
	g.units.order([u], Vector2(65 * Config.CELL, 45 * Config.CELL))  # attack-move: engages
	for i in 4:
		SmokeTest._sim(g, 0.5)
	g.units.order([u], dest, true)
	var d0 := Vector2(u.pos.x - dest.x, u.pos.z - dest.y).length()
	var ammo0 := u.ammo
	for i in 6:
		SmokeTest._sim(g, 0.5)
	var d1 := Vector2(u.pos.x - dest.x, u.pos.z - dest.y).length()
	SmokeTest._check("move order beats firing: closer to destination, no shots",
		u.alive and d1 < d0 - 3.0 and u.ammo == ammo0, "(%.1f -> %.1f m, ammo %.0f -> %.0f)" % [d0, d1, ammo0, u.ammo])
	if u.alive:
		g.units.kill(u)
	SmokeAttackMove._clear(g)


## Every mortar row is untargetable (Snipers, units, repeater skip it) and never a Trebuchet pick.
static func _mortar_rows(g) -> void:
	var rows := 0
	var bad := 0
	for n in g.hazards.nests.nests:
		for m in n.get("mortars", []):
			rows += 1
			var e: Dictionary = m.enemy
			if not (e.get("immune", false) and e.has("targetable") and not e.targetable.call()) or WeaponLogic._siege_foes(g.structures).has(e):
				bad += 1
	SmokeTest._check("mortar rows: untargetable, immune, not trebuchet picks", bad == 0, "(%d rows, %d bad)" % [rows, bad])
