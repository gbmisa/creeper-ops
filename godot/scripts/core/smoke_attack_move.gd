class_name SmokeAttackMove
## Attack-move: a unit walking an order path (e.g. to a rally point) stops and
## fights enemies in gun range instead of walking into them, then continues to
## its destination. No chasing: engagement never extends past gun range, and a
## dry unit keeps walking (retreat takes priority over fighting).
## Burrowed Burrowers are untargetable: shooting them wastes ammo because
## RaiderBurrow.filter ignores hits while "down".


static func run(g) -> void:
	_engages_en_route(g)
	_no_enemy_no_delay(g)
	_dry_unit_retreats_past_enemies(g)
	_burrower_untargetable(g)
	_pad(g, 40, 40, 70, 50)  # leave the terrain flat for the next group


static func _pad(g, x0: int, z0: int, x1: int, z1: int) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)
	_clear_creeper(g, x0, z0, x1, z1)


static func _clear_creeper(g, x0: int, z0: int, x1: int, z1: int) -> void:
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			g.surface.creeper.set_depth(x, z, 0.0)


static func _clear(g) -> void:
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)
	for o in g.hazards.nests.raiders.list.duplicate():
		g.hazards.nests.raiders.kill(o)


static func _spawn_raider_at(g, who: String, cell: Vector2i, guard := true) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	nests.raiders.spawn(nest, RaiderDefs.named(who), guard)
	var r := nests.raiders.list.back() as Dictionary
	(r.node as Node3D).position = g.surface.grid.cell_ground(cell.x, cell.y)
	return r


## A soldier ordered across the map stops for a Skitter in gun range, kills it,
## then continues to its destination (the rally-point case from playtesting).
static func _engages_en_route(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var u: Unit = g.units.spawn("soldier", 45 * Config.CELL, 45 * Config.CELL)
	var dest := Vector2(65 * Config.CELL, 45 * Config.CELL)
	g.units.order([u], dest)
	# Marcher (guard=false): no nest-leash walk-home, stays in the engagement zone.
	var r := _spawn_raider_at(g, "Skitter", Vector2i(51, 45), false)
	var t := 0.0
	var saw_engaged := false
	while t < 60.0 and u.alive and not u.path.is_empty():
		if u.engaged:
			saw_engaged = true
		SmokeTest._sim(g, 0.5)
		t += 0.5
	var d := Vector2(u.pos.x - dest.x, u.pos.z - dest.y).length()
	SmokeTest._check("attack-move: engages en route, kills, then arrives",
		u.alive and not r.alive and u.path.is_empty() and d < 4.0 * Config.CELL and saw_engaged,
		"(skitter dead %s, arrived dist %.1f m, engaged %s, %.1f s)" % [not r.alive, d, saw_engaged, t])
	if u.alive:
		g.units.kill(u)
	_clear(g)


## With no enemies around, an order walks straight through with no engagement.
static func _no_enemy_no_delay(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var u: Unit = g.units.spawn("soldier", 45 * Config.CELL, 47 * Config.CELL)
	var dest := Vector2(65 * Config.CELL, 47 * Config.CELL)
	g.units.order([u], dest)
	var t := 0.0
	var ever_engaged := false
	while t < 30.0 and u.alive and not u.path.is_empty():
		if u.engaged:
			ever_engaged = true
		SmokeTest._sim(g, 0.5)
		t += 0.5
	var d := Vector2(u.pos.x - dest.x, u.pos.z - dest.y).length()
	# 40 m at 5.5 m/s is ~7.3 s on flat ground; 20 s is generous headroom.
	SmokeTest._check("attack-move: no enemy, no delay",
		u.alive and u.path.is_empty() and d < 4.0 * Config.CELL and not ever_engaged and t < 20.0,
		"(dist %.1f m, engaged %s, %.1f s)" % [d, ever_engaged, t])
	if u.alive:
		g.units.kill(u)
	_clear(g)


## A dry unit walks past enemies to resupply instead of stopping to fight it
## can't win (no ammo -> never engaged; retreat takes priority).
static func _dry_unit_retreats_past_enemies(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var sm: StructureManager = g.structures
	var b: Structure = sm.place("barracks", 62, 44, true)
	b.ammo = 50.0
	var u: Unit = g.units.spawn("soldier", 45 * Config.CELL, 47 * Config.CELL)
	u.ammo = 0.0
	g.units.order([u], Vector2(65 * Config.CELL, 47 * Config.CELL))
	# Ranged Spitter on the retreat path: it will shoot the soldier (3 dps), but the
	# dry soldier must keep walking, never engage, and live to resupply.
	var r := _spawn_raider_at(g, "Spitter", Vector2i(55, 47), false)
	var t := 0.0
	var ever_engaged := false
	while t < 60.0 and u.alive and u.state != "idle":
		if u.engaged:
			ever_engaged = true
		SmokeTest._sim(g, 0.5)
		t += 0.5
		if u.state == "return" or u.ammo >= u.def.ammo - 0.01:
			break
	SmokeTest._check("attack-move: dry unit retreats past enemies, never engages",
		u.alive and not ever_engaged and (u.state == "resupply" or u.state == "return" or u.ammo > 1.0),
		"(state %s, ammo %.1f, engaged %s)" % [u.state, u.ammo, ever_engaged])
	if u.alive:
		g.units.kill(u)
	sm.remove(b)
	_clear(g)


## A burrowed Burrower is not acquired and costs no ammo; once surfaced it is.
static func _burrower_untargetable(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var u: Unit = g.units.spawn("soldier", 50 * Config.CELL, 45 * Config.CELL)
	var r := _spawn_raider_at(g, "Burrower", Vector2i(54, 45))  # 8 m away, in gun range
	var e: Dictionary = r.enemy
	SmokeTest._check("burrower: burrowed is not acquired",
		UnitSupply.acquire(u, [e]).is_empty())
	var ammo0 := u.ammo
	UnitSupply._fight(g.units, u, 1.0, [e])
	SmokeTest._check("burrower: no ammo spent while burrowed",
		u.ammo == ammo0, "(ammo %.1f)" % u.ammo)
	r["burrow"] = "up"
	r["surface_t"] = 60.0  # stay surfaced; the sim would detonate it otherwise
	(r.node as Node3D).visible = true
	SmokeTest._check("burrower: surfaced is acquired",
		not UnitSupply.acquire(u, [e]).is_empty())
	UnitSupply._fight(g.units, u, 1.0, [e])
	SmokeTest._check("burrower: ammo spent once surfaced",
		u.ammo < ammo0, "(ammo %.1f -> %.1f)" % [ammo0, u.ammo])
	if u.alive:
		g.units.kill(u)
	_clear(g)
