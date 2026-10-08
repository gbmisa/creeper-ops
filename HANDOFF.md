# Handoff: 2026-10-08 (session 14: 19, 21, 24, 9b merged; playtest 1 fixes; Art 3 planned)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). Castles: [docs/CASTLES2_DESIGN.md](docs/CASTLES2_DESIGN.md). Playtest feedback + plan: [docs/tasks/PLAYTEST1_plan.md](docs/tasks/PLAYTEST1_plan.md).
**Roles:** Opus orchestrates and merges; delegated agents follow [AGENTS.md](AGENTS.md). Agent types available here: `feature-dev`, `level-builder` (Sonnet), `balance-tester` (Haiku). No `stage-runner`/`auditor`. **Muse Code** is joining over SSH: [Muse.md](Muse.md) §3b says how its first task is scored.
**User rule:** playtest feedback gets logged + planned for cheaper agents, not fixed inline (memory `playtest-feedback-workflow`).

## Merged to main this session
- **19 flyers**, **21 Castles 2.0**, **24 play metrics** (`user://metrics/*.json`, `--metrics-report`), **9b** Salvage Engines + ammo grades + Sniper ranged-first targeting.
- 9b merge fixes (Opus): FPS feel effects kept alongside ammo grades; L1 `DEMO` keeps the Ashmoat-safe chain + 9b's extra weapons; L2 engines e3 e4 e5 e7 e8 e9 moved clear of Castles 2.0 footprints; `smoke_placement` now names offending engines.
- **Playtest 1:** Sniper line of sight (`WeaponLogic.sees`, terrain + roofs block); enemy builder never builds under a castle roof (the "underground" Spitter Towers); sabotage shows a countdown, start/interrupt messages, reach 3 m; **Sniper ammo halved** (per_packet 2: 2.5 packets a shot); **hive cores 30 + 15×pressure HP** (was 150 + 100). Metrics hooks: castle held/hostile/siege, flyer kills.

## Verified
- Parse clean, smoke OK (0 failures) after every merge.
- Sims (after 19/21/24, before 9b): L1 undefended 337 s; L1 demo 704 s; L2 demo 395 s. Post-9b/playtest sims: see the last chat or re-run.

## NOT verified / needs the user
- Nobody has played since the fixes: replay L1 and say whether raiders are still "insane". Raider pressure was deliberately left alone (user believes Sniper ammo was the cause).
- The crossbow has no ammo grades (9b graded the Pulse Rifle); castle Repeater turrets have no grades.
- Demo sims aren't seeded, so they're noisy.

## Next
0. **Art 3 tonight (user is burning ~40% of the weekly limit before the reset, but wants it done efficiently):** follow [docs/tasks/ART3_plan.md](docs/tasks/ART3_plan.md). Create worktrees `art3-models`, `art3-feel`, `art3-fx` from `main`, then spawn: Opus for Track M P1 (Blender pipeline + Skitter), Sonnet `feature-dev` for F and X, and a Haiku `balance-tester` as the screenshot judge. Opus does the final pass and merge of each track. First ask the user how "Holding down left..." ended (their message was cut off).
1. **Muse:** run `PLAYTEST1_C_hive_sites.md` in worktree `playtest1c` (branch `fix/playtest1-hive-sites`); Opus reviews/scores it (Muse.md §3b). Fallback: Sonnet `level-builder`.
2. Then D: Haiku screenshot check of every enemy structure (visible + reachable).
3. User replays → `--metrics-report` → Haiku `balance-tester` tunes raider pressure if still needed.
4. 21b castles detail brief is ready (worktree not created).
