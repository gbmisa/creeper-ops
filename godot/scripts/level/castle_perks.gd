class_name CastlePerks
## What holding a castle buys (docs/CASTLES2_DESIGN.md §5): anti-tedium, never a win condition.
##  - Reach: your weapons within REACH_RADIUS cells of a held castle fire REACH_BONUS further
##    (WeaponLogic.range_bonus, set by `attach` for the game's own castles).
##  - Ward: creeper inside a held castle's walls drains WARD_DRAIN depth/s per wet cell, and
##    hives within WARD_HIVE_RADIUS spawn WARD_HIVE_SLOW slower (CastleRaids applies it).
##  - Muster: a free Castle Barracks in the ward (CastleKeeps places it).
## Stage 7 castles get the same perks.


## Hooks the game's castles into weapon range (only the live game calls this).
static func attach(s: Strongholds) -> void:
	WeaponLogic.range_bonus = func(st: Structure) -> float: return range_mult(s, st.x, st.z)
	# P7: castle-only production. (bind() appends, so a lambda carries the castles.)
	Placement.inside_held = func(cell: Vector2i) -> bool: return CastleVaults.inside_held(s, cell)
	Placement.castle_ban = func(x: int, z: int) -> String: return CastleExclusion.reason(s, x, z)


static func range_mult(s: Strongholds, x: int, z: int) -> float:
	return 1.0 + CastleDefs.REACH_BONUS if near_held(s, Vector2(x, z), CastleDefs.REACH_RADIUS) else 1.0


static func centre(lay: Dictionary) -> Vector2:
	var r: Rect2i = lay.rect
	return Vector2(r.position) + Vector2(r.size) * 0.5


## Is a castle you hold within `radius` cells (from its centre) of `at`?
static func near_held(s: Strongholds, at: Vector2, radius: float) -> bool:
	for c in s.list:
		if c.owner == "player" and centre(s.lays[c.id]).distance_to(at) <= radius:
			return true
	return false


## Drains creeper inside a held castle's walls (called from its holding tick).
static func ward(s: Strongholds, c: Dictionary, lay: Dictionary, dt: float) -> void:
	c["ward_t"] = c.get("ward_t", 0.0) + dt
	if c.ward_t < CastleDefs.WARD_TICK:
		return
	var step: float = c.ward_t * CastleDefs.WARD_DRAIN * CastleTurrets.ward_mult(c)  # P5: Ward Lamp doubles the drain
	c.ward_t = 0.0
	var sim := s.world.creeper
	for cell in lay.courtyard:
		if sim.depth_at(cell.x, cell.y) > Config.MIN_DEPTH:
			sim.remove(cell.x, cell.y, step)


## Spawn-rate factor for a hive at `at` (cells): slower near a castle you hold.
static func hive_factor(s: Strongholds, at: Vector2) -> float:
	return 1.0 - CastleDefs.WARD_HIVE_SLOW if near_held(s, at, CastleDefs.WARD_HIVE_RADIUS) else 1.0
