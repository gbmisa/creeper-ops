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
	elif b.squad_role == BotSquad.ROLE_HOLD and b._flat(p.last_known - b.global_position).length() < d["hold"]:
		b._has_target = false
	else:
		_advance(b)
	if b.eye().distance_to(p.last_known) <= d["fire"]:
		b._shoot_at(p.last_known)


## F97 phase C: squad-role movement. FLANK arcs wide around the contact, ADVANCE takes the next
## scored cover toward it (bounded, not a full rush), HOLD falls back to last-known.
static func _advance(b: ScavBot) -> void:
	var role: String = b.squad_role
	var pos := BotCover.NO_COVER
	if role == BotSquad.ROLE_FLANK:
		pos = BotSquad.flank_cover(b)
	elif role == BotSquad.ROLE_ADVANCE and not b.def["overwatch"]:
		pos = BotSquad.next_cover_toward(b)
	if pos == BotCover.NO_COVER:
		pos = b.percept.last_known
	if b.covers.has(pos):
		BotCover.claim(b.session, b, pos, BotCover.threat_pos(b))
	b._go(pos)


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
