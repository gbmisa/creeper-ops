# Stage 19 (long): Flying enemies

**Agent:** Grok Build, one long unattended session. **Worktree:** `creeper fps td-worktrees/stage19` · **Branch:** `stage/19-flyers` · **Progress log:** `docs/tasks/STAGE19_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) first. Runs alongside the content run (9b/12/13) and art pass 2.
**Stay out of:** `command/structure_defs.gd` rows other than adding a `targets_air`-style key, `level/level01.gd`/`level02.gd` terrain code, `raider_meshes*.gd` and `structure_meshes.gd` (art pass 2 edits those: your models go in new files), `core/stockpile.gd`, ammo/extractor code.

## Why
The design promises flyers since Stage 2: "Beams are surface-to-air", "Sealing the last route to the Node is allowed; the enemy responds with mortars, and later flyers" (MASTER_PLAN, Enemies table: "Flyers | Ignore terrain | **Beams**"). Today Beams only shoot spore volleys. Flyers give Beams a job, punish turtling behind cliffs, and add an air layer for the Operative.

## Design (Opus, settled; numbers are starting points for Phase 6)
| Flyer | HP | Speed | Altitude | Behaviour | Unlock (pressure) | Loot |
|---|---|---|---|---|---|---|
| **Spore Bat** | 5 | 7.0 | 6 m | Flocks of 4-8. Dives at the nearest structure (prefers relays, collectors), 4 damage per dive, climbs and repeats every 2.5 s | 0.30 | 10% of 1 |
| **Gasbag** | 45 | 2.0 | 10 m | Drifts to a structure cluster and **drops a creeper blob** (`CreeperSim.add` 3.0 depth on one cell) every 8 s. Creeper bomber, the CW signature threat from the air | 0.50 | 3 |
| **Wyvern** | 90 | 5.0 | 8 m | Late heavy. Strafes weapons with a fire breath cone (12 dps for 2 s), hunts the Operative if within 30 m | 0.80 | 6 |

- **Flight:** ignore terrain and walls entirely; height = `max(ground under them, MAX of the 3x3 around) + altitude`, eased so they glide over cliffs. They never land. No flow field.
- **Spawning:** from a new hive part **Roost** (HP 40, appears at hive stage 2, at a free slot; killing it stops flyers from that hive). Flocks launch every `FLYER_INTERVAL` scaled by pressure. **Sealed-Node response:** when the sealed clock from Stage 8 (`enemy_mortar.gd`) arms, every active roost also launches a flock at the Node.
- **Who hits flyers:** **Beams** (primary: they already target spore volleys; give them the flyer list too), castle **Flak** turrets (they exist: make sure they hit flyers), the **Operative** (rifle hitscan works on anything in its targets list; rockets too), the **Lance**. **Not** cannons, mortars, snipers or units (CW rule: ground weapons can't hit air). Write that table into the log.
- **Shadows / readability:** each flyer casts a small dark blob on the ground below it (a terrain-shader uniform array like `shells`, max 32, or simply the mesh's shadow; pick the cheaper and say why) so a top-down player sees where they are.
- Flyers are enemies (`prey/enemies` dicts: `{ node, oy, radius, alive(), hit(dmg) }`) and shootable targets for the Operative (`{ node, oy, radius, alive(), on_hit(dmg, point) }`).

## Phases
**P0 baseline.** Smoke count; `--demo --units --sim=1500`, `--autostart --sim=900`, `--level=2 --demo --sim=1500` `[sim]` lines into the log.

**P1 flyer core.** `level/flyer_defs.gd` (rows above), `level/flyers.gd` (spawn, flight, targeting, damage, death; state as plain dicts, `state()`/`load_state()` like `Strongholds`), `level/flyer_meshes.gd` (a bat with flapping wings, a gas bladder with tendrils and a glowing sac, a wyvern with wing beats; Blight art style like the Stage 15 raiders). Wire into `game.gd` as wiring only. Debug hook `--flyers=TYPE,N` spawns N near the Node. Smoke (`core/smoke_flyers.gd`): each type spawns, flies over a 4-level cliff without slowing, a Bat dive damages a relay, a Gasbag drop raises creeper depth at its cell.

**P2 counters.** Beams target flyers (keep spore volleys), Flak hits flyers, Operative rifle/rockets and Lance hit them, ground weapons and units ignore them. Smoke: a Beam kills a Bat in range; a cannon with a Bat in range doesn't fire at it; Operative rifle hit registers.

**P3 roost + spawning.** Roost hive part (follow `hive_parts.gd`), flock launches scaled by pressure, sealed-Node flock. Unlocks by pressure via the flyer rows. Smoke: no flyers before 0.30; a stage-2 hive grows a roost; killing the roost stops launches; sealed Node triggers a flock.

**P4 Wyvern + Operative interplay.** Breath cone, Operative hunting within 30 m, the Operative can shoot it down. Smoke for the cone and the hunt.

**P5 readability.** Ground shadow blob, a HUD threat word ("AIR" in the top bar threat text, one-line change in `top_bar.gd`), sounds via `Sfx` (wing flap, gas drop, wyvern roar; procedural like the existing `audio_synth.gd` patterns). Screenshots: a flock over the base from command view; a Gasbag drop; a Wyvern from first person.

**P6 balance.** Re-run P0 sims. Targets: L1 demo Node survives 900 s (the demo has Beams: if it doesn't, add one Beam to `DEMO_BUILD`, don't nerf flyers to zero); undefended L1 dies no later than baseline; flyers visibly matter (log how many structures they killed). Tune only `flyer_defs.gd`/config.

**Wrap-up.** MASTER_PLAN: add a Stage 19 row (⚠) under Phase A and one Changelog line.
