class_name StructureUpkeep
## Per-structure upkeep each frame: creeper contact, repair, construction progress and bars.
## Creeper rule (CW3, docs/CREEPER_SPEC.md §1): depth decides only whether a structure is wet.
## Weapons and the Node have a health reserve: wet, they lose max HP / `wet_time` per second
## whatever the depth, and an unfinished one loses build progress at the same rate (and asks
## for no packets) instead. Everything else dies on contact, built or not — including an
## unfinished weapon with no build progress to lose (a placed-but-never-started ghost dies
## on contact like everything else). A charging BUILT weapon (Nullifier) takes nothing.
## Dry built structures heal to full over HEAL_TIME.


static func creeper_and_repair(mgr, s: Structure, dt: float) -> void:
	s.wet = 0.0 if (s.is_flying() or s.def.get("flying", false)) else mgr.wet_depth(s)
	# Wet means any creeper drawn on it (MIN_DEPTH), so a thin film can't hide a "submerged" survivor.
	if s.wet <= Config.MIN_DEPTH:
		if s.is_built():
			s.hp = minf(s.def.hp, s.hp + s.def.hp / Config.HEAL_TIME * dt)
		return
	if not has_reserve(s):
		mgr.remove(s, "destroyed")
		return
	if s.charge > 0.0 and s.is_built():
		return
	var rate := dt / float(s.def.get("wet_time", Config.WET_TIME))
	if s.is_built():
		mgr.damage(s, s.def.hp * rate)
	elif float(s.delivered) - s.lost <= 0.0:
		# No build progress to lose: the progress loss below would be a no-op at zero
		# delivered, leaving the structure immortal in creeper. Kill it instead.
		mgr.remove(s, "destroyed")
	else:
		s.lost = minf(float(s.delivered), s.lost + s.def.cost * rate)


## The Node, weapons and `reserve` defs (castle keeps) soak creeper for a while; everything
## else dies on contact.
static func has_reserve(s: Structure) -> bool:
	return s.type == "node" or s.def.get("weapon", false) or s.def.get("reserve", false)


static func construction(mgr, s: Structure, dt: float) -> void:
	if s.is_built():
		return
	if s.def.get("drop_pod", false):
		s.built = minf(1.0, s.built + dt / mgr.DROP_POD_TIME)
	else:
		s.built = minf(1.0, (s.delivered - s.lost) / s.def.cost)
	s.body.scale.y = 0.15 + 0.85 * s.built
	if s.is_built():
		mgr.dirty = true  # a finished relay may connect new nodes
		Sfx.play("build", s.pos)
		Bus.structure_built.emit(s)


static func bars(s: Structure, time: float) -> void:
	var f: float = s.hp / s.def.hp
	if not s.is_built():
		s.hp_bar.visible = true
		s.hp_bar.set_value(s.built, Color("5fd4ff"))
	else:
		s.hp_bar.visible = f < 0.999 or s.type == "node"
		var flash := s.hurt > 0.0 and sin(time * 40.0) > 0.0
		s.hp_bar.set_value(f, Color.WHITE if flash else Bar.hp_color(f))
	s.hurt = maxf(0.0, s.hurt - 1.0 / 60.0)
	if s.ammo_bar:
		s.ammo_bar.visible = s.is_built()
		var dry := s.ammo < s.per_shot() and sin(time * 8.0) > 0.0
		var col := Color("9dff7a") if s.type == "barracks" else Color("ffb13b")
		s.ammo_bar.set_value(s.ammo / s.ammo_max(), Color("ff3030") if dry else col)
