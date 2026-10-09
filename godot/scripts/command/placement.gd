class_name Placement
## Placement / move / landing validity. Returns { ok: bool, reason: String, warn: String }.
## `ignore` = a structure whose own cells don't count as occupied (it's the one moving).
##
## Stage 21b P7: `inside_held` is set by CastlePerks.attach to CastleVaults.inside_held
## bound to the game's castles. Defs with "castle_only" refuse everywhere it returns
## false. Unset (invalid) outside the live game: castle_only defs refuse everywhere.


static var inside_held := Callable()


static func footprint_cells(type: String, x: int, z: int) -> Array[Vector2i]:
	var r := StructureDefs.footprint(type)
	var out: Array[Vector2i] = []
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			out.append(Vector2i(x + dx, z + dz))
	return out


static func _ground_rules(mgr, type: String, x: int, z: int, ignore: Structure) -> String:
	var def: Dictionary = StructureDefs.DEFS[type]
	var g: Grid = mgr.world.grid
	var creeper: CreeperSim = mgr.world.creeper
	var h0 := g.height_at(x, z)
	var flying: bool = def.get("flying", false)
	for c in footprint_cells(type, x, z):
		if not g.in_bounds(c.x, c.y):
			return "Out of bounds"
		var i := g.idx(c.x, c.y)
		if g.zone[i] == Grid.Zone.BLIGHT:
			return "Blight zone: nothing can be built or parked here. Send the Operative or units."
		if mgr.enemy_build != null and mgr.enemy_build.occupies(c.x, c.y):
			return "An enemy structure holds this cell"
		if mgr.enemy_build != null and mgr.enemy_build.blocks(c.x, c.y):
			return "Blight Pylon: nothing can be built here. Destroy the pylon."
		if g.blocked[i]:
			if g.yard[i] and g.material[i] == Grid.Mat.NATURAL:
				return "Enemy castle: capture it to build in its courtyard"
			if g.material[i] != Grid.Mat.NATURAL:
				return "Castle stone: build in the courtyard of a castle you hold"
			return "Too close to a hazard"
		var occ = mgr.occupied.get(i)
		if occ != null and occ != ignore:
			return "Occupied"
		if not flying and absf(g.height_at(c.x, c.y) - h0) > 1.01:
			return "Ground too steep"
		if not flying and creeper.depth_at(c.x, c.y) > Config.MIN_DEPTH:
			return "Can't build on creeper: clear it first"
	return ""


## Ground-only rules (bounds, Blight, occupied, slope, creeper); "" when fine. DragBuild snaps with it.
static func ground_reason(mgr, type: String, x: int, z: int) -> String:
	return _ground_rules(mgr, type, x, z, null)


## `planned`: pieces of a drag-build chain not placed yet, Vector3(x, z, link); they count as
## network nodes so the preview matches what commit() will manage.
static func can_place(mgr, type: String, x: int, z: int, planned: Array[Vector3] = []) -> Dictionary:
	var def: Dictionary = StructureDefs.DEFS[type]
	var locked := StructureDefs.lock_reason(mgr.level, type)
	if locked != "":
		return { "ok": false, "reason": locked }
	var why := _ground_rules(mgr, type, x, z, null)
	if why != "":
		return { "ok": false, "reason": why }
	if def.get("unique", false) and mgr.count_type(type) > 0:
		return { "ok": false, "reason": "Only one %s per mission" % def.label }
	if def.get("castle_only", false) and (not inside_held.is_valid() or not inside_held.call(Vector2i(x, z))):
		return { "ok": false, "reason": "%s can only be built inside a castle you hold" % def.label }
	if type == "miner":
		var vein: Dictionary = mgr.deposits.ore_at(x, z) if mgr.deposits != null else {}
		if vein.is_empty() or float(vein.get("left", 0.0)) < 1.0:
			return { "ok": false, "reason": "Miner must sit on an ore deposit" }
	if type == "outpost":
		var pile: Stockpile = mgr.stockpile
		if pile == null or not pile.can_afford("ore", Config.OUTPOST_ORE):
			return { "ok": false, "reason": "Outpost needs %d Ore up front" % int(Config.OUTPOST_ORE) }
	if def.get("drop_pod", false) and mgr.economy.energy < def.cost:
		return { "ok": false, "reason": "Drop pod needs %d energy up front" % def.cost }
	if def.get("needs_network", true) and not mgr.network.in_range(mgr.list, x, z, def.link, null) \
			and not planned.any(func(p: Vector3): return Vector2(p.x - x, p.y - z).length() <= maxf(p.z, def.link)):
		return { "ok": false, "reason": "Out of network range: build a Relay or Collector closer" }
	if type == "nullifier":
		var reach := WeaponLogic.nullify_range()
		var e = mgr.hazards.emitter_near(x, z, reach) if mgr.hazards else null
		var pump: bool = mgr.enemy_build != null and mgr.enemy_build.pump_near(x, z)
		if e == null and not pump:
			return { "ok": false, "reason": "Nullifier must be within %.1f cells of an emitter" % reach }
		if e != null and mgr.hazards.is_shielded(e) and not pump:
			return { "ok": false, "reason": "%s is SHIELDED. %s" % [e.name, e.shield_hint] }
	return { "ok": true, "reason": "" }


## Moving is allowed outside the network (CW3), but you get a warning: no packets there.
static func can_move(mgr, s: Structure, x: int, z: int) -> Dictionary:
	if not s.def.get("movable", false):
		return { "ok": false, "reason": "%s can't be moved" % s.def.label }
	var why := _ground_rules(mgr, s.type, x, z, s)
	if why != "":
		return { "ok": false, "reason": why }
	var warn := ""
	if s.type != "node" and not mgr.network.in_range(mgr.list, x, z, s.def.link, s):
		warn = "Outside the network: it won't get packets there"
	return { "ok": true, "reason": "", "warn": warn }


## Command Node landing site (mission start).
static func can_land(mgr, level: Dictionary, x: int, z: int) -> Dictionary:
	var why := _ground_rules(mgr, "node", x, z, null)
	if why != "":
		return { "ok": false, "reason": why }
	var min_d: float = level.landing_min_dist
	for p in level.hazard_points:
		if Vector2(p.x - x, p.z - z).length() < min_d:
			return { "ok": false, "reason": "Too close to a creeper source (keep %d cells away)" % min_d }
	return { "ok": true, "reason": "" }
