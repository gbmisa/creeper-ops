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
