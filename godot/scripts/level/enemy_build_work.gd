class_name EnemyBuildWork
## Build rate, pump stock, and the one-slot planner (§4.5). Bonus speed is paid from
## pump.material; a jam, an empty stock, or a captured castle leaves the dry rate.


static func income(b, dt: float) -> void:
	cap(b)
	for raw in b.list:
		var s: Dictionary = raw
		if not bool(s.alive) or not bool(s.grown) or str(s.kind) != "leech" or b.denied(s.cell):
			continue
		var hub: Dictionary = b.castle(str(s.hub))
		if hub.is_empty() or str(hub.owner) != "enemy":
			continue
		hub.pump.material = minf(Config.ENEMY_MAT_PER, float(hub.pump.material) + Config.ENEMY_LEECH_MAT * dt)


static func cap(b) -> void:
	for raw in b.castles.list:
		var c: Dictionary = raw
		c.pump.material = minf(Config.ENEMY_MAT_PER, float(c.pump.material))


static func plan(b, dt: float) -> void:
	for raw in b.castles.list:
		var c: Dictionary = raw
		if str(c.owner) != "enemy" or growing(b, str(c.id)) >= EnemyStructures.slots(b.nests.pressure()):
			continue
		b._cool[c.id] = float(b._cool.get(c.id, 0.0)) - dt
		if float(b._cool[c.id]) > 0.0:
			continue
		var picked := take(b, c)
		if picked.is_empty():
			picked = EnemyBuildPlan.pick(b, c)
		if picked.is_empty():
			b._cool[c.id] = 5.0
			continue
		b.begin(c, str(picked.kind), picked.cell, bool(picked.get("rubble", false)), float(picked.get("cost", -1.0)))


static func progress(b, dt: float) -> void:
	for raw in b.list.duplicate():
		var s: Dictionary = raw
		if not bool(s.alive) or bool(s.grown) or not EnemyBuildCrew.onsite(b, s):
			continue
		var hub: Dictionary = b.castle(str(s.hub))
		if hub.is_empty() or str(hub.owner) != "enemy":
			continue
		var cell: Vector2i = s.cell
		var depth: float = b.world.creeper.depth_at(cell.x, cell.y)
		var leeches: int = b.leech_count()
		var pressure: float = b.nests.pressure()
		var intake := intake_of(hub)
		var full := EnemyStructures.rate(intake, depth, leeches, pressure)
		var dry := EnemyStructures.rate(0.0, depth, leeches, pressure)
		var bonus := full - dry
		if bonus > 0.0:
			var want := bonus * Config.ENEMY_MAT_PER * dt
			var pay := minf(float(hub.pump.material), want)
			hub.pump.material = float(hub.pump.material) - pay
			if want > 0.0:
				bonus *= pay / want
			else:
				bonus = 0.0
		s.progress = float(s.progress) + (dry + bonus) * dt
		var k := clampf(float(s.progress) / maxf(float(s.cost), 0.001), 0.0, 1.0)
		(s.node as Node3D).scale = Vector3.ONE * lerpf(0.25, 1.0, k)
		if float(s.progress) >= float(s.cost):
			EnemyBuildFight.grew(b, s)


static func intake_of(hub: Dictionary) -> float:
	if str(hub.owner) != "enemy" or float(hub.pump.jam) > 0.0:
		return 0.0
	return float(hub.pump.intake)


static func growing(b, hub_id: String) -> int:
	var n := 0
	for raw in b.list:
		var s: Dictionary = raw
		if bool(s.alive) and not bool(s.grown) and str(s.hub) == hub_id:
			n += 1
	return n


static func take(b, c: Dictionary) -> Dictionary:
	for raw in b.queue:
		var q: Dictionary = raw
		if str(q.hub) == str(c.id):
			b.queue.erase(q)
			return q
	return {}
