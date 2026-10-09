class_name SmokeRaiders
## Stage 2 checks: Beams ignore raiders, mortar splash nicks them, raiders stop at a cliff,
## and SporeNests reads the level raid schedule. Called from SmokeTest.run.


static func run(g) -> void:
	_beam_ignores_raider(g)
	_beam_kills_acid_in_range(g)
	_beam_ignores_acid_out_of_range(g)
	_beam_ignores_friendly_lob(g)
	_beam_lob_costs_one_shot(g)
	_beam_spore_before_acid(g)
	_mortar_nicks_raider(g)
	_cliff(g)
	_schedule(g)


static func _clear_lobs(g) -> void:
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)


static func _free(sm: StructureManager, grid: Grid, x0: int, z0: int) -> Vector2i:
	for z in range(z0, z0 + 20):
		for x in range(x0, x0 + 20):
			if grid.in_bounds(x, z) and sm.structure_at(x, z) == null:
				return Vector2i(x, z)
	return Vector2i(x0, z0)


static func _spawn(nests: SporeNests) -> Dictionary:
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	nests.raiders.spawn(nest, RaiderDefs.named("Skitter"), false)
	var r: Dictionary = nests.raiders.list.back()
	r.guard = false
	return r


static func _beam_ignores_raider(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	_clear_lobs(g)
	var spot := _free(sm, grid, 6, 6)
	var beam := sm.place("beam", spot.x, spot.y, true)
	beam.cooldown = 0.0
	var r := _spawn(nests)
	r.node.position = grid.cell_ground(spot.x, spot.y) + Vector3(4.0, 0, 0)
	r.node.position.y = grid.smooth_y(r.node.position.x, r.node.position.z)
	var reach: float = WeaponLogic.range_cells(beam) * Config.CELL
	var dist: float = (r.node.position as Vector3).distance_to(WeaponLogic._muzzle(beam))
	var hp: float = r.hp
	var ammo: float = beam.ammo
	WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("beam ignores raider", dist <= reach and r.alive and r.hp == hp and beam.ammo == ammo,
		"(dist %.1f/%.0f hp %.1f ammo %.0f)" % [dist, reach, r.hp, beam.ammo])
	nests.raiders.kill(r)
	sm.remove(beam)


## Beam interception of spitter acid (fix/beam-intercept-lobs). A foe lob inside beam
## range is popped mid-flight: dead, and its on_arrive never fires.
static func _beam_kills_acid_in_range(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var fx = g.surface.effects
	_clear_lobs(g)
	var spot := _free(sm, grid, 6, 6)
	var beam := sm.place("beam", spot.x, spot.y, true)
	beam.cooldown = 0.0
	beam.ammo = 20.0
	var m: Vector3 = WeaponLogic._muzzle(beam)
	var arrived := [false]
	var it: Dictionary = fx.lob(m + Vector3(12, 6, 0), m + Vector3(-40, 0, 0),
		{ "color": Color("d6ff3a"), "size": 0.4, "time": 2.0, "arc": 4.0,
		"on_arrive": func(): arrived[0] = true })
	it["foe"] = true
	WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("beam kills acid in range", bool(it.dead), "dead=%s" % str(it.dead))
	fx.update(3.0)  # fly past the arrival time: the impact must never happen
	SmokeTest._check("acid on_arrive never fires", not arrived[0], "arrived=%s" % str(arrived[0]))
	sm.remove(beam)


## A foe lob outside beam range is untouched and still lands.
static func _beam_ignores_acid_out_of_range(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var fx = g.surface.effects
	_clear_lobs(g)
	var spot := _free(sm, grid, 6, 6)
	var beam := sm.place("beam", spot.x, spot.y, true)
	beam.cooldown = 0.0
	beam.ammo = 20.0
	var m: Vector3 = WeaponLogic._muzzle(beam)
	var reach: float = WeaponLogic.range_cells(beam) * Config.CELL
	var arrived := [false]
	var frm := m + Vector3(reach + 60.0, 6, 0)
	var it: Dictionary = fx.lob(frm, frm + Vector3(-30, -4, 0),
		{ "color": Color("d6ff3a"), "size": 0.4, "time": 1.0, "arc": 3.0,
		"on_arrive": func(): arrived[0] = true })
	it["foe"] = true
	WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("beam ignores acid out of range", not bool(it.dead), "dead=%s" % str(it.dead))
	fx.update(2.0)
	SmokeTest._check("acid out of range still lands", arrived[0], "arrived=%s" % str(arrived[0]))
	sm.remove(beam)


## Friendly lobs (player mortar/bertha shells: no "foe" key) are never intercepted.
static func _beam_ignores_friendly_lob(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var fx = g.surface.effects
	_clear_lobs(g)
	var spot := _free(sm, grid, 6, 6)
	var beam := sm.place("beam", spot.x, spot.y, true)
	beam.cooldown = 0.0
	beam.ammo = 20.0
	var m: Vector3 = WeaponLogic._muzzle(beam)
	var it: Dictionary = fx.lob(m + Vector3(12, 6, 0), m + Vector3(-40, 0, 0),
		{ "color": Color("ffb347"), "size": 0.45, "time": 2.0, "arc": 6.0 })
	WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("beam ignores friendly lob", not bool(it.dead), "dead=%s" % str(it.dead))
	sm.remove(beam)


## Intercepting a glob costs exactly one firing cycle: one per_shot of ammo, and a
## ground raider in range is still untouched (beams never hit ground raiders).
static func _beam_lob_costs_one_shot(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	var fx = g.surface.effects
	_clear_lobs(g)
	var spot := _free(sm, grid, 6, 6)
	var beam := sm.place("beam", spot.x, spot.y, true)
	beam.cooldown = 0.0
	beam.ammo = 20.0
	var m: Vector3 = WeaponLogic._muzzle(beam)
	var r := _spawn(nests)
	r.node.position = grid.cell_ground(spot.x, spot.y) + Vector3(4.0, 0, 0)
	r.node.position.y = grid.smooth_y(r.node.position.x, r.node.position.z)
	var it: Dictionary = fx.lob(m + Vector3(12, 6, 0), m + Vector3(-40, 0, 0),
		{ "color": Color("d6ff3a"), "size": 0.4, "time": 2.0, "arc": 4.0 })
	it["foe"] = true
	var hp: float = r.hp
	var ammo: float = beam.ammo
	var spent: float = beam.per_shot()
	WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("acid killed with raider nearby", bool(it.dead), "dead=%s" % str(it.dead))
	SmokeTest._check("raider still unharmed", r.alive and r.hp == hp, "hp %.1f" % r.hp)
	SmokeTest._check("exactly one shot spent", absf(beam.ammo - (ammo - spent)) < 0.001,
		"ammo %.1f" % beam.ammo)
	nests.raiders.kill(r)
	sm.remove(beam)


## Priority: spore volleys take the zap before acid globs (unified interception rule).
static func _beam_spore_before_acid(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var fx = g.surface.effects
	_clear_lobs(g)
	var spot := _free(sm, grid, 6, 6)
	var beam := sm.place("beam", spot.x, spot.y, true)
	beam.cooldown = 0.0
	beam.ammo = 20.0
	var m: Vector3 = WeaponLogic._muzzle(beam)
	var spore: Dictionary = fx.lob(m + Vector3(14, 6, 0), m + Vector3(-40, 0, 0),
		{ "color": Color("88ff55"), "size": 0.9, "time": 4.0, "arc": 8.0 })
	spore["spore"] = true
	spore["spore_hp"] = Config.SPORE_HP
	var acid: Dictionary = fx.lob(m + Vector3(12, 7, 2), m + Vector3(-38, 0, 2),
		{ "color": Color("d6ff3a"), "size": 0.4, "time": 2.0, "arc": 4.0 })
	acid["foe"] = true
	WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("spore takes the zap first",
		float(spore.spore_hp) < Config.SPORE_HP and not bool(acid.dead),
		"spore_hp %.1f acid_dead=%s" % [float(spore.spore_hp), str(acid.dead)])
	sm.remove(beam)


static func _mortar_nicks_raider(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	var creep = g.surface.creeper
	_clear_lobs(g)
	var spot := _free(sm, grid, 8, 40)
	var mortar := sm.place("mortar", spot.x, spot.y, true)
	mortar.cooldown = 0.0
	var target := spot + Vector2i(3, 0)
	if not grid.in_bounds(target.x, target.y):
		target = spot + Vector2i(-3, 0)
	var saved := {}
	for c in grid.cells_in_radius(spot.x, spot.y, 24.0):
		var i := grid.idx(c.x, c.y)
		saved[i] = creep.depth[i]
		creep.depth[i] = 0.0
	creep.depth[grid.idx(target.x, target.y)] = 6.0
	var r := _spawn(nests)
	r.node.position = grid.cell_ground(target.x, target.y)
	var hp: float = r.hp
	var ammo: float = mortar.ammo
	WeaponLogic.update(mortar, 0.2, sm)
	for i in 22:  # mortar shell flight is 1.0 s
		g.surface.effects.update(0.05)
	var dealt: float = hp - r.hp if r.alive else hp
	SmokeTest._check("mortar splash damages raider", mortar.ammo < ammo and is_equal_approx(dealt, Config.MORTAR_RAIDER_DMG),
		"(dealt %.2f, want %.2f, fired %s)" % [dealt, Config.MORTAR_RAIDER_DMG, mortar.ammo < ammo])
	if r.alive:
		nests.raiders.kill(r)
	sm.remove(mortar)
	for i in saved:
		creep.depth[i] = saved[i]


static func _cliff(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	for x in nests.raiders.list.duplicate():
		nests.raiders.kill(x)
	var col := _column(sm, grid)
	var saved := {}
	for dz in 6:
		for dx in range(-1, 2):
			var c := Vector2i(col.x + dx, col.y + dz)
			saved[c] = grid.height_at(c.x, c.y)
			grid.set_height(c.x, c.y, 4.0 if dz >= 2 else 1.0)
	var cannon := sm.place("cannon", col.x, col.y + 4, true)
	var r := _spawn(nests)
	r.node.position = grid.cell_ground(col.x, col.y)
	var z0: float = r.node.position.z
	for i in 60:
		nests.raiders.update(0.05, [cannon.prey], [Vector2i(cannon.x, cannon.z)])
	var cell := grid.world_to_cell(r.node.position.x, r.node.position.z)
	var h: float = grid.height_at(cell.x, cell.y)
	SmokeTest._check("raider does not climb a 3-level cliff", h <= 1.01 and r.node.position.z > z0 + 1.0,
		"(height %.0f, z %.1f -> %.1f)" % [h, z0, r.node.position.z])
	if r.alive:
		nests.raiders.kill(r)
	sm.remove(cannon)
	for c in saved:
		grid.set_height(c.x, c.y, saved[c])


static func _column(sm: StructureManager, grid: Grid) -> Vector2i:
	for z in range(2, 60):
		for x in range(2, 70):
			var ok := true
			for dz in 6:
				for dx in range(-1, 2):
					if not grid.in_bounds(x + dx, z + dz) or sm.structure_at(x + dx, z + dz) != null:
						ok = false
						break
				if not ok:
					break
			if ok:
				return Vector2i(x, z)
	return Vector2i(3, 3)


static func _schedule(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var saved_sched: Dictionary = nests.schedule
	var saved_time: float = nests.time
	var saved_tier: int = nests.tier
	var saved_raiding: bool = nests.raiding
	SmokeTest._check("nests use the level schedule", nests.schedule == g.level.raid_schedule
		and nests._raid_delay() == Level01.RAID_SCHEDULE.raid_delay
		and nests._tier_time(1) == Level01.RAID_SCHEDULE.tier_times[1])
	nests.schedule = { "raid_delay": 17.0, "tier_times": [0.0, 40.0, 80.0, 120.0] }
	nests.raiding = false
	nests.tier = 0
	nests.time = 16.0
	for n in nests.nests:
		n.timer = 0.0
	nests.update(0.5)
	SmokeTest._check("raid waits for the level delay", not nests.raiding, "(t %.1f)" % nests.time)
	nests.update(1.0)
	SmokeTest._check("raid starts at the level delay", nests.raiding and nests.tier == 0, "(t %.1f tier %d)" % [nests.time, nests.tier])
	nests.schedule = saved_sched
	nests.time = saved_time
	nests.tier = saved_tier
	nests.raiding = saved_raiding
	for n in nests.nests:
		n.timer = 0.0
