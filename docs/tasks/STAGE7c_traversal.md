# Stage 7c: Traversable terrain (Level 1)

**Agent:** Grok Build (Sonnet-class). **Worktree:** `creeper fps td-worktrees/stage7c` · **Branch:** `stage/7c-traversal`
Runs alongside Opus's Stage 7b (castle raids). **Stay out of** `level/stronghold*.gd`, `level/castle_*.gd`, `level/raiders.gd`, `level/raider_field.gd`, and the `CASTLES` / `RAID_SCHEDULE` consts at the top of `level01.gd` (7b edits those).

## Why
Level 1 is sheer terraces almost everywhere. Raiders step one level at a time (`RAIDER_CLIMB`), so they get stranded or pile against walls, units path the long way round, and the map reads as cliffs. The user wants hills that are **traversable in some areas**, while sheer walls still make defensible choke points elsewhere. CW3 style is unchanged: whole levels, flat tops, **no decorative height noise**. Slopes are **stairs of one level per cell or per 2 cells**, at least 3 cells wide.

## Do
1. **Measure first.** Add `core/smoke_traversal.gd` (register one line in `smoke_test.gd` like `SmokeRaiders`). Flood-fill from each nest with `RaiderField.step_ok` (one terrace, no corner cutting) and print:
   - the share of non-Blight cells each nest reaches,
   - the share of all walkable cells in the largest connected region,
   - plateaus/shelves (connected regions of ≥ 12 cells) that no nest can reach.
   Put the numbers **before and after** in your report.
2. **Add a ramp helper.** New static `level/level_ramps.gd` (`class_name LevelRamps`): `stairs(g, from: Vector2i, to: Vector2i, width: int, cells_per_level := 1)` lays a straight stair between two terraces (heights interpolated in whole levels, never lower than what's already there unless the path cuts down into a hill). Keep `level01.gd` under 250 lines; it should only call the helper.
3. **Add routes in `Level01.build()`** (before the "CW3 terrain is whole levels" rounding):
   - The NW emitter plateau, the east emitter shelf, the side terraces west and east of the mesa, and the central knoll each get **at least one** stair a raider can climb.
   - Smooth the lowland: where the fbm noise makes a jump of 2+ levels between neighbours *outside* the named features, cap it so neighbours differ by at most 1 level. Keep the valley.
   - **Do not** add routes onto the southern mesa beyond the existing north stair and the west-ridge gap (the base must keep choke points), and don't touch the castles' footprints.
4. Target after the change: each nest reaches ≥ 70% of non-Blight cells; no isolated plateau except the NE Spire Heights top (Blight, Operative-only by design) and castle interiors.
5. Smoke checks (in `smoke_traversal.gd`): the targets above; `SmokeTraps` still passes; the landing hint is still valid (`Placement.can_land`).

## Verify
- Parse check, full smoke (all PASS), `--demo --units --sim=900` (report Node HP and raider count; compare with `main`), `--autostart --sim=900` (undefended: the Node should now take raider damage sooner; report when).
- Two Xvfb screenshots: one command view of a new stair, one of the whole map (`--look=40,40,120`).

## Report (AGENTS.md)
Files, before/after numbers, sim reports, screenshots paths, anything unsure. Set Stage 7c to ⚠ in MASTER_PLAN.md and add one Changelog line. Don't edit HANDOFF.md.
