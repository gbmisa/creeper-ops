class_name StructureBehaviors
## Per-type behaviour for built, connected, landed structures (weapons: weapon_logic.gd).


static func update(s: Structure, dt: float, mgr, time: float) -> void:
	var spin := s.body.get_node_or_null("Spin") as Node3D
	if spin:
		spin.rotation.y += dt * (4.0 if s.type == "barracks" else 1.6)
	match s.type:
		"beacon":
			var glow := s.body.get_node_or_null("Glow") as Node3D
			if glow:
				glow.scale.y = 1.0 + (0.15 * sin(time * 6.0) if s == mgr.selected_beacon else 0.0)
		"nullifier":
			_nullifier(s, dt, mgr)
		"barracks":
			_barracks(s, dt)
		"terp":
			Terp.tick(s, dt, mgr)


static func _nullifier(s: Structure, dt: float, mgr) -> void:
	if mgr.hazards == null:
		return
	var reach := WeaponLogic.nullify_range()
	var e = mgr.hazards.emitter_near(s.x, s.z, reach)
	var shielded: bool = e != null and mgr.hazards.is_shielded(e)
	var pump: bool = mgr.enemy_build != null and mgr.enemy_build.pump_near(s.x, s.z)
	if e != null and not shielded:
		_charge_null(s, dt, mgr, false)
	elif pump:
		_charge_null(s, dt, mgr, true)
	elif e != null and not s.warned:
		s.warned = true
		Bus.say("Nullifier ready but %s is shielded. %s" % [e.name, e.shield_hint], "warn")


static func _charge_null(s: Structure, dt: float, mgr, pump: bool) -> void:
	s.charge = minf(Config.NULLIFY_TIME, s.charge + dt)
	var core := s.body.get_node_or_null("Core") as Node3D
	if core:
		core.rotation.y += dt * (1.0 + s.charge * 2.0)
		core.scale = Vector3.ONE * (1.0 + s.charge / Config.NULLIFY_TIME * 0.8)
	if s.charge < Config.NULLIFY_TIME:
		return
	if pump:
		if mgr.enemy_build.nullify(s.x, s.z):
			mgr.remove(s, "spent")
		return
	if mgr.hazards.try_nullify(s.x, s.z) == "destroyed":
		mgr.remove(s, "spent")


static func _barracks(s: Structure, dt: float) -> void:
	if s.queue.is_empty():
		return
	var q: Dictionary = s.queue[0]
	if q.delivered < q.cost:
		return
	q.train = q.get("train", 0.0) + dt
	if q.train < UnitDefs.DEFS[q.type].train_time:
		return
	s.queue.pop_front()
	Sfx.play("unit", s.pos)
	Bus.unit_trained.emit(q.type, s)


## Queue a unit (paid by packets as they arrive). Population cap counts queued units too.
static func queue_unit(b: Structure, type: String, living: int) -> bool:
	if living + b.queue.size() >= Config.UNITS_PER_BARRACKS:
		Bus.say("This barracks supports %d units. Build another barracks for more." % Config.UNITS_PER_BARRACKS, "warn")
		return false
	b.queue.append({ "type": type, "cost": UnitDefs.DEFS[type].cost, "delivered": 0 })
	return true
