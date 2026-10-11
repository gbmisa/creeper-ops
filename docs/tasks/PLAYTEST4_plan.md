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
- **S merged** (`pt4/salvage` `ab76810`, smoke 0 failures): `guard_note` and the `hive` / `castle` keys are gone; a hooked engine ships. No engine sits inside a castle wall. Left alone as castle Salvage: vault engines still ship only while the castle is held (`CastleVaults.ships`); ask Gregory if he sees one in play.

## Update 10 (Gregory, 2026-10-10, screenshot)
- **Spitters still shoot straight into a wall** (seen at a Salvage Engine). They must have a clear projectile path before firing. Cause: `RaiderShots._pick` checks sight for beams only; acid is launched at anything in range and the lob is clipped where it meets terrain. -> added to brief R phase 2 as item 7b (fire only when the lob reaches the target, otherwise reposition along the committed path).

## Update 11 (Gregory, 2026-10-10, screenshot of wall archers)
- **Castle wall defenders should not respawn either** (same as the trebuchets). Cause: `castle_guards.gd:120` regrows a slot after `GUARD_RESPAWN`; wall patrols share the garrison timer. -> brief **G** (Sonnet `feature-dev`): no timed respawn, full garrison returns only on a retake.
- Brief R phase 1 started (Sonnet `stage-runner`, `pt4/raider-commit`). Phase 2 follows after review.

## Update 12 (Gregory, 2026-10-10)
- **"Nothing should be able to unhook a salvage machine from a relay except for destroying the relay."** Cause: a hooked socket is raider prey with HP; raiders cut it (`engine_hook.gd:7-13`, "cut by raiders"). -> brief **H** (Sonnet `feature-dev`): sockets are not prey; a hook ends only when its anchor structure is destroyed; wet / deactivated / no route only pause shipping.
- Brief G (castle garrison) started on `pt4/guards`.

## Update 13 (Gregory, 2026-10-10)
- **"Double the length of time for the threat level to increase."** (Also answers Update 9's "stronger enemies are coming out way too fast".) The Threat chip is `Pressure.value` (0 until `grace`, 1 at `cap`). Decision (Opus reading): first raid time unchanged; every later time is stretched to twice as far after grace, on both levels, with tier unlocks kept on the same curve points.
  - L2 (`level02.gd`): tier_times [0, 300, 600, 900] -> [0, 420, 1020, 1620]; pressure points 300/600/900/1800 -> 420/1020/1620/3420; cap 1800 -> 3420. Brute 7:00, Ravager 17:00, Behemoth 27:00, full threat 57:00.
  - L1 (`level01.gd`): tier_times [0, 480, 900, 1320] -> [0, 660, 1500, 2340]; points 480/900/1320/2400 -> 660/1500/2340/4500; cap 2400 -> 4500. Brute 11:00, Ravager 25:00, Behemoth 39:00, full threat 75:00.
  - -> Haiku `balance-tester` on `pt4/threat` (data only, exact numbers given).
- Brief H (engine hook) started on `pt4/hook`.

## Update 14 (Gregory, 2026-10-10)
- **"The spawn rate of the enemies needs to be at a more appropriate ratio. The HP value of the enemies spawning in a castle cannot be greater than the DPS of the operative."** Read as: HP spawned inside a castle per second must stay under the Operative's base DPS (Pulse Rifle 7.1). Today the courtyard garrison refills every 20 -> 5 s with pressure-scaled tiers: up to 8 HP/s with Ravagers, 24 HP/s with Behemoths. -> brief **C** (Sonnet `feature-dev`, after G merges: same files): per-castle HP budget of 0.5 x rifle DPS.
- Open question to Gregory: does the first sentence also mean field nests (outside castles)? Those are 20 -> 5 s per nest, cap 3 -> 10 live raiders, scaling with the Threat curve that Update 13 just stretched.
- Threat curve (Update 13) started on `pt4/threat` (Haiku).

## Update 15 (Gregory, 2026-10-10)
- **Regression, his words:** "the thing that was working before was that I was able to take a tower but now I'm not able to kill the enemies faster than they spawn". He expects the threat stretch (Update 13) plus a cap to fix it: **HP spawned in a castle <= 75% of the Pulse Rifle's DPS at level 3** (Firepower tier 3: 7.14 x 1.75 = 12.5 DPS, so 9.4 HP/s per castle). Brief C updated with that number.
- Opus note: at 9.4 HP/s the cap only bites on Behemoths (120 HP every 5 s = 24 HP/s today); Ravagers at the fastest cadence are 8 HP/s. So the cap alone may not explain or cure what he saw. -> Sonnet `auditor` (read-only): what puts enemies into a hostile castle today, in HP/s over mission time, and what changed in that since the last build he played (`0859412`, pushed 2026-10-09). Findings go here before C starts.
- **Process (Gregory):** a change to working behaviour is written up in `CHANGES.md` (repo root), not asked as yes/no in chat; remind him to review it whenever it gains an entry. Added to CLAUDE.md and AGENTS.md. First version lists the 15 unrequested changes that came in with today's merges.
- **Audit result (Sonnet, read-only, `0859412..HEAD`):** nothing in the castle spawn path, enemy HP, tiers, caps or the rifle changed since the build he last played. Hostile-castle inflow before today's fixes, L2: courtyard garrison refills on `spawn_interval()` (20 -> 5 s) up to 4, timer keeps counting while full so a kill is replaced at once; the same tick also replaced 2 wall patrols and the Warden; Sentinels regrew after 90 s. Estimated HP/s (garrison alone / with patrol + Warden refill): minute 5 0.6 / ~2, minute 10 1.6 / ~5, minute 15 4.1 / ~10, minute 20 5.4 / ~14, against a 7.1 DPS rifle. Estimates, not measured. Likely he reached the castle at higher pressure this time.
- **Merged 2026-10-10 (smoke 0 failures):** `pt4/guards` (Sentinels, wall patrols, Warden, castle Lancers never respawn; full garrison only when the enemy retakes; the courtyard garrison refill is untouched and is brief C's subject), `pt4/threat` (Update 13 numbers; `smoke_roster.gd` follows the new L1 times). Opus one-line revert in `hive_spawning.gd`: the perf merge cached a nest's Sac node and threw "previously freed instance" once the node was replaced, aborting `SporeNests.update` for that frame.
- `pt4/hook` sent back: keep "sockets are not prey" and "anchor destroyed -> unhook"; restore deactivated-anchor shipping and the re-anchor on route loss / flight (not asked for).
- **`pt4/hook` merged** (`06955a5`, smoke 0 failures). Differs from before in exactly two ways: sockets are not prey (no HP, nothing can cut a hook), and a dead or removed anchor unhooks with "relay lost" instead of silently moving the cable. Deactivated anchor, route loss and flight behave as before.
- **`pt4/castle-rate` merged** (`3074ee7`, smoke 0 failures). `CastleDefs.spawn_budget()` = 0.75 x tier-3 rifle DPS = 9.38 HP/s; after a garrison spawn of HP H the next waits >= H / budget (`c.garrison_wait`). Measured in the smoke harness, one castle, garrison killed every step: HP/s before -> after at pressure 0: 0.3 -> 0.3; 0.5: 1.7 -> 1.7; 1.0: 6.2 -> 5.9. The cap only changes the wait after a Behemoth (12.8 s). The garrison alone never exceeded 9.4 HP/s; the relief for castle fights comes from G (no patrol/Warden/Sentinel/Lancer respawn) and the threat stretch.
- **`pt4/raider-commit` phase 1 merged at `af92d9f` on Gregory's instruction ("merge for a new playtest")**, before the L2 verification finished. Smoke 0 failures; headless L2 `--units --perf-probe=4`: same 2 hitches (92, 90 ms at t=29-32 s), `nests: raiders` 0.91 ms. Route search cost on long detours and the real plateau case are still unmeasured; the verify agent continues on the branch.

## Update 16 (Gregory, 2026-10-10, two screenshots)
- **Build menu box changes size when a hovered description wraps to two lines.** Cause: `ui/build_menu.gd:41-43`, the tip label autowraps with a minimum height of one line (20 px), so the panel grows when the text needs two. -> Sonnet `feature-dev` on `pt4/menu-tip`: reserve the height of the tallest description once, so the panel never resizes on hover. Nothing else about the menu changes.
- **`pt4/menu-tip` merged** (`a788a58`, smoke 0 failures): the tip label reserves the height of the tallest text (2 lines, 47 px at 1142 px width; re-measured on resize). One visible difference: the menu is always as tall as it used to get on the longest hover. Not checked in a screenshot.
- **L2 verify of raider-commit (Sonnet, `--level=2 --raider-probe`, Southern Barrows plateau, start (38,150) level 6, Collector (43,150) level 3):** phase 1 as first merged (`af92d9f`) was bad on the real map: 43 A* searches in 90 s (4-8 per raider), 8.3-8.9 ms each, and five of six raiders walked away from the target for about 10 s. Reworked (`2aae045`): one walking-distance field per target, built by `RaiderFieldBuild` at 1 ms per frame, shared by all raiders on that target, cache of 8. **Merged; Opus re-ran the probe on integ:** 1 build (36 slices, largest 1.25 ms), Collector first damaged at 21.3 s, distance-increase 0.00 s for all six, `units/` identical to before phase 1. Smoke 0 failures.
- Brief R item 8 (unit attack orders re-path rule) was Opus's extension, not Gregory's words: moved to `CHANGES.md` as a proposal, not built.
- **Brief R phase 2 merged** (`e1fef8e`, smoke 0 failures twice; L2 `--raider-probe` on integ: 0.00 s distance-increase for all six, 1.21 ms largest frame; `units/` identical to before brief R). Differs from before: (1) Spitters hold fire and walk toward the target until `clip_lob` reaches it (within splash), and do not back off to standoff while blocked; (2) Spitters and Lancers keep their pick until it dies, leaves range or (Lancer) sight at a cell change: a nearer or higher-band prey no longer steals it; (3) a moving target's field is rebuilt only past 4 cells and 1.5 s. `clip_lob` sees terrain and castle roof slabs; Salvage Engine bodies are terrain so they block lobs; trees, props, structures and units do not. `smoke_enemy_los.gd` "acid splashes on a keep wall" was rewritten to "holds fire until the lob is clear" (it asserted the behaviour Gregory asked to remove). Risk noted by the agent: a Spitter near its standoff distance could alternate between closing and backing off; not seen in smoke.

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
