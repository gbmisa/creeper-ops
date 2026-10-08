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

## P3 Improved ammo (done, one gap)
- New: `command/ammo_defs.gd` (numbers), `command/ammo_grades.gd` (rules, static state like `Upgrades`), `core/smoke_ammo.gd` (24 checks).
- Grades: Operative crossbow standard / AP / incendiary, rockets standard / cluster (4 sub-blasts), Snipers and Barracks (units) standard / AP / incendiary. `Ctrl + wheel` = new Global actions `ammo_next` / `ammo_prev` (pseudo keycodes `Keybinds.CTRL_WHEEL_UP/DOWN`, `Keybinds.key_name()`; `InputState` presses them only when Ctrl is held, so a Ctrl wheel never also zooms). No existing action renamed; `user://keybinds.cfg` untouched. The Controls menu shows the new rows; rebinding them to a wheel chord is not supported (a real key can be bound).
- Unlock: level key `"ammo_unlock": "<objective id>"`, unlocks when `Bus.objective_done(id)` fires. **Decision:** L1 and L2 use `"e1"` (Nullify the first Emitter). The brief says L1 "when the Deep Core objective becomes available", but that objective is available from the first second in this build (the list is static), so there is no event to hook; `e1` is the first Network milestone before the Operative dive. L2 pick: `e1` as well.
- Costs (design 5.3): AP / incendiary 12 Salvage per 30 crossbow rounds (0.4 each), cluster 15 per 3 rockets (5 each), network surcharge 0.5 Salvage per ammo packet (charged at launch; broke = standard packet).
- **Decisions:** a structure's magazine holds one grade, so switching grade drops its graded rounds (`Structure.grade_ammo`); graded rounds are used first, standard after. Barracks stock grade flows to docking units (`Unit.grade_ammo`, `UnitSupply._take_grade`); the surcharge is paid on the barracks' ammo packets. AP: +60% vs Brute/Ravager/Behemoth/Warden (raider `tier.name`) and ignores the Warden aura (`AmmoGrades.piercing`, read by `RaiderBurrow.filter`). Incendiary: +2 dps for 3 s on raiders (`AmmoGrades.tick` from `Game.update`) and removes 1.0 creeper at the impact cell. Raider `enemy`/`target` dicts now carry `tier`.
- **Gap (Repeater turrets): not done.** The Repeater fires from `level/castle_turret_fire.gd` (`best.enemy.hit.call(def.power[...])`), which the brief puts off limits (Opus rebuilds castles). Hook for Opus: replace that call with `AmmoGrades.shoot(best.enemy, def.power[s.level - 1], grade, world, p)` and give the turret socket a `grade` / `grade_ammo` like `Structure`.
- Small additive edits in `fps/operative_weapons.gd` (grade per round, tag in the weapon label, two `act()` lines) and `fps/rocket_launcher.gd` (`cluster` flag), kept clear of Stage 23's rework.
- Debug: `--ammo=ap|inc`. Screenshot: `scratchpad/stage9b/p3_hud.png` (HUD shows `[1] Crossbow [INC]`).

## P4 Level placement (done; ramps skipped)
- L1: 5 engines (1 safe wreck near the base; forge by the Central knoll hive; wreck beside the Bastion; bore by Spire Heights; forge by the Rift). L2: 11 engines (2 safe by the landing mesa; 4 hive-tagged; 5 castle-tagged). Cave: 2 (`Cave01.ENGINES`: bore in the east chamber, wreck in the south room), `cash_mode`: no network underground, so hooking strips the engine for 40% of its reserve at once (`EngineDefs.CAVE_CASH`).
- Sites picked with a scanner (flat 5x5 plus stair run, no Blight, not blocked, not Mat != natural); all sockets verified reachable on foot from the landing hint (L1/L2) and the recall pad (cave).
- Ore veins: all three per level are buildable ground, outside every hive claim, reachable on foot (new checks in `core/smoke_placement.gd`, 20 checks). No ore moved.
- **Ramp choke points: skipped.** The engine stairs add chokes by themselves; extra `LevelRamps` stairs would shift the L2 raider paths and the tuned sim baselines. Suggestion: revisit with the P6 numbers in hand.
- Screenshots: `p4_l1.png`, `p4_l2a.png`, `p4_l2b.png` (command view at 105-108 m so the minor markers show).
- Smoke: 531 PASS, 0 FAIL (full run).
