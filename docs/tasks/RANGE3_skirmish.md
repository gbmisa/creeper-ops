# Brief RANGE3: enemy roster + small Skirmish map (playtest tonight)

Worktree `creeper fps td-worktrees/range-skirmish`, branch `feat/range-skirmish` (from `integ/2026-10-09` at this brief).
Progress log: `docs/tasks/RANGE3_progress.md`. Read `AGENTS.md`, this brief, the log, and only files you change or call.

## Gregory's words (2026-10-14)
"Create enemies and a smaller level I can playtest when I get home from work."

## Must NOT change
- The Firing Range as it plays today (layout, kill house, its 2 Scavs and their behaviour/numbers), ballistics, damage,
  armor, recoil, player movement, HUD panels. Main game: only the level-select button list in `game_flow.gd`
  `level_buttons()` (append one button). Main smoke 0 FAIL; `--range-test` all PASS; never weaken a check.
- Other agents are changing `player_weapons.gd`, `tactical_player.gd`, `tactical_viewmodel.gd`, `range_rack.gd`,
  `weapon_defs.gd` (inventory, body/arms) on other branches. Touch those only if unavoidable, and keep such edits tiny.

## Design
**Same scene, new map.** `firing_range.tscn` picks its map from a static `RangeMaps.selected` (`"range"` default,
`"skirmish"`), or `--map=skirmish`. `firing_range.gd` stays wiring; map choice is one branch around the layout/bots
build. Level select gets a **"Skirmish"** button (set the static, `change_scene_to_file` the range scene). This way the
inventory and body work merged later applies to both maps for free.

**Enemy roster** (`scripts/range/bot_defs.gd`, a data table read by `ScavBot`; the existing Scav = row `rifleman`
with today's exact numbers):
- `rifleman`: today's Scav (AK, class 2 vest).
- `pistol`: M1911, no armor, moves faster (RUN +15%), engages under 20 m, flanks more readily.
- `shotgunner`: shotgun, class 3 vest, pushes/rushes to < 10 m instead of holding cover, slower to aim at range.
- `marksman`: sniper rifle, no vest, holds a high or far overwatch spot, long sight range (≥120 m), slow deliberate
  shots, relocates after 2 shots or when hit, short scope glint visible to the player before it fires.
- `boss` ("Warlord"): P90, class 4 armor + helmet, more HP is NOT allowed (same body health model); 2 `rifleman`
  followers that stay within 15 m and react when he is engaged.
Each gets its gun via the same weapon defs/ballistics the player uses. Bots use their gun's real mag/reload.

**Skirmish map** (`scripts/range/skirmish_layout.gd`, plus split helpers if needed; ~120 x 120 m, walled):
- A small compound/village: 4–6 enterable buildings (one two-storey with stairs, using the kill-house building
  approach), cover (crates, walls, vehicles as boxes), a watchtower or rooftop for the marksman, sightlines of 20–100 m.
- Navmesh baked over the whole map (bots path indoors and up stairs).
- Spawn: player at one edge. **Extract** at the far side: stand in the zone 8 s to win. Show the objective on the HUD.
- Enemies: ~10 (5 rifleman, 2 pistol, 1 shotgunner, 1 marksman, boss + 2 followers = 12 max), patrol routes and posts.
- Loot: a few crates (ammo, meds if they exist; leave hooks for the inventory branch: a `loot` list per crate).
- Win/lose: extract = "EXTRACTED" screen with time and kills; death = "KIA" screen. Both offer Restart / Level select.
  Esc menu works as in the range.

## Checks every phase (from `godot/`)
Parse clean; `res://scenes/firing_range.tscn -- --range-test` OK; `-- --smoke --quit=0.1 | grep -c FAIL` is 0. Add
`[range] PASS` checks: each roster row spawns with the right gun/armor; marksman sight range > rifleman; shotgunner
closes distance; boss followers stay near; skirmish builds, navmesh has a path spawn -> extract; extract timer wins.
Screenshots (Xvfb, see `range_shot.gd`; add `--map=skirmish`): view them yourself, small; check the map reads well.

## Phases (one agent does both, then stops)
1. Roster (`bot_defs.gd`, ScavBot reads it, behaviours) + tests. Commit.
2. Skirmish map, spawns, extract, end screens, level-select button + tests + screenshots. Commit.
