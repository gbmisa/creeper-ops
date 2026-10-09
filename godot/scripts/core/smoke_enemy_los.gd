class_name SmokeEnemyLos
## Enemies must not shoot through castle walls. Lancer bolts (near-flat) need line of
## sight at fire time; lobbed acid/spit keeps arcing over low walls but splashes on
## tall blockers instead of passing through them; the Lancer Spire beam needs LOS too.


static func run(g) -> void:
	_lancer_blocked_by_wall(g)
	_lancer_open_ground_still_hits(g)
	_spitter_clears_low_wall(g)
	_spitter_stopped_by_keep(g)
	_spire_beam_blocked_by_wall(g)
	_spire_beam_open_ground_still_hits(g)


static func _pad(g, x0: int, z0: int, x1: int, z1: int) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)


static func _wall(g, x0: int, z0: int, x1: int, z1: int, levels: float) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0 - 2)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h + levels * Config.LEVEL_H })
	TerrainEdit.apply(g.surface, edits)


static func _clear(g) -> void:
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)
	for o in g.hazards.nests.raiders.list.duplicate():
		g.hazards.nests.raiders.kill(o)


static func _spawn_at(g, who: String, cell: Vector2i) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	nests.raiders.spawn(nests.nests[0], RaiderDefs.named(who), true)
	var r := nests.raiders.list.back() as Dictionary
	r.guard = true
	(r.node as Node3D).position = g.surface.grid.cell_ground(cell.x, cell.y)
	return r


static func _lancer_blocked_by_wall(g) -> void:
	_pad(g, 44, 40, 68, 48)
	_wall(g, 52, 42, 54, 46, 4.0)  # 5 m cliff between the Lancer and the sniper
	_clear(g)
	var sm: StructureManager = g.structures
	var sniper := sm.place("sniper", 60, 44, true)
	var r := _spawn_at(g, "Lancer", Vector2i(48, 44))
	var sh0: float = sniper.hp
	var saw_lob := false
	for _i in 100:  # 5 s: more than a full charge + bolt flight
		g.hazards.nests.raiders.update(0.05, [sniper.prey], [])
		g.surface.effects.update(0.05)
		if g.surface.effects.lobs().size() > 0:
			saw_lob = true
	SmokeTest._check("lancer behind a wall does not hit the sniper",
		is_equal_approx(sniper.hp, sh0) and not saw_lob,
		"(hp %.1f of %.1f, lob loosed %s)" % [sniper.hp, sh0, saw_lob])
	g.hazards.nests.raiders.kill(r)
	sm.remove(sniper)
	_clear(g)


static func _lancer_open_ground_still_hits(g) -> void:
	_pad(g, 44, 40, 68, 48)
	_clear(g)
	var sm: StructureManager = g.structures
	var sniper := sm.place("sniper", 60, 44, true)
	var r := _spawn_at(g, "Lancer", Vector2i(50, 44))
	var sh0: float = sniper.hp
	for _i in 100:
		g.hazards.nests.raiders.update(0.05, [sniper.prey], [])
		g.surface.effects.update(0.05)
		if sniper.dead:
			break
	SmokeTest._check("lancer with line of sight still hits the sniper", sniper.hp < sh0 - 20.0,
		"(hp %.1f of %.1f)" % [sniper.hp, sh0])
	g.hazards.nests.raiders.kill(r)
	sm.remove(sniper)
	_clear(g)


static func _spitter_clears_low_wall(g) -> void:
	_pad(g, 44, 40, 68, 48)
	_wall(g, 52, 42, 54, 46, 1.0)  # 1.25 m: the 7.5 m acid arc clears it
	_clear(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 60, 44, true)
	var r := _spawn_at(g, "Spitter", Vector2i(50, 44))
	var hp0: float = cannon.hp
	for _i in 140:  # 7 s: interval + 50 m lob flight
		g.hazards.nests.raiders.update(0.05, [cannon.prey], [])
		g.surface.effects.update(0.05)
		if cannon.hp < hp0:
			break
	SmokeTest._check("spitter acid still lobs over a low wall", cannon.hp < hp0,
		"(hp %.1f of %.1f)" % [cannon.hp, hp0])
	g.hazards.nests.raiders.kill(r)
	sm.remove(cannon)
	_clear(g)


static func _spitter_stopped_by_keep(g) -> void:
	_pad(g, 44, 40, 68, 48)
	_wall(g, 52, 42, 54, 46, 8.0)  # 10 m keep wall: the 7.5 m arc cannot clear it
	_clear(g)
	var sm: StructureManager = g.structures
	var cannon := sm.place("cannon", 60, 44, true)
	var r := _spawn_at(g, "Spitter", Vector2i(50, 44))
	var hp0: float = cannon.hp
	var saw_lob := false
	for _i in 140:
		g.hazards.nests.raiders.update(0.05, [cannon.prey], [])
		g.surface.effects.update(0.05)
		if g.surface.effects.lobs().size() > 0:
			saw_lob = true
	SmokeTest._check("spitter acid splashes on a keep wall, not through it",
		is_equal_approx(cannon.hp, hp0) and saw_lob,
		"(hp %.1f of %.1f, lob loosed %s)" % [cannon.hp, hp0, saw_lob])
	g.hazards.nests.raiders.kill(r)
	sm.remove(cannon)
	_clear(g)


static func _spire_setup(g, wall_levels: float) -> Array:
	_pad(g, 44, 40, 68, 48)
	if wall_levels > 0.0:
		_wall(g, 52, 42, 54, 46, wall_levels)
	_clear(g)
	var b = g.builder
	b.clear()
	b.hold = true
	var sm: StructureManager = g.structures
	var sniper := sm.place("sniper", 58, 44, true)
	var hub: Dictionary = _hub(g)
	var s: Dictionary = b.begin(hub, "lancer", Vector2i(50, 44), false, -1.0)
	EnemyBuildFight.grew(b, s)
	return [b, s, sniper]


static func _hub(g) -> Dictionary:
	for raw in g.castles.list:
		var c: Dictionary = raw
		if str(c.owner) == "enemy":
			return c
	return g.castles.list[0]


static func _spire_beam_blocked_by_wall(g) -> void:
	var parts := _spire_setup(g, 4.0)
	var b = parts[0]
	var s: Dictionary = parts[1]
	var sniper: Structure = parts[2]
	var sh0: float = sniper.hp
	for _i in 60:  # 3 s: two full 1.5 s charge cycles
		EnemyBuildFight.beam(b, s, 0.05)
		g.surface.effects.update(0.05)
	SmokeTest._check("lancer spire cannot beam through a wall", is_equal_approx(sniper.hp, sh0),
		"(hp %.1f of %.1f)" % [sniper.hp, sh0])
	_teardown_spire(g, parts)


static func _spire_beam_open_ground_still_hits(g) -> void:
	var parts := _spire_setup(g, 0.0)
	var b = parts[0]
	var s: Dictionary = parts[1]
	var sniper: Structure = parts[2]
	var sh0: float = sniper.hp
	for _i in 60:
		EnemyBuildFight.beam(b, s, 0.05)
		g.surface.effects.update(0.05)
		if sniper.hp < sh0:
			break
	SmokeTest._check("lancer spire with line of sight still beams", sniper.hp < sh0,
		"(hp %.1f of %.1f)" % [sniper.hp, sh0])
	_teardown_spire(g, parts)


static func _teardown_spire(g, parts: Array) -> void:
	var b = parts[0]
	var sniper: Structure = parts[2]
	b.clear()
	b.hold = true
	if not sniper.dead:
		g.structures.remove(sniper)
	_clear(g)
