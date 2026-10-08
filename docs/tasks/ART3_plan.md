# Art 3 plan (2026-10-08): real models, enemy animation, gun feel

User feedback, logged as given: "Graphics still not very good. No animations for the enemies. Gun recoil doesn't feel good, but time to kill can't be insane. Later: ammo reserves the player carries in an inventory, so they can't blast through the whole level. Holding down left..." (**cut off: ask the user how it ends**, probably Pulse Rifle auto-fire on held LMB).
**Budget note:** the user wants to burn about 40% of a weekly limit before tonight's reset, but still efficiently. **Cheaper agents do the groundwork; Opus does the final pass on each track.** Run at most 3 agents at once (plus Muse if it's on `playtest1c`).

## Facts (checked)
- Blender **5.2 LTS** is installed (`/snap/bin/blender`) and runs headless: `blender -b --python script.py`. Subagents can script models with bpy through Bash; no MCP needed.
- No imported models exist: every mesh is procedural GDScript (`level/raider_meshes.gd` + `raider_meshes_ranged.gd`, `flyer_meshes.gd`, `hive_meshes.gd`, `units/unit_meshes.gd`, `command/structure_meshes.gd`, `fps/weapon_models.gd`). Raiders are removed instantly (`Raiders.kill` → `queue_free`).
- `STAGE20_art2_long.md` and `STAGE23b_viewmodel_polish.md` were never run; their worktrees are stale. Make **new** worktrees from `main`.

## Tracks
| Track | Worktree / branch | Groundwork agent | Final pass | Files it owns |
|---|---|---|---|---|
| **M: Blender models + skeletal animation** | `art3-models` / `art/3-models` | **P1 pipeline + Skitter: Opus** (new cross-system pipeline; say why in the spawn). **P2-P4: Sonnet `feature-dev`**, ≤2 phases each, resuming from `docs/tasks/ART3M_progress.md` | **Opus:** review screenshots via a Haiku verdict, fix the worst 3, merge | `art/blender/*.py` (new), `godot/assets/models/*.glb` (new), `level/raider_meshes*.gd`, `flyer_meshes.gd`, `hive_meshes.gd`, `units/unit_meshes.gd`, new `level/creature_anim.gd`; one hook line each in `raiders.gd` / `flyers.gd` / `unit_manager.gd` (move speed, attack, death) |
| **F: gun feel** | `art3-feel` / `art/3-gun-feel` | **Sonnet `feature-dev`**: 23b brief (arms, Pulse Rifle model, spray brightness, crossbow reload) **plus** recoil feel: spring-damped kick with recovery, camera punch, per-weapon recoil curve, Pulse Rifle bloom while LMB is held, sound layering. **No damage, HP, rate or range numbers change** (time to kill stays). | **Opus:** feel review from Xvfb shot pairs + the user's play | `fps/*model*.gd`, `fps/viewmodel_motion.gd`, `fps/spray_fx.gd`, `fps/crossbow_fx.gd`, `fps/operative_weapons.gd` (feel calls only), `audio_synth.gd` (new sounds only) |
| **X: effects (Stage 20 minus creatures)** | `art3-fx` / `art/3-fx` | **Sonnet `feature-dev`**: Stage 20 P1 (network weapons react), P2 (hit flash + deaths for **structures only**), P4 (cave + terrain bands), P6 (perf ≤10%). **Skip P3 and all raider/flyer/unit meshes** (Track M owns them) and the viewmodel (Track F). | **Opus:** rubric scores before/after, merge | `command/structure_meshes.gd`, `world/effects.gd`, `world/props.gd`, `world/world_look.gd`, `shaders/*` |
| **J: screenshot judge** | n/a | **Haiku `balance-tester`**: after each phase, judge the shots with `JUDGE_art_rubric.md` and reply in words (Opus never reads images in its own session) | n/a | none |

### Track M phases
- **P1 (Opus): pipeline.** `art/blender/lib.py` (materials as vertex colour + a few PBR mats matched to the game palette, low-poly 300-1500 tris, armature helpers, export glTF with animations named `idle`, `walk`, `attack`, `hit`, `die`). `art/blender/build_all.sh` rebuilds every `.glb`. Godot side: `CreatureAnim` loads `res://assets/models/<id>.glb`, scales it to the current procedural size, plays `walk` with speed scaling, one-shots `attack`/`hit`, plays `die` then frees (raider death no longer instant). **Fallback:** if a `.glb` is missing, use the old procedural mesh. **Skitter end to end**, with smoke (model loads, every clip exists, death delays the free) and an Xvfb shot. Commit.
- **P2 (Sonnet):** Brute, Ravager, Behemoth, Sentinel. **P3 (Sonnet):** Spitter, Lancer, Warden, Spotter, Burrower. **P4 (Sonnet):** flyers (wing flap = `walk`), soldier and wagon units, hive core pulse.
- **P5 (Opus, final):** Haiku judges every creature in `--gallery` and in-game. Opus fixes the worst issues, checks perf with `--demo --units --sim=900` wall time (≤10% slower), and merges.

## Not now (logged for design)
- **Ammo reserves + inventory** for the Operative (carried rounds per weapon, resupply at Totem/Node/barracks or loot, HUD count). This changes balance, so **Opus designs it after the playtest-1 debugging is done**, then Sonnet builds it. It interacts with 9b's ammo grades (`AmmoGrades`) and the Armoury.
- The sentence that ends "Holding down left": ask the user.

## Merge order
F and X touch different files, so they can merge as they finish. M merges last (largest). Merge `fix/playtest1-hive-sites` (Muse) whenever it's ready; it only touches level files.
