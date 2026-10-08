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

## P4 Staged capture + war engines
- New: `level/castle_stages.gd` (CastleStages: gate → bailey → keep, contest, ring retake, per-ring gate owner, bailey
  build rights, garrison home, marker text), `stronghold_tick.gd` (per-state ticks split out of `stronghold.gd`, which
  keeps `_capturing/_holding/_pad` wrappers for old smoke), `castle_engines.gd` + `castle_engine_meshes.gd` (trebuchets).
- `StrongholdRules`: new state keys `stage`, `ring`, `engines`; `sealed(c, lay, ring)`, `in_ward`; `sync_grid` hangs gates
  per ring. `StrongholdHooks`: prey/enemy rows per ring (inner walls are always raider prey), `breach_cells(c, lay, ring)`.
  `Strongholds.castle_goals`: ward cells + one breach line per sealed ring. Crown hits do nothing until the bailey is yours.
- Siege on a concentric castle: raiders anywhere inside → siege; only raiders in the ward run the retake timer.
- Engines: 2 per concentric castle (opposite corners), range 40 / min 8, 11 s, 3 s ground ring + whistle, blast 2.5 cells
  (45 structure / 25 unit / 22 Operative), HP 140, respawn 150 s until the bailey falls. Weapons first; the Operative only
  in line of sight (roofs hide you). Units, Snipers and the Lance hit them (`Strongholds.enemies`, `CastleGuards.foes`).
  Sentinels no longer post on the engines' corner towers; the keep roof corners are Sentinel posts.
- Rings share the enemy-mortar shader slots (`EnemyMortarFire.extra`).
- Smoke: 510 PASS (+15 capture: every transition, contest, ring retake, bailey build rights, siege only from the ward,
  abandoned keep keeps the rings, save round trip; +10 engines incl. "an Operative who walks out takes nothing").
- Screenshot: p4_engine_ring.png (trebuchet on the NW tower, ring under the target cannon).
- Debug: `--engines=I` (a cannon in reach, engines fire now), `--stage=I,N`.

## P5 Held perks
- New: `level/castle_perks.gd` (CastlePerks: reach, ward drain, hive slow), `castle_vaults.gd` (CastleVaults: engine/
  placement API). `CastleKeeps` also places a free, finished **Castle Barracks** in the ward of a held castle (muster),
  removed when the castle falls. Stage 7 castles get reach/ward/hive slow too (their courtyards are too tight for a barracks).
- Numbers (CastleDefs): reach +25% weapon range within 28 cells of a held castle's centre; ward drains 0.03 depth/s per wet
  courtyard cell; hives within 30 cells spawn 30% slower; muster on.
- 9b hook: `CastleVaults.ships(castles, cell)` is false inside a castle you don't hold; `lay.vaults` = 2 ward cells beside
  the keep for the richest engines; `CastleVaults.inside_held` for future castle-only production.
- Smoke: 518 PASS (+9 perks; muster checks wait for a concentric castle in Level 1). `smoke_castle_raids` nest-buff check now
  includes the ward factor.
- Screenshot: p5_held.png (held Crown Keep: blue banners, keep sender + Castle Barracks in the ward).

## P6 Level conversion
- **Level 2:** all five castles concentric. Ashgate 35 at (6,104), Thornwall 35 raised at (121,121) (was (126,108): the
  Spore Spire ramp ends at z 104), Crown Keep 39 (bailey 7) at (61,61), Northreach 35 raised at (8,8), Stormcrown 35 at
  (117,8). Moved hives East Moor → (112,104) and Southern Barrows → (34,151) (and their knolls) so stamps don't cut walls;
  `demo_target` follows East Moor. Intro line explains the rings.
- **Level 1:** Ashmoat → compact concentric 31 (bailey 5, 9x9 keep, no spire column) at (0,49): the SW is the only corner
  with room; it replaces most of the west ridge and notches the landing mesa's west edge (x 31-34 is now its apron).
  One trebuchet with `engine_range` 24 (new row key) so it guards the castle, not the landing mesa. SW vent moved to
  (20,45) (feeds the north moat), ore (22,58) → (33,66), Level 1 gets its own `demo` list (relay (28,48) → (33,47), cannon
  (29,50) → (35,50)). **High Bastion stays a Stage 7 raised keep**: no room in the north for 31+ cells; it also keeps the
  Stage 7 code (spire ramp, jump pad, drawbridge) under test.
- Castle smoke adapted (decisions, all in castle smoke files unless noted): Stage 7-only checks (spire past MAX_LEVEL,
  spire ramp/jump pad) use Bastion; crown tests set the keep stage first; siege/retake raiders stand in the ward; breach
  checks use the outer ring; turret sockets may sit on tower tops; `smoke_loot` crown test sets the keep stage;
  `smoke_supply_rules` and `smoke_test` barracks/path checks moved 3-4 cells east onto the mesa (the apron took x 31-34).
- New row keys: `engine_range`. Socket cells for inner gates use the inner rect.
- Smoke: 575 PASS.
- Sims (before → after): L1 `--demo --units --sim=900` Node dies 663 → 640 s; L1 `--autostart` 337 → 337 s;
  L2 `--demo` 383 → 348 s (Thornwall's NW trebuchet reaches the east collectors of the demo base: by design);
  L2 `--autostart` 227 → 226 s. Without the 24-cell range, L1's trebuchet shelled the demo base and the Node died at 365 s.
- Screenshots: p6_l2_map.png (all five castles), p6_l1_map.png, p6_l1_held.png (held Ashmoat + muster barracks).

## Shared-file edits (for the orchestrator)
- `command/weapon_logic.gd`: `static var range_bonus` (callable) multiplies `range_cells` (set by `CastlePerks.attach`).
- `core/game.gd`: `CastlePerks.attach(castles)` (1 line).
- `level/enemy_mortar_fire.gd`: `static var extra` + 4 lines appending it to the `shells` uniform.
- `core/game.gd`: `castles.engine_prey = surface_prey` (1 line).
- `core/smoke_level02.gd`: "guards: all posted" counts live Sentinels (foes() now includes engines).
- `world/grid.gd`: `roof` array (+resize) and `GridRoofs.in_slab` in `raycast` (2 lines).
- `fps/player_controller.gd`: `can_occupy`/`_push_out` use `GridRoofs.op_height`; ceiling clamp + `GridRoofs.stand_y`.
- `core/debug.gd`: one `CastleDebug.apply(g, args)` line, header doc line, `castle2` in the auto list.
- `core/smoke_test.gd`: registration lines; the barracks-cap test barracks moved (33,70) → (37,72).
- `core/smoke_supply_rules.gd`: the solid-towers path test moved one cell east (35..41, 74).
- `core/smoke_loot.gd`: crown-drop test sets the keep stage first (1 line).
- `level/level01.gd`: Ashmoat row, vent, ore, `demo` list (9b also edits level placement here: conflicts likely). `core/smoke_level02.gd`: tower check floods roofs for concentric castles.
- `level/level02.gd`: Crown Keep row.

## Suggestions
(none yet)
