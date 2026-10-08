# Stage 9b long run: progress log

Agent: Claude Sonnet 5.5 (delegated). Branch `stage/9b-content`. Brief: [STAGE9b_content_long.md](STAGE9b_content_long.md).

## P0 baseline (before any change, headless, 900 s sims)
| Run | Result |
|---|---|
| smoke | OK, 0 failures (full run, all PASS) |
| `--demo --units --sim=900` | Node dies at 615 s |
| `--autostart --sim=900` | Node dies at 336 s |
| `--level=2 --demo --units --sim=900` | Node dies at 390 s |
| `--level=2 --autostart --sim=900` | Node dies at 227 s |
(P0 baseline note: the brief says L2 demo "P0 - 60 s" floor, so the L2 demo target is >= 330 s.)

## P1 Engines exist (done)
- New: `level/engine_defs.gd` (kinds, numbers), `level/engine_shape.gd` (terrain stamp), `level/engine_meshes.gd` (models, sockets, cable), `level/salvage_engines.gd` (runtime), `level/engine_hook.gd` (hold-E interactable, cable, prey), `core/debug_engines.gd` (`--engine=I[,hold|hooked|top[,S]]`), `core/smoke_engines.gd`.
- Level 1 data: `ENGINES` (5) in `level01.gd`, stamped by `EngineShape.stamp_all` right after `HiveShape.stamp_all`.
- Decisions (spec silent):
  - **Stand surfaces**: the body is stamped into the heightfield (whole levels, `Mat.STONE`, `blocked=1`), so `Grid.stand_y`/`step_ok` just work. Body = floor + `top` levels (wreck/forge 4, bore 3). A south-face stair of one-level steps (walkable: CLIMB 1.1) reaches the top; nothing shorter does, so bodies are walls to everyone off the stair. A jump only reaches ~+0.9 level (6.4^2 / 2g = 1.14 m), so a 2-level gap is not reliably jumpable: "climb" means the stair, not a jump. Raiders can also climb the stair (RAIDER_CLIMB 1.1) which is part of the threat.
  - Sockets sit on the terrace ramp of the wall (not a vertical face): `EngineShape._socket` finds where the ramp is `lift` m above the Operative's standing cell. The ledge socket of the forge is on the stair face at level +2.
  - Socket reach: horizontal <= 1.5 m, chest height within 1.7 m (`near` key on the interactable).
  - `hold` interactables: new optional keys `hold` (seconds), `near`, `ready`, `progress` handled by `FpsMode._hold_use` (small additive change to `fps_mode.gd`).
  - `Packets.launch_route` added; `launch_return` now calls it.

## P2 Hook + ship (done)
- Shipping: 1 Salvage / 6 s / hooked socket from `reserve`, packets fly socket -> anchor -> network route reversed -> Node (return packets, no energy). Anchor = nearest built, connected, relaying structure within 8 cells of the socket (re-picked when it dies; cable follows).
- Pauses: creeper over the socket's standing cell (wet), a live hive in the row's `hive` key, a castle in the row's `castle` key not owned by the player. **Castle hook:** read through `Strongholds.list[i].owner == "player"` (same check as `Strongholds.held()`); no castle code touched.
- Prey: hooked sockets are in `Game.surface_prey()` (kind "socket", 30 HP clamp). Hit to 0 unhooks.
- Smoke: `core/smoke_engines.gd` (11 checks) + `core/smoke_engines_ship.gd` (16 checks incl. hold-E through `FpsMode._interact` with a parsed key event). `--smoke=engines` runs just those (dev shortcut, `SmokeTest.only`).
- Screenshots: `scratchpad/stage9b/p2_hold.png` (first person mid-hook, 24%), `p2_cmd.png` (command view, 2/2 hooked, Salvage arriving).
