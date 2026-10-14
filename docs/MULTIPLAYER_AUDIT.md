# Multiplayer audit (MP-0, 2026-10-14, grep pass over `scripts/tactical/` + `scripts/range/`, tests excluded)
Rules: `docs/MULTIPLAYER.md`. ~60 hits, grouped by pattern.

| System | Blockers | Main items |
|---|---|---|
| Player | 8 | statics `RecoilModel.tarkov` (recoil_model.gd:8), `RangeLoadout.saved` (range_loadout.gd:4), `RangeMaps.selected` (range_maps.gd:6); `Input.` read in tactical_player.gd:128; mouse-mode reads |
| Weapons | 6 | `Input.is_mouse_button_pressed` (player_weapons.gd:147); `rng.randomize()` (player_weapons.gd:51); static `Ballistics._zero_cache` (fine as a pure cache, verify) |
| Inventory | 7 | `inventory_ui.gd` / `inventory_view.gd` call `inv.move/place/remove` directly (~8 sites); static uid counter `ItemDefs._uid` (item_defs.gd:38) needs server-issued ids; ~14 tactical classes lack `to_dict` |
| Bots | 9 | single `player` target in scav_bot.gd (7 refs) and range_bots.gd; static `BotNoise.listeners`; `rng.randomize()` (scav_bot.gd:76) |
| Maps/flow | 4 | `reload_current_scene` / `change_scene_to_file` in firing_range.gd, skirmish_end.gd, range_maps.gd:11 (needs a server-driven map change) |
| HUD/UI | 3 | HUD bound to the one player |
| Audio | done | sound now goes through `RangeAudio.event(dict)` with a `local` flag (feat/r5-sound d0adf7a); call sites still emit directly, MP-1 routes them via server events |

## MP-1 order (refactor, behaviour identical in single player)
1. `PlayerState` per player (inventory, loadout, recoil mode, health, stats); statics above move into it.
2. `players` list: bots, noise, perception, extract take the list; HUD/viewmodel bind to the local player.
3. Inventory request functions (`request_move/fit/drop/pick`), UI calls only those; server-issued item uids.
4. Input frames: gameplay reads `InputState` snapshots only.
5. Seeded per-entity RNG (guns, bots, items); no `randomize()` in rule code.
6. Map changes through one `RangeMaps.go` that a server can broadcast.
7. `to_dict/from_dict` for players, bots, world items, projectiles (join mid-session).
