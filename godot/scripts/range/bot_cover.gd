class_name BotCover
extends RefCounted
## F97 phase B: scored cover selection + per-session reservation.
## Markers are points ~0.9 m off a box face. A marker is usable when it is hidden from the contact
## at crouch eye (0.9 m). Scoring: peekable at stand eye (1.6 m) +, travel distance -, preferred
## range band per kind +/-, exposed path -. Hard rejects: visible from the contact, reserved by an
## ally, flanked (claimed against a threat more than COVER_FLANK_ANGLE away from the current one).
## Reservations live on the RangeSession (no statics): marker -> {"bot": claimer, "threat": threat pos}.

const NO_COVER := Vector3.INF
const CROUCH_EYE := 0.9
const STAND_EYE := 1.6
const THREAT_EYE := 1.4


static func threat_pos(b: ScavBot) -> Vector3:
	return b.percept.contact.pos + Vector3(0, THREAT_EYE, 0)


## Best-scoring marker for this bot, or NO_COVER. Does not claim; claim separately.
## The optional squad enforces the phase C rules: ~4 m spacing between moving squad members
## and the 12° line-of-fire rule seen from the contact.
static func pick(b: ScavBot, squad: BotSquad = null) -> Vector3:
	if b.covers.is_empty() or b.session == null or not b.is_inside_tree():
		return NO_COVER
	var space := b.get_world_3d().direct_space_state
	var threat := threat_pos(b)
	var best := NO_COVER
	var best_score := -INF
	for m in b.covers:
		var s := score(b, m, threat, space, squad)
		if s > best_score:
			best_score = s
			best = m
	return best


static func score(b: ScavBot, marker: Vector3, threat: Vector3, space: PhysicsDirectSpaceState3D, squad: BotSquad = null) -> float:
	if _reserved_by_ally(b.session, marker, b):
		return -INF
	if _flanked(b.session, marker, threat):
		return -INF
	if BotPerception.los(space, marker + Vector3(0, CROUCH_EYE, 0), [threat]):
		return -INF  # visible from the contact: not cover
	if squad != null and _squad_blocks(b, marker, squad):
		return -INF  # spacing or line-of-fire rule
	var s := 0.0
	if BotPerception.los(space, marker + Vector3(0, STAND_EYE, 0), [threat]):
		s += BotTacticsDefs.COVER_W_PEEK
	var d := Vector2(marker.x - b.global_position.x, marker.z - b.global_position.z).length()
	s -= d * BotTacticsDefs.COVER_W_DIST
	var hold: float = b.def.get("hold", 30.0)
	if hold > 0.0:
		var td := Vector2(marker.x - b.percept.contact.pos.x, marker.z - b.percept.contact.pos.z).length()
		s -= absf(td - hold) * BotTacticsDefs.COVER_W_BAND
	var mid := (b.global_position + marker) * 0.5 + Vector3(0, CROUCH_EYE, 0)
	if BotPerception.los(space, threat, [mid]):
		s -= BotTacticsDefs.COVER_W_EXPOSED
	return s


## True when a squad rule rejects this marker: within SPACING of another living member
## (or its move target), or inside MIN_ANGLE_SEP of a member's line of fire seen from the contact.
static func _squad_blocks(b: ScavBot, marker: Vector3, squad: BotSquad) -> bool:
	var cpos := b.percept.contact.pos
	for o in squad.living():
		if o == b:
			continue
		var ob := o as ScavBot
		if Vector2(marker.x - ob.global_position.x, marker.z - ob.global_position.z).length() < BotTacticsDefs.SPACING:
			return true
		if ob._has_target and Vector2(marker.x - ob._target.x, marker.z - ob._target.z).length() < BotTacticsDefs.SPACING:
			return true
		var a := Vector2(ob.global_position.x - cpos.x, ob.global_position.z - cpos.z)
		var cc := Vector2(marker.x - cpos.x, marker.z - cpos.z)
		if a.length() > 0.01 and cc.length() > 0.01 and absf(rad_to_deg(a.angle_to(cc))) < BotTacticsDefs.MIN_ANGLE_SEP:
			return true
	return false


## Claim a marker for a bot (releases its old claim first). Stores the threat it was picked against.
static func claim(session: RangeSession, bot: ScavBot, pos: Vector3, threat: Vector3) -> void:
	if session == null:
		return
	release(session, bot)
	_purge(session)
	session.cover_claims[pos] = {"bot": bot, "threat": threat}


## Release every claim held by a bot.
static func release(session: RangeSession, bot: ScavBot) -> void:
	if session == null:
		return
	for pos in session.cover_claims.keys():
		var c: Dictionary = session.cover_claims[pos]
		if c.get("bot") == bot:
			session.cover_claims.erase(pos)


## Who holds this marker now (null when free or the holder is gone).
static func holder(session: RangeSession, pos: Vector3) -> ScavBot:
	if session == null:
		return null
	var c: Dictionary = session.cover_claims.get(pos, {})
	var h: Object = c.get("bot")
	if h == null or not is_instance_valid(h):
		if not c.is_empty():
			session.cover_claims.erase(pos)
		return null
	return h as ScavBot


static func _reserved_by_ally(session: RangeSession, marker: Vector3, me: ScavBot) -> bool:
	var h := holder(session, marker)
	return h != null and h != me


## True when the marker was claimed against a threat far (angularly) from the current one:
## the cover no longer protects against this threat.
static func _flanked(session: RangeSession, marker: Vector3, threat: Vector3) -> bool:
	if session == null:
		return false
	var c: Dictionary = session.cover_claims.get(marker, {})
	if c.is_empty():
		return false
	var old: Vector3 = c.get("threat", threat)
	var a := Vector2(old.x - marker.x, old.z - marker.z)
	var cc := Vector2(threat.x - marker.x, threat.z - marker.z)
	if a.length() < 0.01 or cc.length() < 0.01:
		return false
	return absf(rad_to_deg(a.angle_to(cc))) > BotTacticsDefs.COVER_FLANK_ANGLE


## Drop claims whose holder is gone.
static func _purge(session: RangeSession) -> void:
	for pos in session.cover_claims.keys():
		var c: Dictionary = session.cover_claims[pos]
		var h: Object = c.get("bot")
		if h == null or not is_instance_valid(h):
			session.cover_claims.erase(pos)
