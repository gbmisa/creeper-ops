# F97 progress: enemy squad tactics (`feat/enemy-ai`)

## Phase A — contact memory + fuzzy hearing + forget/defend (`92fce9b9`)
Kinds fight the same; they *remember* differently. New `BotContact`: heard shots fuzzy (15% of distance, 2–20 m); lost sight grows error 3 m/s (cap 25 m); forgotten at 20 s. `last_known`/`has_last` mirror it; `age` runs on after forgetting (calm clock). New Hold state: SEARCH→Hold on forgotten, Hold→Patrol only when calm (45 s) and arrived. Tests: new `range_test_contact.gd` (19); updated `range_test_hearing.gd`, `range_test_bots.gd`. Suite: 1138/1 — known pre-existing F88 "Scav 5 Search" (base 1113/1 same). Must-not-change: none. Open: none.

## Phase B — cover scoring + reservation (`c7d24790`)
Every kind scores cover: peekable +30, distance −1/m, band fit −2/m, exposed approach −40; rejects visible, ally-reserved, flanked (>60°). Claims on `RangeSession.cover_claims`; re-pick/death frees. `find_cover` and Hold use it. Tests: new `range_test_cover.gd` (9). Suite: 1147/1 — known intermittent navmesh flake. Must-not-change: none. Open: none.

## Phase C — squad planner (`a8d10730`)
Marksmen/warlords hold; breachers advance; runners flank; riflemen advance past 40 m else hold. New `BotSquad`: squads from ally/leader links + 25 m proximity; caps ≤half push, ≤1 flank (weakest demoted); flankers arc 65° away from the advancer; re-plan on 3 s, contact move >10 m, death, new info. Cover enforces 4 m spacing + 12° line-of-fire (fixed signed-angle bug). `BotEngage` routes by role; `RangeSession.bots`/`squads` fed by both spawners. Tests: new `range_test_squad.gd` (24). Suite: 1171/1 — navmesh flake. Must-not-change: none. Open: none.

## Phase D — combat loop at cover (`85589d71`)
Bots at cover with a live contact fight: HIDE (1.5–4 s) → PEEK (sidestep to LOS, fire 1–3 s) → HIDE; reposition after 3 peeks, when flanked, or when exposed. New `BotCombat`; runs in ENGAGE/COVER only when at cover, `active` flag persists through reposition; `find_cover` skipped while active. `BotBrain.next()` untouched (pure). Tests: new `range_test_combat.gd` (13). Suite: 1185/0. Must-not-change: none. Open: none.
