# Brief A4 (Muse): player weapons, Collector and Relay use animated models

**Branch:** `art/4-structure-models` (from `main`, with the models already in it: cannon, mortar, sniper and beam in 3 parts each, plus `collector.glb`). `relay.glb` follows on the same branch; until it lands, leave the Relay procedural. **Start now.** A3 runs in parallel, so don't touch the hive, Totem, pod or Node code.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, `command/weapon_meshes.gd`, `command/support_meshes.gd`, and `creature_anim.gd` plus its use in `hive_meshes` / creatures (the load/play/die pattern to reuse). Change only the mesh files, the code that plays clips, and smoke rules.

## Models (Opus, `godot/assets/models/`)
| Structure | Files |
|---|---|
| cannon, mortar, sniper, beam | `<id>_base.glb`, `<id>_turret.glb`, `<id>_arm.glb` |
| collector, relay | `<id>.glb` |

- **Weapons come in 3 parts** so the existing aim code keeps working. The base origin is at ground centre. The turret origin is the yaw pivot: the procedural `Turret` node's position. The arm origin is the shoulder pin: the procedural `Arm` node's position inside `Turret`. Each arm is modelled at pitch 0 with its head pointing **+X**, the same pose as the procedural arm.
- Real metres, scale 1. Clips on every file: `idle` and `walk` (the same; loop both at load), `attack`, `hit`, `die`.
- Glow materials are fixed per structure. Don't tier-swap or recolour them.
- **Effect meshes cast no shadow:** set `cast_shadow = OFF` on the meshes that use the materials `flash_white`, `ray_red`, `fire`, `flame` and `smoke` (muzzle flashes, the beam ray, the bolt trail).

## Tasks
1. **Weapons.**
   - Build the procedural tree exactly as today, so `Turret`, `Arm` and `Muzzle` keep their transforms and `WeaponLogic` aims them unchanged.
   - Then, when all 3 models exist and `CreatureAnim.disabled` is off, free every procedural `MeshInstance3D` under the root. Attach `_base` to the root, `_turret` under `Turret` and `_arm` under `Arm`. `Muzzle` stays where it is.
   - Fall back to the procedural meshes if any of the 3 files is missing.
2. **Clips.**
   - `attack` plays on the **arm** each time the weapon fires (recoil, flash). Rate-limit it to the clip length, so fast weapons such as the cannon restart it instead of stacking.
   - `hit` plays on all 3 parts on damage, at most once every 0.3 s.
   - `die` plays on all 3 parts on destruction; free the structure when the base clip ends. Keep today's effects (debris, flashes from brief X) unchanged.
3. **Collector and Relay.** Use `<id>.glb` in `SupportMeshes` and drop the code `Spin` rotation when the model is used; the clips turn the vanes.
   - Collector: `attack` is unused for now.
   - Relay: `attack` plays when a packet passes through it, at most once every 0.5 s.
4. **Construction.** Keep whatever the game shows for unbuilt structures today (scale, transparency, scaffold), applied to the model.
5. **Smoke rules:**
   - Each of the 6 structures gets its model(s) when the files exist, with all 5 clips.
   - A weapon with models still has `Turret`, `Arm` and `Muzzle` at the same positions as the procedural build (within 1 cm).
   - With `CreatureAnim.disabled`, the procedural meshes are used.

## Must not change
Weapon stats, aim rules, and the muzzle and shot origins. Run L1 `--demo --units --sim=900` before and after; the results must match within noise.

## Report
AGENTS.md format, including the shot-tour lines (brief S) for one of each structure, so Opus can screenshot them.
