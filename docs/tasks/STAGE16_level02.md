# Stage 16: Level 2 "The Crown Marches" (large map, real castles, ranged guards)

Worktree `creeper fps td-worktrees/stage16`, branch `stage/16-level02`. AGENTS.md applies: do only this brief, commit on your branch, never merge.

## Goal
A second, **much larger and harder** level built around **five castles that look like castles**, each with its spire in the courtyard and **guards with long-range attacks from the first second**. Level 1 stays as it is.

## 1. Level selection (small)
- New `level/levels.gd` (`Levels`): `static func build(n: int) -> Dictionary` and `static func cave(n: int) -> Dictionary` (Level 2 may reuse `Cave01`; give it a Rift). `game.gd` calls `Levels.build(level_no)` instead of `Level01.build()`.
- `--level=2` CLI hook (`debug.gd`), and two buttons ("Level 1: Hollow Ridge", "Level 2: The Crown Marches") on the briefing screen in `game_flow.gd`. Default stays Level 1.
- **Don't edit `level01.gd`** (Stage 7c is changing it).

## 2. The map: `level/level02.gd` (copy `level01.gd`'s pattern)
- **160 x 160** cells (4x Level 1's area). Check the CPU sim, terrain chunks and raider flow field cope: report ms/tick from `--perf-sim` or the sim report, and the GPU parity run if you have a display.
- Terraces 0..10, explicit ramps, **every castle reachable on foot** from the landing area (raiders step one terrace; the Operative too, plus jump).
- **Five castles** spread over the map, a mix of ground (moat) and raised (drawbridge) variants, sizes 17–23. The richest one in the centre.
- Harder than Level 1: 4–5 emitters (some shielded by objectives), more nests, `RAID_SCHEDULE` earlier (raids ~180 s, tiers sooner), `CASTLE_RULES` aggression ~1.0–1.2, shorter reprisal warnings (~60 s). Write an `intro` that tells the player about the guards.
- If `level02.gd` passes ~250 lines, put shaping helpers into `level/level_shape.gd` (shared static helpers; level01 can adopt them later).

## 3. Castles that look like castles: `castle_shape.gd` (opt-in row keys, Level 1 unchanged)
Walls are terrain; keep it that way. Add, behind row keys so Level 1 castles don't change:
- `"towers": true`: round-ish (or 3x3) **corner towers** rising 2 levels above the wall top, with stairs or a ladder route from the wall walk.
- `"gatehouse": true`: two towers flanking each gate.
- `"keep": true` (optional): an inner wall ring around the spire base.
- Expose the new cells in the layout (`lay.towers`: list of `{ cells, top }`) so the art stage can crown them with roofs and battlements. Placeholder visuals are fine; **Stage 15 does the art** in parallel.
- `Grid.step_ok`, gates, decks, `yard` and `TerrainEdit` must keep working. Spire stays `Mat.SPIRE`.

## 4. Ranged guards: new `level/castle_guards.gd` (`CastleGuards`)
- Each hostile castle has `guards` (row key, e.g. 4–8) **Sentinels** posted on tower tops and the wall walk. They exist from mission start (no raid delay), never leave their post, and respawn slowly from the crown nest (`GUARD_RESPAWN`) while the castle is hostile. Capture clears them; a retake brings them back.
- Range `GUARD_RANGE` **longer than Sniper range (26 cells)**, e.g. 32 cells, needs line of sight (`Grid.raycast`). They shoot the Operative, units and structures.
- **Fair, visible projectiles:** arcing bolts with travel time, a charge-up glow (~0.8 s) before each shot, and a sound (`Sfx`). The Operative can dodge by moving. Damage numbers in `config.gd` (`GUARD_*`).
- They are shootable targets (Operative, units, turrets, the Lance; snipers only if within their own range) using the agent dictionary contracts in CLAUDE.md.
- Add a `"Sentinel"` row (a guard tier dict, not in `RAIDER_TIERS` escalation) and draw it with `HazardMeshes.raider(tier)`. Stage 15 is designing its look; a placeholder is fine.
- Level 1 rows have no `guards` key, so Level 1 plays the same.
- Wire it from `game.gd` (one line or two) and the targets/prey lists through `stronghold_hooks.gd`.

## Don't
- Touch `level01.gd`, the mesh/art files beyond a placeholder, packets, sim rules. Rename no ids.

## Check
- Parse clean; smoke all PASS. New `core/smoke_level02.gd` registered in `smoke_test.gd`: Level 2 builds at 160x160 with 5 castles; every castle gate is reachable on foot from the landing hint (flow field or `Pathfind`); guards exist at t=0, fire at an in-range target with line of sight, don't fire beyond `GUARD_RANGE` or through terrain; a bolt hits a stationary Operative and misses one that moved; capture clears guards; Level 1 castle layouts are unchanged (no towers).
- Sims: `--level=2 --demo --units --sim=900` and `--level=2 --autostart --sim=900` (undefended must fall well before Level 1's 363 s). Report both.
- Screenshots (Xvfb, see CLAUDE.md): a high overview of the whole map, one castle from command view, one castle from first person with a guard bolt in flight. Save to `docs/level02/`.
- MASTER_PLAN.md: add row 16 status ⚠ and one Changelog line.
