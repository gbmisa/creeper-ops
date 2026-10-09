# Handoff: 2026-10-09 (integration + playtest 3, Opus)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md).
Repo: https://github.com/gbmisa/creeper-ops (private). **Muse** codes from GitHub branches; **Opus** orchestrates, merges and does the visuals.

**Everything lives on `integ/2026-10-09`** (worktree `creeper fps td-worktrees/integ`, local only, not pushed, not on main). Gregory is playtesting it:
`cd "…/creeper fps td-worktrees/integ" && godot --path godot`

## In integ (full smoke OK: 0 failures, parse clean)
- Muse's 12 overnight branches: 13 tuning, plasma recoil, K split, playtest-small, shot tour, 21b castles, Q spitter towers, anti-creeper, playtest2 pressure, A3 hive models, A4 structure models, art/3-models.
- Muse's 9 follow-ups: enemy-los, beam-intercept-lobs, enemy-castle-mortars, spitter-vs-structures, network-planned-relays, raider-circle-anim, bailey-standard-ux, ammo-float-snap, deploy-from-node. **deploy-from-node changes a settled rule** (deploy from the Node when there's no Totem; the Totem is cheap and builds itself). Gregory hasn't confirmed it.
- Playtest 3 fixes ([docs/tasks/PLAYTEST3_feedback.md](docs/tasks/PLAYTEST3_feedback.md), status line at item list end):
  - Spitter range 14, with a smoke rule that acid reach stays below Sniper range.
  - `art/totem-red`: taller Totem with a red glowing ball, unviewed.
  - `pt3/enemy-builds`: mortars die only to the demo charge (free while `DEMO_CHARGE_FREE`); spitter towers pay 0 Salvage; enemy rebuilds wait `ENEMY_REBUILD_DELAY` 30 s.
  - `pt3/castle-guard`: Lancers garrison hostile castles (`castle_lancers.gd`); no building within `BUILD_BAN_RADIUS` 24 of an unheld castle (`castle_exclusion.gd`, red rings in the shader, unviewed).

## Open (playtest 3)
1. Enemies float on creeper (item 2).
2. Flying Node launches packets (item 15; update the CLAUDE.md contract).
3. Railgun prompt says where to buy it and clears on weapon switch (item 6).
4. Ask Gregory: should E-hold mortar sabotage still kill a mortar and pay 5 Salvage?
5. The Ashmote Keep over-the-wall Lancer shot is unreproduced; it needs Gregory's replay.

The pt3/small-fixes agent for items 1-3 was stopped by Gregory before it changed anything. Don't restart it unasked.

## Decisions pending from Gregory
- UI: `ui/overhaul` (Opus) vs `fix/ui-viewport-fit` (Muse). Screenshots are in the session scratchpad `ui/`; regenerate if gone.
- Tuning (Lance cooldown 60→45, Wyvern HP 90→70): deferred until after more playtests.
- When to merge integ → main and push.

## Debt
`raiders.gd` 304 lines, `weapon_logic.gd` 356, `shot_tour.gd` 300: split. A4 `_relay_pass` is O(n) per waypoint.

## Not verified
No human look at: the Totem, the build-ban rings, the 21b castles, the anti-creeper fluid, military glb pivots. GPU (Vulkan) path not checked.
