# Stage 10b: Operative deployment, recall and respawn

Spec: docs/STRONGHOLDS_DESIGN.md §5.4 (and §2 for the Stockpile). Read both first.

Today: the Beacon structure is the teleport point (`game_flow.gd` `try_teleport()`), recall is a held key costing `Config.RECALL_COST` (`fps_mode.gd` `_recall()`), and a suit failure auto-recalls with `KO_PENALTY` and `TELEPORT_COOLDOWN`.

## Steps
1. **Stockpile.** Create `core/stockpile.gd` (`Stockpile`, RefCounted) exactly as design §2: `ore`, `salvage`, `add(kind, n)`, `spend(kind, n) -> bool`, `can_afford(kind, n)`. `game.gd` owns one (`g.stockpile`) and wires it like `economy`. Nothing produces Ore or Salvage yet (that's Stage 9a), but respawn already charges Salvage. Add a debug hook `--salvage=N` that sets it, for tests.
2. **New file `fps/operative_deploy.gd`** owns deploy, recall and respawn. Move the teleport logic out of `game_flow.gd` into it, so `game_flow.gd` gets *smaller*.
3. **Totems.** The `beacon` def keeps its id (never rename ids) but its `label` becomes "Totem", with an updated `desc`. Deploying to a Totem and recalling while within 3 m of one are free and instant.
4. **Drop anywhere.** A new Orbital-tab tool `@drop`, added like `@lance`: click any surface cell, pay `Config.DROP_BASE` (20) + 1 energy per `Config.DROP_PER_CELLS` (4) cells from the nearest Totem, capped at `Config.DROP_MAX` (80). A pod falls for `DROP_TIME` (3 s, visible, with a sound), then the Operative spawns there. If the energy isn't there, say so in the log.
   - Drops into an enemy Shield Dome are blocked. Shield Domes don't exist yet (Stage 8c), so add an injected `drop_blocked := func(cell) -> bool: return false` that 8c will fill in.
5. **Recall anywhere.** Holding Recall costs no energy. Unless within 3 m of a Totem, it starts a teleporter cooldown of `2 × (path length to the nearest Totem ÷ Config.WALK)`. Use the Operative's grid passability (a BFS over cells using `PlayerController`'s climb rule); if there's no path, use straight-line distance × 1.4. With no Totem at all, measure to the Command Node. While holding Recall, the first-person HUD shows the cooldown it will cause.
6. **Death replaces suit failure.** When the Operative's HP hits 0:
   - Remove the auto-recall, `KO_PENALTY` and `TELEPORT_COOLDOWN` path.
   - Lose carried extractors (a counter; Stage 9b adds the item) and crafted ammo (a hook for Stage 10).
   - Back to command mode; the Operative is "down".
   - Respawn costs `RESPAWN_ENERGY` (100) and `RESPAWN_SALVAGE` (25) and takes `RESPAWN_TIME` (45 s). Each further death this level multiplies both costs by 1.5 (`RESPAWN_GROWTH`). The timer waits while the cost can't be paid; the top bar or info panel shows the status.
   - Teleporting is impossible while down.
7. Every number above goes in `config.gd`. Update CLAUDE.md (`fps/` and `core/` rows, plus a key-contract line about deployment) and the briefing/help text that mentions Beacons or recall cost.

## Smoke checks (new file `core/smoke_deploy.gd`)
- Drop cost grows with distance from the nearest Totem and is capped.
- Recall at a Totem: no cooldown. Recall 20 cells away: cooldown ≈ 2 × path ÷ WALK.
- Death with 0 Salvage: the respawn waits; set the Salvage and it completes after `RESPAWN_TIME`.
- The second death costs 1.5× the first.

## Verify
Parse check; all smoke tests PASS; an Xvfb screenshot of the Orbital tab showing the Drop tool (`--tool=@drop --hover=x,z`, if that hook works with the new tool).
