class_name UnitAttack
## Focus-fire and retaliation. A player attack order (right-click an enemy) or a counter-attack
## puts a unit in "attack": it closes to gun range of `target`, fires until it dies, then goes
## back to its patrol / post (retaliation) or holds where it stands (player order). Retaliation
## has a leash; any move order clears it (UnitManager.order).


## The living enemy nearest `p` (world point) within ATTACK_PICK_RADIUS of its edge, or {}.
static func enemy_near(enemies: Array, p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var bd := Config.ATTACK_PICK_RADIUS
	for e in enemies:
		if not e.alive.call() or (not e.get("immune", false) and e.has("targetable") and not (e.targetable as Callable).call()):
			continue
		var ep: Vector3 = e.node.position
		var d := Vector2(ep.x - p.x, ep.z - p.z).length() - float(e.get("radius", 0.0))
		if d < bd:
			bd = d
			best = e
	return best


static func order(mgr: UnitManager, units: Array, foe: Dictionary) -> void:
	if foe.get("immune", false):
		Bus.say("Guns can't destroy that. Plant a demolition charge with the Operative.", "warn")
		Sfx.play("deny")
		return
	for u in units:
		if u.state == "resupply":
			continue
		_begin(mgr, u, foe, false)
		u.post = null
		u.patrol.clear()
	Sfx.play("click")


static func _begin(mgr: UnitManager, u: Unit, foe: Dictionary, leash: bool) -> void:
	u.target = foe
	u.forced = false
	u.target_leash = leash
	u.leash_from = Vector2(u.pos.x, u.pos.z)
	u.state = "attack"
	u.attack_t = 0.0
	u.path = []


## The target while it is alive and being hunted, else {} (so _fight falls back to acquire).
static func pick(u: Unit) -> Dictionary:
	if u.state != "attack" or u.target.is_empty() or not u.target.alive.call():
		return {}
	if (u.target.node.position as Vector3).distance_to(u.pos) > u.def.gun.range:
		return {}
	return u.target


static func tick(mgr: UnitManager, u: Unit, dt: float) -> void:
	var t := u.target
	var here := Vector2(u.pos.x, u.pos.z)
	if t.is_empty() or not t.alive.call() or (u.target_leash and here.distance_to(u.leash_from) > Config.RETALIATE_LEASH):
		_finish(mgr, u)
		return
	var tp: Vector3 = t.node.position
	if tp.distance_to(u.pos) <= u.def.gun.range * 0.9:
		u.path = []
		return
	u.attack_t -= dt
	if u.path.is_empty() or u.attack_t <= 0.0:
		u.attack_t = Config.ATTACK_REPATH
		mgr.walk_to(u, Vector2(tp.x, tp.z))
		if u.path.is_empty():
			_finish(mgr, u)  # unreachable


static func _finish(mgr: UnitManager, u: Unit) -> void:
	var retaliating := u.target_leash
	u.target = {}
	u.path = []
	if not u.patrol.is_empty():
		UnitPatrol.resume(mgr, u)
	elif retaliating and u.post != null:
		u.state = "return"
		mgr.walk_to(u, u.post)
	else:
		u.state = "idle"


## Called when a unit is hit: an idle or patrolling unit goes after the nearest enemy and
## idle allies nearby join (up to RETALIATE_HELPERS).
static func retaliate(mgr: UnitManager, u: Unit) -> void:
	if not u.alive or u.state not in ["idle", "patrol"]:
		return
	var foe: Dictionary = {}
	var bd := Config.RETALIATE_SEEK
	for e in mgr.enemies:
		if not e.alive.call() or e.get("immune", false):
			continue
		var d := (e.node.position as Vector3).distance_to(u.pos)
		if d < bd:
			bd = d
			foe = e
	if foe.is_empty() or u.ammo < 1.0:
		return
	_begin(mgr, u, foe, true)
	var reach := Config.RETALIATE_CELLS * Config.CELL
	var helpers := 0
	for o in mgr.list:
		if helpers >= Config.RETALIATE_HELPERS:
			break
		if o != u and o.state in ["idle", "patrol"] and o.ammo >= 1.0 and o.pos.distance_to(u.pos) <= reach:
			_begin(mgr, o, foe, true)
			helpers += 1
