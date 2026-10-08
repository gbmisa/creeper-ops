# Stage 19 progress log (flyers)

Branch `stage/19-flyers`. Agent: Claude Sonnet 5.5.

## P0 baseline (before any flyer code; headless, machine shared with other runs)
- Smoke: 456 PASS, 0 FAIL.
- `--demo --units --sim=1500`: over at t=601 (Node dead; Brute 5, Skitter 28, Spitter 7). Known: the 9b run owns this.
- `--autostart --sim=900`: dies at 336 s (Skitter only).
- `--level=2 --demo --sim=1500`: dies at 364 s.

## Design table: who hits flyers
| Weapon | Hits flyers? |
|---|---|
| Beam (structure) | yes: spore volleys first, then the nearest flyer in range (`Flyers.strike`) |
| Castle Flak | yes: same, additive edit at the end of `CastleTurretFire._flak` |
| Orbital Lance | yes: `Flyers.strike_area` in `Orbital._strike` (one line) |
| Operative (rifle, rockets, all guns) | yes: flyers are in `world.targets` like raiders |
| Cannon, Mortar, Bertha, Thor, Sniper, units, Repeater, Lobber | no (they never look at the flyer list) |

## P1 flyer core: done
- New: `level/flyer_defs.gd`, `flyers.gd`, `flyer_ai.gd`, `flyer_meshes.gd`, `flyer_launch.gd` (roost + launches + `--flyers` demo, used from P3), `core/smoke_flyers.gd`.
- Wiring: `SporeNests` owns `flyers` (created in `_init`, updated in `update`, saved in `state()`/`load_state()`); game.gd untouched. `--flyers=bat|gasbag|wyvern,N` in debug.gd; sim report has `flyers` stats (spawned/killed/structures/drops).
- Spec gap: a flyer is NOT in `SporeNests.enemies()`, which is how units are kept from shooting it.

## P2 counters: done
- `WeaponLogic._beam` (after the spore loop), `CastleTurretFire._flak` (after the spore loop) and `Orbital._strike` (one line) call `Flyers.strike` / `strike_area`. **Merge note for Opus (castle rebuild):** the only edit in castle code is the block at the end of `_flak`: `var fp = Flyers.strike(world, at, reach, def.power[s.level - 1])` + burst + `return true`. If `_flak` moves, re-add that block.
- Operative: flyers are in `world.targets`; no weapon code edited. Smoke: Beam kills bat; cannon/sniper ignore; Flak fires; Lance area; rifle hits a Wyvern.

## P3 roost + spawning: done
- `FlyerLaunch.sync` (called from `Hives.tick`) grows a "roost" part at `Config.FLYER_ROOST_P` 0.30. **Spec gap:** the brief says hive stage 2, but HIVE_P2 is 0.70 after the Stage 8 rebalance, so bats (unlock 0.30) could not launch. Roost stage tag is 1; slot `roost` added to `HiveShape.OFFSETS`; `HiveMeshes._roost`; `Hives.base_hp` roost = 40.
- Flock interval lerps 50 s -> 22 s with pressure; cap `FLYER_MAX` 24. Sealed Node (`seal >= MORTAR_SEAL`) launches a flock with `node_bias` at once and every 40 s while sealed. A killed roost stays dead until the hive is rebuilt.

## P4 Wyvern: done
- Breath cone (12 dps, 2 s, 16 m, half-angle 0.45 rad) hits everything in `nests.prey` (structures, units, Operative). Hunts the Operative within 30 m, else the nearest weapon. Smoke for cone and hunt.

## P5 readability: done
- Shadow: a dark alpha disc per flyer on the ground (cheaper than a shader uniform array; no terrain-shader edit, works in the CPU/GPU paths alike). HUD: "AIR n" appended to the top-bar threat text. Sounds: flap, drip, roar, screech (`audio_synth.gd`). Screenshots in scratchpad/stage19: bats.png (flock over base, command view), gasbag_drop.png, wyvern_fps.png (first person), gasbag.png, wyvern.png.
- Wyvern wings are plain boxes: art pass can improve.

## P6 balance: partial
- With the stock sims flyers never appear: the Node dies at 624 s (L1 demo), 336 s (autostart), 369 s (L2) to ground raiders, before pressure 0.30 + roost growth (~625 s on L1, ~390 s on L2). Sims after (stock): L1 demo dies 624 s, autostart 336 s, L2 369 s: unchanged within noise, so "undefended no later than baseline" holds. The L1 demo not surviving 900 s is the pre-existing ground-raider problem (9b run); a Beam would not fix it, so DEMO_BUILD is untouched.
- New hooks to test flyers: `--t0=S` (start the mission clock at S), `--noflyers`. L1 demo `--t0=700 --sim=900`: 59 flyers spawned, 48 killed by the demo Beams, 3 structures killed, 3 Gasbag drops; node died at 233 s with flyers vs 228 s without. L1 `--t0=900`: 25 spawned, 21 killed, 3 structures; dies 94 s vs 108 s. L2 `--t0=400`: 72 spawned, 48 killed, 11 structures; dies 161 s vs 182 s. Flyers matter modestly and Beams counter them; numbers left at the brief's starting values.

## Suggestions
- Wyvern/Gasbag art (wing membranes), flyer markers in command view, Flak on Beam-free levels, include Roost in the L1/L2 objective text.
