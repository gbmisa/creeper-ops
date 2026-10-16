# F97 progress: enemy squad tactics (`feat/enemy-ai`)

## Phase A — contact memory + fuzzy hearing + forget/defend (commit `92fce9b9`)

**What each kind does now:** unchanged in a straight fight; the difference is what they *remember*. A heard shot gives every kind a fuzzy contact (never the exact spot), losing sight grows the error instead of a perfect last-known, and bots that search too long give up to a defensive post instead of patrolling back.

**Behaviour changes:** `BotPerception.hear(shot)` stores a `BotContact` (error 15 % of distance, 2–20 m) instead of the exact shot position; `last_known`/`has_last` mirror the contact. Lost sight grows contact error at 3 m/s (cap 25 m). New `Hold` brain state: SEARCH → Hold when the contact is forgotten (20 s), Hold → Patrol only when calm (45 s) and arrived. `shot_cover` also set when entering TakeCover from Hold. Contact `age` keeps advancing after forgetting (it is the calm clock).

**Tests:** new `range_test_contact.gd` (19 checks: fuzz, decay, forget, brain transitions, full shot→cover→forget→hold→patrol loop). Updated `range_test_hearing.gd` (fuzzy assertion, Hold brain checks) and `range_test_bots.gd` (`_pure` sequence Search→Hold→Patrol; `_cover_heal` sets up a real contact).

**Suite:** 1138 passed, 1 failed — the known pre-existing F88 "Scav 5 Search" (fails on base too). Base: 1113 passed, 1 failed (same). Zero new failures. (A navmesh flake fired once on my tree, not on base; it is the known intermittent flake, unrelated to this change.)

**Must-not-change:** none touched. **Open:** none.

## Phase B — cover scoring + reservation (commit `c7d24790`)

**What each kind does now:** every kind picks smarter cover. Marksmen still hold overwatch (no markers); breachers still rush (never take cover); everyone else now scores markers instead of taking the nearest hidden one, and two bots never stack on the same spot.

**Behaviour changes:** new `BotCover`: score = peekable-at-stand-eye (+30), travel distance (−1/m), range-band fit vs the kind's `hold` (−2/m off), exposed approach (−40); hard rejects for visible-from-contact, ally-reserved, or flanked (claimed against a threat >60° away) markers. Reservations live on `RangeSession.cover_claims` (marker → {bot, threat}); re-picking frees the old claim, death frees all. `BotShooting.find_cover` uses the scorer; `scav_bot._enter(HOLD)` takes the best scored post.

**Tests:** new `range_test_cover.gd` (9 checks: visible rejected, exposed approach penalised, best pick, claim recorded, two bots never share, two claims, re-pick releases, flanked rejected, release frees all).

**Suite:** 1147 passed, 1 failed — the known intermittent navmesh flake (fired on base never in 2 runs; unrelated to this change). Zero new failures.

**Must-not-change:** none touched (`RangeSession.cover_claims` is the brief-mandated per-session table). **Open:** none.
