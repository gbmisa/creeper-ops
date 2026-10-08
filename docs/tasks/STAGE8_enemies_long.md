# Stage 8 (long, overnight): Enemy roster, hives and enemy mortars

**Agent:** Grok Build, one long unattended session. **Worktree:** `creeper fps td-worktrees/stage8` · **Branch:** `stage/8-enemies`
This brief covers MASTER_PLAN Stages **8b** (roster) then **8a** (hives + enemy mortars). The design is settled in [docs/STRONGHOLDS_DESIGN.md](../STRONGHOLDS_DESIGN.md) **§3.3, §4.1, §4.2, §4.3**. Read those sections first: they are the spec. Numbers there win over anything you'd invent. Don't start 8c (enemy construction), 9a (Ore/return packets) or §4.4 loot pickups.

Other agents run at the same time. **Stay out of:** `scripts/ui/*` except the one line in `top_bar.gd` named below, `scripts/command/*`, `scripts/fps/*` except the damage hook named in Phase 7, `shaders/creeper.gdshader`, `shaders/*.gdshaderinc`, `world/terrain_mesh.gd`, `level/castle_*.gd` (except `castle_raids.gd` reading the new roster), and the terrain/ramp code in `level01.gd`'s `build()`.

## How to work through the night
- Do the phases **in order**. Each phase ends **playable**: parse check clean, full smoke all PASS, then **commit** with message `Stage 8 Pn: ...`.
- Keep a running log in `docs/tasks/STAGE8_progress.md`: per phase, what you did, test output (pass count, sim lines), decisions you took where the spec was silent, and anything left unfinished. Update it **before** each commit. If the session dies, this file is how Opus resumes.
- If a phase is blocked after a real attempt (about 3 tries at the same problem), write down exactly what blocks it in the progress log, `git stash` or revert the half-done part so the branch stays green, and **continue with the next phase that doesn't depend on it**. Don't stop the whole night on one problem.
- Every file under ~250 lines: split by responsibility before it gets close. New tunables go in `config.gd` or the def tables, never inline. New `class_name` files: run `godot --headless --path godot --import`.
- New smoke checks go in new files `core/smoke_roster.gd`, `core/smoke_hives.gd` and `core/smoke_enemy_mortar.gd`, each registered with one line in `smoke_test.gd`.
- Visual check each phase that adds something visible: an Xvfb screenshot (CLAUDE.md Testing §5). Add a `--gallery` row or a debug hook if you need one (in `debug.gd`, documented in its header comment).

## Phase 0: baseline (no code)
Record into the progress log the current results on `main` code: full smoke count; `--demo --units --sim=900`, `--autostart --sim=900`, `--level=2 --autostart --sim=900` and `--level=2 --demo --sim=900` `[sim]` lines (Node HP, raider counts, when the Node died).

## Phase 1: Pressure (§4.1)
- New static `level/pressure.gd` (`class_name Pressure`): `value(level, t)` from the level's `"pressure": { grace, cap }` and optional `"pressure_points"` (piecewise linear). Add `PRESSURE` data to `level01.gd` and `level02.gd` (pick grace/cap so the **current** tier unlock times roughly hold: L1 Brute ~8 min, Ravager ~15, Behemoth ~22; say what you chose).
- Nest spawn interval `lerp(20, 5)` and cap `lerp(3, 10)` read pressure instead of minutes. Keep the existing `RAID_SCHEDULE` raid **start** times.
- Overrun at pressure 1: every 45 s each active nest sends `6 + tier × 2` straight at the Node.
- HUD: change only the `threat` text in `ui/top_bar.gd` to also show `Pressure NN%` (one-line change; 18c edits other UI files).
- Smoke: pressure 0 before grace, 1 at cap, monotonic; spawn interval/cap at 0 and 1; overrun fires.

## Phase 2: Roster table (§4.2)
- New `level/raider_defs.gd` (`class_name RaiderDefs`): one row per enemy in §4.2 (hp, speed, attack, range, unlock pressure, loot, size, colour, role front/ranged/support). Replace `Config.RAIDER_TIERS` with it **everywhere** (callers: `raiders.gd`, `spore_nests.gd`, `castle_raids.gd`, `stronghold.gd`, `top_bar.gd`, `gallery.gd`, `debug.gd`, smoke files). Keep Skitter/Brute/Ravager/Behemoth stats exactly as today.
- Spawning picks from the enemies unlocked at the current pressure (weighted toward the newest unlocks; say how).
- `raider_meshes.gd`: a distinct silhouette per new enemy (Spitter, Lancer, Warden, Spotter, Burrower), same Blight art style as Stage 15. If `raider_meshes.gd` would pass 250 lines, split it (e.g. `raider_meshes_ranged.gd`).
- Smoke: every row spawns; unlocks follow pressure; the old four keep their stats.

## Phase 3: Ranged attackers: Spitter and Lancer
- Ranged enemies stop when the target is in range and keep their distance (§4.2). Shots are **visible projectiles with travel time** that can be dodged (look at how castle Sentinel bolts work in `castle_guards.gd` and reuse that pattern; don't edit that file, copy the approach into a new `level/raider_shots.gd`).
- Spitter: acid lob, 6 damage / 2 s, small splash, range 20. Lancer: 1.5 s charge (visible), 25 damage, range 32, **targets Snipers first**, then other weapons. Both hit structures, units, the Operative, castle turrets. Use the same prey dictionaries as melee raiders (CLAUDE.md agent dictionaries).
- Smoke: a Spitter in range damages a cannon; a Lancer picks a Sniper over a nearer cannon; a projectile in flight can miss a target that moved.

## Phase 4: Warden and Burrower
- Warden: allies within 5 cells take −50% damage (one aura, not stacking). Show a faint ring under it (a mesh disc on the raider is fine here; it's a unit, not ground overlay).
- Burrower: moves underground ignoring terrain and walls (straight line or a simple grid path that ignores `step_ok`), shows a dust trail, surfaces next to the nearest **weapon**, can only be hit while surfacing (1.5 s), bursts for 60 in 1.5 cells.
- Smoke: Warden halves damage; Burrower reaches a weapon behind a cliff and its burst damages it; it can't be hit while underground.

## Phase 5: Mixed groups
- From pressure 0.35 each raid rolls roles 50% front / 35% ranged / 15% support, gathers 10 s at the nest, then moves together at the slowest member's speed (§4.2). Castle reprisals (`castle_raids.gd`) use the same group builder.
- Smoke: a raid of 20 at pressure 0.5 has roughly those shares and moves as one group.
- Sim: `--autostart --sim=1800` and `--level=2 --autostart --sim=1800`; log every enemy type seen in the progress log.

## Phase 6: Hives (§3.3)
- `level/hive_shape.gd` (berm ring with gaps, Blight inside), `level/hives.gd` (state per hive as a plain dict: active / razed / outpost, stage from pressure, parts at slots, 20 s grow-in, rebuilding by raiders), `level/hive_parts.gd` (Core, pit, spitter turret, spore launcher; HP/behaviour from §3.3), meshes in a new `level/hive_meshes.gd`.
- Rename/fold today's `spore_nests.gd` into the hive's spawner part as §3.3 says (`hive_spawning.gd`), keeping the escalation behaviour. Level `nests` rows become `hives`; convert L1 and L2. The Core is hit only by the Operative and the Lance. Core death: razed, Blight clears, 40 Salvage.
- Outpost on a razed Core cell → `outpost` state. The spec's Ore cost waits for 9a: charge energy only and note it in the progress log.
- Keep the existing objective "Destroy all Spore Nests (optional)" working (it now means "raze all hives").
- Smoke: growth stages appear at the right pressure; killing pits slows spawns; Core immune to cannons; raze → Blight clears; rebuild by 3 raiders in 30 s; a player structure within 4 cells blocks the rebuild; state round-trips.

## Phase 7: Enemy mortars + Spotter (§4.3)
- `level/enemy_mortar.gd` (+ meshes): range 36, min 6, every 6 s, blast 2.5 cells; structure 30 / unit 20 / Operative 70% max HP at centre, falling off; Earth −1 level at the 3×3 impact via **`TerrainEdit` only**, never below `grid.base_height`; Spire cells skipped.
- **All four fairness rules:** launch thump, a growing red ground ring for `MORTAR_TELEGRAPH` 2.5 s with a whistle in the last 1 s; minimum range; targets the Operative only while a Spotter has line of sight (`grid.raycast`, 25 m), HUD "SPOTTED" (one label: add it in `fps/` HUD code only if there's an existing alert hook; otherwise use `Bus.say` and note it); Operative sabotage: hold E for 3 s within 2 m → destroyed + 5 Salvage (an interactable dict).
- The ring is a **terrain shader uniform** (`terrain.gdshader`; add a small `uniform vec4 shells[8]` block next to the existing rings, never a quad). Don't touch `terrain_look.gdshaderinc`.
- When built: hive stage ≥ 3 builds one; any active hive builds one within 60 s after the Node has had no raider route for 60 s (`RaiderField.reachable`); max 1 per hive, 2 at stage 4; each mortar comes with a Spotter that respawns 30 s after dying.
- Operative damage: use the existing Operative damage path (grep how raiders/Sentinels hurt the Operative) rather than changing `fps/*` logic.
- Smoke: min range respected; Operative untargeted without a Spotter in sight, targeted with one; Earth lowered but never below `base_height`; sabotage works; the sealed-Node rule builds one.
- Screenshot: a telegraphed shell ring on the ground (command view) and the mortar model.

## Phase 8: Balance pass and wrap-up
- Re-run the Phase 0 sims and put before/after side by side. Targets: L1 demo Node still survives 900 s; L1 undefended Node dies **sooner** than baseline but not before 200 s; L2 demo doesn't die before baseline − 120 s. Tune only `config.gd` / `raider_defs.gd` / level `PRESSURE` data to hit them.
- Update `docs/STRONGHOLDS_DESIGN.md` with "*As built (Stage 8):*" notes where you deviated. In MASTER_PLAN.md set 8a and 8b to ⚠ and add one Changelog line. Don't edit HANDOFF.md or CLAUDE.md (Opus updates the architecture map on merge; list the new files in your report).

## Report (AGENTS.md)
Per phase: done / partial / skipped, commits, test counts, sim before/after, screenshot paths, every spec gap you filled and how. Say "committed on branch stage/8-enemies". Never merge.
