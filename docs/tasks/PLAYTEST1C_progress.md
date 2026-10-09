# Playtest 1C progress: hive sites (branch `fix/playtest1-hive-sites`)

Brief: `docs/tasks/PLAYTEST1_C_hive_sites.md`. Hive cores die in 4-6 s now; the
challenge moves from killing the core to *getting there*. Each hive site gets
one access challenge built from existing tools only (terrain shaping, stairs,
Blight, emitter placement). No config.gd changes, no hive/emitter/castle/ore/
landing moves.

**Spec conflict found:** the brief says L2 has 4 hives, but `level02.gd` has 6
(Rift, Spire Heights, North Knoll, West Moor, East Moor, Southern Barrows).
All 6 are done. "No two hives on a level use the same main challenge" is
impossible with 6 hives and 4-5 challenge kinds, so L2 repeats `plateau` once
(Southern Barrows); the smoke check requires >= 4 distinct kinds on L2 and
full uniqueness on L1 (3 hives).

Access kinds (written as `"access"` on each hive row): `plateau`, `blight`,
`creeper`, `chokepoint`, `cavemouth`.

## P1 — L1 (done)
- **Rift (9,38) → `cavemouth`:** the Rift hollow got a level-5 rim ring
  (r 8.5-10.5 around (14,42)) with two gaps (east at (24,42), north at
  (14,32)). Kept out of `smooth_lowland` via the keep mask. Raiders and the
  Operative enter/exit only through the gaps.
- **Spire Heights (59,13) → `plateau`:** removed the old south stair
  (z 20-35); the plateau is sheer level 10 on all sides now. New single stair
  on the east side from (72,11) down to (79,11), facing away from the southern
  landing mesa.
- **Central knoll (40,23) → `blight`:** Blight band x 32-48, z 31-34 across
  the southern approach. The walk crosses Blight (no building); the network
  routes around either end.
- New smoke file `godot/scripts/core/smoke_hive_sites.gd` (class
  `SmokeHiveSites`), registered in `smoke_test.gd`. Per hive on L1+L2 it
  checks: (a) Operative flood (`LevelShape.walkable_from`, PLAYER faction)
  from the landing hint reaches within 2 cells of the core; (b) raider flood
  (`RaiderField.step_ok`) from the hive reaches the player half
  (z >= 65% of map height); (c) the `access` tag is a valid kind; plus kind
  variety per level.
- Parse: clean (`--import`, no errors). Smoke: full suite PASS, 705 checks, 0 failures
  (includes the 19 new `SmokeHiveSites` checks: access tags valid, Operative
  reaches all 3 L1 cores, raiders leave all 3 hives, kinds mixed; traversal
  "no stray isolated plateau" still green with the new rim).
- Pushed: <hash>

## P2 — L2 (done)
- **Spire Heights (133,64) → `plateau`:** already a sheer level-10 plateau;
  the south ramp is the only way up. No terrain change, tag added.
- **Rift (15,60) → `cavemouth`:** level-5 rim ring (r 8.5-10.5 around
  (20,64)) with east and north gaps, in `Level02Terrain._rift()`.
- **North Knoll (82,40) → `chokepoint`:** ridge ring (r 9-11) at knoll-top + 2
  with a single 2-cell pass on the south side (x 81-82).
- **West Moor (44,66) → `blight`:** Blight band x 36-64, z 74-77 across the
  south-east approach.
- **East Moor (112,104) → `creeper`:** 1-level-deep channel (x 115-117,
  z 96-112) running south from Emitter East; the emitter keeps it wet.
- **Southern Barrows (34,151) → `plateau`:** rect (28,145)-(40,157) set to
  level 6 with a single west stair (ramp (28,151) -> (20,151)). Repeats the
  `plateau` kind (documented above).
- Parse: clean. Smoke: full suite PASS, 734 checks, 0 failures (includes all 29
  `SmokeHiveSites` checks: 6 L2 hives tagged, Operative reaches every core,
  raiders leave every hive; L2 kinds mixed 5 distinct with `plateau` x2).
- Pushed: <hash>

## P3 — verify (done)
- `--autostart --sim=600` and `--demo --units --sim=900` on both levels,
  Node death times before -> after: <numbers>.
- Xvfb screenshots of every hive site (`--look=x,z`) in scratch.
- Commit: <hash>

## Suggestions (not in the brief)
- Seed the RNG for `--sim` runs (HANDOFF already notes sims are not
  deterministic; before/after death times are noisy).
