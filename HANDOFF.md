# Handoff: 2026-10-07 (session 10: Stage 7b castle stakes; three Grok stages briefed)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md); spec: [docs/STRONGHOLDS_DESIGN.md](docs/STRONGHOLDS_DESIGN.md). How to run: [RUN.md](RUN.md). Git repo; parallel work in worktrees under `../creeper fps td-worktrees/`.

**Roles:** Opus orchestrates (briefs in `docs/tasks/`, reviews, only one who merges). Grok follows [AGENTS.md](AGENTS.md).

Done on `main` this session (all committed):
- **Stage 7b, castle stakes (Opus):** `level/castle_raids.gd` (`CastleRaids`, wired in `game.gd`). Capture → reprisal countdown (L1 90 s) → the nearest nest sends a group with mission "castle". Held castles then draw sieges every `interval()` with a 45 s warning. Size and rate scale with the level's `CASTLE_RULES` aggression × (1 + held_stack × (held − 1)), tier for now (8a: pressure). Hostile castles speed up nests within 30 cells (`nest.rate`). Markers: countdown over the castle, "Gathering" over the source nest. `--raid=I[,S]` hook. Turrets (done earlier) are the prep answer.
- **Nullifier moved to the Weapons tab** (slot 5).
- **Briefs** for 10a (Armoury) and 11a (Terp, Earth only); worktrees `stage10a`, `stage11a` created. `stage7c` updated to the same base.

## Parallel work in flight (Grok, not merged)
| Stage | Worktree / branch | Brief |
|---|---|---|
| 7c traversable terrain | `stage7c` / `stage/7c-traversal` | docs/tasks/STAGE7c_traversal.md |
| 10a Armoury | `stage10a` / `stage/10a-armoury` | docs/tasks/STAGE10a_armoury.md |
| 11a Terp (Earth) | `stage11a` / `stage/11a-terp` | docs/tasks/STAGE11a_terp_earth.md |
| 15 Fantasy art (Claude subagent, rounds scored by a judge agent) | `stage15` / `stage/15-fantasy-art` | docs/tasks/STAGE15_fantasy_art.md + JUDGE_art_rubric.md |
| 16 Level 2, 160x160, 5 castles, ranged Sentinels (Claude subagent) | `stage16` / `stage/16-level02` | docs/tasks/STAGE16_level02.md |
Stage 15/16 merge notes: 15 splits `structure_meshes.gd` (11a adds a Terp case: port it). 16 adds `lay.towers` in `castle_shape.gd`; 15 decorates the old layout, so crown the towers at merge. 16 swaps `Level01.build()` for `Levels.build(n)` in `game.gd`.
Merge notes: 7c edits `level01.gd` `build()`; 7b added `CASTLE_RULES` at the top and `"castle_rules"` in the level dict, so expect a small conflict there. 11a edits the Titans MENU line next to the Nullifier move. All three add a line to `smoke_test.gd`/`debug.gd`/`Keybinds` and the plan changelog. 10a exposes an Armoury API for castles: wire it into held castles (stronghold_hooks) at merge.

## Verified (headless + Xvfb)
- Smoke **182/182 PASS** (15 new in `smoke_castle_raids.gd`).
- `--demo --units --sim=900`: Node 500/500, 2 nests alive, no castles taken (raids 0).
- `--demo --units --raid=0,20 --sim=600`: reprisal of 4 marches, enters the undefended courtyard, Ashmoat falls. Node 500/500.
- `--autostart --sim=900` (undefended): Node dies at 363 s (raids start 300 s; nests are castle-fed from the start on L1).
- Screenshot: countdown and "Gathering" markers (`--raid=0,80 --look=10,52,90`).

## NOT verified (needs a human)
- Whether reprisal sizes (L1: 4 at tier 0, 6 when two castles held) and siege timing (480 s with one castle, 320 s with two) feel fair; whether turrets + 90 s is enough prep.
- Stages 1, 2, 4, 5, 6, 7, 10b still lack a human playtest.

## Known issues / decisions
- Raiders sent at castles share one flow field to *all* held castles, so with two held a raid may go to the nearer one rather than its named target. Fine for now; per-castle fields if it matters.
- Creeper ignores gates and decks. Pre-existing at quit: "N resources still in use" and the Environment RID leak.
- Merged worktrees (`stage5/6/7/10b`, `grok-command-mode`) can be removed.

## Next steps
1. Start the three Grok agents (prompt in docs/tasks/README.md). Review and merge each as it reports (7c first: it touches level01).
2. Then briefs for 8a (nest bases, mortars, pressure → replace tier in CastleRaids), 8b (roster), 9a (Ore, Miner, return packets).
