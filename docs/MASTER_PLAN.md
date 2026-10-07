# Master Plan: Strongholds, Salvage and Scale

The living plan. **Update this file at the end of every stage:** tick the box, set the status, add a line to the Changelog, and move any new decisions into Settled Design. It replaces the Roadmap in [DEV_PLAN.md](DEV_PLAN.md). That file's model-routing guide still applies.

**Status:** Stages 1–7 and 10b merged to `main` (⚠ = not human-verified), plus the command-mode split. Playtest fixes 2026-10-07 on `main` (uncommitted). Next, in parallel: **7b castle stakes (Opus)** and **7c traversable terrain (Grok, brief written)**; then 8a/8b/9a.
**Status key:** ☐ not started · ◐ in progress · ☑ done (verified) · ⚠ done, not verified by a human

---

## 1. Settled design

### Pillars
- **Race the pressure.** Enemy pressure rises over the level and has a **cap**, past which a win is no longer realistic. You win by finishing objectives before then, not by turtling or hoarding.
- **CW3 core, FPS edge.** The network and creeper play like Creeper World. The Operative goes where the network can't.
- **RTS scale later.** Maps will get large enough that a level spans several sittings. Multiple bases (Outposts) and, later, armies matter.

### Resources (four, each with one job)
| Resource | Source | Spent on | Carries to the next level? |
|---|---|---|---|
| **Energy** | Collectors | Packets: builds, ammo, Earth terraforming | No |
| **Ore** | **Miners** on ore deposits (finite, often contested) | **Metal** terraforming, castle wall plating, heavy structures, **Outposts** | No |
| **Salvage** | Extractors on deposits in enemy bases (main source), loot pickups (Operative only), slow trickle from held castles | Operative upgrades, castle turrets and repair, advanced weapons (burn Salvage per shot), improved ammo | No |
| **Aether** | Held castles, objectives | Forge (network upgrades) | No |

Nothing carries over except a separate **meta skill tree** (Phase B), which has a story reason for why everything else is left behind.

### Creeper rules
- **Unbuilt** structures die instantly on creeper contact. **Built weapons take HP damage** instead. Other built structures (collectors, relays, miners, extractors) die instantly.
- The **Nullifier** counts as a weapon and is **immune while charging**.
- Nothing can be placed on creeper deeper than `MIN_DEPTH`. The Command Node only loses HP.
- Full weapons never request packets. *(Already built.)*
- Creeper hurting the Operative is fine, since the rocket launcher clears it.

### Strongholds (one shared system, owned by the enemy or the player)
**Nest base (enemy):** a walled compound with a **Hive Core**, spawner pits, defences (spitter turrets, spore launcher, **enemy mortars**), guards and **Salvage deposits**. It grows with mission time.
- Destroying the Core lets you build an **Outpost** there (costs Ore). Outposts **launch packets** from the shared energy bank. Each request is served by the closest sender along the relays.
- Raiders can retake an Outpost. The site turns back into a nest and its extractors are destroyed.

**Castle (contested):** walls, gates, walkways along the tops of the walls, and a **spire** in the courtyard with a nest on top.
- Capture: break in, climb the spire, destroy the crown nest, hold the zone against a counterattack.
- Held: makes Aether and a Salvage trickle. **Turrets** go on wall and gate sockets (3 or more), with levels I to III, bought **from command mode or in first-person**. Walls are **destructible** and repaired with Salvage.
- Retaken: raiders breach the walls, and if they hold the courtyard with no turrets alive, the castle flips back and the nest regrows.

### Salvage loop
1. The Node builds **Extractors** from packets. The network delivers them to supply points (Node, held castle, Outpost, **Supply Depot**).
2. The Operative carries **2** (an upgrade raises this to 3, then 4) and plants them on deposits by holding E. It takes multiple trips.
3. Extractors ship Salvage home as **return packets** only while inside network range. Outside range they store a small amount.
4. A retake destroys the extractors and whatever Salvage they hold.

**Improved ammo** (armour-piercing, incendiary, cluster) works for the Operative, Snipers, turrets and units. Network weapons receive it as special packets. Recipes unlock **late** (by level progress) and are costly. They're for the final push. Tuning target: little Salvage left over at the win.

### Operative upgrades (last for one level)
Firepower, survival (HP, armour, shield), mobility (jump jet, sprint) and carry capacity. Bought with Salvage at the Node armoury or at any held castle. **Advanced weapons** (railgun, plasma thrower, demolition charge) are unlocked with Salvage, then burn Salvage per shot.

### Enemies
**Rules:** raiders **cannot climb steep cliffs**; they only move between cells that differ by one terrace level. With no route, they attack the nearest structure they can reach. Per-level schedules set when raids start and when each tier unlocks.

| Enemy | Role | Range | L1 unlock (example) | Counter |
|---|---|---|---|---|
| Skitter | Melee swarm | Melee | Start | Mortar splash, units |
| Spitter | Acid lobber | Medium (< Sniper range) | ~6:00 | Snipers |
| Brute | Armoured, hits walls hard | Melee | ~9:00 | Snipers, AP ammo |
| Lancer | Charged beam | Long (> Sniper range) | ~12:00 | Operative, Lance, turrets |
| Warden | Shields allies | Support | ~15:00 | Focus fire |
| Spotter | Lets enemy mortars target the Operative | Sight | With mortars | Kill it |
| Ravager / Behemoth | Heavy melee | Melee | ~18:00 / ~24:00 | Everything |
| Flyers | Ignore terrain | Varies | Later levels | **Beams** |

Mixed groups (Brutes up front, Spitters behind, a Warden in the middle) start once Lancers unlock.

**Enemy mortars** are strong enough to blast Earth down. They are built by nest bases, especially when the Node is sealed off. **Fairness rules toward the Operative:**
1. Every shell is telegraphed: a launch sound, then a whistle and a red ground marker for about 2.5 s.
2. A minimum range: close in is safe.
3. They can only target the Operative while a Spotter sees them. The HUD shows "Spotted".
4. The Operative can sabotage one by holding E, or with a demolition charge from range.

### Who kills what
| Weapon | Targets |
|---|---|
| Sniper | **Main anti-raider weapon** |
| Mortar | Creeper. Splash does about 30% damage to raiders. Never the main defence. |
| Beam | **Surface-to-air.** Burns flying enemies (spore volleys now, flyers later) |
| Cannon | Creeper only |
| Castle turrets, Operative, Lance, units | Raiders |

### Terraforming (Terp)
- You paint target heights and the Terp raises or lowers cells one level at a time. It unlocks in later levels.
- **Earth** costs lots of packets. Creeper has to pile up to get over it. Enemy mortars can lower it.
- **Metal** costs Ore. Creeper can't wear it down, it barely takes mortar damage, and raiders have to break through it.
- **Sealing the last route to the Node is allowed.** The enemy responds with mortars, and later flyers.

### Tech
- **The creeper sim moves to the GPU** (compute). Minimum spec is an RTX 3060, and graphics stay simple. The CPU sim stays as the headless fallback and the parity reference, since `--headless` has no graphics device.
- Gameplay reads a CPU copy of creeper depth that the GPU sends back a few times per second. Weapon hits and emitters send batched changes to the GPU.
- **One terrain-editing tool** serves the Terp, breakable walls and growing nests. It updates the creeper sim, the terrain mesh chunks, the raider flow field, unit pathfinding and first-person collision.
- **Every new system keeps its state as plain, saveable data** (save and load arrive in Phase B).

---

## 2. Phase A: build the designed systems

Each stage lists the model, the files involved, and the acceptance check. Every stage ends with: the parse check, smoke tests all passing, HANDOFF.md updated, and this file updated.

| # | Stage | Model | Status |
|---|---|---|---|
| 1 | Creeper damage rules | Sonnet 5.5 (`feature-dev`) | ⚠ |
| 2 | Weapon roles, cliff rule, per-level schedules | Sonnet 5.5 (Grok) | ⚠ |
| 3 | Design doc ([STRONGHOLDS_DESIGN.md](STRONGHOLDS_DESIGN.md)) | **Opus 5.5** | ☑ §0 answered 2026-10-07 |
| 4 | GPU creeper sim | **Opus 5.5** | ⚠ built + parity verified; needs a human play check |
| 5 | Terrain-editing tool | Sonnet 5.5 (Grok), merged before review | ⚠ verified headless + GPU parity |
| 6 | Multiple packet senders and Outposts | Sonnet 5.5 (Grok), Opus review | ⚠ merged, verified headless |
| 7 | Strongholds, castles, spire climb | **Opus 5.5** (built) | ⚠ verified headless + screenshots |
| 7b | **Castle stakes:** reprisal raid on capture, recurring sieges, aggression that stacks with castles held, hostile castles buff nests, prep window. **Castle turrets pulled in (done ⚠)** | **Opus 5.5** | ◐ turrets done; raids next |
| 7c | Traversable terrain on Level 1 (stairs, no isolated shelves) | Sonnet 5.5 (Grok), Opus review | ☐ brief: [tasks/STAGE7c_traversal.md](tasks/STAGE7c_traversal.md) |
| 8a | Nest bases and enemy mortars | Sonnet 5.5 | ☐ |
| 8b | Enemy roster (incl. Burrower, Weaver) | Sonnet 5.5 | ☐ |
| 8c | **Enemy construction:** hubs in enemy castles, Weavers, Leeches, build planner, enemy structures (design §4.5) | Sonnet 5.5, Opus review | ☐ |
| 9a | Return packets, Salvage, Ore, Miner, turrets | Sonnet 5.5 | ☐ |
| 9b | Extractors and supply points | Sonnet 5.5 | ☐ |
| 10 | Armoury (incl. Ctrl + wheel ammo switching) | Sonnet 5.5 | ☐ |
| 10b | **Operative deployment:** Totems, drop anywhere, recall cooldown, Shield Domes block drops, expensive respawn (design §5.4) | Sonnet 5.5 (Grok), Opus review | ⚠ merged, verified headless |
| 11 | Terp | Sonnet 5.5 | ☐ |
| 12 | Level placement | Sonnet 5.5 (`level-builder` with `model: sonnet`) | ☐ |
| 13 | Tuning | Haiku 4.5 (`balance-tester`) | ☐ |
| 14 | Review and screenshots | **Opus 5.5** | ☐ |

### Stage details

**1. Creeper damage rules.** `command/structure_upkeep.gd`, `smoke_rules.gd`. Built weapons take HP damage from creeper depth, and unbuilt structures still die instantly. The Nullifier is immune while charging. Check: new smoke tests (a weapon survives a short soak, an unbuilt one dies, a charging Nullifier survives).

**2. Weapon roles, cliff rule, per-level schedules.** `weapon_logic.gd`, `raider_field.gd`, `raiders.gd`, `spore_nests.gd`, `level01.gd`, `cave01.gd`, `config.gd`.
- Beams are surface-to-air and burn flying enemies. Mortar splash does `MORTAR_RAIDER_DMG` to raiders.
- Remove cliff climbing; raiders with no route attack the nearest structure they can reach.
- `NEST_RAID_DELAY` and the tier times move into the level data.
- Check: smoke tests (a Beam ignores raiders, a raider stops at a cliff, schedules are read from the level). `--sim=1200` report.

**3. Design doc** (`docs/STRONGHOLDS_DESIGN.md`). Turns Section 1 into a buildable spec, covering:
- The four Stronghold states and the numbers.
- How walls are built (terrain or props) and how the climb works (collision, landing spots).
- How the GPU sim reads and writes data.
- The terrain-editing interface.
- How packets pick a sender when there are several.
- The return-packet path and how improved ammo arrives as packets.
- The enemy roster's stats and the mortar fairness numbers.
- The pressure cap.
- Rules for keeping state saveable.
- A list of files to split, so every file stays under 250 lines.

**The user reads and approves this before Stage 4.**

**4. GPU creeper sim.** `sim/creeper_sim.gd` is split into an interface plus `creeper_cpu.gd` and `creeper_gpu.gd` and a compute shader. `creeper_mesh.gd` samples the sim's data directly on the GPU. Check: the headless suite still passes on the CPU version; a parity test on a real display (GPU vs CPU totals after N ticks, within tolerance); a frame-time comparison on a large test grid.

**5. Terrain-editing tool.** A new file, `world/terrain_edit.gd`. Check: a smoke test raises and lowers a cell and confirms the creeper sim, mesh chunk, flow field, pathfinding and collision all update.

**6. Multiple packet senders and Outposts.** `network.gd` (shortest path from several senders), `packets.gd`, `economy.gd` (shared bank), plus a new `outpost` structure entry. Check: a smoke test shows a far structure fed from the nearer sender; demo sim.

**7. Strongholds, castles, spire climb.** New files `level/stronghold.gd`, `stronghold_meshes.gd` and `castle_shape.gd`, replacing `aether_towers.gd`. Check: smoke tests (capture, retake, wall breach); a first-person screenshot of the climb.

**7b. Castle stakes** (Opus; files: new `level/castle_raids.gd`, `stronghold.gd`, `config.gd`, level `CASTLE_RULES`, `ui/objectives.gd`/markers, new `smoke_castle_raids.gd`). Castles are prized by both sides; holding many must become a liability as the enemy strengthens.
- **Aggression** per level: `CASTLE_RULES = { aggression, held_stack, reprisal_warn, siege_interval }`. Level 1 is gentle (aggression ~0.5, long warnings); later levels push aggression above 1.
- **Reprisal raid on capture:** after `reprisal_warn` s (L1 90 s; HUD countdown, marker on the source nest), one gathered group marches on the castle. Size = (base + per_tier × tier) × aggression × (1 + held_stack × (held − 1)). This is the "big raid".
- **Recurring sieges** on each held castle; the interval shrinks with aggression and castles held, with a 45 s warning. Holding every castle late in the game should draw more raids than you can answer, so the right play is to pick the ones that are worth it.
- **Hostile castles help the enemy:** each castle the enemy holds speeds up the nests near it (and becomes an 8c build hub later), so taking a castle also weakens the enemy.
- **Prep:** the warning window is for buying castle turrets (built, see changelog), moving snipers/units, dropping a Totem and parking the Operative on the spire top (stalls a retake).
- Uses nest `tier` until 8a's `pressure` exists, then switches to it. Check: smoke (reprisal fires after the warning at the right size, stacking with held count, L1 numbers, siege interval, hostile-castle nest buff, state round-trip); `--castle` playtest screenshots.

**8a. Nest bases and enemy mortars.** Hive Core, pits, defences and growth over time. Raiders rebuild nests. Destroying the Core lets you build an Outpost. Enemy mortars appear when the Node is sealed off, with all four fairness rules. The pressure cap. Check: smoke tests; screenshot of a telegraphed shell.

**8b. Enemy roster.** Ranged attacks and projectiles; Spitter, Lancer, Warden, Spotter; mixed groups; unlocks per level. Check: smoke test of each enemy's attack; a sim report showing all tiers.

**9a. Return packets, Salvage, Ore, Miner, turrets.**
- The return-packet path back along the relays.
- Ore deposits and the Miner. Loot pickups and the castle trickle.
- Turrets and wall repair from command mode.
- Top bar shows Ore and Salvage.
- Check: smoke tests (income flows, cutting the relays stops it).

**9b. Extractors and supply points.** Built at the Node, delivered, carried (limit), planted, range check, destroyed on retake. The Supply Depot. Check: a smoke test running the full loop.

**10. Armoury.** A new static class, `fps/operative_upgrades.gd` (same pattern as `upgrades.gd`). Advanced weapons, ammo crafting, and late-unlocking improved-ammo packets for network weapons. Check: smoke tests (multipliers apply, Salvage burns, ammo is locked until the level milestone).

**11. Terp.** Terraforming with Earth (packets) and Metal (Ore), on top of the Stage 5 tool. Mortar damage differs by material. Sealing routes is allowed. Check: smoke tests; screenshot.

**12. Level placement.** Castles, nest bases, ore and Salvage deposits, ramp choke points, for Level 1 and the cave. Check: screenshots, and an undefended run shows pressure.

**13. Tuning.** Targets:
- Every ranged enemy has a counter you can afford when it unlocks.
- Little Salvage left over at the win.
- The pressure cap lands after a reasonable winning time.
- The sim report gains new fields: Salvage left, Ore mined, pressure at the win.

**14. Review and screenshots.** Code review of the core stages, then screenshots of a base assault, a castle defence, and the upgrade flow. Then a human playtest.

---

## 3. Phase B: scale and RTS (only when asked)
| Item | Model |
|---|---|
| Save and load in the middle of a level (terrain edits, creeper, structures, units, Strongholds, clock) | Opus format design, Sonnet build |
| Meta skill tree and its story framing, plus a campaign profile | Opus design, Sonnet build |
| Large-map performance: terrain level of detail, chunked flow fields, profiling | Opus |
| RTS army control: control groups, squads, rally points, unit production at Outposts | Opus design, Sonnet build |
| Phase 3 difficulty: director, reinforcements, time gates (see DEV_PLAN) | Opus design, Sonnet build |
| Flying enemies (Beam targets) | Sonnet |

## 4. Open questions
- None blocking. The Stage 3 doc will raise the detailed numbers for approval.
- Set aside: the CW3 behaviour spec (`CREEPER_SPEC.md`, prose only). Ask before doing it.

## 5. Already built (session 6, 2026-10-07)
Rebindable keys (F10). The can't-build-on-creeper rule. The full-ammo packet fix. First-pass Aether Towers (Stage 7 replaces them). First-pass nest raiders with tier escalation (Stages 2 and 8 rework them). 49/49 smoke tests pass.

## 6. Changelog
- 2026-10-07: **Castle turrets** pulled forward from 9a into 7b (Opus, ⚠ no human playtest). `castle_turrets.gd` (defs, sockets, buy/upgrade I–III with Salvage) + `castle_turret_fire.gd` (Repeater → raiders, Lobber → creeper at 60% mortar, Flak → spore volleys; creeper damage like weapons; models). 5 sockets per castle (4 wall corners, 1 beside each gate). Bought from the new **Castle tab (F5)** by clicking a socket, or with E in first person. A standing turret blocks a retake; a retake clears them. Salvage now flows: `CASTLE_SALVAGE_RATE` 0.1/s per held castle and `CASTLE_CAPTURE_SALVAGE` 30 on capture. Raiders can melee turrets. `--turrets=I` debug hook. 167 smoke checks pass.
- 2026-10-07: Playtest batch 3 (Opus). **Packets have no priority**: round robin over every requester, ammo and builds alike (was ammo first). **CW3 box select of weapons** (units first, else movable weapons); group move keeps formation, hold fire/supply/recycle apply to all; amber group rings on the terrain shader (`sels`). **Units can't walk through structures** (`Pathfind` `solid` + `UnitManager._move`; string-pulling samples every crossed cell). Units restock at the **nearest stocked barracks** (`Unit.depot`); the Barracks panel can select its units or all units (U). **First-person building** (`fps/operative_build.gd`, B): tab/slot keys as in command mode, crosshair ghost, normal placement rules. **Nullifier** range scales with Forge Fire Range (`WeaponLogic.nullify_range`) and it soaks creeper HP while unbuilt (`soaks_unbuilt`); Level 1 emitters 4.0 → 3.0 per pulse. Raiders blocked on the way to a target follow the flow field for `RAIDER_DETOUR_TIME` (Bastion garrison stuck at its gate). `emitter_ring` in the sim report. 159 smoke checks pass.
- 2026-10-07: Castle fixes (Opus). The rifle now hits a target when the muzzle is inside it (it missed the crown point-blank). The crown nest is solid (`CROWN_RADIUS` 1.2) and has 40 HP (was 60). **The courtyard of a castle you hold is buildable** (`Grid.yard`, unblocked in `StrongholdRules.sync_grid`), so a relay there links the castle to the network. Hostile courtyards and castle stone say why they can't be built on. A retake destroys what you built in the courtyard (`Strongholds.on_lost`). `smoke_castle_build.gd`.
- 2026-10-07: Playtest fixes (Opus). Operative is pushed out of walls it sank into in the air (stuck in an inside corner after the spire jump pad). Raiders no longer cut diagonals past cliff corners (they stopped at walls) or stand on the sloped foot of tall walls (they hung on the moat wall). Structures that die on contact now die at any visible creeper (`MIN_DEPTH`, was `DAMAGE_DEPTH`): an unbuilt mortar survived a thin film. Darker claimed-ground tint. F8 `test_recall`: instant recall, no cooldown (testing). New `smoke_traps.gd` (no pits on the map, inside-corner push-out). 146/146 smoke. Planned 7b (castle stakes, Opus) and 7c (traversal, Grok).
- 2026-10-07: Stage 7 done (Opus, ⚠ no human playtest). Castles replace Aether Towers: `CastleShape`/`SpireShape` cut ground and raised (plateau + drawbridge) variants with moats, 2-wide stone walls with corner stairs, faction gates, pillar climb routes and a 7x7 obsidian spire (16-step ramp + jump pad, top 20 levels up). `Strongholds` runs hostile → capturing → held → siege with garrisons, counterattacks, Aether income, breaches through `TerrainEdit`, gate/winch damage and the spire pump (moat creeper → `pump.material` for 8c). `Grid.deck`/`stand_y` for drawbridges. Level 1 gets Ashmoat Keep (ground, moat, SW) and High Bastion (raised, N); cave towers removed. 40 new smoke checks incl. a scripted first-person pillar climb and jump pad (118/118). Decisions: creeper ignores gates/decks; a dead winch opens the bridge to everyone; walls are raider prey only where raiders can stand (no moat, not raised); counterattack size uses nest tier until 8a's pressure; Salvage trickle, turrets and wall repair wait for 9a.
- 2026-10-07: Stage 5 done (Grok; merged in session 7, exercised by Stage 7). `TerrainEdit` + `World.terrain_changed`, chunked terrain (`TerrainChunks`, 2 rebuilds/frame), `Grid.step_ok` with faction gates shared by raiders, units and the Operative, `base_height`, materials. 18 new smoke checks (`smoke_terrain.gd`). GPU parity now includes a mid-run ring wall and fails if the height upload is skipped. `--raise=x,z,r,by` debug hook.
- 2026-10-07: Split `command_mode.gd` (247 lines) into `command_input.gd`, `command_select.gd` and `command_hover.gd`. No behaviour change. `CommandMode` stays the entry class.
- 2026-10-07: Stage 6 ⚠. Packets launch from the nearest sender (Command Node or Outpost). Outposts cost 40, add `OUTPOST_STORAGE` 50 to the shared bank, and produce nothing. A flying Node no longer stops packets while an Outpost is up.
- 2026-10-07: Stage 10b ⚠. Totems (beacon id), `@drop` pods, recall cooldown from the walk path, and paid respawn. Smoke in `smoke_deploy.gd`. Opus review on merge: `@drop` ported into the split command files; the recall path now uses `Grid.step_ok` (gates, decks); recalling from the cave measures from the Rift.
- 2026-10-07: §0 answered. Added: castle variants (ground / raised with drawbridge and moat), wall platforming, tall indestructible spires with a creeper pump, enemy construction (§4.5), Operative deployment rework (§5.4), Ctrl + wheel ammo. New Stages 8c and 10b.
- 2026-10-07: Stage 4 done. GPU creeper sim (creeper_gpu.gd + creeper_flow.glsl) with CPU fallback. Parity PASS (300 ticks, max cell diff < 0.00001). Perf on the RTX 5090: 80x80 0.55 → 0.027 ms/tick, 512x512 12.3 → 0.055 ms/tick. Live and fast-forward runs match the CPU build.
- 2026-10-07: Stage 3 design doc written (docs/STRONGHOLDS_DESIGN.md). Its §0 lists 10 decisions for the user to approve.
- 2026-10-07: Plan created from the design conversation. Old corrections that were never built are folded into Stages 1 and 2.
- 2026-10-07: Stage 1 ⚠. Built `weapon` structures take creeper HP damage; a weapon with `charge > 0` takes none. New `WEAPON_CREEPER_BASE_DPS` 5.5 / `WEAPON_CREEPER_DPS` 2.5: a 40 HP cannon lasts 5 s at depth 1, about 3 s at depth 3. (Opus review: the Node keeps `STRUCT_*` 6/14; Grok's first version had changed those too.)
- 2026-10-07: Stage 2 done headless (⚠, no human playtest). Beams are surface-to-air and burn flying enemies, mortar splash deals `MORTAR_RAIDER_DMG`, raiders step one terrace, and raid timing comes from each level's `RAID_SCHEDULE`.
