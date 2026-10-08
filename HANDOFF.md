# Handoff: 2026-10-08 (session 14: Stages 19, 21, 24 merged)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). Rules: [docs/CREEPER_SPEC.md](docs/CREEPER_SPEC.md); castles: [docs/CASTLES2_DESIGN.md](docs/CASTLES2_DESIGN.md).
**Roles:** Opus orchestrates and merges; delegated agents follow [AGENTS.md](AGENTS.md). Token rules: CLAUDE.md "Token budget rules" (`feature-dev`/`balance-tester`/`level-builder`, not general-purpose; no `stage-runner`/`auditor` agent types exist in this setup, use `feature-dev` / `balance-tester`).

## Merged to main this session
- **19 flyers** (Sonnet): Spore Bat, Gasbag, Wyvern, Roost at pressure 0.30 (`Config.FLYER_ROOST_P`). Hit by Beams, castle Flak (block at end of `CastleTurretFire._flak`, survived the 21 merge), Lance, Operative. Hooks `--flyers=T,N`, `--t0=S`, `--noflyers`.
- **21 Castles 2.0** (Opus): concentric castles, Operative-only roof layer (`Grid.roof`), capture gate → bailey → keep, trebuchets, held perks, tunables in `level/castle_defs.gd`. L1 has one compact castle (Ashmoat, SW); High Bastion is still Stage 7 style.
- **24 Play metrics** (Sonnet, Opus review): `PlayMetrics` records events, 10 s samples and a summary per mission to `user://metrics/*.json`. Report: `godot --headless --path godot -- --metrics-report[=N] [--metrics-dir=D]`. Sims write only with `--metrics=PATH`. Opus fix: surface→cave is one incursion. Post-merge hooks: `castle_held/hostile/siege`, `flyer_killed`.
- Conflicts were only registration lines (smoke_test.gd) and docs rows; resolved keep-both.

## Verified (merged main)
- Parse clean. Smoke OK, 0 failures (612+ checks).
- Sims: L1 `--autostart` Node dies 337 s (unchanged); L1 `--demo --units --sim=900` dies 704 s (36 flyers spawned, 12 killed); L2 `--level=2 --demo` dies 395 s.
- `--metrics-report` prints per-mission lines and per-level averages.

## NOT verified / needs the user
- **Nothing played by a human:** castles 2.0 interiors and capture, flyers, metrics files from real play.
- Demo sim is not deterministic (no fixed seed), so before/after comparisons are noisy.
- Ground raiders kill the L1/L2 demo bases before flyers matter; that's 9b's balance job.

## Open branches
- `stage/9b-content` (Salvage Engines, level placement, tuning): 1 commit ahead, **not reviewed**. Will conflict with 21 in `level01.gd`/`level02.gd` (castles moved hives and Thornwall).

## Next
1. **User: play a few missions** on L1 and L2, then run `--metrics-report`; tune difficulty from that (a `balance-tester` can read the JSON).
2. Review + merge 9b (resolve level placement against Castles 2.0).
3. 21b castles detail brief is ready (`docs/tasks/STAGE21b_castles_detail_long.md`, worktree not created).
4. Small: seed the RNG for `--sim` runs; count weapon move orders in metrics APM.
