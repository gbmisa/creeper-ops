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

## P5 Sim report fields (done)
- `[sim]` report now carries `salvage`, `salvage_earned`, `salvage_left`, `ore_mined`, `pressure`, `sockets_hooked`, `win_time` (-1 until the last required objective completes), `objective_times` and `mix` (structure counts). `Stockpile.earned_salvage/earned_ore`, `Game.win_time/objective_times`.
- `--demo` now hooks the nearest safe engine at 120 s (every socket, free relay chain, no Operative walking): `DebugEngines.demo`. Documented in the `debug.gd` header.

## P6 Tuning (done; numbers below are headless sims, 900 s)
| Run | P0 | Now |
|---|---|---|
| L1 `--demo --units` | Node dies 615 s | **900 s, Node 500/500, 6 of 6 runs** (was 642-785 s before the rules below) |
| L1 `--autostart` | 336 s | 336, 337, 337 s (inside the noise of P0; not tuned) |
| L2 `--demo --units` | 390 s | 434, 643, 638 s (floor P0 - 60 = 330 s) |
| L2 `--autostart` | 227 s | 226 s |
- **Rule changes (player side; Spitter untouched at HP 10 / range 20):**
  1. A Sniper picks ranged raiders (`tier.role == "ranged"`: Spitter, Lancer) in range before nearer melee ones (`WeaponLogic._snipe`).
  2. Sniper range is measured on the ground (xz), like the enemy ranged weapons. Before, a Spitter on the flat out-reached a Sniper standing a mesa above it (3D distance), which is why the demo's Snipers lost the stand-off. This was the big fix: 2 of 6 runs survived before it, 6 of 6 after.
  3. Better scripted `DEMO_BUILD` (debug.gd): 5 more Snipers, 3 more Beams, 4 more Cannons, 5 Reactors, 1 Storage. Spore volleys killed the forward Cannons and then the creeper took the Node, so the extra Cannons and Beams matter.
  4. The demo spends Salvage on armour-piercing Snipers while the stockpile holds more than 60 and buys the railgun (60) at 840 s (`DebugEngines.spend`).
- **Ranged counters at unlock (L1 demo):** Spitter unlocks at pressure 0.10 (390 s): 7 Snipers, energy 1/120 (demand 8.7/s vs income 4.4/s: tight but nothing dry), Salvage 88 earned and spent on AP. Lancer unlocks at 0.55 (about 850 s): its 32-cell beam out-ranges every Sniper (20, max 28 with Fire Range), so the counter is the Operative's railgun, bought for 60 Salvage from the fund the demo keeps; at 850 s the demo base has fallen to 1 Sniper and 2 Beams but the Node holds to 900 s. Spotter (support) 0.70 and Warden (support, AP ignores its aura) have no separate counter need.
- **Leftover Salvage:** at 900 s the demo holds 1-5 of 120 earned (1-4%); one run held 55 (the railgun purchase missed by 5). Target 20%: met.
- **Pressure cap vs objective time:** L1 cap is 2400 s; the demo completes only `e1` (at 2 s), so the cap is later than any objective it completes. A real winning time needs a human run (the demo cannot dive or climb).
- L2 demo engine: the bore ships only ~8 Salvage in 180 s (the demo relay chain is often wet); left as is.
- New: `core/smoke_tuning.gd` (6 checks). Full smoke: 537 PASS, 0 FAIL.

## Not done / needs Opus
- Repeater turret ammo grades (castle file; hook given under P3).
- Ramp choke points (P4).
- Nothing played by a human: hooking feel, cable look, marker text overlap on long guard notes, Forward+ look.

## Suggestions
- The marker label for a guarded engine is long ("... ships nothing until the Rift hive is razed"); shorten or move the guard note to the info panel.
- The forge at the Rift (L1 e5) sits right at the Operative's usual drop point; fine now (debug drop moved 3 cells), but a Totem near it is a natural first hook.
- Consider `Sentinel`-style snipe_foes ordering and Spotter handling when flyers land (Stage 19 owns `level/flyer*`).
- A keybind-menu capture for Ctrl + wheel so players can rebind the ammo chord.
