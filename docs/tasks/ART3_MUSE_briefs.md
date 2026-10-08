# Art 3: Muse coding briefs (2026-10-08)

Muse writes the code; Opus builds the Blender models and judges the visuals. Context: [ART3_plan.md](ART3_plan.md).
**Every brief:** clone `https://github.com/gbmisa/creeper-ops`, check out the named branch, follow `AGENTS.md`, keep `docs/tasks/<ID>_progress.md` up to date, and **push only that branch**. Never touch `main`. Run the parse and smoke checks from CLAUDE.md "Testing" (steps 1-2) before every commit. If Godot 4.7 isn't available, say so in the report; Opus will run the checks.
The three briefs share no files, so they can run in parallel.

---
## F: gun feel (branch `art/3-gun-feel`, progress `ART3F_progress.md`)
1. Do [STAGE23b_viewmodel_polish.md](STAGE23b_viewmodel_polish.md) in full: arms, the Pulse Rifle model, spray brightness, crossbow reload.
2. Recoil feel: spring-damped viewmodel kick with recovery (no snapping back), a small camera punch (pitch and slight random yaw, which recovers), a recoil curve per weapon as data, Pulse Rifle bloom/spread that grows while LMB is held and recovers on release, and layered fire sounds (new procedural sounds in `audio_synth.gd`).
3. **Hard rule: time to kill stays the same.** Don't change any damage, HP, fire rate, range or ammo number. Feel only.
Files: `fps/*model*.gd`, `fps/viewmodel_motion.gd`, `fps/spray_fx.gd`, `fps/crossbow_fx.gd`, `fps/operative_weapons.gd` (feel calls only), `core/audio_synth.gd` (new sounds only), recoil data in `config.gd` or a new `fps/recoil_defs.gd`.
Done when: parse and smoke are clean, plus a smoke rule that a full Pulse Rifle magazine still kills the same test target in the same number of shots as before.

---
## X: effects (branch `art/3-fx`, progress `ART3X_progress.md`)
Do [STAGE20_art2_long.md](STAGE20_art2_long.md) phases **P1** (network weapons react), **P2 for structures only** (hit flash + death), **P4** (cave + terrain bands) and **P6** (perf: `--demo --units --sim=900` wall time no more than 10% slower than `main`). **Skip P3 and anything to do with raider, flyer or unit meshes** (Opus owns those) and the viewmodel (brief F owns that).
Files: `command/structure_meshes.gd` (+ split files if it grows past 250 lines), `world/effects.gd`, `world/props.gd`, `world/world_look.gd`, `shaders/*`.
Report the perf numbers (main vs branch) in the report.

---
## A: creature animation runtime (branch `art/3-creature-anim`, progress `ART3A_progress.md`)
Godot side of skinned creature models. Opus delivers the `.glb` files separately. Build it so it works with **zero** `.glb` files present (procedural fallback everywhere).
**Model contract (what Opus exports):** `godot/assets/models/<id>.glb`, where `<id>` is the lower-case tier/def name (`skitter`, `brute`, `spitter`, flyer ids, `soldier`...). There is one AnimationPlayer with clips `idle`, `walk` (looping, authored at 1 m/s ground speed), `attack`, `hit` and `die` (one-shots). The model faces **+X**, feet at y=0, and is authored at **u = 1** (the same unit as `_skitter(r, u, ...)`: Godot scales it by the same `tier.size * k` the procedural mesh uses). A material named `glow` on the model gets replaced with the tier's `StructureMeshes.glow(tier.color, 1.0)`.
1. New `level/creature_anim.gd` (`class_name CreatureAnim`): `make(id, scale, glow) -> Node3D or null` (null when there's no `.glb`; cache the loaded PackedScenes), `move(node, speed_mps)` (walk/idle blend, `speed_scale` = speed / (1 m/s × the model's scale), so feet don't slide; e.g. a Skitter scaled 0.9 walking 4.2 m/s plays walk at 4.67×), `attack(node)`, `hit(node)`, `die(node, then: Callable)` (plays `die`, then calls `then`; with no clip, calls it at once).
2. Hooks: `RaiderMeshes.make`, the flyer and unit mesh makers, and the hive core try `CreatureAnim.make` first and fall back to the procedural mesh. One call each in `raiders.gd`, `flyers.gd` and `unit_manager.gd` for move, attack and hit. **Raider death is no longer instant:** `Raiders.kill` removes it from targeting and collision at once, then frees the node after `die` (max 1.5 s).
3. A debug hook `--gallery`: every creature id in a row with labels, cycling clips every 2 s (for Opus's screenshots). Document it in `debug.gd`.
4. Smoke: with no `.glb`, every creature still spawns procedurally; with a test `.glb` (make a tiny one in code or skip if impossible), the clips exist and death delays the free.
Files: new `level/creature_anim.gd`, `level/raider_meshes*.gd`, `level/flyer_meshes.gd`, `level/hive_meshes.gd`, `units/unit_meshes.gd`, the one-line hooks above, `core/debug.gd`, smoke files.

---
## Muse prompt (paste one per brief; swap the letter)
> Clone https://github.com/gbmisa/creeper-ops and check out branch `<BRANCH>`. Read AGENTS.md, CLAUDE.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/ART3_MUSE_briefs.md section **<F|X|A>**, plus the files it links. Do that section and nothing else. Commit and push only to `<BRANCH>`. Never touch main, never merge. Report in the AGENTS.md format.
