# Playtest 4 feedback and plan (Gregory, 2026-10-10)

Logged by Opus. Gregory plays `integ/2026-10-09` (worktree `integ`, see RUN.md). All work branches from integ.

## Done inline on integ (uncommitted, smoke green)
- **Shield Dome needs no charge:** def key `no_charge` (enemy_structures.gd); `DemoCharge.chargeable` skips it, so the 3 s Sabotage prompt always shows.
- **Crown nest takes a charge:** crown target is `chargeable`, gated by `charge_ok` (no plant while the crown is warded).
- **Burrower out of L1 and L2:** level key `raider_ban: ["Burrower"]` -> `RaiderDefs.banned`, read in `unlocked()`. The Burrower itself is untouched.
- **Prompts follow rebinds:** `Keybinds.fill()` swaps `{use}` / `{teleport}` tokens in objective hints; Spire, Rift, Deep Core and Armoury texts now read the live bind instead of a literal E / R / T.
- Smoke `holdbar` hard-coded `[E]`; it failed with the player's F bind. Now reads `Keybinds.short("use")`.

## Not on integ yet
- **A. Deactivate (Z) + Esc pause menu:** commit `5a7f2f7` on `feat/deactivate-pause-menu` was cut from `main`, which is 172 commits behind integ. Port it to integ (cherry-pick, expect conflicts in game_flow.gd / info_panel.gd / command_select.gd). *Sonnet `feature-dev`: mechanical port with a smoke file to prove it.*

## Open items
1. **FPS still bad at ~12 min.** Gregory's ask: make the map static (no runtime terrain changes) and redo raider pathing.
   - Known from PT3-G (measured at 60 s only): the cost that grows with time was animated skeletons and draw calls (67 -> 100 skeletons, 5.4k -> 10k draws); the flow field was already time-sliced; castles are ~2,500 MeshInstances.
   - Runtime terrain writers today: `terp.gd`, `enemy_mortar_hit.gd` (craters), `raider_shots.gd`, `raider_burrow.gd`, `stronghold_rules.gd` (wall breach), `wall_repair.gd`. Each fires `Bus.terrain_changed` -> chunk rebuild, GPU height upload, field invalidate, unit re-plan.
   - **Step 1, measure (Haiku `balance-tester`):** L2 `--autostart --sim=720` and a `--demo` run; report per-system ms at minutes 1, 6, 12, the count of `terrain_changed` per minute, live raiders, skeletons, draw calls. Cheap, and it tells us whether terrain edits are the cost or enemy count is.
   - **Step 2a, static map (Sonnet `stage-runner`, brief by Opus):** craters, acid and burrow dig become visual only (decal/tint, no height change). **Needs Gregory's call:** Terp (the whole tool edits terrain) and castle wall breach/repair (walls are terrain).
   - **Step 2b, pathing (Sonnet):** with static ground the walk-height cache and area labels are built once per level; the field rebuilds only when goals change (structure placed/lost, gate opened). Opus reviews: this touches `Grid.step_ok` users across raiders, units and the Operative.
   - **Step 2c, if step 1 blames enemy count (Sonnet):** animation LOD and a live raider cap; merge castle meshes.
2. **Base losses are invisible in first person.** Only a log line bottom-left; the centre-screen alert exists only for the Node (`game_flow.gd:26`). Add: a centre alert + alarm sound when a structure is destroyed or the base is under attack (rate limited, with a count: "BASE UNDER ATTACK: 3 lost"), a red screen-edge pulse, and a persistent base-status chip on the FPS HUD. *Sonnet `feature-dev`: UI + a Bus signal, follows the Node alert pattern.*
3. **Barracks units don't patrol on their own.** Only barracks inside a held castle auto-patrol (PT3 item 17). Make every new unit auto-patrol a loop around its barracks until given an order. *Sonnet `feature-dev`: small, in `unit_patrol.gd` / spawn.*
4. **Castle is retaken before the reprisal.** Ordinary raiders walk in and run the 15 s `RETAKE_TIME` before any turret can be bought. Proposal: after a capture the castle cannot be sieged until the reprisal arrives (grace = the reprisal countdown), raiders with no castle mission ignore it during that window, and the countdown shows on the castle marker. *Sonnet `feature-dev` for the rule + smoke; Haiku `balance-tester` to check the reprisal still lands.*

5. **Right-click an enemy = attack it.** Selected soldiers/crawlers walk to the clicked spot instead of targeting the enemy under the cursor. Add an attack order: pick the raider / hive part / enemy structure under the click, units close to weapon range and keep firing until it dies, then hold. Ground click stays a move. *Sonnet `feature-dev`: `command_select.gd` pick + a `Unit.focus` target in `unit_supply.gd`.*

## Update, same day (Gregory)
- **Terp is not available on L1/L2**, so the static-map question is only about castle walls and craters there.
- FPS is still bad at 18 min and **much worse in first person** than in command view. Gregory suspects enemy count, not time. That points at rendering (skeletons, draw calls, the long first-person view distance over ~2,500 castle meshes), not the sim or pathing.
- So item 1 reorders: **measure both views first** with `--bench-l2` (needs the real display, so it opens a game window for a few minutes; ask first), in command and Operative view with 20 / 40 / 60 live raiders. Then 2c (animation LOD, distance culling, castle mesh merge, shadow distance in FPS) before 2a/2b.

## Update 2 (Gregory)
- Trebuchet range stays. **L2 needs more space** between castles and Salvage Engines (brief L).
- **Units must fight back** when shot, with nearby allies joining (brief U, with items 3 and 5).
- **Trebuchets must not respawn** unless the castle is retaken (brief A, phase 2).
- Perf is the top priority; craters/height changes may go if they cost frames. Bench first (Opus, when Gregory stops playing).
- Go-ahead given: briefs U, A, P, L in `PLAYTEST4_briefs.md`, Sonnet agents, own worktrees `pt4-*`. Opus integrates.

## Update 3 (Gregory)
- **Units must not shoot what they cannot destroy** (they empty their ammo into an enemy mortar, which only a charge kills). Added to brief U.
- **Move orders are ignored while units are firing** (crawlers locked on the mortar would not leave). A player order must always override combat. Added to brief U.
- **Logic audit** requested: a read-only Sonnet pass over who can damage what, looking for more dead ends like that. Findings go in `PLAYTEST4_audit.md`.

## Update 4 (Gregory)
- **Spacing rule for L2:** a trebuchet-free, buildable corridor from the landing mesa to every map edge and every Salvage Engine (added to brief L, with a flood-fill smoke check).
- **Click an enemy trebuchet to see its range** (ground rings, plus a warning ring while placing inside its reach). Brief R, branch `pt4/trebrange`, Sonnet.
- `pt4/port` (deactivate + Esc pause menu) is done and reviewed, commit `52316c1`. Merge waits until Gregory stops playing.
- Audit item 3 (respawn can wait forever) still needs Gregory's call.

## Update 5 (Gregory)
- `pt4/units` done (`76169de`, `14f0495`): attack order, move order beats combat, retaliation (nearest enemy within 30 m, so not Lancers), auto-patrol, mortars untargetable. The "mortar rows" smoke check found 0 rows; tighten at merge.
- **Mortars: free Operative sabotage, no charge needed** (overrides PT3 item 10). Chosen over "units can destroy them" to keep one rule; units still ignore mortars. Third commit on `pt4/units`.

## Update 6 (Gregory)
- **Deploy from any Totem or the Node, by choice**, and **recall cooldown measured to the nearest Totem/Node**, not the home one. A picker (`fps/deploy_pick.gd`) exists but did not give him the choice in play; the agent diagnoses first. Brief D, branch `pt4/deploy`, Sonnet.

## Update 7 (Gregory, 2026-10-10, after the perf merge)
- **Skitters walk back and forth and cannot attack a tower; "pathing seems a lot worse".** Not reproduced yet; level, tower and terrain not known.
- Cheap diagnosis (Opus, reading only): `RaiderMove.walk` is line-for-line the old `Raiders._walk` apart from the bucketed neighbour list. Behaviour differences from `pt4/perf-enemies`: melee target held 0.3-0.5 s (`Raiders._acquire`, no range or reach re-check in between), `RaiderField.next_step` cached per cell until the 2 s field interval, group speed cached per frame. None of these obviously explains pacing. The older straight-walk / 2 s flow-field detour loop in `Raiders._think` can oscillate when the target is in the same walking area but a cliff blocks the straight line; unchanged today.
- Found while reading: `Raiders._index` counts dead raiders in `group_slow` (the old `RaiderGroups.speed` skipped them). Small, not the reported bug.
- Plan (not started, ask first): one Sonnet `feature-dev` run. Reproduce headless with a debug hook from Gregory's description, bisect `09aa016` (before the perf merges) against HEAD, fix on a `pt4/raider-pacing` branch with a smoke check, fix `group_slow`. Opus reviews and merges. Sonnet because it is a scoped bug with a repro in existing systems.

## Update 8 (Gregory, 2026-10-10)
- **A hooked-up Salvage engine must ship Salvage with no other condition.** He hooked L2 engine e4 and got "ships nothing until the Southern Barrows hive is razed".
- Cause: a designed rule, not a bug. Engine rows with a `hive` key ship only once that hive is razed, and rows with a `castle` key only while that castle is held (`level/salvage_engines.gd:90-93`; data in `level01.gd` ENGINES e2/e4/e5 and `level02.gd` e3-e6 plus the castle rows).
- Decision (Gregory): remove the condition. Hooking to the network is the only requirement.
- Plan (not started, ask first): Sonnet `feature-dev`, small. Remove the hive and castle gates from `salvage_engines.gd`, drop the `hive`/`castle` keys and the data comments from both level files, update the engine prompt text and the smoke checks that assert the gate. Sonnet rather than Haiku because rule code and smoke change, not only level data.

## Update 9 (Gregory, 2026-10-10, with two screenshots)
- **Pathing (Update 7) explained.** L2, hive plateau west of engine e4: Skitters on the plateau target a Collector at the cliff foot, cannot step down, and alternate every 2 s between the straight line and the flow field (`Raiders._think` detour timer). This loop is older than the perf merge. Gregory's rule: pick the most direct walkable path to the chosen target and keep both until the target dies or the path breaks; lock on to moving targets instead of re-deciding several times a second; applies to all pathfinding. -> brief **R** in PLAYTEST4_briefs.md (Sonnet `stage-runner`, 2 phases: raiders, then moving targets + shooters + unit attack orders).
- **Salvage Engines (Update 8) decided:** remove the hive gate. Castles do not contain engines and award Salvage on their own; engines get no castle condition either. -> brief **S** (Sonnet `feature-dev`).
- **"The stronger enemies are coming out way too fast."** L2 `RAID_SCHEDULE` (`level02.gd:9`): first raid 3:00, Brute 5:00, Ravager 10:00, Behemoth 15:00, pressure cap 30:00. L1 is 5:00 / 8:00 / 15:00 / 22:00, cap 40:00. Data-only change (`RAID_SCHEDULE` + `PRESSURE_POINTS`, kept in step). Waiting on Gregory for target times and which level he was on. -> Haiku `balance-tester` once the numbers are set.

## Perf findings (Opus, PerfProbe, L2 `--demo`, 28 min, RTX 5090, 1440p)
Tool: `godot --path godot --rendering-driver vulkan -- --level=2 --demo --nocapture --perf-probe=28` (headless: sim numbers only).
- **Terrain edits: 0 in 28 minutes.** The static-map / pathing rework is dropped; it would fix nothing.
- **No node leak** (8.7k -> 9.2k nodes). An earlier reading of 27k was the probe not yielding frames.
- **Frame is sim-bound, not GPU-bound:** command view 82-111 fps running, 240 (vsync cap) with the sim frozen.
- **Hitches:** `EnemyBuilder.update` 1,088 / 468 / 731 ms at raid start (t=182-197 s), then 62-110 ms every 5 s from t=525 to 930 (80+). -> `pt4/perf-builder` (Sonnet).
- **Per frame:** enemy logic 3.75 ms (raiders 1.85, hives 0.66, mortars 0.57, flyers 0.28) for <100 creatures. -> `pt4/perf-enemies` (Sonnet).
- **Creeper GPU sim:** 5.6 ms per `update(0.05)` on the CPU side (readback + CPU anti-creeper tick), 30 ticks/s. Open (Opus, needs the display).
- **First person:** HUD markers cost 6.7 ms a frame (every label rewritten every frame). Fixed: 0.07 ms. Shadow pass doubles draw calls (10.5k -> 5.5k without). Open.
- Not yet measured: a surviving late-game player base (`--probe-base`).
- Merged into integ, smoke green: `pt4/port`, `pt4/units`, `pt4/alerts`, `pt4/deploy`, `pt4/trebrange`. Pending: `pt4/l2space` (L2 trebuchet range 12 by Gregory's call).

## Perf merge (2026-10-10, Opus; all three in integ, smoke 0 failures twice)
- `pt4/perf-builder`: planner edge scan time-sliced (`ENEMY_PLAN_BUDGET_US`), fair-spitter test best-first and cached. Agent's L2 12-min headless probe: HITCH lines 44 -> 0, worst update 1090 -> 39.6 ms, same 13 enemy builds.
- `pt4/perf-enemies`: target scans, hive bookkeeping, mortar aim and castle zone scans on timers; bucketed raider separation; cached `RaiderField.next_step`. `hazards.nests.update` 2.65 -> 1.63 ms (target 1.2 not met; the rest is per-raider `RaiderMove.walk`, ~0.6 ms for 50 raiders). Mortar and late-game castle cost not measured (base lost by 720 s).
- `pt4/perf-units`: `Pathfind.find` rewritten (reused packed buffers, binary heap, windowed smoothing in `PathSmooth`), `UnitPaths` budget queue (`PATH_FRAME_MS` 3) and 3 s unreachable-goal cooldown. Search ~175 ms -> ~9 us per node (capped 6000-node worst case ~55 ms). Units hitches in 4 min: ~56 (up to 949 ms) -> 1-2 of ~80 ms.
- Merged build, Opus headless `--level=2 --demo --units --perf-probe=4`: 2 HITCH lines (79 and 81 ms at t=29-32 s, outside the updaters). **Not re-measured on the display** (fps, minute 28, `--probe-base`).
- Behaviour to watch in play: raiders and enemy mortars re-pick targets every 0.3-0.5 s; units with a queued path order stand a few frames; a goal found unreachable is not searched again for 3 s (per unit type and goal cell).
- The two smoke fixes are test-side: `attack order: holds after kill` removes the bystander raider first; the dry-unit retreat check no longer requires the unit to survive the Spitter.

## Noted for later (Gregory)
- **Reconfigure pathfinding in Rust** (GDExtension via `gdext`, same interface, GDScript fallback). Not started. `pt4/perf-units` is merged (numbers above are the ones to beat); start from a fresh session. Details in HANDOFF.md, next step 4.

## Questions for Gregory
- Static map: do **castle walls** stop being breakable (gates only)? Craters would become marks with no height change.
- OK to run the bench (a game window opens on your screen for a few minutes)?
