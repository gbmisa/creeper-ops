# MP-1 Progress Log

Branch: `feat/mp1`. Base: `integ/2026-10-09` (6520548b). All work in `~/workspace/creeper-mp1/work/`.

## Done

### New files (`godot/scripts/`)
- `tactical/id_source.gd` — `IdSource`: session-owned uid issuer (`next()`, `note()`). Rule 6.
- `tactical/tac_events.gd` — `TacEvents`: per-session event bus (shot_fired, hit_confirmed, reloaded, picked_up, dropped, died, noise_emitted).
- `tactical/player_state.gd` — `PlayerState`: peer_id, node, inv, recoil_mode, stats, is_local; `to_dict`/`from_dict`.
- `tactical/range_session.gd` — `RangeSession`: players, local, ids, seed, events, noise (BotNoise), maps (RangeMaps), saved_kit; `add_player()`, `next_seed()` (deterministic), `nearest_player()`, `save_kit()`, `deploy()`, `clear_kit()`.
- `core/input_frame.gd` — `InputFrame`: plain-data snapshot (seq, pressed/held, mouse, buttons, wheel, shift, captured).

### Modified
- `core/input_state.gd` — `process_priority = -100`; `_process` snaps to `frame`; `snap()` builds InputFrame from `Keybinds.action_ids()`; right-button tracking.
- `core/keybinds.gd` — added `action_ids()` (append-only).
- `range/tactical_player.gd` — gameplay reads `input.frame.*`; `session` member; `BotNoise.emit` → `session.noise.emit`.
- `range/player_weapons.gd` — `setup()` takes session (5th arg); rng from `session.next_seed()`; `session.saved_kit`; `inv.ids`; recoil sync from `session.local.recoil_mode`; `BotNoise.emit` → `session.noise.emit` + `session.events.shot_fired`.
- `tactical/recoil_model.gd` — `tarkov` static → instance var.
- `range/tactical_viewmodel.gd` — `RecoilModel.tarkov` → `weapons.recoil.tarkov`.
- `range/range_menu.gd` — `setup(session)`; recoil toggle flips `session.local.recoil_mode`; map buttons use `session.maps`.
- `range/bot_noise.gd` — static → instance (consts stay static).
- `range/range_maps.gd` — `static var pending` (bootstrap nav state, documented); instance `selected`; `static go(map)`; instance `change(map)`.
- `range/look_materials.gd`, `range/range_layout.gd` — read `RangeMaps.pending`.
- `range/skirmish_end.gd` — `_init(session)`; restart/back use `session.maps.change()`.
- `range/skirmish_game.gd` — `start()` takes session; `session.noise.reset()`; `session.deploy/clear_kit`.
- `range/scav_bot.gd` — `setup(session,...)`; rng from `session.next_seed()`; `session.noise.listen()`; targets `session.nearest_player()`; `to_dict`/`from_dict`.
- `tactical/body_health.gd`, `tactical/gun.gd`, `tactical/magazine.gd` — `to_dict`/`from_dict`.
- `tactical/inventory.gd` — `ids: IdSource`; `_init` takes optional IdSource; `make()` helper; request API: `request_move/place/remove/drop/pick/add/fit/unfit`.
- `tactical/item_defs.gd` — `make(id, opts, ids: IdSource)`; `_uid`/`note_uid` statics deleted.
- `tactical/inventory_io.gd` — `item_from_dict(d, ids)`; `load_dict` threads `inv.ids`.
- `tactical/starter_loadout.gd`, `range/hand_gear.gd`, `range/range_shot.gd`, `tactical/attachments.gd`, `tactical/inv_reload.gd`, `range/range_crate.gd` — `ItemDefs.make` → `inv.make`.
- `range/inventory_ui.gd` — all mutations via `request_*`; `input.frame.act`.
- `range/range_bots.gd` — `setup(session,...)`; `session.noise.reset()`; `input.frame.act`.
- `range/firing_range.gd` — creates `RangeSession`, `add_player`, wires session everywhere; `menu.deploy_requested` → `session.deploy`; `menu.reset_requested` → `session.maps.change` (replaces `reload_current_scene`).
- `range/range_truck.gd` — `weapons.session.deploy`; `input.frame.act`.
- `range/range_test_deploy.gd` — rewritten for session.
- `range/range_loadout.gd` — DELETED (functionality moved to RangeSession).

### Verified
- `Ballistics._zero_cache` static is a pure memoization cache (key → deterministic value), not per-player state. Left as-is.
- Parse clean: `godot --headless --path . --import` prints no SCRIPT ERROR (2026-10-14).

## In progress
- Test updates (`range_test_skirmish/bots/inv/attach/body/roster`) — delegated to subagent.
- New MP-1 tests (`range_test_mp1.gd`): two-PlayerState independence, nearest-player targeting, request validation, seed determinism, PlayerState round-trip — delegated to subagent.

## Not done
- Commit + push to `feat/mp1`.
- Smoke baseline on pristine integ tree vs final tree (gate: no NEW failures).
- Final rebase onto `integ/2026-10-09` LAST, then push again.

## Behaviour changes (all within brief)
- Inventory reset now does a soft in-session map change instead of `reload_current_scene()` (session persists; required for MP-1).
- Item uids now come from the session's IdSource (previously a global static counter).
- Bot hearing is per-session (previously a global static); bots target `session.nearest_player()`.
- Recoil mode is per-player (`session.local.recoil_mode`); the range-menu toggle flips the local player's mode.
- Input is snapped once per frame (priority -100) and gameplay reads the snapshot; behaviour-identical single-player.
