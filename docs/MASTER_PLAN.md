# Master Plan: Strongholds, Salvage and Scale

The living plan. **Update this file at the end of every stage:** tick the box, set the status, add a line to the Changelog, and move any new decisions into Settled Design. It replaces the Roadmap in [DEV_PLAN.md](DEV_PLAN.md). That file's model-routing guide still applies.

**Status (2026-10-08):** everything through Stage 18 and Stage 8 (8a + 8b) is merged to `main` (⚠ = not human-verified). Open: 8c enemy construction, 9a/9b economy, 12 level placement, 13 tuning, 14 review. Waiting on the user: a playtest of the merged build and the Spitter decision (see HANDOFF).
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
| 7b | **Castle stakes:** reprisal raid on capture, recurring sieges, aggression that stacks with castles held, hostile castles buff nests, prep window. **Castle turrets pulled in (done ⚠)** | **Opus 5.5** | ⚠ done, verified headless + screenshot |
| 7c | Traversable terrain on Level 1 (stairs, no isolated shelves) | Sonnet 5.5 (Grok), Opus review | ⚠ merged 2026-10-08 (Grok, Opus review) |
| 8a | Nest bases and enemy mortars | Grok Build (long run with 8b) | ⚠ merged 2026-10-08 (Grok long run; Spitter retuned to melee range: needs user call) |
| 8b | Enemy roster (incl. Burrower, Weaver) | Grok Build (long run, before 8a) | ⚠ merged 2026-10-08 (Grok long run) |
| 8c | **Enemy construction:** hubs in enemy castles, Weavers, Leeches, build planner, enemy structures (design §4.5) | Sonnet 5.5, Opus review | ⚠ |
| 9a | Return packets, Salvage, Ore, Miner, turrets | Sonnet 5.5 | ☐ |
| 9b | Extractors and supply points | Sonnet 5.5 | ☐ |
| 10 | Armoury (incl. Ctrl + wheel ammo switching). **10a** = upgrades + advanced weapons; 10b-ammo later | Sonnet 5.5 (Grok) | ⚠ merged 2026-10-08 (Grok, Opus review) |
| 10b | **Operative deployment:** Totems, drop anywhere, recall cooldown, Shield Domes block drops, expensive respawn (design §5.4) | Sonnet 5.5 (Grok), Opus review | ⚠ merged, verified headless |
| 11 | Terp. **11a** = Earth only; Metal (11b) after 9a's Ore | Sonnet 5.5 (Grok) | ⚠ merged 2026-10-08 (Grok, Opus review) |
| 15 | **Fantasy art pass:** structures redesigned, weapons on jointed arms, soldiers at Operative height, structures taller than the Operative, Blight enemies, castle decor, dusk lighting. Judged by an art-judge agent each round | Opus 5.5 subagent + Opus judge | ⚠ round 4 on `stage/15-fantasy-art` (awaiting judge); brief: [tasks/STAGE15_fantasy_art.md](tasks/STAGE15_fantasy_art.md) |
| 17 | **CW3 fidelity** ([CREEPER_SPEC.md](CREEPER_SPEC.md), gaps: [CW3_FIDELITY_GAPS.md](CW3_FIDELITY_GAPS.md)): 30 Hz clamped edge flow, top-up emitters with `start`, flat wet damage by `wet_time`, progress loss for unbuilt sites, slow heal, `CreeperStrike` area removal, CW3 weapon ranges/costs, roaming Thor | **Opus 5.5** | ⚠ verified headless + GPU parity |
| 16 | **Level 2 "The Crown Marches":** 160x160, five castles with towers/gatehouses, ranged Sentinel guards from t=0, harder schedule, level select | Sonnet 5.5 subagent, Opus review | ⚠ done headless, branch stage/16-level02; brief: [tasks/STAGE16_level02.md](tasks/STAGE16_level02.md) |
| 18a | **Visual pass 1 + drag-build:** per-pixel ground (grass, rock strata, castle ashlar, Blight cracks, bump), glossy deep-navy creeper; drag a tool to lay Collector/Relay chains at max link or rows of other structures | **Opus 5.5** | ⚠ on main, smoke 235/235, Xvfb screenshots only |
| 18b | **First-person visuals:** crossbow/sprayer/launcher models, sky with sun disc + clouds, aerial haze, SSAO | Grok Build | ⚠ merged 2026-10-08 (Grok, Opus review) |
| 18c | **HUD declutter:** compact objectives (J expands), fading 5-line log, smaller fading banner, "Crossbow" label | Grok Build | ⚠ merged 2026-10-08 (Grok, Opus review) |
| 18d | **Drag-build polish:** ghosts per piece, field outlines, cost line, Operative drag-build, smoke | Grok Build | ⚠ merged 2026-10-08 (Grok, Opus review) |
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
- 2026-10-08: Stage 8c enemy construction (⚠, branch stage/8c-enemy-construction). Enemy castles send Weavers and raise shields, spitters, pylons, lancers, leeches, pumps, and seal mortars (design §4.5). Smoke 410/410. L1 `--demo --units --sim=900` Node 500/500.
- 2026-10-08: Opus merged 7c, 11a, 10a, 18b, 18c, 18d and Stage 8 (8b roster + 8a hives/mortars, 8 phases, log in tasks/STAGE8_progress.md). Smoke 382/382 x3. Merge fixes: raider separation can't add speed (groups march together), Armoury weapons show the crossbow model, Lancer smoke isolated from leftover raiders, command view uses 1/4 fog (18b haze washed the map out). Sims: L1 demo 900 s Node 500; L1 undefended dies 336 s; L2 undefended 226 s; L2 demo 652 s.
- 2026-10-07: Stage 11a Terp (Earth only, ⚠): paint a target level; a Terp spends 4 packets and 3s per level via TerrainEdit. Metal, mortar-by-material, and the seal warning wait for 11b.
- 2026-10-07: Long overnight brief for Grok: Stage 8 (8b roster, then 8a hives + enemy mortars) in 8 committed phases with a progress log.
- 2026-10-07: Stage 18a ⚠ (Opus). Terrain look + creeper surface shaders, DragBuild (chains/rows). Briefs out for Grok: 18b FPS visuals, 18c HUD, 18d drag-build polish, and SYNC (merge main into 7c/10a/11a).
- 2026-10-07: Merged Stages 15, 16, 17 to `main` (Opus). Integration: Level 2 emitters retuned as CW3 bursts (4/4/6 every 0.5 s, delayed 5s at 300/600 s; vents every 1 s), Nullifier text "within 10 cells", Level 2 terrain towers crowned (battlements, flagpoles, banners; no roof, Sentinels stand there). User requests: **held castles launch packets** (`CastleKeeps`, `keep` def), **a flying Command Node keeps its network connected** (no launches until it lands), **raiders ignore prey they can't walk to** (walking areas in `RaiderField`, 14 ms relabel on 160x160 after a terrain/gate change). Sniper stays at 5 packets/shot (user: build reactors). New `smoke_keeps.gd`; 235 smoke checks.
- 2026-10-07: **Stage 17 CW3 fidelity** (Opus, ⚠ no human playtest). Sim: 30 ticks/s, each east/south edge moves 0.04 × head difference clamped to 0.04 × the giver's depth (CPU + `creeper_flow.glsl`, parity exact), films < 0.001 evaporate. Emitters raise their cell to `amount` (`CreeperSim.raise`, GPU delta mode 2) every `interval` from `start`. Contact: Node and weapons lose max HP / `wet_time` per s whatever the depth (cannon 12 s, mortar 16, beam 1.6, Bertha 160, Nullifier 8, Node 90); unbuilt ones lose progress (`s.lost`) and request nothing; everything else dies on contact; dry structures heal over `HEAL_TIME` 50 s. Weapons (`CreeperStrike`): cannon 12 hits of 1 depth over r 6, range 9; mortar 3.5 on every wet cell in r 4, range 13; Bertha 100 over r 10, no range limit (min 5), 150/shell; sniper range 20, 5 packets/shot; beam range 23; Nullifier r 10, 2 s charge. **Thor** (`roams`) fires from its magazine off-network and in flight. L1 emitters/vents now burst every 0.5/1.0 s and the cave core tops up to a rising depth (coverage matches the old tuning). 192 smoke checks. Known: snipers run the bank dry against big raids at 5 packets/shot (demo 900 s: 2 snipers + 1 mortar dry).
- 2026-10-07: Stage 16 ⚠ (branch stage/16-level02). Level 2 "The Crown Marches" (160x160, 5 castles with towers/gatehouses/keep, `levels.gd` + `--level=N` + briefing buttons) and `CastleGuards` Sentinels (range 32, charge 0.8 s, slow arcing bolts, line of sight, cleared on capture). Not playtested; emitter output needs a retune after the CW3 sim stage.
- 2026-10-07: Stage 15 round 4 ⚠ (judge round 3: 4.125, all ≥ 4). Ravager gets a broad bone-plated carapace with green back pustules (ranks between Brute and Behemoth from the command camera); mortar cradle arms reach past the bowl rim, core dimmed. Screenshots in docs/art/round_4/.
- 2026-10-07: Stage 15 round 3 ⚠ (judge round 2: REVISE 3.75). Upright 2.4 m Sentinel with a side-held spine-bow (fixed design height), green glow and bone/fungal lumps on every raider tier (`ShapeKit.taper/horn`), matte egg-sac crown nest with curved ribs, raised mortar cradle with verdigris trim, obsidian spire ribs/shards/veins, dim gate trim, decor stone matched to the graded walls, deeper big crystals, soldier cloak and shield. `--look` takes an optional pitch. Screenshots in docs/art/round_3/.
- 2026-10-07: Stage 15 round 2 ⚠ (judge round 1: REVISE 3.1). Small weapons rebuilt with 0.25 m+ jointed arms and distinct heads (bombard, mortar bowl, lens ring, ballista; heads may overhang the cell above 2.5 m). Glow energy capped (`StructureMeshes.GLOW_CAP`). Arbalest viewmodel, wooden portcullis/drawbridge with faction trim, obsidian spire with stone bands, stone Outpost, Blight rift/core/pylon/crown nest, rune jump pad, rougher raiders with green fungal glow, 2.4 m Sentinel, bigger banners, softer dusk shadows. Screenshots in docs/art/round_2/.
- 2026-10-07: Stage 15 round 1 ⚠ (art only, no rule changes). `structure_meshes.gd` split into kit + `weapon_meshes`/`titan_meshes`/`support_meshes`, cached materials, `ShapeKit` (lathe, strut, arch, banner). Weapons are stone towers → bronze yaw ring → jointed `Arm` (pitched visually in `WeaponLogic._aim`) → head with a `Muzzle` (shot effects start there; rule origin unchanged). Terp mesh added (no def yet). Soldiers 1.8 m, Blight raiders per tier + Sentinel (`RaiderMeshes`), castle towers/gatehouse/faction banners (`CastleDecor`), dusk light, terrain grade. `--gallery[=fps]` hook. Screenshots in docs/art/round_1/.
- 2026-10-07: Briefs for Stage 15 (fantasy art, with a judge rubric) and Stage 16 (Level 2, large map, real castles, ranged guards). Both run as Claude subagents in worktrees `stage15`/`stage16` beside the Grok stages.
- 2026-10-07: **Stage 7b done** (Opus, ⚠ no human playtest). New `level/castle_raids.gd` (`CastleRaids`) watches castle states: taking a castle starts a reprisal countdown (L1 90 s), then the nest nearest it sends one group with mission "castle"; every held castle then draws a siege each `interval()` with a 45 s warning. Size = (base + per_tier × tier) × aggression × (1 + held_stack × (held − 1)); the interval divides by the same factor (min `CASTLE_SIEGE_MIN` 90 s). Hostile castles speed up nests within 30 cells (`nest.rate`, read by `SporeNests`). Rules: `Config.CASTLE_RULES` merged with the level's `CASTLE_RULES` (L1: aggression 0.5, reprisal_warn 90, nest_buff 0.15). State in `c.raid` (saved with `Strongholds.state()`). Markers: countdown over the castle, "Gathering" over the source nest. `--raid=I[,S]` hook; `castle_raids` in the sim report. Also: the Nullifier moved to the Weapons tab. 182 smoke checks pass.
- 2026-10-07: Briefs for 10a (Armoury: upgrades + advanced weapons) and 11a (Terp, Earth only) so three Grok agents run beside 7b. Improved ammo, Pack and Metal wait for 8b/9a.
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
