# Bench 512 (long): large-map readiness at 512×512 cells

**Agent:** Grok Build. **Worktree:** `creeper fps td-worktrees/bench512` · **Branch:** `stage/bench512` · **Progress log:** `docs/tasks/BENCH512_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) first. Runs alongside 9b, 19, 20 and Opus's Stage 21 (castles).
**Stay inside:** a new `level/level_bench.gd`, `core/debug.gd` (hooks), new `core/bench_*.gd` files, and, in P3 only, `level/raider_field.gd` + `world/terrain_chunks.gd` + `sim/creeper_mesh.gd`.

## Why
The user's map-size cap is **10× Level 2's area, about 512×512 cells (~1 km)**, with creeper flowing over the whole map every tick (no freezing far regions). The GPU sim is already measured at 512² (0.057 ms/tick on the RTX 5090). Everything around it hasn't been: the whole-map creeper mesh, terrain chunk count, the raider flow field re-plan after each terrain edit, headless CPU sim speed, memory.

## Phases
**P1 bench level.** `level/level_bench.gd` (`--level=bench`): 512×512, terraces 0..10 from layered noise (whole levels, CW3 style), 8 emitters spread out, 6 hives, 2 castles from existing level rows (copy a L2 castle row), landing site in the middle. Must load and pass `Placement.can_land` at its hint.

**P2 measure** (real display, Vulkan, `--rendering-driver vulkan`; and headless where noted). Write a table in the log:
- Frame time (avg, 1% worst) in command view at 3 zooms and in first person, at t=60 s and after creeper covers ~50% of the map (`--fast` or a `--flood` debug hook that raises every emitter's amount).
- GPU sim ms/tick (existing `--perf-sim=512`) and readback cost.
- Terrain: vertex count, chunk count, time to build at load, time to rebuild after `--raise` of a 6-cell disc.
- Raider flow field: wall time of `RaiderField.invalidate()` + re-plan after a terrain edit (instrument with `Time.get_ticks_usec`).
- Load time, memory (`Performance.MEMORY_STATIC`, video memory), headless CPU sim ms/tick.
- Same table for Level 2 (160²) as the comparison.

**P3 fix the worst one or two.** Budget: 60 fps on the RTX 5090 with headroom for a 3060 (assume 3.5× slower GPU). Likely fixes, only if the numbers say so: incremental flow-field updates limited to the edited region + its connected area; terrain and creeper meshes with distance-based detail (coarser chunks beyond ~150 m; the creeper mesh split into chunks that share the depth texture); spreading terrain-edit work over frames. Keep CW3 creeper rules and GPU/CPU parity untouched (`--gpu-parity` must still PASS). Smoke must stay green on L1/L2.

**P4 report.** Before/after table, what's still over budget, and recommendations for Opus (don't implement anything else).
