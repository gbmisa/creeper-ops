# Brief A5 (Muse): titans, Nullifier and Outpost use the military models

**Branch:** `art/5-military-models`. Opus creates it from `main` **after A4 merges**, with the models already in it. A5 reuses A4's loader in the same mesh files, so don't start before then.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, A4's brief and the code it added, `command/titan_meshes.gd`, the `nullifier` function in `command/weapon_meshes.gd`, `outpost` in `command/support_meshes.gd`, and `_charge_null` plus the `Spin` code in `command/structure_behaviors.gd`.

## Models (Opus, `godot/assets/models/`)
Gregory asked for these to look **military** (olive drab, gunmetal, concrete, hazard stripes), not brass. Every file has `idle`/`walk` (identical, loop both), `attack`, `hit` and `die`. Real metres, facing +X.

| Structure | Files | Attach under |
|---|---|---|
| bertha, thor | `<id>_base.glb`, `<id>_turret.glb`, `<id>_arm.glb` | root (Thor: `Hull`), `Turret`, `Arm`, exactly as A4 does weapons |
| terp | `terp_base.glb`, `terp_spin.glb` | root, `Spin` (the crane and hammer; the code still turns `Spin`) |
| nullifier | `nullifier_base.glb`, `nullifier_core.glb` | root, `Core` (the code still spins and grows `Core` while charging) |
| outpost | `outpost.glb` | root (the radar turns in the clips) |

- The pivots match the procedural nodes. Turret, Arm, Muzzle, Spin, Core and Hull keep their transforms (smoke check within 1 cm).
- Bertha's gun is modelled tilted 0.7 rad inside the arm, matching the procedural `gun` node, so don't add another tilt.
- Thor's base hangs below the Hull origin (the hull bottom is at -1.3 m), the same as the procedural hull.
- **No shadow** (cast_shadow OFF) on meshes using `flash_white`, `fire`, `smoke`, `smoke_dark` or `arc_blue` that belong to the effect bones (`flash`, `smoke`, `arc`), and on the ground rings (`pulse`, `shock`). Easiest rule: no shadow for any mesh whose material is emissive or smoke.

## Clips
- **bertha, thor:** `attack` plays on the arm each shot, rate-limited to the clip length. `hit` and `die` work as in A4.
- **terp:** `attack` plays on `terp_spin` (with `terp_base` for the shock ring) each time the Terp edits terrain, at most once per clip length.
- **nullifier:** play `attack` on both parts once, at the moment it fires (charge complete). While it charges, play `idle`; the code's `Core` spin and scale stay on top.
- **outpost:** `attack` plays when it launches a packet, at most once every 0.6 s.
- Fallback: if any file of a structure is missing, or `CreatureAnim.disabled` is on, use the procedural build.

## Smoke rules
- Each of the 5 structures uses its models when the files exist, with all 5 clips.
- Pivot nodes match the procedural positions within 1 cm.
- With `CreatureAnim.disabled`, the procedural meshes are used.

## Must not change
Stats, aim, muzzle positions, Terp and Nullifier behaviour, the flight and landing code. Run L1 `--demo --units --sim=900` before and after; the results must match within noise.

## Report
AGENTS.md format, plus shot-tour lines for one of each structure.
