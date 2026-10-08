# Stage 20 (long): Art pass 2, motion and feedback

**Agent:** Grok Build, one long unattended session. **Worktree:** `creeper fps td-worktrees/stage20` · **Branch:** `stage/20-art2` · **Progress log:** `docs/tasks/STAGE20_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) and [JUDGE_art_rubric.md](JUDGE_art_rubric.md) first. Runs alongside the content run and flyers (Stage 19).
**Visual code only.** You may edit `*_meshes.gd`, `world/effects.gd`, `world/props.gd`, `world/world_look.gd`, `fps/weapon_models.gd`, `shaders/*`, and add new visual files. **No gameplay logic, Config gameplay numbers, defs stats or smoke-rule changes.** Animation hooks into logic must be one-line calls (e.g. `Effects.muzzle(...)` where a weapon already fires). Flyer models belong to Stage 19; don't touch `flyer_*`.

## Why
Stills now look decent (Stages 15, 18a, 18b), but nothing *moves or reacts*: weapons don't recoil, hits don't flash, raiders glide like chess pieces, deaths just vanish, explosions are small. The user judges felt feedback (memory: "polish + CW fidelity, verify visually"). The cave still has the old flat look. Some terrain spots read badly in first person (gentle 7c stair slopes show smeared, banded walls).

## Phases (each: build, screenshot, self-judge with the rubric, write the score and the worst 3 issues in the log, fix, commit)
**P0 audit.** Screenshots of the current state: `--demo --sim=120` (command), `--demo --sim=120 --surface`, `--gallery`, `--cave`, `--level=2 --castle=0,pad`, `--mortar --look=48,33,38,0.85`. Score each with the rubric. List the 10 weakest things you see, ranked. This list drives P1-P5 (adjust the phases to it and say so).

**P1 weapons react.** Recoil on every network weapon's barrel/arm when it fires, muzzle flash (short emissive flash + light) for cannon/sniper/mortar/Bertha/Thor, beam glow pulse, nullifier charge glow. A packet arriving pops a small flash on the receiver. Use `CPUParticles3D` (Xvfb runs GL compatibility, where GPU particles may not show).

**P2 hits and deaths.** Hit flash (brief white/red emissive) on structures, units, raiders, hive parts; raider death = burst of Blight goo particles + the mesh shrinking, not instant vanish; structure death = debris chunks and a dust puff; creeper splash particles where weapons strike creeper (`CreeperStrike` call sites: one-line hooks). Bigger, readable explosions for rockets, mortars and enemy mortar shells (ring shockwave + smoke).

**P3 creatures move.** Procedural walk cycles: raiders bob and swing limbs scaled by speed, Brutes stomp, Lancer charge glow builds, Burrower dust trail more visible, units (soldiers) walk and aim. Operative viewmodel sway and recoil kick in first person.

**P4 cave and terrain.** The cave: rock walls with strata (reuse `terrain_look.gdshaderinc`, `is_cave` is already a uniform), bioluminescent fungus props, colder fog, light shafts from the Rift. Terrain: fix the smeared bands on gentle stair slopes (look at `rock_wall`/`cliff` weighting in `terrain_look.gdshaderinc` for slopes between 0.2 and 0.5), add small grass tufts/rocks as props near the camera in first person only if cheap (MultiMesh).

**P5 UI feedback.** Floating damage numbers off by default but a `Config` toggle; HUD hit marker exists, make the kill confirm readable; the SPOTTED label (from the loot/spotted branch, if on main) gets a pulse. Keep within `ui/` files only for this phase.

**P6 performance check.** With all effects on, `--demo --units --sim=900` must not get slower than baseline by more than 10% (wall time, log both); cap particle counts in config.

**Wrap-up.** Final rubric scores per view vs P0, before/after screenshot pairs listed in the log. MASTER_PLAN: add a Stage 20 row (⚠) and one Changelog line.
