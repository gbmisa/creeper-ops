class_name SmokeRosterFight
## Stage 8 combat checks for the roster: ranged shots, the Warden aura, the Burrower.
## Called from SmokeRoster so each file stays short.


static func run(g) -> void:
	_ranged(g)
	_warden_halves(g)
	_burrow_cliff(g)
	_burrow_only_while_up(g)
	_group(g)


static func _ranged(g) -> void:
	_spitter_hits_cannon(g)
	_lancer_picks_sniper(g)
	_shot_can_miss(g)


static func _pad(g, x0: int, z0: int, x1: int, z1: int) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)


static func _clear_shots(g) -> void:
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)


static func _spawn_at(g, who: String, cell: Vector2i) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	nests.raiders.spawn(nests.nests[0], RaiderDefs.named(who), true)
	var r := nests.raiders.list.back() as Dictionary
	r.guard = true
	(r.node as Node3D).position = g.surface.grid.cell_ground(cell.x, cell.y)
	return r


static func _spitter_hits_cannon(g) -> void:
	_pad(g, 4, 70, 28, 74)
	_clear_shots(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 21, 72, true)
	var r := _spawn_at(g, "Spitter", Vector2i(6, 72))
	var hp0: float = cannon.hp
	for _i in 50:  # 2.5 s: the first lob lands, the next has not
		g.hazards.nests.raiders.update(0.05, [cannon.prey], [])
		g.surface.effects.update(0.05)
	SmokeTest._check("spitter in range damages a cannon", cannon.hp < hp0 - 5.0 and cannon.hp > hp0 - 7.0,
		"(hp %.1f of %.1f)" % [cannon.hp, hp0])
	g.hazards.nests.raiders.kill(r)
	sm.remove(cannon)
	_clear_shots(g)


static func _lancer_picks_sniper(g) -> void:
	_pad(g, 2, 60, 36, 64)
	_clear_shots(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 12, 62, true)
	var sniper := sm.place("sniper", 28, 62, true)
	var r := _spawn_at(g, "Lancer", Vector2i(4, 62))
	var prey: Array = [
		{ "node": cannon.node, "radius": 1.0, "type": "cannon", "weapon": true,
			"alive": func(): return not cannon.dead, "hit": func(d): sm.damage(cannon, d) },
		{ "node": sniper.node, "radius": 1.0, "type": "sniper", "weapon": true,
			"alive": func(): return not sniper.dead, "hit": func(d): sm.damage(sniper, d) },
	]
	var ch0: float = cannon.hp
	var sh0: float = sniper.hp
	for _i in 90:  # 4.5 s: one charge and one flight, not a second bolt
		g.hazards.nests.raiders.update(0.05, prey, [])
		g.surface.effects.update(0.05)
	SmokeTest._check("lancer picks a sniper over a nearer cannon", sniper.hp < sh0 - 20.0 and is_equal_approx(cannon.hp, ch0),
		"(sniper %.1f, cannon %.1f)" % [sniper.hp, cannon.hp])
	g.hazards.nests.raiders.kill(r)
	sm.remove(cannon)
	sm.remove(sniper)
	_clear_shots(g)


static func _shot_can_miss(g) -> void:
	_pad(g, 2, 50, 40, 54)
	_clear_shots(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 21, 52, true)
	var r := _spawn_at(g, "Spitter", Vector2i(6, 52))
	var raiders: Raiders = g.hazards.nests.raiders
	var shot: Dictionary = {}
	for _i in 4:
		raiders.update(0.05, [cannon.prey], [])
		if g.surface.effects.lobs().size() > 0:
			shot = g.surface.effects.lobs()[0]
			break
	SmokeTest._check("spitter looses a lob", not shot.is_empty())
	cannon.node.position += Vector3(40, 0, 0)
	var hp0: float = cannon.hp
	for _i in 80:
		if not g.surface.effects.lobs().has(shot):
			break
		g.surface.effects.update(0.05)
	SmokeTest._check("a shot in flight misses a cannon that moved", is_equal_approx(cannon.hp, hp0),
		"(hp %.1f)" % cannon.hp)
	raiders.kill(r)
	sm.remove(cannon)
	_clear_shots(g)


static func _hit(r: Dictionary, dmg: float) -> void:
	var eh := r.enemy as Dictionary
	(eh.hit as Callable).call(dmg)


static func _warden_halves(g) -> void:
	var brute := _spawn_at(g, "Brute", Vector2i(8, 30))
	var w := _spawn_at(g, "Warden", Vector2i(8, 30))
	(w.node as Node3D).position = (brute.node as Node3D).position + Vector3(2, 0, 0)
	_hit(brute, 8.0)
	SmokeTest._check("warden halves damage", is_equal_approx(brute.hp, 12.0), "(hp %.1f)" % brute.hp)
	var w2 := _spawn_at(g, "Warden", Vector2i(8, 30))
	(w2.node as Node3D).position = (brute.node as Node3D).position + Vector3(-2, 0, 0)
	_hit(brute, 8.0)
	SmokeTest._check("warden auras do not stack", is_equal_approx(brute.hp, 8.0), "(hp %.1f)" % brute.hp)
	(w.node as Node3D).position += Vector3(50, 0, 0)
	(w2.node as Node3D).position += Vector3(-50, 0, 0)
	_hit(brute, 8.0)
	SmokeTest._check("full damage outside the aura", is_equal_approx(brute.hp, 0.0), "(hp %.1f)" % brute.hp)
	for who in [brute, w, w2]:
		if who.alive:
			g.hazards.nests.raiders.kill(who)


static func _burrow_cliff(g) -> void:
	_pad(g, 4, 42, 26, 46)
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(8, 44)
	var wall := []
	for z in range(42, 47):
		for x in range(12, 15):
			wall.append({ "x": x, "z": z, "height": h + 4.0 })
	TerrainEdit.apply(g.surface, wall)
	var blocked: bool = not g.hazards.nests.raiders.field.step_ok(11, 44, 12, 44)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 16, 44, true)
	var r := _spawn_at(g, "Burrower", Vector2i(8, 44))
	var prey: Array = [{ "node": cannon.node, "radius": 1.0, "type": "cannon", "weapon": true,
		"alive": func(): return not cannon.dead, "hit": func(d): sm.damage(cannon, d) }]
	var ch0: float = cannon.hp
	var host: Raiders = g.hazards.nests.raiders
	for _i in 180:  # 9 s: 16 m at 3 m/s, then the 1.5 s surface
		if cannon.dead or cannon.hp < ch0:
			break
		RaiderBurrow.step(host, r, 0.05, prey)
	SmokeTest._check("burrower crosses a cliff and bursts a weapon",
		blocked and (cannon.dead or cannon.hp <= ch0 - 50.0),
		"(blocked %s, hp %.1f of %.1f)" % [blocked, cannon.hp, ch0])
	if r.alive:
		g.hazards.nests.raiders.kill(r)
	if not cannon.dead:
		sm.remove(cannon)


static func _burrow_only_while_up(g) -> void:
	var r := _spawn_at(g, "Burrower", Vector2i(6, 36))
	var hp0: float = r.hp
	_hit(r, 9.0)
	var ignored := is_equal_approx(r.hp, hp0)
	r["burrow"] = "up"
	_hit(r, 9.0)
	SmokeTest._check("burrower is hittable only while surfacing", ignored and is_equal_approx(r.hp, hp0 - 9.0),
		"(hp %.1f)" % r.hp)
	g.hazards.nests.raiders.kill(r)


static func _group(g) -> void:
	var tiers: Array = RaiderGroups.compose(20, 0.5, 0)
	var front := 0
	var ranged := 0
	var support := 0
	var odd := false
	for row in tiers:
		var d: Dictionary = row
		var special := str(d.get("special", ""))
		if special == "burrow" or special == "spotter":
			odd = true
		match str(d.role):
			"front": front += 1
			"ranged": ranged += 1
			"support": support += 1
	SmokeTest._check("a group of 20 at pressure 0.5 has the role shares",
		not odd and front == 10 and ranged == 7 and support == 3, "(%d/%d/%d)" % [front, ranged, support])
	_pad(g, 18, 72, 55, 76)
	var grid: Grid = g.surface.grid
	var home: Vector3 = grid.cell_ground(22, 74)
	var nest := { "name": "test", "pos": home, "count": 0, "x": 22, "z": 74 }
	var host: Raiders = g.hazards.nests.raiders
	var gid := RaiderGroups.spawn(host, nest, tiers)
	var members: Array = []
	for r in host.list:
		if int(r.get("group", -1)) == gid:
			members.append(r)
	host.field.invalidate()
	for _i in 80:  # 4 s of gathering; a march would already have left the nest
		host.update(0.05, [], [Vector2i(50, 74)])
	var stayed := true
	for r in members:
		if not r.alive:
			continue
		var p: Vector3 = (r.node as Node3D).position
		if Vector2(p.x - home.x, p.z - home.z).length() > 8.0:
			stayed = false
	SmokeTest._check("a group gathers at the nest", stayed and members.size() == 20, "(%d)" % members.size())
	var slow := INF
	for r in members:
		r["gather"] = 0.0
		slow = minf(slow, float((r.tier as Dictionary).speed))
	var same := true
	for r in members:
		if absf(RaiderGroups.speed(host, r) - slow) > 0.01:
			same = false
	var starts: Array = []
	for r in members:
		var p: Vector3 = (r.node as Node3D).position
		starts.append(Vector2(p.x, p.z))
	host.field.invalidate()
	for _i in 20:  # 1 s of marching
		host.update(0.05, [], [Vector2i(50, 74)])
	var near := INF
	var far := 0.0
	for i in members.size():
		if not members[i].alive:
			continue
		var p: Vector3 = (members[i].node as Node3D).position
		var moved: float = Vector2(p.x, p.z).distance_to(starts[i])
		near = minf(near, moved)
		far = maxf(far, moved)
	SmokeTest._check("a group marches at one speed", same and far - near < 1.5 and near > slow * 0.45,
		"(slow %.1f, moved %.1f..%.1f)" % [slow, near, far])
	for r in members:
		if r.alive:
			host.kill(r)
