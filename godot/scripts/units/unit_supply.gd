class_name UnitSupply
## Unit combat, creeper damage and the resupply loop. Units are a tool, not a crutch:
##  - every gunshot and every creeper spray spends 1 ammo
##  - at 0 ammo, or below RETREAT_HP, a unit walks to its barracks (any barracks if its own is
##    gone) and docks; the barracks hands over ammo from its own packet-fed stock
##  - restocked, it walks back to the post it was ordered to
## No barracks, or an empty barracks stock, means the unit stays dry.


static func update(mgr: UnitManager, u: Unit, dt: float, enemies: Array) -> void:
	_creeper_damage(mgr, u, dt)
	if not u.alive:
		return
	match u.state:
		"move", "return":
			if u.path.is_empty():
				u.state = "idle"
		"resupply":
			_resupply(mgr, u, dt)
			return
	if (u.ammo < 1.0 or u.hp < u.def.hp * UnitDefs.RETREAT_HP) and _head_home(mgr, u):
		return
	_fight(mgr, u, dt, enemies)


static func _creeper_damage(mgr: UnitManager, u: Unit, dt: float) -> void:
	var d := mgr.world.creeper.depth_world(u.pos)
	if d > Config.DAMAGE_DEPTH:
		mgr.damage(u, (Config.UNIT_CREEPER_BASE_DPS + d * Config.UNIT_CREEPER_DPS) * u.def.creeper_mult * dt)


static func _barracks_for(mgr: UnitManager, u: Unit) -> Structure:
	if u.home and not u.home.dead and u.home.is_built():
		return u.home
	var b := mgr.structures.nearest_to(int(u.pos.x / Config.CELL), int(u.pos.z / Config.CELL),
		func(s): return s.type == "barracks" and s.is_built() and mgr.living_for(s) < Config.UNITS_PER_BARRACKS)
	if b:
		u.home = b
	return b


static func _head_home(mgr: UnitManager, u: Unit) -> bool:
	var b := _barracks_for(mgr, u)
	if b == null:
		if not u.warned_dry and u.ammo < 1.0:
			u.warned_dry = true
			Bus.say("%s is out of supply with no barracks to return to." % u.def.label, "warn")
		return false
	u.warned_dry = false
	u.state = "resupply"
	mgr.walk_to(u, Vector2(b.pos.x, b.pos.z + 3.5))
	if u.ammo < 1.0:
		Bus.say("%s out of ammo: returning to barracks." % u.def.label, "info")
	return true


static func _resupply(mgr: UnitManager, u: Unit, dt: float) -> void:
	var b := _barracks_for(mgr, u)
	if b == null:
		u.state = "idle"
		return
	var dist := Vector2(u.pos.x - b.pos.x, u.pos.z - b.pos.z).length()
	if dist > Config.RESUPPLY_RANGE + 3.0:
		if u.path.is_empty():
			mgr.walk_to(u, Vector2(b.pos.x, b.pos.z + 3.5))
		return
	var take := minf(minf(Config.RESUPPLY_RATE * dt, b.ammo), u.def.ammo - u.ammo)
	u.ammo += take
	b.ammo -= take
	u.hp = minf(u.def.hp, u.hp + UnitDefs.DOCK_HEAL * dt)
	if u.ammo >= u.def.ammo - 0.01 and u.hp >= u.def.hp * 0.9:
		if u.post != null:
			u.state = "return"
			mgr.walk_to(u, u.post)
		else:
			u.state = "idle"


static func _fight(mgr: UnitManager, u: Unit, dt: float, enemies: Array) -> void:
	u.gun_cd -= dt
	u.clear_cd -= dt
	if u.ammo < 1.0:
		return
	var w := mgr.world
	var gun: Dictionary = u.def.gun
	var clear: Dictionary = u.def.clear
	var best: Dictionary = {}
	var bd: float = gun.range
	for e in enemies:
		if not e.alive.call():
			continue
		var d := (e.node.position as Vector3).distance_to(u.pos)
		if d < bd:
			bd = d
			best = e
	var muzzle := u.pos + Vector3(0, 1.0 if u.type == "crawler" else 0.9, 0)
	if not best.is_empty():
		var ep: Vector3 = best.node.position + Vector3(0, best.get("oy", 0.0), 0)
		if u.path.is_empty():
			u.heading = atan2(-(ep.z - u.pos.z), ep.x - u.pos.x)
		if u.gun_cd <= 0.0:
			u.gun_cd = gun.rate
			u.ammo -= 1.0
			best.hit.call(gun.damage)
			w.effects.beam(muzzle, ep, Color("ffc06a") if u.type == "crawler" else Color("bfffa0"), 0.07, 0.04)
			Sfx.play("rifle", u.pos)
		return
	if u.clear_cd > 0.0:
		return
	var c := w.grid.world_to_cell(u.pos.x, u.pos.z)
	var t = w.creeper.nearest_wet(c.x, c.y, clear.range)
	if t == null:
		return
	u.clear_cd = clear.rate
	u.ammo -= 1.0
	if clear.splash > 0.0:
		w.creeper.remove_radius(t.x, t.y, clear.splash, clear.power)
	else:
		w.creeper.remove(t.x, t.y, clear.power)
	var p := w.grid.cell_ground(t.x, t.y) + Vector3(0, w.creeper.depth_at(t.x, t.y), 0)
	if u.path.is_empty():
		u.heading = atan2(-(p.z - u.pos.z), p.x - u.pos.x)
	w.effects.beam(muzzle, p, Color("9dff7a"), 0.1, 0.12 if u.type == "crawler" else 0.04)
