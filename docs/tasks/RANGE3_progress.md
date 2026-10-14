# RANGE3 progress log

## Phase 1: roster (done)
- `bot_defs.gd` table (rifleman = original Scav numbers, pistol, shotgunner, marksman, boss). ScavBot/BotShooting/BotMotion/BotBrain/BotPerception read it
  (`BotEngage` = engage/patrol/relocate per row). `ArmorDefs` gained `vest3`. `BotMesh(def)` picks gun model/uniform, has a scope glint.
- `RangeMaps` (static `selected`, `go(map)`): level-select "Skirmish" button, Esc menu "Deploy to Skirmish" / "Back to Firing Range".
- `range_test_roster.gd` checks (rows, glint, relocate, shotgunner closes, boss followers). `--range-test` OK 93, smoke 0 FAIL.
