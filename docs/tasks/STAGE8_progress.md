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

## Phase 3: Spitter and Lancer — done

Commit message: `Stage 8 P3: Spitter and Lancer shots`.

### What changed

- `level/raider_shots.gd`. Acid and Lancer bolts are `effects.lob` arcs. The aim point is where the target stood when the shot left. Impact hurts whoever is still inside the radius.
- Spitter: every 2 s, 6 damage, splash 1.5 cells, range 20 cells. Lancer: 1.5 s growing glow, then 25 damage in a 1.2 m radius, range 32 cells. After the bolt, 1.5 s before the next charge.
- They stop inside range and back up when closer than 65% of range. With nobody in range they march (guards patrol).
- Lancers prefer a Sniper, then any prey with `weapon` set (player weapons and castle turrets), then anyone else. Nearest inside a band.
- `game.gd` `surface_prey` copies each structure's prey and adds `type` and `weapon`. Command code was not edited. `castle_guards.gd` was not edited.

### Decisions where the spec was silent

- Roster `range` is cells, matching the §4.2 table and the Sniper comparison. Multiplied by `Config.CELL` at use.
- The spec names the Lancer's 1.5 s charge and not a cooldown. `RAIDER_LANCER_GAP` is another 1.5 s so they do not chain bolts.
- Spitter splash is the full 6 to everyone still inside 1.5 cells. No falloff.
- No line-of-sight test on these shots. The spec only requires travel time so a moving target can be missed. Spotter line of sight is phase 7.
- Standoff fraction is 0.65. Acid speed 18 m/s, bolt speed 32 m/s.

### Tests

- Parse clean. Smoke **258 PASS / 0 FAIL** (254 previous + 4). A Spitter in range took a cannon from 40 to 34. A Lancer took the farther Sniper from 40 to 15 and left the nearer cannon at 40. A lob already in flight missed a cannon that was moved 40 m.
- Screenshot `/tmp/stage8-shots/p3-ranged.png` (`--ranged`, Xvfb 1600x900). The Spitter's acid lob is in the air on the southern pad. The Lancer sits at the left edge of that frame.

### Not finished

- Phase 4 onward. Warden aura, Burrower, groups, hives, mortars, balance.

## Phase 4: Warden and Burrower — done

Commit message: `Stage 8 P4: Warden aura and Burrower`.

### What changed

- `level/raider_burrow.gd`. A Warden's hit reduction is applied in the raider hit callback: one living Warden within its row range (5 cells) halves the damage, once. The Warden itself is not an ally of its own aura. A second Warden does not halve it again.
- The aura is a flat torus on the Warden node, 5 cells out. Not a ground overlay.
- A Burrower walks a straight XZ line at its speed, ignoring `step_ok`, with the mesh hidden and a dust puff every 0.22 s. Hits while `burrow == "down"` are ignored. Within 1.6 m of the nearest weapon it surfaces for `surface` seconds (1.5), can be shot, then bursts `damage` (60) inside `splash` cells (1.5). It digs again if it lives.
- With no weapon in the prey list it walks at the nearest other prey (the Node, once `surface_prey` has tagged it).

### Decisions where the spec was silent

- The burst is at the end of the 1.5 s on the surface, so that window is the chance to kill it before the explosion.
- "Next to" is 1.6 m, inside the 3 m burst.
- The aura radius is the Warden row's `range` in cells, times `Config.CELL`.

### Tests

- Parse clean. Smoke **263 PASS / 0 FAIL** (258 previous + 5). A Brute took 4 of an 8-damage hit beside one Warden, and still 4 beside two. Outside the rings it took the full 8. A Burrower crossed a 4-level wall (`step_ok` false) and left a cannon at -20 (40 − 60). Underground, 9 damage did nothing; on the surface the same hit landed.
- Screenshot `/tmp/stage8-shots/p4-burrow.png` (`--burrow`, Xvfb 1600x900). The Warden's ring is a flat circle on the grass. The Burrower is underground; its dust puffs are small at this distance.

### Not finished

- Phase 5 onward. Mixed groups, hives, mortars, balance.

## Phase 5: mixed groups — done

Commit message: `Stage 8 P5: mixed raid groups`.

### What changed

- `level/raider_groups.gd`. From pressure 0.35 a marching spawn is a group, not one raider. Size is `round(lerp(4, 8, pressure))`. The nest waits `interval * size` so the headcount rate stays close to the old one. Guards, the overrun wave, and castle garrisons stay single spawns.
- Shares are 50% front (Skitter, Brute, Ravager, Behemoth), 35% ranged (Spitter, Lancer), 15% support (Warden). Burrowers and Spotters are not in those pools. An empty pool falls back to the front line, which is what happens before the Warden unlocks at 0.50.
- The group mills at the nest for 10 s, then every living member moves at the slowest member's speed.
- Castle reprisals and the stronghold counterattack use the same `compose`.
- The sim report now includes `raider_seen`, a count of every tier that spawned.

### Decisions where the spec was silent

- `compose(n, p, salt)` does not touch the global RNG. Salt 0 spaces the role rolls evenly, so 20 raiders are exactly 10 / 7 / 3. A non-zero salt shifts which rows fill those shares. Inside a role the weight is still `2^order`.
- Between pressure 0.35 and 0.50 the support roll becomes a front-line raider, because no support row is unlocked yet.

### Tests

- Parse clean. Smoke **266 PASS / 0 FAIL** (263 previous + 3). The group of 20 was 10 / 7 / 3 with no Burrower and no Spotter. After 4 s every member was still at the nest. With the gather cleared they moved at 2.6 m/s (the Lancer), between 1.9 m and 3.2 m in one second.
- `--autostart --sim=1800`: L1 Node dies at t=380. `raider_seen` is Skitter 20. Pressure is still under 0.10, so nothing else has unlocked.
- `--level=2 --autostart --sim=1800`: Node dies at t=252. `raider_seen` is Skitter 44. The label already says Spitter (pressure about 0.12) but no Spitter had spawned in that last 12 s. Both deaths are before pressure 0.35, so an undefended start never meets a mixed group. Logs: `/tmp/stage8-p5/auto-l1.log`, `auto-l2.log`.

### Not finished

- Phase 6 onward. Hives, mortars, balance. The defended sims in phase 8 are where the later roster shows up.

## Phase 6: hives — done

Commit message: `Stage 8 P6: hives replace spore nests`.

### What changed

- Each former nest is a hive. `HiveShape` stamps a berm of whole Earth levels with three gaps, and Blight inside the ring that actually rose. Stage follows pressure: 0 at the start (Core + one pit), 1 at 0.20, 2 at 0.45, 3 at 0.70, 4 at 0.90. Parts added after stage 0 grow in over 20 s and can be shot while small.
- The Core takes damage only from the Operative and the Lance. Razing it clears the Blight, pays 40 Salvage, and leaves the site razed. An Outpost on the Core cell marks the hive `outpost`. Three raiders within 4 cells for 30 s rebuild it one stage lower, unless a player structure is that close.
- `spore_nests.gd` is now `hive_spawning.gd`. The class is still `SporeNests`, and level rows are `hives` with `nests` kept as an alias. The objective id stays `nests`. Living grown pits share one spawn clock, so killing a pit slows the next spawn. The spore launcher uses the old Spire volley.
- A Lance that is about to land is applied to hive parts from `game.gd`. `orbital.gd` is unchanged.

### Decisions where the spec was silent

- The mortar id is listed at stage 4 and skipped. Phase 7 builds the mortar body. Stage 4 still applies the +50% HP.
- A rebuilt hive's parts start fully grown. There is no second 20 s grow, and the Core does not use the old nest HP heal.
- The Lance deals `HIVE_LANCE_DMG` 100. It hurts the Core. It does not erase a fresh one. `HiveParts.lance` holds that scan so `hives.gd` stays under 250 lines. Rebuild, Blight, and the anchor live in `hive_site.gd` for the same reason.
- An outer berm is stamped only when at least 8 cells can rise by one whole level without a cliff. Otherwise the inner ring is used and Blight stops at that ring. Level 1 and 2 knolls are flat only out to about 3 cells, so most of them take the inner ring. The plateau nest can hold the outer one.
- The spawn clock stays on the hive. The wait is the old interval divided by the number of living grown pits. One fire releases one raider, or one group once groups are on. Stage 0 parts are present immediately.
- The Outpost still costs its existing 40 energy packets. No second energy charge, and no Ore until 9a.
- An undamaged part's HP tracks the pressure formula, including the stage-4 bonus. A damaged part is multiplied by 1.5 only on the frame it enters stage 4.
- The hive spitter uses the raider Spitter numbers (6 damage, 2 s, 20 cells, splash 1.5 cells).

### Tests

- Parse clean (second import, no SCRIPT ERROR). Smoke **286 PASS / 0 FAIL** (266 previous + 20). Stages match pressure after the roster smoke's clock is put back to 0. Two grown pits wait half as long as one (8.70 s vs 17.39 s), and killing the extra pit lengthens the wait. At t=2040 (pressure 0.95) the Core is 367.5 / 367.5 and there is still no mortar body. A cannon shot leaves the Core untouched. Razing clears Blight and adds 40 Salvage. One razed hive does not complete the objective. An Outpost claims the site and losing it returns `razed`. A collector 3 cells away blocks the rebuild. Three raiders restore it after the full 30 s, not at 20 s. Save/load restored stage and Core HP (the restored HP was 250 after the stage-4 drop divided a full Core by 1.5).
- Screenshot `/tmp/stage8-shots/p6-hive.png` (`--look=40,23,42,0.9`, Xvfb 1600x900). Central knoll: inner Earth berm, Blight bowl, Core and one pit.

### Not finished

- Phase 7: enemy mortars and the Spotter. Phase 8: balance, the as-built notes, and the MASTER_PLAN status cells.

## Phase 7: enemy mortars and Spotter — done

Commit message: `Stage 8 P7: enemy mortars and spotters`.

### What changed

- `level/enemy_mortar.gd` builds the mortars. Stage 3 builds one, stage 4 builds a second and both gain the +50% HP. Any active hive also builds one within 60 s after the Node has had no walking route for 60 s. Each mortar grows in over 20 s and brings a Spotter.
- A shell is aimed, then a red ring grows on the ground for 2.5 s (`shells[8]` on `terrain.gdshader`). A thump plays at launch and a whistle in the last 1 s. Blast is 2.5 cells: structures 30, units 20, the Operative 70% of max suit at the centre, falling off. The 3×3 loses one Earth level through TerrainEdit, never below `base_height`. Spire cells are skipped.
- The Operative is a target only while that mortar's Spotter has line of sight within 25 m. `Bus.say("SPOTTED", "bad")` fires when a shell is called on them. Hold E within 2 m starts a 3 s channel; staying there destroys the mortar and pays 5 Salvage.

### Decisions where the spec was silent

- The mortar is not a hive part. The stage-4 part id stays skipped so the body can be two mortars, and so a sealed hive can build one before stage 3. `enemy_mortar_fire.gd` and `enemy_mortar_hit.gd` hold the aim and the blast so each file stays under 250 lines.
- A killed mortar is not rebuilt. An ungrown extra is removed if the hive drops below the stage that wanted it. A grown one stays. Razing the hive removes them. They are not in the hive save blob.
- The seal clock is global. It resets if any active hive can walk to the Node (`RaiderField.reachable`), and a flying Node counts as open. The build happens once the clock has been closed for 60 s and then another 60 s.
- A spotted Operative is preferred over a weapon. Units are splash, not an aim point. Weapons and Terps beat other structures.
- The Spotter is a real raider posted beside its mortar. Only a Spotter with a post holds still, so the roster smoke's unposted Spotter still wanders. It respawns 30 s after dying while the mortar lives, and it dies with the mortar. It counts toward the nest's raider cap.
- Sabotage is the only thing that pays the 5 Salvage. Shot death does not. `use()` starts the channel; the mortar update finishes it if the Operative is still within 2 m. There is no HUD widget for SPOTTED. The operative HUD has no alert hook, and this brief stays out of `scripts/ui`.
- Metal and plated stone lose nothing to a shell. A stone wall segment is not damaged here. Both would be new per-cell chip state, and the wall HP would mean editing `castle_*.gd`.
- At most 8 telegraphs are drawn. A ninth shell still lands.

### Tests

- Parse clean. Smoke **307 PASS / 0 FAIL** (286 previous + 21). A collector 4 cells away is ignored. A cannon beats a nearer relay. The Operative is ignored without a Spotter, chosen when one can see them, and ignored again inside 6 cells. The Spotter is still dead at 29 s and back at 31 s. Earth at the impact goes from base+2 to base+1, then refuses to go under base. A Spire neighbour is unchanged. The centre hit takes the suit from 100 to 30. Sabotage cancels if you step away, waits out 3 s, then pays 5 Salvage. Stage 3 builds one mortar, stage 4 a second at 120 HP. An open route does not arm the seal. Lifting the Node off the ground for 50 s does not build; the following 80 s does, one mortar.
- Screenshot `/tmp/stage8-shots/p7-mortar.png` (`--mortar --look=48,33,38,0.85`, Xvfb 1600x900). The tube and its red mouth sit up the slope from a red ring on the grass.

### Not finished

- Phase 8 closed the balance pass. Metal chip, stone-wall HP, and a real SPOTTED widget stay unbuilt.

## Phase 8: balance and wrap-up — done

Commit message: `Stage 8 P8: balance pass and as-built notes`.

### Sims, before then after

Phase 0 baselines are in the Phase 0 section. The "before" column is this branch after Phase 7, before the tune. Logs are under `/tmp/stage8-p8/`.

| Run | Phase 0 | Before the tune | After |
|---|---|---|---|
| L1 `--demo --units --sim=900` | time 900, node_hp 500 | time 638, node_hp 0 | time 900, over false, node_hp 500 |
| L1 `--autostart --sim=900` | time 354, node_hp 0 | time 381, node_hp 0 | time 341, node_hp 0 |
| L2 `--autostart --sim=900` | time 235, node_hp 0 | time 254, node_hp 0 | time 226, node_hp 0 |
| L2 `--demo --sim=900` | time 668, node_hp 0 | time 373, node_hp 0 | time 645, node_hp 0 |

The L1 demo Node is still up at 900 s. The undefended L1 Node dies at 341 s, inside (200, 354). The L2 demo dies at 645 s, which is after the floor of 548 s (baseline minus 120). The undefended L2 Node dies at 226 s.

### What the tune changed

- Skitter melee is 6 dps. One raider per nest stays home (`NEST_GUARDS` 1). That is what pulls the undefended L1 loss under the old 354 s.
- Hive stages start at pressure 0.55 / 0.70 / 0.85 / 0.95. Groups start at 0.60. Lancers unlock at 0.55 and Burrowers at 0.65.
- Spitter HP is 4 and the lob range is 2 cells, so they stand in the melee line. At range 20 they shelled the scripted base while Snipers shot nearer Skitters.
- Brute, Ravager and Behemoth stats are unchanged. `STRONGHOLDS_DESIGN.md` has an "*As built (Stage 8):*" note on §3.3, §4.1, §4.2 and §4.3. MASTER_PLAN 8a and 8b are ⚠, with one changelog line.

### Tests

- Smoke **307 PASS / 0 FAIL**, same count as Phase 7. Log `/tmp/stage8-p8/smoke2.log`. No new `class_name`. The Spitter cannon check waits 1.5 s so one short lob is the only hit.

### Not done

- Loot pickups (§4.4), enemy construction and the Weaver (§4.5), a real hold-E, a SPOTTED HUD widget, the metal/plated 1/8 chip, stone-wall 40 HP, and Ore on Outposts. Mortars are still absent from the hive save. More than 8 shell rings are not drawn. The demolition charge (§5.2) is not this stage.
