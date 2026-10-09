class_name EnemyBuildFight
## Combat for finished enemy structures (§4.5). Spitters match the hive spitter.
## A Lancer Spire charges 1.5 s, then hits snipers before any other weapon.
## A Creeper Pump emits only while an undenied Leech is nearby. Blight is a real zone.


static func tick(b, dt: float) -> void:
	var prey: Array = b.nests.prey.call()
	for raw in b.list:
		var s: Dictionary = raw
		if not bool(s.alive) or not bool(s.grown):
			continue
		match str(s.kind):
			"spitter":
				spit(b, s, dt, prey)
			"lancer":
				beam(b, s, dt)
			"pump":
				emit(b, s, dt)
			"pylon":
				hold_blight(b, s)
			"mortar":
				pass
	blight_dps(b, dt)
	if not b.mortars.is_empty():
		EnemyMortarFire.volley(b.nests, {"mortars": b.mortars}, dt)
		for raw in b.mortars:
			var m: Dictionary = raw
			if bool(m.alive) and bool(m.grown):
				EnemyMortars._spotter_clock(b.nests, m, dt)


static func grew(b, s: Dictionary) -> void:
	s.grown = true
	(s.node as Node3D).scale = Vector3.ONE
	if str(s.kind) == "pylon":
		paint(b, s)
		var aura := HazardMeshes.blight_aura(float(EnemyStructures.DEFS["pylon"].radius) * Config.CELL)
		(s.node as Node3D).add_child(aura)
	elif str(s.kind) == "mortar":
		arm_mortar(b, s)
	var hub: Dictionary = b.castle(str(s.hub))
	var who := str(hub.name) if not hub.is_empty() else "The enemy"
	Bus.say("%s finished a %s." % [who, EnemyStructures.DEFS[s.kind].label], "warn")


static func spit(b, s: Dictionary, dt: float, prey: Array) -> void:
	s.cd = float(s.cd) - dt
	if float(s.cd) > 0.0:
		return
	var reach := Config.HIVE_SPITTER_RANGE * Config.CELL
	var from: Vector3 = s.pos
	var best: Dictionary = {}
	var bd := reach
	for raw in prey:
		var q: Dictionary = raw
		if not (q.alive as Callable).call():
			continue
		var node := q.node as Node3D
		var d := Vector2(node.position.x - from.x, node.position.z - from.z).length()
		if d < bd:
			bd = d
			best = q
	if best.is_empty():
		return
	s.cd = Config.HIVE_SPITTER_INTERVAL
	var aim: Vector3 = (best.node as Node3D).position
	var splash := Config.HIVE_SPITTER_SPLASH * Config.CELL
	var dmg := Config.HIVE_SPITTER_DMG
	b.world.effects.lob(from + Vector3(0, 1.1, 0), aim, {
		"color": Color("d6ff3a"), "size": 0.28, "time": maxf(from.distance_to(aim) / Config.RAIDER_SHOT_SPEED, 0.35),
		"arc": 2.5,
		"on_arrive": func() -> void:
			b.world.effects.burst(aim, Color("d6ff3a"), splash, 0.35)
			for q in prey:
				var item: Dictionary = q
				if not (item.alive as Callable).call():
					continue
				var p: Vector3 = (item.node as Node3D).position
				if Vector2(p.x - aim.x, p.z - aim.z).length() <= splash:
					(item.hit as Callable).call(dmg),
	})


static func beam(b, s: Dictionary, dt: float) -> void:
	var def: Dictionary = EnemyStructures.DEFS["lancer"]
	var best: Structure = null
	var band := 0
	var bd := INF
	for raw in b.structures.list:
		var st: Structure = raw
		if st.dead or st.built < 1.0 or st.is_flying() or not bool(st.def.get("weapon", false)):
			continue
		var dist := Vector2(st.pos.x - s.pos.x, st.pos.z - s.pos.z).length() / Config.CELL
		if dist > float(def.range):
			continue
		var rank := 2 if st.type == "sniper" else 1
		if rank > band or (rank == band and dist < bd):
			band = rank
			bd = dist
			best = st
	if best == null:
		s.charge = 0.0
		return
	s.charge = float(s.charge) + dt
	b.world.effects.beam(s.pos + Vector3(0, 3.2, 0), best.pos + Vector3(0, 1.5, 0), Color("e6d2ff"), 0.05, 0.08)
	if float(s.charge) < float(def.interval):
		return
	s.charge = 0.0
	b.structures.damage(best, float(def.damage))
	Sfx.play("beam", s.pos)


static func emit(b, s: Dictionary, dt: float) -> void:
	if not fed(b, s):
		return
	var every := float(EnemyStructures.DEFS["pump"].every)
	s.cd = float(s.cd) - dt
	if float(s.cd) > 0.0:
		return
	s.cd = every
	var cell: Vector2i = s.cell
	b.world.creeper.add(cell.x, cell.y, float(EnemyStructures.DEFS["pump"].amount))


static func fed(b, s: Dictionary) -> bool:
	var cell: Vector2i = s.cell
	for raw in b.list:
		var other: Dictionary = raw
		if not bool(other.alive) or not bool(other.grown) or str(other.kind) != "leech":
			continue
		if b.denied(other.cell):
			continue
		if (other.cell as Vector2i).distance_to(cell) <= Config.ENEMY_LEECH_RANGE:
			return true
	return false


static func paint(b, s: Dictionary) -> void:
	var grid: Grid = b.world.grid
	var painted: Array = []
	for raw in grid.cells_in_radius(s.cell.x, s.cell.y, float(EnemyStructures.DEFS["pylon"].radius)):
		var cell: Vector2i = raw
		var i := grid.idx(cell.x, cell.y)
		if grid.zone[i] == Grid.Zone.NONE:
			grid.zone[i] = Grid.Zone.BLIGHT
			painted.append(cell)
	s.painted = painted


static func hold_blight(b, s: Dictionary) -> void:
	var grid: Grid = b.world.grid
	for raw in s.get("painted", []):
		var cell: Vector2i = raw
		var i := grid.idx(cell.x, cell.y)
		if grid.zone[i] == Grid.Zone.NONE:
			grid.zone[i] = Grid.Zone.BLIGHT


static func blight_dps(b, dt: float) -> void:
	for raw in b.structures.list:
		var st: Structure = raw
		if st.dead:
			continue
		for cell in Placement.footprint_cells(st.type, st.x, st.z):
			if b.blocks(cell.x, cell.y):
				b.structures.damage(st, Config.ENEMY_BLIGHT_DPS * dt)
				break


static func arm_mortar(b, s: Dictionary) -> void:
	var hive := {"pos": s.pos, "count": 0, "name": s.hub, "state": "active"}
	var m := {
		"mid": "hub-%s-%d" % [str(s.hub), b.mortars.size()], "hive": hive, "node": s.node, "pos": s.pos,
		"alive": true, "grown": true, "hp": s.hp, "max_hp": s.max_hp, "cd": Config.MORTAR_INTERVAL,
		"telegraph": null, "channel": 0.0, "spotted": false, "spotter": {}, "spotter_t": 0.0,
	}
	s.mortar = m
	b.mortars.append(m)
	EnemyMortarFire.spotter(b.nests, m)


static func stop_mortar(b, s: Dictionary) -> void:
	var m: Dictionary = s.get("mortar", {})
	if m.is_empty():
		return
	m.alive = false
	m.telegraph = null
	b.mortars.erase(m)
	var spot: Dictionary = m.get("spotter", {})
	if not spot.is_empty() and bool(spot.get("alive", false)):
		b.nests.raiders.kill(spot)
	s.mortar = {}
