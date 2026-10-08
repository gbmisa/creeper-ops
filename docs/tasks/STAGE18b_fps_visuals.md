# Stage 18b: First-person visuals (weapon model, sky, atmosphere)

**Agent:** Grok Build. **Worktree:** `creeper fps td-worktrees/stage18b` · **Branch:** `stage/18b-fps-visuals`
Runs alongside 18c (HUD) and 18d (drag-build). **Stay out of** `scripts/ui/*`, `scripts/command/*`, `shaders/terrain*.gdshader*`, `shaders/creeper.gdshader`, `shaders/noise.gdshaderinc` (Opus just rewrote those in 18a).

## Why
The user says first person looks bad. In `--demo --sim=120 --surface` the held crossbow is a few brown boxes, the dusk sky is a flat purple gradient, distant hills are smeared beige, and there is almost no depth haze. Ground and creeper shaders were fixed in 18a; this stage does the rest of the first-person picture.

## Do
1. **Crossbow model.** Find where the first-person weapon mesh is built (`fps/operative_weapons.gd` / `player_controller.gd`; grep "crossbow" or the BoxMesh that makes the stock). Move model building into a new static `fps/weapon_models.gd` (`class_name WeaponModels`) and build a proper fantasy crossbow from primitives: tapered wooden stock with a grip and shoulder rest, a bronze/iron prod (two curved limbs from 4+ angled segments each, thicker at the centre), a visible string (thin cylinder from each limb tip to the nut), a loaded bolt with a fletching, metal bands and the existing blue crystal as the sight. Use `StandardMaterial3D` with roughness/metallic per part (wood ~0.7 rough, metal 0.35 rough 0.8 metallic). Same for the sprayer and rocket launcher if they are also boxes: give each a recognisable silhouette. Keep the weapon's current screen position, scale and gameplay untouched.
2. **Sky** (`world/world_look.gd`, surface only). Keep the warm dusk mood (low amber sun in the east, violet-blue zenith) but make it read: give `ProceduralSkyMaterial` a visible sun disc (`sun_angle_max`, `sun_curve`), stronger horizon glow toward the sun, `sky_curve`/`ground_curve` tuned so the horizon band isn't a flat stripe. If you can do it cheaply, add a few high cloud wisps with a small sky shader (`shader_type sky`, value noise) instead of ProceduralSky. Make sure the sun direction in the sky matches the `DirectionalLight3D` (`sky` shaders get `LIGHT0_DIRECTION`).
3. **Atmosphere.** Distance haze that tints toward the horizon colour (`fog_aerial_perspective`, `fog_sun_scatter`, density so the far map edge is ~40% hazed), and in Forward+ enable `ssao_enabled` (radius ~1.5, intensity ~1.5) so cliff feet and structure bases get contact shade. Add a gentle `adjustment_*` pass only if it helps (saturation ≤ 1.1). The cave keeps its current look except SSAO.
4. **Don't** change gameplay, Config values, terrain or creeper shaders.

## Verify
- Parse check, full smoke (all PASS).
- Xvfb screenshots before/after (same commands), at least: `--demo --sim=120 --surface`, `--level=2 --castle=0,pad`, `--cave`. Note: Xvfb runs GL compatibility, where SSAO is off; say so in the report rather than faking it.
- Check `--demo --sim=120 --surface --rocket` so the rocket launcher model is visible, if it changed.

## Report (AGENTS.md)
Files, screenshot paths (before/after pairs), anything unsure. Set Stage 18b to ⚠ in MASTER_PLAN.md and add one Changelog line. Don't edit HANDOFF.md.
