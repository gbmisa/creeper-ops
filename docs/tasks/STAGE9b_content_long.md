# Stage 9b + 10b-ammo + 12 + 13 (long): extractors, improved ammo, level placement, tuning

**Agent:** Grok Build, one long unattended session. **Worktree:** `creeper fps td-worktrees/stage9b` · **Branch:** `stage/9b-content` · **Progress log:** `docs/tasks/STAGE9b_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) first. Spec: [STRONGHOLDS_DESIGN.md](../STRONGHOLDS_DESIGN.md) **§2, §5.1, §5.3**, MASTER_PLAN Stages **9b, 12, 13**. Main already has 9a (return packets, Ore veins, Miner, Outpost Ore cost), 8c (Weavers), loot pickups and SPOTTED.
Runs alongside Stage 19 (flyers) and Stage 20 (art). **Stay out of** `level/flyer*`, `*_meshes.gd` visual tweaks (new structures get their models in a new `command/economy_meshes.gd`), `shaders/*`, `world/effects.gd`.

## Phases
**P0 baseline.** Smoke count; `--demo --units --sim=900`, `--autostart --sim=900`, `--level=2 --demo --sim=900`, `--level=2 --autostart --sim=900` `[sim]` lines.

**P1 Supply Depot + ordering extractors (§5.1).** New structure `depot` (12 packets, relays, holds 4 extractors; def row + menu tab + model). Supply points: Node, held castle keeps, Outposts, Depots. Selecting one shows "Order Extractor" (info panel button + a rebindable action) which becomes a 10-packet build job there, stock up to 4. Smoke `core/smoke_extractors.gd`.

**P2 Carry + plant (§5.1).** E within 3 m of a supply point takes extractors (carry 2; raise via `OperativeUpgrades` if a carry upgrade row exists, else add one row); FPS HUD `Extractors 1/2`. Hold E 3 s on a Salvage deposit to plant: a player structure that links as a network leaf, ships Salvage return packets while connected (use 9a's return-packet path), stores up to 15 otherwise; inside an *active* hive it plants but ships nothing until the hive is razed. Destroyed on castle retake if it's in that castle. Smoke: the full loop order → deliver → carry → plant → Salvage arrives at the Node.

**P3 Improved ammo (§5.3).** AP / Incendiary / Cluster grades; `ammo_next` / `ammo_prev` actions on **Ctrl + mouse wheel** (extend `keybinds.gd` for wheel + modifier without renaming any existing action and without touching `user://keybinds.cfg`); level `"ammo_unlock": "<objective id>"` (L1: when the Deep Core objective becomes available; L2: pick one and log it); Operative, Snipers, Repeater turrets and units, with the Salvage surcharges. Smoke: locked before the milestone; AP ignores the Warden shield; incendiary removes creeper at the impact cell; surcharge charged per packet; keybind defaults don't collide.

**P4 Level placement (Stage 12).** For **L1, L2 and the cave**: Salvage deposits (some safe, most inside or beside hives and castles so planting is a risk/reward choice), Ore veins sanity check (9a placed them: verify reachability), a Supply-Depot-friendly spot per front, and ramp choke points (use `LevelRamps`; never add decorative height noise; whole levels only). Keep every existing smoke (landing hint valid, traversal targets from 7c). Screenshots: whole-map `--look=x,z,120` per level with deposits visible.

**P5 Sim report fields (Stage 13).** Add to the `[sim]` report: `salvage_left`, `salvage_earned`, `ore_mined`, `pressure`, `extractors_planted`, `win_time` (when objectives complete). Teach the scripted demo (`DEMO_BUILD` / `--demo`) to order and plant one extractor so the loop is exercised in sims (document it in `debug.gd`'s header).

**P6 Tuning (Stage 13 targets).** Targets, each with numbers in the log:
- Every ranged enemy has a counter the player can afford when it unlocks (show Salvage/energy available at each unlock time in the L1 demo).
- Little Salvage left over at a win (demo end: spendable ≤ 20% of earned).
- Pressure cap lands after a reasonable winning time (L1 cap later than the demo's objective completion).
- L1 demo Node survives 900 s; L1 undefended dies between 200 s and its P0 time; L2 demo not earlier than P0 − 60 s.
Tune only `config.gd`, def tables, level data. Never change Stage 17 CW3 creeper rules (`docs/CREEPER_SPEC.md`).
- **The Spitter stays at spec (HP 10, range 20): the user chose that.** Today the L1 demo loses the Node at ~603 s because its Snipers shoot nearer Skitters while Spitters shell from 20 cells. Fix that on the *player* side: a Sniper target priority that prefers ranged enemies in range (log it as a rule change), and/or a better scripted `DEMO_BUILD`. Don't weaken the Spitter.

**Wrap-up.** MASTER_PLAN: 9b, 12, 13 status cells ⚠; 10 cell notes "ammo done"; one Changelog line.
