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

L2 `--autostart --sim=900` (undefended), wall 51 s. Log `/tmp/stage8-p0/auto-l2.log`:

- time 235, over true, node_hp 0
- nests_alive 6, raider_tier Skitter, about 44 Skitters
- coverage 0.13, no structures left

L2 `--demo --sim=900`, wall 168 s. Log `/tmp/stage8-p0/demo-l2.log`:

- time 668, over true, node_hp 0 (the Node dies at 11:08, before the 900 s mark)
- nests_alive 6, raider_tier Ravager, a mix of Skitter, Brute and Ravager
- structures 18, coverage 0.26, energy 1, income 0.77
- Phase 8 floor for this run is baseline minus 120 s, so 548 s.

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

## Phase 2: roster (§4.2) — done

Commit message: `Stage 8 P2: enemy roster and silhouettes`.

### What changed

- `level/raider_defs.gd` is the roster. `Config.RAIDER_TIERS` is gone. Callers use `RaiderDefs.named`, `unlocked`, `newest`, or `pick`.
- Skitter, Brute, Ravager and Behemoth keep hp, dps, speed, size and colour. New rows: Spitter, Lancer, Burrower, Warden, Spotter. Their attacks are not live yet (dps 0), so they march and do not chew.
- Spawn picks among ordinary unlocked rows with weight `1 << order` (oldest 1). Spotter is unlocked at 0.70 but `pick` skips it until a mortar brings one (phase 7).
- `RaiderMeshesRanged` draws Spitter, Lancer, Warden, Spotter and Burrower. The gallery packs ten figures at `24 + i * 4`.
- Brute and Behemoth `wall_mult` 3 applies only when the prey dict has `wall: true` (castle wall segments).
- The threat line names `RaiderDefs.newest(pressure)`, not the schedule index. The schedule index still advances for castle-raid size.

### Decisions where the spec was silent

- New colours: Spitter `d6ff3a`, Lancer `e6d2ff`, Burrower `c4a06a`, Spotter `7ee0ff`, Warden `ffb03a`. Sizes: 0.6, 0.85, 0.7, 0.5, 1.0.
- Spotter unlock 0.70 matches hive stage 3 (the first mortar). `special: "spotter"` keeps it out of natural spawns. `unlocked()` still lists it.
- Burrower `special: "burrow"` so phase 5 can leave it out of the front-line pool. It is in the weighted pick from pressure 0.40.
- Loot is stored on the row and not spawned. Skitter loot is a 10% chance of 1 (`loot_p` 0.1). Everyone else is `loot_p` 1.0.
- Weight at pressure 0.20 is Skitter 1, Spitter 2, Brute 4 (total 7). Roll 0 is Skitter. Roll 0.99 is Brute.
- Non-melee `dps` stays 0 until phases 3 and 4. Stored `range` is cells, matching the spec table. Melee reach is unchanged.

### Tests

- Parse: `--import` clean after typing the wall-damage product as `float`.
- Smoke **254 PASS / 0 FAIL** (246 previous + 8 roster checks).
- Screenshot `/tmp/stage8-shots/p2-roster.png` (`--gallery`, Xvfb 1600x900). The ten figures stand on the south strip: the original four, the five new silhouettes, and the Sentinel. They are small at the existing gallery distance.

### Not finished

- Phase 3 onward. Ranged shots, Warden aura, Burrower, groups, hives, mortars, balance.
