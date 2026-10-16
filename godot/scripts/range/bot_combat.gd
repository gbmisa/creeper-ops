class_name BotCombat
extends RefCounted
## F97 phase D: the fight-from-cover loop. Sub-states HIDE / PEEK / REPOSITION, ticked from
## ScavBot._act() while in ENGAGE with cover and a live contact (else BotEngage runs).
## HIDE at the cover marker; PEEK sidesteps to a point with LOS to the contact and fires a burst
## (PEEK_BURST 1-3 s); HIDE again (1.5-4 s); repeat. Reposition after REPOSITION_PEEKS peeks,
## when flanked, or when the cover is no longer hidden. No posture/animation: a peek is a sidestep.

const HIDE := "hide"
const PEEK := "peek"
const REPOSITION := "reposition"

var sub := HIDE
var sub_t := 0.0
var sub_dur := 0.0
var peeks := 0
var peek_pos := Vector3.ZERO
var active := false  # the loop is running (entered at cover, persists through reposition)


static func _cb(b: ScavBot) -> BotCombat:
	return b.combat


## One tick of the loop. Moves the bot with _go, fires with _shoot_at; BotBrain is untouched.
## Sets active=false when the contact is lost (the caller falls back to BotEngage).
static func tick(b: ScavBot, dt: float) -> void:
	var cb := _cb(b)
	if not b.percept.contact.has():
		cb.active = false
		return
	cb.active = true
	cb.sub_t += dt
	var at_cover := Vector2(b.global_position.x - b.cover_pos.x, b.global_position.z - b.cover_pos.z).length() < 1.5
	if cb.sub == REPOSITION:
		if b._arrived() or at_cover:
			cb.peeks = 0
			_start_hide(b)
		return
	if not at_cover:
		b._go(b.cover_pos)  # just picked cover (or knocked off it): move there first
		cb.sub = REPOSITION
		cb.sub_t = 0.0
		return
	if _should_reposition(b):
		_start_reposition(b)
		return
	match cb.sub:
		HIDE:
			if cb.sub_t >= cb.sub_dur:
				_start_peek(b)
		PEEK:
			b._shoot_at(b.percept.contact.pos)
			if cb.sub_t >= cb.sub_dur:
				_start_hide(b)


static func _start_hide(b: ScavBot) -> void:
	var cb := _cb(b)
	cb.peeks += 1
	b._go(b.cover_pos)
	cb.sub = HIDE
	cb.sub_t = 0.0
	cb.sub_dur = b.rng.randf_range(BotTacticsDefs.HIDE_MIN, BotTacticsDefs.HIDE_MAX)


## Sidestep from the cover to the first lateral offset with LOS to the contact at stand eye.
static func _start_peek(b: ScavBot) -> void:
	var cb := _cb(b)
	var contact := b.percept.contact.pos
	var from: Vector3 = b.cover_pos
	var space := b.get_world_3d().direct_space_state
	var to_c := Vector2(contact.x - from.x, contact.z - from.z)
	if to_c.length() < 0.01:
		return
	to_c = to_c.normalized()
	var perp := Vector2(-to_c.y, to_c.x)
	var offs := [1.2, -1.2, 2.0, -2.0]
	# try in random order
	for i in range(offs.size() - 1, 0, -1):
		var j := b.rng.randi_range(0, i)
		var tmp: float = offs[i]
		offs[i] = offs[j]
		offs[j] = tmp
	var aim := contact + Vector3(0, BotCover.THREAT_EYE, 0)
	for off in offs:
		var p := from + Vector3(perp.x * off, 0.0, perp.y * off)
		if BotPerception.los(space, p + Vector3(0, BotCover.STAND_EYE, 0), [aim]):
			cb.peek_pos = p
			b._go(p)
			cb.sub = PEEK
			cb.sub_t = 0.0
			cb.sub_dur = b.rng.randf_range(BotTacticsDefs.PEEK_BURST_MIN, BotTacticsDefs.PEEK_BURST_MAX)
			return
	# no peek point with LOS: stay hidden, retry soon
	cb.sub_t = 0.0
	cb.sub_dur = 1.0


static func _should_reposition(b: ScavBot) -> bool:
	var cb := _cb(b)
	if cb.peeks >= BotTacticsDefs.REPOSITION_PEEKS:
		return true
	var threat := BotCover.threat_pos(b)
	if BotCover.is_flanked(b.session, b.cover_pos, threat):
		return true
	var space := b.get_world_3d().direct_space_state
	return BotPerception.los(space, b.cover_pos + Vector3(0, BotCover.CROUCH_EYE, 0), [threat])


static func _start_reposition(b: ScavBot) -> void:
	var cb := _cb(b)
	BotCover.release(b.session, b)
	BotShooting.find_cover(b)
	cb.peeks = 0
	cb.sub_t = 0.0
	if b.has_cover:
		b._go(b.cover_pos)
		cb.sub = REPOSITION
	else:
		_start_hide(b)  # nowhere better: keep the loop going from here
