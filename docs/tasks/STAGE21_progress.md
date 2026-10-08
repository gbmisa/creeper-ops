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

## Shared-file edits (for the orchestrator)
(none yet)

## Suggestions
(none yet)
