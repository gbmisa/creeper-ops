# Brief MP-1: multiplayer-ready refactor of the tactical layer (Muse)
Branch `feat/mp1` from `integ/2026-10-09` at this brief. Progress log `docs/tasks/MP1_progress.md`.
Read `AGENTS.md`, `docs/MULTIPLAYER.md` (rules + authority table), `docs/MULTIPLAYER_AUDIT.md` (blockers + order).

## Goal
Single player plays **exactly** as today, but the code follows MULTIPLAYER.md rules 1–8 so MP-2 (ENet listen server,
2–4 co-op players) is wiring, not a rewrite. No networking code in this stage except an optional `NetRole` stub
(always "offline").

## Do (in the audit's MP-1 order)
1. `PlayerState` (per player: peer id, inventory, loadout, recoil mode, health/BodyHealth, stats). Move the statics
   `RecoilModel.tarkov`, `RangeLoadout.saved`, `RangeMaps.selected` (and any other per-player `static var`) into it or
   into a per-session `RangeSession` object that survives scene changes (one autoload-free holder is fine).
2. `players` list in the session; bots, `BotNoise`, perception, extract, deploy, laser `spot_mult` take players, not one
   `player`. HUD, viewmodel, camera, audio "local" flag bind to the local player only.
3. Inventory request API (`request_move/place/remove/fit/unfit/drop/pick`) with validation; UI calls only these.
   Item uids issued by an `IdSource` owned by the session (server-issued later), not a static counter.
4. Input frames: gameplay reads an `InputFrame` snapshot (move, look delta, buttons, seq) produced from `InputState`;
   no `Input.*` in rule code (`player_weapons.gd:147`, `tactical_player.gd:128`).
5. Seeded per-entity RNG for guns, bots, items, ballistics spread; no `randomize()` in rule code (seed from session).
6. Map changes only via `RangeMaps.go()`; end screens/menus call it.
7. `to_dict/from_dict` for PlayerState, bots (state needed to spawn mid-session), world items, projectiles.
8. Effects as events: shots/hits/reload/pickup emit signals (or one `TacEvents` bus per session) that audio/visuals
   subscribe to; RangeAudio already takes event dicts.

## Must not change
Any behaviour or number, feel, visuals, tests' expectations. `--range-test` (currently OK 513) all PASS unchanged, plus
new tests: two PlayerStates in one session have independent inventories/recoil mode; bots target the nearest of two
players; inventory requests reject invalid moves; same seed -> same spray/spread sequence; PlayerState round-trips
to_dict/from_dict. Main smoke 0 FAIL. Keep files under ~250 lines.

## Checks
From `godot/`: `godot --headless --path . --import`, then `godot --headless --path . res://scenes/firing_range.tscn --
--range-test | grep -E "\[range\] (OK|FAIL)"`, and `godot --headless --path . -- --smoke --quit=0.1 | grep -c FAIL` = 0.
Commit per step; push `feat/mp1`; report: what moved where, test count, anything you could not keep identical.
