class_name UnitMotion
## One walking step with terrain limits and solid structures. A blocked full step slides
## along the free axis (big bodies like the Crawler no longer stall on a tower corner), and a
## unit that makes no progress along its path for STUCK_TIME seconds re-plans it.

const STUCK_TIME := 1.0
const STUCK_DIST := 0.6   # metres it must cover per STUCK_TIME while it has somewhere to go


static func step(mgr: UnitManager, u: Unit, d: Vector2, dt: float) -> Vector3:
	var p := u.pos
	for try in [d, Vector2(d.x, 0.0), Vector2(0.0, d.y)]:
		if try.length_squared() > 0.0 and _free(mgr, u, p.x + try.x, p.z + try.y):
			p.x += try.x
			p.z += try.y
			break
	p.y = mgr.world.grid.stand_y(p.x, p.z, Grid.Faction.PLAYER)
	_watch(mgr, u, p, d, dt)
	return p


static func _free(mgr: UnitManager, u: Unit, nx: float, nz: float) -> bool:
	var g := mgr.world.grid
	var a := g.world_to_cell(u.pos.x, u.pos.z)
	var b := g.world_to_cell(nx, nz)
	if not g.in_bounds(b.x, b.y):
		return false
	if b == a:
		return true
	var rise := g.walk_height(b.x, b.y, Grid.Faction.PLAYER) - g.walk_height(a.x, a.y, Grid.Faction.PLAYER)
	var into_tower: bool = mgr.world.occupied.call(b.x, b.y) and not mgr.world.occupied.call(a.x, a.y)
	return rise <= u.def.climb and -rise <= u.def.drop and not into_tower


## No progress for a second while trying to walk: plan the route again.
static func _watch(mgr: UnitManager, u: Unit, p: Vector3, d: Vector2, dt: float) -> void:
	if u.path.is_empty() or d.length_squared() <= 0.0:
		u.stuck_t = 0.0
		u.stuck_from = p
		return
	u.stuck_t += dt
	if u.stuck_t < STUCK_TIME:
		return
	if p.distance_to(u.stuck_from) < STUCK_DIST:
		mgr.walk_to(u, u.path.back())
	u.stuck_t = 0.0
	u.stuck_from = p
