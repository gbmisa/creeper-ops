# Stage 21 progress log (Castles 2.0, Opus)

Branch `stage/21-castles`, worktree `creeper fps td-worktrees/stage21`. Design: [CASTLES2_DESIGN.md](../CASTLES2_DESIGN.md).

## Baseline (main @ 1eb0ab1)
- Smoke: 456 PASS, 0 FAIL.
- `--demo --units --sim=900`: Node dies at 663 s; castles hostile; 3 nests alive.
- `--autostart --sim=900`: Node dies at 337 s.
- `--level=2 --demo --sim=900`: Node dies at 383 s; 11 structures left.
- `--level=2 --autostart --sim=900`: Node dies at 227 s.

## P1 Design
- Wrote `docs/CASTLES2_DESIGN.md`. Key decisions (user may revisit):
  - Interiors = an Operative-only **roof layer** (`Grid.roof`), like drawbridge decks. Creeper, raiders, units see the floor.
  - Concentric castles opt in per row (`plan: "concentric"`); Stage 7 rows still build the old way until converted.
  - The keep hall holds the crown nest and the final capture point; 11x11 keeps keep the obsidian spire column through the hall (landmark), no spire ramp/jump pad.
  - Stage order gate → bailey → keep; the bailey stage needs every trebuchet dead; the crown is shielded until the bailey is yours.
  - Tunables in a new def table `level/castle_defs.gd` instead of `config.gd` (fewer merge conflicts).
  - Level 1 castles become compact concentric (29–31), not 35+: the map is 80x80.

## P2 Shape v2 + P3 Interiors (one commit: the shape writes roofs, the walk needs them)
- New: `level/castle_defs.gd` (CastleDefs), `castle_shape2.gd` (ring grammar), `castle_stairs.gd` (split-spiral tower
  stairs, doors, roofs), `castle_keep_shape.gd` (keep hall, column, stair, zones), `castle_interior_meshes.gd` (roof
  slabs + braziers), `castle_debug.gd` (`--castle2=I,spot`, `--stage`, `--held`), `castle_stages.gd` (stub: set_stage),
  `world/grid_roofs.gd` (GridRoofs: Operative layer, ceiling, flat castle stone, `walkable` flood).
- Rows with `"plan": "concentric"` go to CastleShape2; Stage 7 rows unchanged but now also carry `stages`, `zones.keep`,
  `crown_at`. `StrongholdRules.in_zone` reads `lay.zones`. L2 Crown Keep converted (size 37 at 62,62) as the test bed.
- Decisions: tower stair = split spiral (hatch at top-1, both sides descend one level per ring cell), so both wall-walk
  doors and the bailey door line up on a 3x3 ring. **Roof headroom is 3 levels** (2 put the head in the slab while
  stepping up to the next step). **Castle stone stands flat for the Operative** (`GridRoofs.CLIFF` 1.5): neighbours more
  than 1.5 levels away don't bend the floor; TERRACE_BAND 2/3 otherwise lifts you 1.5 m up the walls of a 1-wide stair.
  Raiders/terrain mesh unchanged (they still use the terraced surface), so the visible floor still ramps at the walls.
- Smoke: 485 PASS (new: 16 shape, 13 walk incl. scripted climbs of a corner tower, a gatehouse tower and the keep
  stair to the roof; a kick under the gate hall roof stops at the slab; rays stop on roofs; raiders/creeper see the floor).
- Screenshots (scratchpad/stage21): p2_top.png (command view, whole castle), p2_cmd1.png, p3_gate.png (outside),
  p3_bailey.png (inner gate passage), p3_gatehall.png, p3_hall.png (crown in the keep hall), p3_roof.png (keep roof), p3_tower.png.
- Unfinished: the roof slab is plain stone (no ashlar texture); command view can't see creeper under roofs.

## Shared-file edits (for the orchestrator)
- `world/grid.gd`: `roof` array (+resize) and `GridRoofs.in_slab` in `raycast` (2 lines).
- `fps/player_controller.gd`: `can_occupy`/`_push_out` use `GridRoofs.op_height`; ceiling clamp + `GridRoofs.stand_y`.
- `core/debug.gd`: one `CastleDebug.apply(g, args)` line, header doc line, `castle2` in the auto list.
- `core/smoke_test.gd`: registration lines. `core/smoke_level02.gd`: tower check floods roofs for concentric castles.
- `level/level02.gd`: Crown Keep row.

## Suggestions
(none yet)
