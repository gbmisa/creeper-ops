# Brief FB-B: Skirmish fixes (F5, F18, F19, F25, F26)
Source: `docs/playtests/feedback_2026-10-14.md` (main repo). Branch `fix/fb-b-skirmish`.
Base: `integ/2026-10-09` after `feat/mp1` merges (else `origin/feat/mp1`). Agent: Muse or Sonnet `feature-dev`, 2 phases max.
Read `AGENTS.md`, this brief, the files you change. **Change only what each item names.**

## Phase 1: cover is real
- **F25 props have no collision.** Sandbags, guardhouse, concrete blocks, pallets, barrels, trees, oil tanks in the
  skirmish layout (`range/skirmish_layout.gd`, `skirmish_parts.gd`, `look_props.gd` / `look_prop_defs.gd`) are visual only.
  Give each a `StaticBody3D` with simple box/cylinder shapes on `TacticalConfig.LAYER_WORLD`, so it blocks the player, bots,
  bullets and bot sight. Trees: trunk only. Rebake/refresh the bot navmesh so bots path around them.
- **F5 bots shoot through cover.** Bots must only fire with a clear line from muzzle to target (raycast on `LAYER_WORLD`),
  and bullets stop on cover (check `Ballistics` hits world colliders; F25 adds them). Check `bot_perception.gd`,
  `bot_shooting.gd`, `bot_engage.gd`. Suppressing fire at a last-known position is fine if the shots really hit the cover.
- Must not change: bot damage, fire rates, ranges, layout positions, loot, bot placement.
- Tests: player can't walk through a sandbag; a bot behind a wall doesn't hit the player; a bullet into a barrel stops.

## Phase 2: bots and pause
- **F18 aimbots.** Bots land headshots across the map. `bot_shooting.gd:35` already scales `aim_error` by distance; find
  why it still hits (aim point = head? error too small? applied once per burst?). Target: spread grows with distance, aim at
  centre mass (head only by chance), a reaction delay before the first shot after spotting (`BotDefs` keys, numbers in the
  def table). Keep damage and fire rate. Report hit rate at 10 / 50 / 100 m before and after (headless test).
- **F19 pause doesn't pause.** The range Esc menu (`range/range_menu.gd`) doesn't stop the world: bots keep shooting.
  Opening it must freeze bots, their shots, ballistics, bleeding and timers (`get_tree().paused`, with the menu and HUD on
  `PROCESS_MODE_ALWAYS`). Closing resumes exactly. Test: a bot mid-burst while paused deals 0 damage over 3 s.
- **F26 dark interiors + floating light.** Remove the floating light and the "WH-1" stencil in the ammo + meds room
  (`look_kestrel.gd:123` and the light near it). Add ceiling light fixtures (simple mesh + OmniLight3D, shadows off) to
  skirmish interiors so they are readable. Must not change layout, loot, bot placement. Opus judges the screenshots.

## Done
Parse clean, `--range-test` all PASS, main `--smoke` 0 FAIL. Push, report every behaviour change, stop.
