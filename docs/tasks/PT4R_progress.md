# PT4 R progress (raiders commit to a target and a path)

## Phase 1: DONE (static targets, melee raiders)
- `level/raider_paths.gd` (`RaiderPaths`, `Raiders.paths`): per-raider state in `r["_pt"]` = {tgt, mode STRAIGHT/WAIT/PATH, wps, i, cell, ver, stk, next}. `goal(r, target, dt)` returns the XZ to walk to, or null (caller uses the flow field while a search waits).
- Straight test once per commit (`_clear`: quarter-cell samples, `RaiderField.step_ok` per cell change, success once within striking reach). Blocked: raider queued (Array + flag `r._pq`; never use raider dicts as dict keys, they mutate) and served under `RAIDER_PATH_FRAME_MS`, max `RAIDER_PATH_MAX_NODES`.
- Re-plan triggers: `RaiderField.version` bumped by `invalidate()` (PATH mode only re-plans if the remaining polyline fails `_clear`; STRAIGHT mode re-tests), stuck handling (`_stuck_rest` starts), path spent short of the target (at most every `RAIDER_REPLAN_MIN`).
- `Pathfind`: def keys `faction` (default PLAYER), `ignore_creeper`, `corners` (no diagonal corner cutting, matches `RaiderField.step_ok`; needed or smoothed paths were rejected and re-planned every tick). Units unchanged.
- `Raiders._acquire`: a held target is kept (`_keep`: alive, grounded, guard leash, `RAIDER_LOSE` for non-structure targets of marchers, reachable re-check once per field version). Scan only when no target. `detour` and `RAIDER_DETOUR_TIME` removed. `_index` skips dead raiders.
- Config added: `RAIDER_LOSE` 18, `RAIDER_PATH_FRAME_MS` 3, `RAIDER_PATH_MAX_NODES` 4000, `RAIDER_REPLAN_MIN` 1.
- Smoke `core/smoke_raider_commit.gd` (a)-(d), group `--smoke=raidercommit`. Per-raider search count is `r._searches`; `paths.total_searches` is global.

## For Phase 2
- Moving targets already get lock-on + `RAIDER_LOSE`; straight mode re-tests when the target cell changes; PATH mode only re-plans at path end (item 6's `RAIDER_REPATH_CELLS` / `RAIDER_REPATH_MIN` distance rule is NOT done: add in `goal()` by comparing `st.cell` to the target cell).
- `RaiderShots._held_pick`, spitter lob test, `unit_attack.gd` untouched.
- Smoke tests in this harness need `r["hp"] = 1e6` (full-run world has turrets/creeper) and region x40..70, z50..76 (map is 80x80).
