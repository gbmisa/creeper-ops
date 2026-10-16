class_name BotSquad
extends RefCounted
## F97 phase C: one plan per squad, built from ally/leader links + spawn proximity.
## Roles HOLD / ADVANCE / FLANK respect the brief's caps; flank arcs and the spacing +
## line-of-fire rules keep movers apart. Re-plan on events (invalidate()) or every REPLAN_TIME.

const ROLE_HOLD := "hold"
const ROLE_ADVANCE := "advance"
const ROLE_FLANK := "flank"

var members: Array = []  # ScavBot
var roles := {}  # ScavBot -> String
var flank_side := {}  # ScavBot -> float (+1/-1), for flankers
var plan_age := 999.0
var contact_pos := Vector3.ZERO
var _aged_frame := -1  # physics frame the shared plan_age was last advanced in


static func _alive(b) -> bool:
	return is_instance_valid(b) and not (b as ScavBot).body.dead


func living() -> Array:
	return members.filter(_alive)


static func _dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Partition bots into squads: transitive closure over ally/leader links + SQUAD_RADIUS proximity.
static func build(all: Array) -> Array:
	var squads: Array = []
	var assigned := {}
	for b in all:
		if assigned.has(b) or not _alive(b):
			continue
		var grp := _closure(b, all)
		var sq := BotSquad.new()
		sq.members = grp
		squads.append(sq)
		for m in grp:
			assigned[m] = sq
	return squads


static func _closure(root, all: Array) -> Array:
	var grp := [root]
	var seen := {root: true}
	var queue := [root]
	while not queue.is_empty():
		var b = queue.pop_back()
		for o in _links(b, all):
			if not seen.has(o):
				seen[o] = true
				grp.append(o)
				queue.append(o)
	return grp


static func _links(b, all: Array) -> Array:
	var out := []
	var sb := b as ScavBot
	if sb.ally != null and all.has(sb.ally) and _alive(sb.ally):
		out.append(sb.ally)
	if sb.leader != null and all.has(sb.leader) and _alive(sb.leader):
		out.append(sb.leader)
	for o in all:
		if o == b or not _alive(o):
			continue
		var so := o as ScavBot
		if so.leader == b or so.ally == b:
			out.append(o)
		elif _dist(so.global_position, sb.global_position) <= BotTacticsDefs.SQUAD_RADIUS:
			out.append(o)
	return out


## Resolve (building when needed) the squad for a bot on its session. Never returns null.
static func resolve(session: RangeSession, bot: ScavBot) -> BotSquad:
	for sq in session.squads:
		if (sq as BotSquad).members.has(bot):
			return sq
	var all: Array = session.bots.filter(_alive)
	if not all.has(bot):
		all.append(bot)
	session.squads = build(all)
	for sq in session.squads:
		if (sq as BotSquad).members.has(bot):
			return sq
	return null


## Per-bot per-tick: resolve the squad, age/re-plan the shared plan, read this bot's role.
static func tick_bot(session: RangeSession, b: ScavBot, dt: float) -> void:
	var sq := resolve(session, b)
	b.squad = sq
	var c := b.percept.contact
	var cpos := c.pos if c.has() else sq.contact_pos
	var frame := Engine.get_physics_frames()
	if sq._aged_frame != frame:
		sq._aged_frame = frame
		sq.plan_age += dt
	if sq.needs_replan(cpos):
		sq.plan(cpos, b.rng)
	b.squad_role = str(sq.roles.get(b, ROLE_HOLD))


func needs_replan(contact: Vector3) -> bool:
	if plan_age >= BotTacticsDefs.REPLAN_TIME:
		return true
	if living().size() != roles.size():
		return true  # member died or joined
	return _dist(contact, contact_pos) > BotTacticsDefs.REPLAN_MOVE


func invalidate() -> void:
	plan_age = BotTacticsDefs.REPLAN_TIME


## Assign roles with the brief's caps: at most ceil(n/2) pushers, at most 1 flank.
func plan(contact: Vector3, rng: RandomNumberGenerator) -> void:
	contact_pos = contact
	plan_age = 0.0
	var lv := living()
	var prefs := {}
	for m in lv:
		prefs[m] = _prefer(m, contact)
	# flank cap: keep the most eager
	var flanks := lv.filter(func(m): return prefs[m] == ROLE_FLANK)
	if flanks.size() > BotTacticsDefs.FLANK_CAP:
		flanks.sort_custom(func(a, b): return _flank_eagerness(a) > _flank_eagerness(b))
		for i in range(BotTacticsDefs.FLANK_CAP, flanks.size()):
			prefs[flanks[i]] = ROLE_ADVANCE
	# push cap: demote the weakest advancers first (breachers never demote first)
	var push := lv.filter(func(m): return prefs[m] == ROLE_ADVANCE or prefs[m] == ROLE_FLANK)
	var max_push := int(ceil(lv.size() * BotTacticsDefs.PUSH_CAP))
	if push.size() > max_push:
		var adv := push.filter(func(m): return prefs[m] == ROLE_ADVANCE)
		adv.sort_custom(func(a, b): return _push_strength(a, contact) < _push_strength(b, contact))
		for i in range(push.size() - max_push):
			prefs[adv[i]] = ROLE_HOLD
	roles = prefs
	_assign_flank_sides(contact)


static func _prefer(m, contact: Vector3) -> String:
	var sm := m as ScavBot
	match sm.kind:
		"marksman":
			return ROLE_HOLD  # never pushes, overwatch only
		"boss":
			return ROLE_HOLD  # warlord holds, followers screen
		"shotgunner":
			return ROLE_ADVANCE  # breacher pushes the last stretch
		"pistol":
			return ROLE_FLANK  # runner is flank-eager
	if sm.leader != null and _alive(sm.leader) and (sm.leader as ScavBot).kind == "boss":
		return ROLE_HOLD  # warlord's screen holds with it
	return ROLE_ADVANCE if _dist(sm.global_position, contact) > BotTacticsDefs.RIFLEMAN_PUSH_DIST else ROLE_HOLD


static func _flank_eagerness(m) -> float:
	var sm := m as ScavBot
	return 2.0 if bool(sm.def.get("flank_eager", false)) else 1.0


static func _push_strength(m, contact: Vector3) -> float:
	var sm := m as ScavBot
	if sm.kind == "shotgunner":
		return 1.0e9
	return _dist(sm.global_position, contact) - BotTacticsDefs.RIFLEMAN_PUSH_DIST


## Flankers go the side away from the advancer, seen from the squad->contact axis.
func _assign_flank_sides(contact: Vector3) -> void:
	flank_side.clear()
	var c := _center()
	var axis := Vector2(contact.x - c.x, contact.z - c.z)
	if axis.length() < 0.01:
		axis = Vector2(0, 1)
	axis = axis.normalized()
	for m in living():
		if roles.get(m) != ROLE_FLANK:
			continue
		var side := 0.0
		for o in living():
			if o == m or roles.get(o) != ROLE_ADVANCE:
				continue
			var so := o as ScavBot
			var rel := Vector2(so.global_position.x - c.x, so.global_position.z - c.z)
			var cr := axis.x * rel.y - axis.y * rel.x
			if absf(cr) > 0.01:
				side = signf(cr)
				break
		flank_side[m] = -side if side != 0.0 else 1.0


func _center() -> Vector3:
	var c := Vector3.ZERO
	var lv := living()
	if lv.is_empty():
		return c
	for m in lv:
		c += (m as ScavBot).global_position
	return c / lv.size()


## Flank waypoint: FLANK_ANGLE off the squad->contact axis (away from the advancer),
## at the flanker->contact range (min 15 m). The arc swept around the contact is the angle.
static func flank_point(sq: BotSquad, b: ScavBot) -> Vector3:
	var c := sq.contact_pos
	var ctr := sq._center()
	var axis := Vector2(c.x - ctr.x, c.z - ctr.z)
	if axis.length() < 0.01:
		axis = Vector2(0, 1)
	axis = axis.normalized()
	var side: float = sq.flank_side.get(b, 1.0)
	var out := axis.rotated(side * deg_to_rad(BotTacticsDefs.FLANK_ANGLE))
	var dist := maxf(Vector2(b.global_position.x - c.x, b.global_position.z - c.z).length(), 15.0)
	return Vector3(c.x + out.x * dist, 0.0, c.z + out.y * dist)


## Best cover for a flanker: nearest marker to the flank point (within 15 m), else the point itself.
static func flank_cover(b: ScavBot) -> Vector3:
	var sq: BotSquad = b.squad
	if sq == null or not b.percept.contact.has() or b.covers.is_empty():
		return BotCover.NO_COVER
	var fp := flank_point(sq, b)
	var best := fp
	var bd := 15.0
	for m in b.covers:
		var d := _dist(m, fp)
		if d < bd:
			bd = d
			best = m
	return best


## Best-scoring cover that makes progress toward the contact, or NO_COVER.
static func next_cover_toward(b: ScavBot) -> Vector3:
	if not b.percept.contact.has() or not b.is_inside_tree():
		return BotCover.NO_COVER
	var c := b.percept.contact.pos
	var my_d := _dist(b.global_position, c)
	var space := b.get_world_3d().direct_space_state
	var threat := BotCover.threat_pos(b)
	var best := BotCover.NO_COVER
	var best_score := -INF
	for m in b.covers:
		if _dist(m, c) >= my_d - 2.0:
			continue  # must make progress toward the contact
		var s := BotCover.score(b, m, threat, space, b.squad)
		if s > best_score:
			best_score = s
			best = m
	return best
