# Stage 24: Play metrics (for tuning difficulty)

**Agent:** Sonnet (`feature-dev`). Two phases, then stop and report (AGENTS.md).
**Worktree:** `creeper fps td-worktrees/stage24` · **Branch:** `stage/24-metrics` (from `main`).
**Why:** the user wants the game to record how they play, so difficulty can be tuned from real sessions instead of only bot sims. Recording only. **Do not change any difficulty or balance number, and do not build dynamic difficulty** (that is saved design for Phase 3).

## Read only
AGENTS.md, CLAUDE.md (Architecture map, Key contracts, Testing), this brief, and the files you change. Skim `core/bus.gd`, `core/game.gd`, `core/game_flow.gd` (`end_game`), `command/economy.gd`, `core/stockpile.gd`, `level/pressure.gd`, `command/structure_manager.gd` (`remove`), `core/keybinds.gd` (how `persist` and `user://` are handled), `core/debug.gd`.

## Design (settled)
- **One recorder, fed by signals.** New `core/play_metrics.gd` (`class_name PlayMetrics`, RefCounted). `game.gd` creates it and calls `metrics.tick(dt)` from the loop: **2 lines in game.gd, no rules there.**
- **Generic event hook:** add `signal metric(kind: String, data: Dictionary)` to `bus.gd`. Systems report with one line: `Bus.metric.emit("structure_lost", {...})`. Future stages (flyers, castles) add their own one-liners; you don't touch those branches.
- **Three kinds of data**
  1. **Events** (timestamped by mission time `game.time`): structure built (type), structure lost (type, reason, `wet` = by creeper or not), structure recycled, Node hit, Node destroyed, Operative down, recall, enter/exit cave, deploy/drop, nest/hive destroyed, objective done, unit trained, castle state change if a signal exists on main (skip otherwise), mode switch (command / surface / cave), pause/speed change, victory/defeat.
  2. **Samples every `Config.METRICS_SAMPLE` s (10):** time, pressure (`Pressure.value`), energy, max energy, income, `economy.wasted`, ore, salvage, structure count by type, unit count, live raiders, creeper-covered cells (count of `depth > Config.MIN_DEPTH` on the surface; use the CPU copy, read-only), Node HP fraction, current mode.
  3. **Summary** at mission end (or quit): level id, won/lost, duration, cause of end, time in each mode, Operative deaths, incursions (count + total time), structures built/lost by type, lost-to-creeper vs lost-to-raiders, peak creeper cells, time with full bank (energy ≥ 98% max) and time starved (energy < 1 while anything requests), first-loss time, pressure at end, mean actions per minute (builds + orders + mode switches).
- **Storage:** one JSON per mission at `user://metrics/<level>_<YYYYMMDD-HHMMSS>.json` (`{summary, samples, events}`). Write on `end_game`, and also on quit/level change if the mission ran ≥ 60 s (partial: `ended: "quit"`). Never write anywhere else; never touch `user://keybinds.cfg`.
- **Tests and sims never pollute the player's folder:** `PlayMetrics.persist := true` static, smoke sets it false (like `Keybinds.persist`). Headless `--sim` runs write only when `--metrics=<abs path>` is given, so a bot run can be compared against human runs.
- **Switch:** `Config.METRICS_ON := true`. No UI toggle needed.
- **Report:** `godot --headless --path godot -- --metrics-report[=N]` prints the last N (default 10) missions from `user://metrics/`, one line each (level, result, duration, first loss, deaths, lost by creeper/raiders, starved %, full-bank %, command/FPS time split), then averages per level. Put this in `core/metrics_report.gd`, called from `debug.gd` with one line.
- **End screen:** add 3-4 short lines to the existing end screen (duration, structures lost, Operative deaths, "metrics saved"). No new panels.
- **Files under ~250 lines.** If the recorder grows, split events/samples (`play_metrics.gd`) from summary maths (`metrics_summary.gd`).

## Phases
- **P1 recorder:** Bus signal, `play_metrics.gd`, the emit lines (add `reason` to structure loss by emitting `metric` inside `StructureManager.remove`; do not change `structure_removed`'s signature), samples, JSON write, config keys, smoke file `core/smoke_metrics.gd` (registered with one line in `smoke_test.gd`): events recorded for a build, a loss by creeper, an Operative down; samples at the right interval; summary fields present and sane; `persist=false` writes nothing to `user://metrics`; `--metrics=` path write round-trips through `JSON.parse_string`. Commit.
- **P2 report + end screen:** `metrics_report.gd`, `--metrics-report`, end-screen lines, `--metrics=` on sims. Verify: run `-- --demo --units --sim=600 --metrics=<scratch>/demo.json --quit=0.1` and `-- --autostart --sim=400 --metrics=<scratch>/auto.json --quit=0.1`, then point the report at that folder (add `--metrics-dir=` for this) and paste its output in your report. Commit.

## Verify (CLAUDE.md Testing)
Parse clean, smoke all PASS (state the count; baseline on main is ~456), the two sims above with report output. Sim Node death times must match main (recording must not change the game). In MASTER_PLAN.md add a Stage 24 row set to ⚠ and one Changelog line.

## Report also
Every shared file you edited, with line counts; every emit site added; any event you could not find a hook for.
