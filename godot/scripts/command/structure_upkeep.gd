class_name StructureUpkeep
## Per-structure upkeep each frame: creeper contact, repair, construction progress and bars.
## Creeper rule: unbuilt structures, and built ones that are not weapons, die on contact.
## Built weapons (def.weapon) lose HP from depth, using the Node's formula, and die at 0.
## A weapon with charge > 0 (the charging Nullifier) takes none. Hovering and in-flight
## structures are out of reach.


static func creeper_and_repair(mgr, s: Structure, dt: float) -> void:
	s.wet = 0.0 if (s.is_flying() or s.def.get("flying", false)) else mgr.wet_depth(s)
	if s.wet > Config.DAMAGE_DEPTH:
		if _dies_on_contact(s):
			mgr.remove(s, "destroyed")
			return
		if s.def.get("weapon", false) and s.charge > 0.0:
			return
		var dps: float = (Config.STRUCT_BASE_DPS + s.wet * Config.STRUCT_DPS) * (1.0 - s.def.get("creeper_resist", 0.0))
		mgr.damage(s, dps * dt)
	elif s.connected:
		s.hp = minf(s.def.hp, s.hp + Config.REPAIR_PER_SEC * dt)


## The Node always soaks. Anything else soaks only once it is a built weapon.
static func _dies_on_contact(s: Structure) -> bool:
	if s.type == "node":
		return false
	return not s.is_built() or not s.def.get("weapon", false)


static func construction(mgr, s: Structure, dt: float) -> void:
	if s.is_built():
		return
	if s.def.get("drop_pod", false):
		s.built = minf(1.0, s.built + dt / mgr.DROP_POD_TIME)
	else:
		s.built = minf(1.0, float(s.delivered) / s.def.cost)
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
