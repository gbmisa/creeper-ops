# Stage 9b + 10b-ammo + 12 + 13 (long): Salvage Engines, improved ammo, level placement, tuning

**Agent:** Grok Build, one long unattended session. **Worktree:** `creeper fps td-worktrees/stage9b` · **Branch:** `stage/9b-content` · **Progress log:** `docs/tasks/STAGE9b_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) first. Spec: **the Salvage Engine design below (replaces §5.1 extractors and the Supply Depot; the user asked for objects the Operative hooks into from first person)**, [STRONGHOLDS_DESIGN.md](../STRONGHOLDS_DESIGN.md) **§2, §5.3**, MASTER_PLAN Stages **9b, 12, 13**. Main already has 9a (return packets, Ore veins, Miner, Outpost Ore cost), 8c (Weavers), loot pickups and SPOTTED.
Runs alongside Stage 19 (flyers) and Stage 20 (art). **Stay out of** `level/flyer*`, `level/castle_*.gd`, `level/stronghold*.gd` (Opus is reworking castles: Stage 21), `*_meshes.gd` visual tweaks (new structures get their models in a new `command/economy_meshes.gd`), `shaders/*`, `world/effects.gd`.

## Phases
**P0 baseline.** Smoke count; `--demo --units --sim=900`, `--autostart --sim=900`, `--level=2 --demo --sim=900`, `--level=2 --autostart --sim=900` `[sim]` lines.

## Salvage Engines (Opus design, settled; numbers are starting points for P6)
- **What:** big ancient machines and wrecks placed in level data (`ENGINES`: `{ id, x, z, kind, sockets, reserve }`). Kinds: `wreck` (fallen titan, 2 sockets), `bore` (buried drill head, 1 socket), `forge` (ruined engine, 3 sockets). Footprint 3x3 to 5x5 cells, solid to walkers, never buildable.
- **Hook sockets:** glowing points *on the object* at different heights. At least one socket per multi-socket engine sits on top or on a ledge of the machine, so the Operative has to climb/jump (the model's top is walkable: stamp the footprint as a raised `Grid` block or add stand surfaces so `Grid.stand_y` works; say which).
- **Hooking (first person only):** within 1.5 m of a socket, hold E for `ENGINE_HOOK_TIME` 2.5 s. A cable visibly shoots from the gauntlet into the socket and then runs from the socket to the nearest connected relaying structure. Requires a connected relaying structure within `ENGINE_LINK` 8 cells of the engine; otherwise the prompt says "No network in reach: build a Relay within 8 cells". Command mode can't hook (Operative-only objective action rule).
- **Shipping:** a hooked engine is a network leaf that launches Salvage **return packets** (9a's path) at `ENGINE_RATE` 1 Salvage per 6 s **per hooked socket**, from a finite `reserve` (e.g. wreck 120, bore 60, forge 250). Visible: sockets glow and a slow pulse runs down the cable; reserve shown on its marker/info panel. Depleted engines go dark.
- **Threats:** creeper over the engine pauses it (wet). Raiders and Weavers treat hooked sockets as prey (`clamp` HP 30 each): a cut socket unhooks and the Operative must go back. An engine inside an *active* hive can be hooked but ships nothing until the hive is razed (high risk, high reserve). An engine inside a castle ships only while the castle is held.
- **Markers:** minor markers "Salvage Engine 1/3 hooked, 85 left"; an unhooked engine near the network gets a brief hint once.

**P1 Engines exist.** `level/salvage_engines.gd` (state as plain dicts with `state()`/`load_state()`), models in a new `level/engine_meshes.gd` (rusted bronze and stone machine parts, glowing sockets, cable), level data for **L1 and L2** (2-4 per level to start). Debug hook `--engine=I` drops the Operative beside engine I. Smoke `core/smoke_engines.gd`: engines block walkers; the top socket is reachable by jumping (simulate the controller or test `stand_y`); hook prompt refuses without a relay in reach.

**P2 Hook + ship.** Hold-E hooking with the cable visuals, return packets per socket, reserve depletion, wet pause, clamps that raiders/Weavers cut, hive/castle rules above. Smoke: hook → Salvage arrives at the Node; two sockets ship twice as fast; a raider cuts a clamp and shipping drops; wet engine pauses; hive engine ships nothing until razed. Screenshots: first-person at a socket mid-hook; command view with a hooked engine and its cable.

**P3 Improved ammo (§5.3).** AP / Incendiary / Cluster grades; `ammo_next` / `ammo_prev` actions on **Ctrl + mouse wheel** (extend `keybinds.gd` for wheel + modifier without renaming any existing action and without touching `user://keybinds.cfg`); level `"ammo_unlock": "<objective id>"` (L1: when the Deep Core objective becomes available; L2: pick one and log it); Operative, Snipers, Repeater turrets and units, with the Salvage surcharges. Smoke: locked before the milestone; AP ignores the Warden shield; incendiary removes creeper at the impact cell; surcharge charged per packet; keybind defaults don't collide.

**P4 Level placement (Stage 12).** For **L1, L2 and the cave**: Salvage Engines (some safe, most inside or beside hives and castles so hooking is a risk/reward choice; some need platforming to reach the top socket), Ore veins sanity check (9a placed them: verify reachability), the cave gets 1-2 engines, and ramp choke points (use `LevelRamps`; never add decorative height noise; whole levels only). Keep every existing smoke (landing hint valid, traversal targets from 7c). Screenshots: whole-map `--look=x,z,120` per level with deposits visible.

**P5 Sim report fields (Stage 13).** Add to the `[sim]` report: `salvage_left`, `salvage_earned`, `ore_mined`, `pressure`, `sockets_hooked`, `win_time` (when objectives complete). Teach the scripted demo (`DEMO_BUILD` / `--demo`) to hook one engine (scripted, no controller) so the loop is exercised in sims (document it in `debug.gd`'s header).

**P6 Tuning (Stage 13 targets).** Targets, each with numbers in the log:
- Every ranged enemy has a counter the player can afford when it unlocks (show Salvage/energy available at each unlock time in the L1 demo).
- Little Salvage left over at a win (demo end: spendable ≤ 20% of earned).
- Pressure cap lands after a reasonable winning time (L1 cap later than the demo's objective completion).
- L1 demo Node survives 900 s; L1 undefended dies between 200 s and its P0 time; L2 demo not earlier than P0 − 60 s.
Tune only `config.gd`, def tables, level data. Never change Stage 17 CW3 creeper rules (`docs/CREEPER_SPEC.md`).
- **The Spitter stays at spec (HP 10, range 20): the user chose that.** Today the L1 demo loses the Node at ~603 s because its Snipers shoot nearer Skitters while Spitters shell from 20 cells. Fix that on the *player* side: a Sniper target priority that prefers ranged enemies in range (log it as a rule change), and/or a better scripted `DEMO_BUILD`. Don't weaken the Spitter.

**Wrap-up.** MASTER_PLAN: 9b (note "Salvage Engines replace extractors"), 12, 13 status cells ⚠; add an "*As built (Stage 9b)*" note to STRONGHOLDS_DESIGN §5.1; 10 cell notes "ammo done"; one Changelog line.
