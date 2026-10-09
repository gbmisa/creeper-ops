# Brief Q (Muse): enemy Spitter Towers on L1 (playtest bug)

**Branch:** `fix/q-spitter-towers` (from `main`). **Start now.** C (`stage/21b-castles-detail`) is running in castle code, so touch only the files listed here, and say in the report if you had to touch a file C also changed.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, `level/enemy_build_plan.gd`, `level/enemy_structures.gd`, `level/enemy_build_fight.gd`, the `ENEMY_BUILD_*` and `HIVE_SPITTER_*` lines in `core/config.gd`, and the `sniper` row in `command/structure_defs.gd`.

## Gregory's report (L1)
> "There's a spinner tower that's still spawning underground. On the first level, and the spinners are able to shoot from where the sniper can't get them. And there's a shitload of them."

"Spinner tower" = the **Spitter Tower** that enemy-held castles build (`EnemyStructures` "spitter", built by `EnemyBuildPlan`).

## What Opus found (verify each one)
1. **Underground:** some towers are placed with their mesh below the terrain. Check how `enemy_structures.gd` sets the node's `y` (`cell_ground` vs `stand_y` on castle plateaus, terraced walls, `_is_edge` cells on a cliff lip). Also check whether the cell's height changes after placement (terrain edits, mortars, castle shaping).
2. **Out of reach:** `_edge` scores sites *away* from the player's weapons (`far`). Spitter range is `HIVE_SPITTER_RANGE` 20, and Sniper range is also 20. A tower on a cliff edge or one terrace up can hit the player while snipers can't get line of sight or range.
3. **Too many:** `_kinds` repeats spitter / pylon / lancer with no cap, so a castle left alone keeps adding towers.

## Tasks
1. **Repro first.** Print the counts per castle for L1 at 10, 20 and 30 min (`--autostart --sim=1800` and `--demo --units --sim=1800`). For each tower, print its `y` against `stand_y` and `cell_ground` at its cell. Put the numbers in the report.
2. **Height:** every enemy structure stands on the visible ground of its cell. Re-seat it on `Bus.terrain_changed` if its cell moved, or put it somewhere it never moves.
3. **Fair sites:** a spitter is only placed where at least one buildable cell within Sniper range has line of sight to it (reuse the sniper LOS helper from `SmokeSniperLos` / `WeaponLogic`). The alternative is to give spitters a range shorter than the Sniper's. Pick one, say why, and put the number in `config.gd`.
4. **Cap:** add `ENEMY_BUILD_MAX_PER_KIND` (try 2 spitters, 2 lancers and 2 pylons per castle at L1 pressure, growing with pressure). Keep the existing order.
5. **Smoke rules:** a placed enemy structure's `y` is within 0.2 m of `stand_y`; the per-kind cap holds after a long sim; one spitter site per L1 castle passes the LOS rule.

## Must not change
Hive spitter turrets (`hive_parts.gd`), the build order, or any castle or hive file outside the list. Run L1 `--demo --units --sim=900` before and after, and report both.

## Report
AGENTS.md format with the before and after counts.
