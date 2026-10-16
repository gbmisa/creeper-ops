class_name BotTacticsDefs
extends RefCounted
## Tunables for enemy squad tactics (F97). All numbers live here, out of the logic; Gregory may retune.
## Phase A: contact memory. Phase B: cover scoring + reservation. Phase C: squad planner. Phase D: combat loop.


# --- Phase A: contact memory + fuzzy hearing + forget/defend ---
const CONTACT_FORGET := 20.0  # s with no new info before a contact is forgotten (search, then give up)
const CALM_PERIOD := 45.0      # s of no contact info before a holding bot resumes patrol
const HOLD_FALLBACK := 105.0   # safety: HOLD never lasts longer than this
const HEAR_ERR_FRAC := 0.15    # heard-shot error as a fraction of distance to the shot
const HEAR_ERR_MIN := 2.0      # m, closest a heard shot is ever localized
const HEAR_ERR_MAX := 20.0     # m, farthest a heard shot is ever localized
const SIGHT_ERR_GROWTH := 3.0  # m/s the contact error grows after losing sight
const SIGHT_ERR_MAX := 25.0    # m cap on lost-sight error


# --- Phase B: cover scoring + reservation ---
const PUSH_CAP := 0.5        # at most this fraction of a squad pushes (ADVANCE + FLANK)
const FLANK_CAP := 1         # at most this many FLANK roles per squad
const REPLAN_TIME := 3.0     # s between squad re-plans (events re-plan immediately)
const SPACING := 4.0         # m minimum spacing between moving squad members
const MIN_ANGLE_SEP := 12.0  # degrees minimum angular separation seen from the contact


# --- Phase D: combat loop at cover (peek / hide / reposition) ---
const PEEK_BURST_MIN := 1.0  # s of firing per peek
const PEEK_BURST_MAX := 3.0
const HIDE_MIN := 1.5        # s hidden between peeks
const HIDE_MAX := 4.0
const REPOSITION_PEEKS := 3  # reposition after this many peeks from one spot
