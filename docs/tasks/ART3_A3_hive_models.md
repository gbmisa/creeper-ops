# Brief A3 (Muse): hive structures, Totem and drop pod use the animated models

**Branch:** `art/3-hive-models`. Opus creates it from `art/3-integration` after A2 is merged, with `art/3-models` merged in, so the models are already there. **Don't start until that branch exists.**
**Read:** AGENTS.md, this brief, and `docs/tasks/ART3_A2_integration.md` (for the CreatureAnim API as it stands). Change only the files listed below plus a smoke rule.

## Models (Opus, `godot/assets/models/`)
`hive_core`, `hive_pit`, `hive_spitter`, `hive_launcher`, `hive_mortar`, `hive_roost`.
- **Scale and orientation:** real metres, scale 1, origin at ground centre, feet at y = 0. The spitter and mortar face **+X**.
- **Clips:** `idle` and `walk` (identical, loop them at load as for creatures), `attack`, `hit`, `die`.
- **Materials:** the glow materials have fixed colours per kind and are **not** tier-swapped. Don't recolour them.

## Tasks
0. **Carried over from A2** (Opus merged A2 without them): the gallery camera for `--gallery=anim:<id>` (A2 task 2), the perf numbers (A2 task 5), and the `glow` material on low tiers rendering cream instead of the tier colour (green on skitters). The `die()` tree guard is already fixed (`022b25a`).
1. **`HiveMeshes.part(kind)`** (`level/hive_meshes.gd`): when `CreatureAnim` has the model `"hive_" + kind`, return it, playing `idle`. Keep the procedural mesh as the fallback (and under `CreatureAnim.disabled`). This covers `enemy_mortar.gd:148` and `flyer_launch.gd`, which call it too.
2. **Attack hooks.** Play `attack` once at each of these, then go back to `idle`:
   - pit: when a raider spawns from it (`hives.gd` / `hive_spawning.gd`).
   - spitter: when it fires (`hive_parts._spitter`).
   - launcher: when it fires a volley (`hive_parts._launcher`).
   - mortar: when the enemy mortar fires (`enemy_mortar_fire.gd`).
   - roost: when it launches a flyer (`flyer_launch.gd`).
   - core: when the nest spawns, or whatever its existing pulse marks.
   - Also, the spitter and mortar **yaw to face their target** when they fire. The model's +X is forward, so `rotation.y = atan2(-dz, dx)`.
3. **Hit and die.** `hit` plays in `HiveParts.hurt` (rate-limit it to one every 0.3 s). `die` plays when a part is destroyed, and the node is freed when the clip ends (`CreatureAnim.die(node, then)`). Keep whatever the game does today (effects, salvage) unchanged.
4. **Growth.** If a part grows in (`grown == false`, or by stage), keep the current scale-up behaviour and apply it to the model root.
5. **Smoke rules:**
   - Each of the 6 kinds loads a model with all 5 clips.
   - With `CreatureAnim.disabled`, `part()` still returns the procedural mesh.
6. **Hook.** Make `--creatures=near` also work for hives, or add `--look` coordinates for the nearest L1 and L2 hive to the RTS camera hook, so Opus can screenshot them. Name the command line in your report.

## Totem and drop pod (also Opus models, same folder)
7. **`totem.glb` is the structure `beacon`.** Use it in `SupportMeshes.beacon` (keep the procedural mesh as fallback). It's about 2.9 m tall, so check `StructureMeshes.top_y("beacon")` (2.7) and raise it to about 3.2 if the bars clip. Play `attack` when the Operative deploys from it (`OperativeDeploy`), `hit` on damage and `die` on destruction. Note: the model's `glow` is unused; its glow material is a fixed teal.
8. **`drop_pod.glb` is new.** The `@drop` currently shows only a beam (`OperativeDeploy._tick_pod`). Change it to:
   - Spawn the pod about 60 m above the target cell, playing `walk` (falling, flame on).
   - Move it down over `Config.DROP_TIME`, easing in so it accelerates. Keep the existing beam as a guide.
   - On arrival, play `attack` (touchdown: dust ring, doors open) and spawn the Operative as today.
   - Then play `idle`. After `Config.POD_LINGER` (a new tunable, about 6 s) play `die` (it sinks) and free it.
   - Smoke rule: the pod node exists while the drop is pending and is gone after linger + die.

## Must not change
Hive HP, damage, ranges, rates and spawn logic. Run L1 `--autostart --sim=600` and `--demo --units --sim=900` before and after; the results must match within noise. Put the numbers in your report.

## Report
Use the AGENTS.md format. Include the hook command line for Opus's screenshots, and anything about the models that looked wrong (scale, facing, floating).
