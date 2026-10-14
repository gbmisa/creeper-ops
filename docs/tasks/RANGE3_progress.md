# RANGE3 progress log

## Phase 1: roster (done)
- `bot_defs.gd` table (rifleman = original Scav numbers, pistol, shotgunner, marksman, boss). ScavBot/BotShooting/BotMotion/BotBrain/BotPerception read it
  (`BotEngage` = engage/patrol/relocate per row). `ArmorDefs` gained `vest3`. `BotMesh(def)` picks gun model/uniform, has a scope glint.
- `RangeMaps` (static `selected`, `go(map)`): level-select "Skirmish" button, Esc menu "Deploy to Skirmish" / "Back to Firing Range".
- `range_test_roster.gd` checks (rows, glint, relocate, shotgunner closes, boss followers). `--range-test` OK 93, smoke 0 FAIL.

## Phase 2: Skirmish map (done)
- `RangeMaps.selected` / `--map=skirmish`; `firing_range.gd` branches only around layout / rack / targets+bench / bots. Level select "Skirmish" and Esc-menu buttons go through `RangeMaps.go()`.
- `skirmish_data.gd` (tables), `skirmish_parts.gd` (walls with doors/windows, slabs, ramps), `skirmish_layout.gd` (120x120 walled map, 5 buildings, hotel 2nd floor via ramp, watchtower, cover, loot crates, extract marker, navmesh bake), `skirmish_game.gd` (12 enemies, HUD objective, extract 8 s, loot, KIA/EXTRACTED), `skirmish_end.gd` (Restart / Level select / Back to Firing Range).
- Stairs are ramps (collider) with tread strips: step boxes would not be climbable by the capsule bots.
- Player starts with the M1911 and the weapon rack stands behind the spawn. Loot items `{ammo, meds}` per crate (hook for the inventory branch).
- `--range-test` OK 106; smoke 1264 PASS / 0 FAIL. Screenshots in /tmp/claude-1000/shots (s1, t1, t2, t3).
- Navmesh needs ~30 physics frames to sync on this map (tests wait).

## RANGE4 (deploy): done
- `range_truck.gd` (Deploy truck inside the booth at (-6.4,0,3), F "Deploy to Skirmish with this kit"); `RangeLoadout.deploy(inv)` = save + `RangeMaps.go("skirmish")`, used by truck and Esc button (`RangeMenu.deploy_requested`). `RangeLoadout.clear()`.
- Skirmish: M1911 `give` only when `RangeLoadout.saved` is empty. `SkirmishGame.finish`: win saves inventory, KIA clears.
- Restart (end screen) reloads the scene and so reuses whatever is saved (extract: carried kit; KIA: default kit).
- Tests `range_test_deploy.gd` (4 checks); existing skirmish test now gives the game a `weapons` object. `--range-test` OK 191, smoke 0 FAIL.
