# Handoff: 2026-10-10 (playtest 4: fixes and perf merged, ready for Gregory's playtest, Opus)

## State
Godot 4.7 game in `godot/`. **Gregory plays this worktree** (`creeper fps td-worktrees/integ`, branch `integ/2026-10-09`, see RUN.md), not `main`. Do all gameplay work on branches cut from it.
Plan and log: [docs/tasks/PLAYTEST4_plan.md](docs/tasks/PLAYTEST4_plan.md) (feedback, decisions, perf findings). Briefs: `PLAYTEST4_briefs.md`. Logic audit: `PLAYTEST4_audit.md`.
Nothing is pushed to GitHub. `main` is 170+ commits behind integ.

## Merged into integ today (smoke only, not yet played by Gregory)
`pt4/port` (Z deactivate, Esc pause menu), `pt4/units` (attack order, move beats combat, retaliation, auto-patrol, mortars untargetable, free mortar sabotage), `pt4/alerts` (base alerts in first person, castle grace until the reprisal launches, trebuchets revive only on retake), `pt4/deploy` (choose Node or any Totem, recall measured to the nearest site), `pt4/trebrange` (click a trebuchet for range rings), `pt4/l2space` (L1/L2 trebuchet `engine_range` 12, one engine moved), plus Opus inline: Shield Dome needs no charge, crown nest takes a charge, Burrower banned on L1/L2 (`raider_ban`), prompts follow rebinds (`Keybinds.fill`), marker label caching.

## Perf (top priority). Tool: `core/perf_probe.gd`
`godot --path godot --rendering-driver vulkan -- --level=2 --demo --units --nocapture --probe-base --perf-probe=28` (real display, ~15 min). Headless gives sim numbers only: `godot --headless --path godot -- --level=2 --demo --units --perf-probe=4 | grep "^\[probe\]"` (~90 s). `HITCH` lines = one update over 60 ms, with ms per surface updater (index 5 = EnemyBuilder).
Findings (L2, minute 28, 1440p, RTX 5090): sim-bound, not GPU-bound (240 fps cap with the sim frozen; 62 fps command / 49 fps first person running). Zero terrain edits, no node leak: **the static-map / pathing rework is dropped.**
**Perf branches merged 2026-10-10** (`pt4/perf-builder`, `pt4/perf-enemies`, `pt4/perf-units`; smoke 0 failures twice; numbers in PLAYTEST4_plan.md, "Perf merge"). Headless L2 `--units --perf-probe=4` on the merged build: 2 hitches of ~80 ms (was ~56, up to 949 ms). Enemy update 2.65 -> 1.63 ms (target 1.2 missed; the rest is per-raider `RaiderMove.walk`). **Display probe not re-run**, so fps at minute 28 is unknown.
Open, not assigned: creeper GPU sim CPU side 5.3 ms per `update(0.05)` (readback + CPU anti-creeper tick, `sim/creeper_gpu.gd`); shadow pass doubles draw calls in first person (10.5k vs 5.5k; 150 -> 204 fps with shadows off, sim frozen).

## Known issues
- Smoke `attack order: holds after kill (attack)` (smoke_unit_orders.gd) fails about 2 runs in 3 on integ. Everything else passes.
- L2 spacing only partly met: engines e3, e4, e5, e10 still inside or near trebuchet reach; safe corridor reaches W and S edges only. Gregory will direct moves from playtesting.
- Retaliation targets the nearest enemy within 30 m, so not Lancers (64 m).
- Audit item 3: Operative respawn can wait forever if Salvage runs out. Gregory: will judge in playtests.
- File length: ~250 lines is a default, not a cap (Gregory, 2026-10-10). Split only files that mix responsibilities.

## Next steps
1. **Gregory playtests integ** (L2 with units is the perf case). Log feedback as Update N in the plan (workflow: log, brief, cheap agents, Opus merges).
2. Re-run the display probe (`--probe-base`, minute 28) and record fps before/after in PLAYTEST4_plan.md.
3. Creeper sim CPU cost and first-person shadows (Opus or a Sonnet brief with probe numbers).
4. **Pathfinding in Rust (Gregory, 2026-10-10: noted, not started; do it in a fresh session, not a long one).** Port unit pathfinding (`units/pathfind.gd`), then the raider flow field (`level/raider_field*.gd`) if still over budget, to a Rust GDExtension (`gdext`) behind the same `Pathfind.find` / `RaiderField` interface, keeping the GDScript version as the headless/test fallback. `pt4/perf-units` has landed (GDScript A* is now ~9 us per node, so measure first whether a port is still worth it); the remaining enemy cost is `RaiderMove.walk`, so a raider port must move the whole walk step in one batched call, not just the field lookup. Needs a brief (build steps, `.gdextension` file, Linux target) and a Sonnet agent; Opus reviews.
5. Push integ to GitHub and tell Muse (docs/tasks/MUSE_NOTES.md) when Gregory agrees.
