class_name SmokeSpitterSiege
## Spitter acid must threaten structures. Root cause of the playtest report
## ("spitters deal no damage to the Command Node"): dry built structures heal
## def.hp / HEAL_TIME per second, and the node's 10 HP/s regen out-healed acid
## (6 dmg / 2 s = 3 DPS), so hits never stuck. Any hit now pauses healing for
## StructureUpkeep.REGEN_DELAY, so chip damage accumulates under sustained fire.


static func run(g) -> void:
	_regen_pauses(g)
	_acid_sticks_on_node(g)
	_acid_hurts_cannon(g)
	_no_double_dip(g)


static func _regen_pauses(g) -> void:
	var sm: StructureManager = g.structures
	var node: Structure = sm.command_node()
	node.hp = 400.0
	sm.damage(node, 10.0)  # 390, and healing pauses for REGEN_DELAY
	for i in 40:
		StructureUpkeep.creeper_and_repair(sm, node, 0.05)  # 2 s, inside the delay
	SmokeTest._check("healing pauses right after a hit", is_equal_approx(node.hp, 390.0),
		"(hp %.1f, want 390)" % node.hp)
	for i in 120:
		StructureUpkeep.creeper_and_repair(sm, node, 0.05)  # +6 s, delay expires mid-way
	SmokeTest._check("healing resumes after the delay", node.hp > 390.0,
		"(hp %.1f)" % node.hp)
	node.hp = node.def.hp


static func _spawn_spitter(g, near: Vector3) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	for x in nests.raiders.list.duplicate():
		nests.raiders.kill(x)
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	nests.raiders.spawn(nest, RaiderDefs.named("Spitter"), false)
	var r: Dictionary = nests.raiders.list.back()
	r.node.position = near
	return r


static func _node_row(sm: StructureManager) -> Dictionary:
	var node: Structure = sm.command_node()
	var row := node.prey.duplicate() as Dictionary
	row["type"] = node.type
	row["weapon"] = bool(node.def.get("weapon", false))
	return row


## Drives one spitter against one prey row for `seconds`, stepping raiders,
## lob flight and structure upkeep manually (no full game update).
static func _siege(g, sm: StructureManager, r: Dictionary, row: Dictionary, seconds: float) -> void:
	var nests: SporeNests = g.hazards.nests
	var steps := int(seconds / 0.05)
	for i in steps:
		nests.raiders.update(0.05, [row], [])
		g.surface.effects.update(0.05)
		StructureUpkeep.creeper_and_repair(sm, sm.command_node(), 0.05)


static func _acid_sticks_on_node(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var node: Structure = sm.command_node()
	node.hp = float(node.def.hp)
	var row := _node_row(sm)
	var spot: Vector3 = grid.cell_ground(node.x + 4, node.z)
	var r := _spawn_spitter(g, spot)
	_siege(g, sm, r, row, 14.0)  # 7 shots x 6 dmg; regen stays suppressed (2 s < 5 s delay)
	SmokeTest._check("spitter acid sticks on the Command Node", node.hp < 490.0,
		"(hp %.1f/%.0f after 14 s)" % [node.hp, float(node.def.hp)])
	nests_cleanup(g)
	node.hp = float(node.def.hp)


static func _acid_hurts_cannon(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var node: Structure = sm.command_node()
	var cannon: Structure = sm.place("cannon", node.x + 6, node.z, true)
	var row := cannon.prey.duplicate() as Dictionary
	row["type"] = cannon.type
	row["weapon"] = true
	var r := _spawn_spitter(g, _open_spot(grid, cannon, float(RaiderDefs.named("Spitter").size)))
	var nests: SporeNests = g.hazards.nests
	for i in 280:  # 14 s
		nests.raiders.update(0.05, [row], [])
		g.surface.effects.update(0.05)
		StructureUpkeep.creeper_and_repair(sm, cannon, 0.05)
		if cannon.dead:
			break
	SmokeTest._check("spitter acid destroys a cannon", cannon.dead,
		"(hp %.1f/%.0f)" % [cannon.hp, float(cannon.def.hp)])
	if not cannon.dead:
		sm.remove(cannon)
	nests_cleanup(g)


## A spot just outside the Spitter's standoff ring (it backs off inside
## RAIDER_STANDOFF x range, so it shoots from here) whose acid arc clears the
## terrain (Level 2 is loaded in the full run; some bearings sit behind a terrace).
static func _open_spot(grid: Grid, s: Structure, size: float) -> Vector3:
	var aim: Vector3 = s.node.position
	var ring: float = float(RaiderDefs.named("Spitter").range) * Config.RAIDER_STANDOFF + 1.0
	for i in 16:
		var a := TAU * i / 16.0
		var spot := grid.cell_ground(s.x + roundi(cos(a) * ring), s.z + roundi(sin(a) * ring))
		var from := spot + Vector3(0, size, 0)
		var arc := clampf(from.distance_to(aim) * 0.15, 1.2, 8.0)
		if WeaponLogic.clip_lob(grid, from, aim, arc) == aim:
			return spot
	return grid.cell_ground(s.x + roundi(ring), s.z)


static func _no_double_dip(g) -> void:
	var sm: StructureManager = g.structures
	var node: Structure = sm.command_node()
	node.hp = float(node.def.hp)
	var at: Vector3 = node.node.position
	var unit_hp := [100.0]
	var unit_node := Node3D.new()
	unit_node.position = at
	var prey := [
		{ "node": unit_node, "alive": func(): return true, "hit": func(d): unit_hp[0] -= d },
		_node_row(sm),
	]
	RaiderShots._impact(g.surface, at, 3.0, 6.0, Color.WHITE, prey)
	SmokeTest._check("impact hits each target exactly once",
		is_equal_approx(unit_hp[0], 94.0) and is_equal_approx(node.hp, float(node.def.hp) - 6.0),
		"(unit %.1f, node %.1f)" % [unit_hp[0], node.hp])
	unit_node.free()
	node.hp = float(node.def.hp)


static func nests_cleanup(g) -> void:
	var nests: SporeNests = g.hazards.nests
	for x in nests.raiders.list.duplicate():
		nests.raiders.kill(x)
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)
