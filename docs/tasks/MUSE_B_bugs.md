# Muse B: small bug fixes (2026-10-08)
Branch `fix/muse-b-bugs`, progress `docs/tasks/MUSEB_progress.md`. Follow AGENTS.md. Push only this branch; never commit `godot/.godot/`.

1. **FPS camera inside geometry.** Repro: `--demo --sim=60 --surface` (Xvfb shot by Opus): the Operative's camera starts inside a large orange curved mesh with a cream-coloured blob next to it. Find which node it is (print the meshes within 2 m of the camera at spawn) and fix the cause: the spawn position, or that mesh's placement or scale. Add a smoke check: no visible MeshInstance3D AABB contains the camera position at Operative spawn on L1 and L2.
2. **`RecoilDefs.cam` is dead data** (review of art/3-gun-feel): either scale the camera punch by it in `operative_weapons.gd` (keeping today's feel for the rifle: cam = 1.0) or remove the field and its smoke assert. Pick wiring it in.
3. **Weapon label:** the FPS HUD shows "[1] Pulse Rifle". Check Stage 23 (Pulse Rifle on 1, Crossbow on Y) against STAGE18c and report which is intended; if the label is already right, change nothing and say so.
4. **`hud.gd` is at 246 lines:** split one responsibility out (e.g. the alert/reason panels) before anything else grows it.
Report: what each was, file:line, smoke result.
