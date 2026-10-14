# Handoff: 2026-10-13 (Firing Range + Tarkov-style combat module merged into integ, Opus)

## NEW 2026-10-13: Firing Range (separate scene; the main game is unchanged)
Play: `godot --path godot res://scenes/firing_range.tscn` (or `godot/tools/range.sh`). Brief + log: `docs/tasks/RANGE_brief.md`, `RANGE_progress.md`. Screens: `docs/art/range/`.
- `scripts/tactical/` = reusable Tarkov-style combat module (ballistics with drop/drag/zeroing, armor pen formula, world-material penetration + ricochet, 7-zone health with spill/bleeds/fractures, magazines + chamber, malfunctions, recoil/sway/ergo). `scripts/range/` = level, player, viewmodel, HUD, targets, kill house + 2 Scav bots (perception, warm-up aim, cover, heal, flank, suppress, search).
- Guns (CC0/CC-BY, `assets/models/guns/CREDITS.md`, sources in `art/guns_src/`): M1911, P90, AK-47, M870, M1 Garand, AXMC .338. No free MG / grenade launcher model, so those classes are out.
- Only change outside the new folders: `keybinds.gd` gained 24 `t_*` ids and a "Tactical" group (shows in the Controls screen).
- Verified: `--range-test` OK 80, main smoke 0 FAIL, 60 s bot soak clean, Xvfb screenshots. **Not verified:** real mouse/keyboard play, audio by ear, bot difficulty, GPU (Vulkan) look.
- Next: Gregory playtests the range; then decide how operatives + Tarkov bots enter the RTS (his new direction: fewer, smarter enemies, objectives and pressure instead of doom-stacking, several operatives).

## Earlier (2026-10-10)

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

## Playtest 4 afternoon (Updates 7-15 in PLAYTEST4_plan.md; briefs R, S, G, H, C in PLAYTEST4_briefs.md)
**Hard rules added today (CLAUDE.md, AGENTS.md):** change only what Gregory named; perf/refactor must be behaviour-identical; a change to working behaviour goes in `CHANGES.md` (repo root) for his ruling, never a yes/no in chat; remind him to review it when it gains entries. `CHANGES.md` has 15 entries (unrequested changes from the perf merges) plus proposal P1 (unit attack re-pathing), no rulings yet.
Merged into integ after the perf merges, smoke 0 failures: `pt4/salvage` (engines ship once hooked, no hive/castle gate), `pt4/guards` (Sentinels, wall patrols, Warden, castle Lancers never respawn; back only on a retake), `pt4/threat` (time after grace doubled on L1 and L2), `pt4/hook` (sockets are not prey; only a dead/removed anchor unhooks), `pt4/castle-rate` (garrison HP budget 0.75 x tier-3 rifle DPS = 9.4 HP/s; only bites after a Behemoth), `pt4/raider-commit` phase 1 at `af92d9f` (raiders keep one target and one route, `RaiderPaths`), and a one-line revert in `hive_spawning.gd` (cached Sac node threw "previously freed instance").
**Brief R is complete and merged (phase 2 `e1fef8e`: lock-on for moving targets, shooters keep their pick, Spitters fire only along a clear lob).** Raider pathing is verified on L2 (`--level=2 --raider-probe`): per-target walking-distance fields (`RaiderPaths`, 1 ms per frame builds), 0 s backtracking, 1.25 ms largest frame; `units/` untouched. The first version merged for the playtest (per-raider A*) was bad on the real map and is replaced.
Pushed to GitHub: integ at `463989f` only (before every fix above).

## Next steps
1. Gregory playtests integ (restart the game). Log feedback as Update 16+.
4. Gregory's rulings on `CHANGES.md` entries 1-15; revert what he rejects.
5. Display perf probe (`--probe-base`, minute 28) not re-run since the perf merges.
6. Pathfinding in Rust: noted, not started; measure first whether it is still needed (unit A* is about 9 us per node; raider cost is `RaiderMove.walk`).
7. Push integ and note Muse (docs/tasks/MUSE_NOTES.md) when Gregory says so.
