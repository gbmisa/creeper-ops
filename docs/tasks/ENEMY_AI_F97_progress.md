# F97 progress: enemy squad tactics (`feat/enemy-ai`)

## Phase A — contact memory + fuzzy hearing + forget/defend (commit TBD)

**What each kind does now:** unchanged in a straight fight; the difference is what they *remember*. A heard shot gives every kind a fuzzy contact (never the exact spot), losing sight grows the error instead of a perfect last-known, and bots that search too long give up to a defensive post instead of patrolling back.

**Behaviour changes:** `BotPerception.hear(shot)` stores a `BotContact` (error 15 % of distance, 2–20 m) instead of the exact shot position; `last_known`/`has_last` mirror the contact. Lost sight grows contact error at 3 m/s (cap 25 m). New `Hold` brain state: SEARCH → Hold when the contact is forgotten (20 s), Hold → Patrol only when calm (45 s) and arrived. `shot_cover` also set when entering TakeCover from Hold. Contact `age` keeps advancing after forgetting (it is the calm clock).

**Tests:** new `range_test_contact.gd` (19 checks: fuzz, decay, forget, brain transitions, full shot→cover→forget→hold→patrol loop). Updated `range_test_hearing.gd` (fuzzy assertion, Hold brain checks) and `range_test_bots.gd` (`_pure` sequence Search→Hold→Patrol; `_cover_heal` sets up a real contact).

**Suite:** 1138 passed, 1 failed — the known pre-existing F88 "Scav 5 Search" (fails on base too). Base: 1113 passed, 1 failed (same). Zero new failures. (A navmesh flake fired once on my tree, not on base; it is the known intermittent flake, unrelated to this change.)

**Must-not-change:** none touched. **Open:** none.
