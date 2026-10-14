class_name BotEngage
## ScavBot Engage/Patrol behaviour per roster row: advance-and-fire distances, overwatch relocation, escort following.


static func engage(b: ScavBot) -> void:
	var d := b.def
	var p := b.percept
	if not p.seeing:
		if d["overwatch"]:
			b._has_target = false
		else:
			b._go(p.last_known)
		return
	if d["overwatch"]:
		if b.reloc_t > 0.0 and not b._arrived():
			return
		b.reloc_t = 0.0
		b._has_target = false
	elif b._flat(p.last_known - b.global_position).length() < d["hold"]:
		b._has_target = false
	else:
		b._go(p.last_known)
	if b.eye().distance_to(p.last_known) <= d["fire"]:
		b._shoot_at(p.last_known)


## Marksman: move to the next overwatch spot and stay quiet until there.
static func relocate(b: ScavBot) -> void:
	if not b.def["overwatch"] or b.patrol.size() < 2 or b._dying or b.body.dead:
		return
	b.patrol_i = (b.patrol_i + 1) % b.patrol.size()
	b.shots_since = 0
	b.reloc_t = 10.0
	b.winding = false
	b.mesh.glint(false)
	b._go(b.patrol[b.patrol_i])


static func patrol(b: ScavBot) -> void:
	var l := b.leader
	if l != null and is_instance_valid(l) and not l.body.dead:
		if b._flat(l.global_position - b.global_position).length() > BotDefs.FOLLOWER_CLOSE:
			b._go(l.global_position)
		else:
			b._has_target = false
		return
	if b.def["overwatch"]:
		if b._arrived() and b.reloc_t > 0.0:
			b.reloc_t = 0.0
		return
	if b._arrived():
		b.patrol_i = (b.patrol_i + 1) % b.patrol.size()
		b._go(b.patrol[b.patrol_i])
