# Stage 8 progress

Branch `stage/8-enemies`. Worktree `creeper fps td-worktrees/stage8`.
Baseline code is `8312c03`. Do not treat a parallel Godot launch as finished until its `[sim]` line is in the log.

## Phase 0: baseline

Smoke on `8312c03` after a headless `--import` (the worktree had no `.godot` class cache): **235 PASS / 0 FAIL**.

`--demo --units --sim=900` (L1), wall 68 s:

- time 900, over false, node_hp 500
- nests_alive 2, raider_tier Ravager
- raiders: 16 Skitter (15 guards) + 4 Brute
- energy 1, income 2.4, structures 17, connected 16, coverage 0.26
- objectives done: e1. castles both hostile. aether 35

L1 `--autostart --sim=900` (undefended), wall 22 s:

- time 354, over true, node_hp 0 (the Node dies at 5:54)
- nests_alive 3, raider_tier Skitter, about 23 Skitters
- coverage 0.33, no structures left

L2 `--autostart --sim=900` and L2 `--demo --sim=900` are still running from a `git archive` of `8312c03` (`/tmp/stage8-base`, `XDG_DATA_HOME=/tmp/stage8-userdata` so the player's keybinds file is left alone). Logs: `/tmp/stage8-p0/auto-l2.log`, `demo-l2.log`. Numbers land in the next phase note.

## Phase 1: pressure (§4.1) — done

Commit message: `Stage 8 P1: pressure curve, spawn rates and overrun waves`.

### What changed

- `level/pressure.gd`: `value(level, t)` is 0 until grace, 1 at and after cap. With no `pressure_points`, linear between grace and cap. With points, piecewise linear. `legacy_tier(p)` maps onto the old 0..3 band at 0.20 / 0.60 / 0.85.
- L1 `PRESSURE` grace 300, cap 2400, points so Brute is 0.20 at 480 s, Ravager 0.60 at 900 s, Behemoth 0.85 at 1320 s, then 1.0 at 2400. Raid start stays `RAID_SCHEDULE` 300 s.
- L2 grace 180 (the raid start), cap 1800, points so Brute is 0.20 at 300 s, Ravager 0.60 at 600 s, Behemoth 0.85 at 900 s.
- Spawn interval is `lerp(20, 5, pressure)`, cap is `round(lerp(3, 10, pressure))`. Nest HP growth and the schedule tier index are unchanged, so existing escalate / raid-delay smokes still pass.
- Overrun at pressure 1: every 45 s each active nest sends `6 + legacy_tier * 2` (12 at the cap) with `overrun` set, walking straight at the Command Node (`node_pos` injected from `game.gd`). Ignores guard slots and the per-nest cap. Still stops at `RAIDER_MAX_TOTAL`.
- `ui/top_bar.gd`: the threat string also ends with `Pressure NN%`.

### Decisions where the spec was silent

- `pressure_points` are `{ t, p }` in mission seconds. Before grace the value is 0 even if a point says otherwise. At and past cap it is 1.
- Overrun "tier" is `Pressure.legacy_tier`, not the schedule index, so a time jump to the cap still sends a full wave of 12.
- Overrun raiders use a straight XZ walk (cliffs still block via `step_ok`), not the flow field, and they are not turned into guards.

### Tests

- Parse: `--import` clean after typing `node_pos.call()` as `Vector3` (inference warnings are errors here).
- Smoke **246 PASS / 0 FAIL** (235 old + 11 pressure checks in `core/smoke_roster.gd`).
- Screenshot `/tmp/stage8-shots/p1-pressure.png` (`--autostart --sim=500`, Xvfb 1600x900). The top bar reads `Nests: Skitter  Pressure…` and the percent is clipped off the right edge of that one label. Not a layout change: 18c owns the HUD. The undefended Node in that shot died at 6:20 (t=380, node_hp 0), which is the old loss, not an overrun (pressure was still under 0.1).

### Not finished

- Phase 2 onward.
- The three remaining Phase 0 sims (see above).
