class_name BotBrain
extends RefCounted
## Scav state machine. `next()` is a pure function of (state, facts), so it can be scripted in tests.
## Facts: aware, seeing, noise, since_seen, hp (0..1), hurt, reloading, arrived, cover (a cover spot exists),
## outgunned, ally_engaged, ally_flank, has_last, forgotten (contact aged out), calm (no contact info for CALM_PERIOD),
## shot (a gunshot was just heard), shot_cover (this TakeCover came from a heard shot, not from a fight), t (seconds in this state).

const PATROL := "Patrol"
const INVESTIGATE := "Investigate"
const ENGAGE := "Engage"
const COVER := "TakeCover"
const HEAL := "Heal"
const FLANK := "Flank"
const SEARCH := "Search"
const SUPPRESS := "Suppress"
const HOLD := "Hold"  # F97: defensive post after the contact is forgotten; stays alert, patrols only when calm

const HEAL_TIME := 5.0
const HEAL_BELOW := 0.5
const HURT_BELOW := 0.8
const LOST_SIGHT := 2.0
const COVER_WAIT := 1.5
const SUPPRESS_TIME := 5.0
const FLANK_TIME := 14.0
const AIM_ERR_START := 9.0   # degrees on first sight, shrinks to AIM_ERR_END over AIM_WARM seconds
const AIM_ERR_END := 1.2
const AIM_WARM := 3.0
const BURST_RANGE := 25.0

var state := PATROL
var t := 0.0


func update(dt: float, facts: Dictionary) -> String:
	t += dt
	facts["t"] = t
	var n := next(state, facts)
	if n != state:
		state = n
		t = 0.0
		return n
	return ""


static func aim_error(sight_t: float) -> float:
	return lerpf(AIM_ERR_START, AIM_ERR_END, clampf(sight_t / AIM_WARM, 0.0, 1.0))


static func next(s: String, f: Dictionary) -> String:
	var aware: bool = f.get("aware", false)
	var t: float = f.get("t", 0.0)
	match s:
		PATROL, INVESTIGATE, SEARCH:
			if aware:
				return ENGAGE
			if f.get("shot", false) and f.get("cover", false) and s != SEARCH:  # F87: under fire, get to cover first
				return COVER
			if f.get("noise", false) and s != INVESTIGATE:
				return INVESTIGATE
			if f.get("ally_engaged", false) and f.get("has_last", false):
				return FLANK
			if s == INVESTIGATE and ((f.get("arrived", false) and t > 2.5) or t > 20.0):
				return PATROL
			if s == SEARCH and f.get("forgotten", false):
				return HOLD  # F97: gave up the search -> defensive post, not straight back to patrol
		ENGAGE:
			if (f.get("reloading", false) or f.get("outgunned", false) or (f.get("hurt", false) and f.get("hp", 1.0) < HURT_BELOW)) \
					and f.get("cover", false):
				return COVER
			if not f.get("seeing", false) and f.get("since_seen", 0.0) > LOST_SIGHT:
				if f.get("flank_eager", false) and f.get("has_last", false) and not f.get("ally_flank", false):
					return FLANK
				return SUPPRESS if f.get("ally_flank", false) else SEARCH
		COVER:
			if f.get("shot_cover", false) and aware:  # F88: running to cover from a shot, then sees the player: fight
				return ENGAGE
			if f.get("arrived", false):
				if f.get("hp", 1.0) < HEAL_BELOW and not f.get("seeing", false):
					return HEAL
				if t > COVER_WAIT and not f.get("reloading", false):
					return ENGAGE if aware else SEARCH
		HEAL:
			if t >= HEAL_TIME:
				return SEARCH
			if aware and f.get("seeing", false):
				return ENGAGE
		FLANK:
			if aware:
				return ENGAGE
			if (f.get("arrived", false) and t > 1.0) or t > FLANK_TIME:
				return SEARCH
		SUPPRESS:
			if aware and f.get("seeing", false):
				return ENGAGE
			if t > SUPPRESS_TIME:
				return SEARCH
		HOLD:  # F97: defensive post. Stays alert; only patrols again after a calm period.
			if aware:
				return ENGAGE
			if f.get("shot", false) and f.get("cover", false):
				return COVER
			if f.get("noise", false):
				return INVESTIGATE
			if (f.get("arrived", false) and f.get("calm", false)) or t > BotTacticsDefs.HOLD_FALLBACK:
				return PATROL
	return s
