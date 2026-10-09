# Brief PT3-G (Muse): Level 2 frame rate (playtest 3, item 30)

**Branch:** `pt3/l2-perf` (from `integ/2026-10-09`). Touch `level/raider_field.gd`, `level/raiders.gd` (field calls only), `core/config.gd`, and a smoke/bench file. Ask before touching anything else.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, `level/raider_field.gd`, `level/raiders.gd` lines 20-40 and 94-101.

## Gregory's report
> Low FPS on Level 2 in both modes, on an RTX 5090. "It's only slow when the game is unpaused. When paused, it runs buttery smooth."

So it is simulation (CPU script) time, not rendering.

## What Opus measured (headless, L2 `--autostart`, 60 s, ms per frame averaged)
| System | L1 | L2 |
|---|---|---|
| creeper sim (CPU; Gregory runs the GPU sim, Opus checks that separately) | 0.39 | 10.2 |
| **raiders: `field.update`** (RaiderField) | small | **3.88** |
| raiders: think (~20 raiders) | | 0.25 |
| hives, mortars, castles, units, structures | | < 0.5 each |

L2 is 160x160 (L1 80x80). `RaiderField.rebuild` runs a full-grid pass in **one frame** every `RAIDER_FIELD_INTERVAL` (2 s) and again on every `invalidate()` (every `Bus.terrain_changed`, e.g. each mortar crater), plus `_label_areas`. That is a big spike every 2 s or more often: it reads as stutter. `castle_field` likely has the same pattern.

## Tasks
1. **Measure first:** add a bench hook (`--bench-field`) that prints the cost of one `rebuild` and one `_label_areas` on L1 and L2, and how many rebuilds happen per minute in `--level=2 --autostart --sim=600`. Report the numbers.
2. **Time-slice** the rebuild: compute the new field over several frames into a back buffer with a per-frame budget (`RAIDER_FIELD_BUDGET_MS`, start 1.0), then swap. Raiders keep using the old field until the swap. Same for `castle_field` and `_label_areas`.
3. **Coalesce invalidations:** many `terrain_changed` events within a short window trigger one rebuild, not one each (but a rebuild in progress restarts if terrain changed under it).
4. Hot loop clean-up where it is cheap: packed arrays instead of Dictionaries/Arrays in the BFS, no per-cell allocations, `grid.idx` inline.
5. **Results:** worst single-frame cost of the field on L2 under 2 ms; raider behaviour unchanged (existing raider smoke checks still pass; add one that a raider reaches the Node on a fixed L2 seed in about the same time as before, ±10%).

## Must not change
Raider pathing rules (one terrace up/down, reachability, castle missions, gates).

## Report
AGENTS.md format with before/after bench numbers and the L2 per-frame worst case.

## Addendum (Opus, GPU run on Gregory's RTX 5090, L2 `--autostart`)
- 25-43 fps, falling as enemies pile up: 67 -> 100 animated skeletons, draw calls 5.4k -> 10k, nodes ~8.5k (L1: 215 fps, 21 skeletons, 3.3k draws).
- `Game.update` averages 6-12 ms with **150-185 ms single-frame spikes** from `surface_hazards` -> raiders -> `RaiderField` (task 2 above).
- GPU creeper sim costs ~3.4 ms/frame on the CPU side (readback `to_float32_array` + log replay on 25.6k cells): look at doing the replay in packed ops or every other readback.
- The rest of the frame grows with enemy count outside `Game.update`: AnimationPlayers/skeleton poses per raider, per-raider meshes. Pause looks smooth because `CreatureAnim.set_all_paused` zeroes `speed_scale` (pose stops changing).
- Extra tasks: (6) animation LOD: raiders off-screen or farther than ~60 m get `callback_mode_process` manual and are advanced at 10 Hz (or paused); (7) report draw calls per raider and merge static sub-meshes per raider type if > 3; (8) a `--bench-l2` hook that prints avg/worst frame ms after 5 min of `--autostart`, before and after.
