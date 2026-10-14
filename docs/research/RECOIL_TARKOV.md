# Tarkov-style recoil: research and proposal (2026-10-14)
Gregory: "Do my research on Tarkov style recoil. It didn't feel great this morning."

## How Tarkov (and its best mods) model it
- **Two layers.** *Weapon recoil*: the gun/barrel kicks up and back. *Camera recoil*: the view follows only part of it.
  Bullets leave along the barrel, so the reticle climbs while the screen moves much less. BSG's patches tune
  "camera recoil" separately and cut it by 20 % for all weapons in 0.13.0.2 because heavy camera kick made guns
  unusable ([GGRecon](https://www.ggrecon.com/guides/escape-from-tarkov-0-13-0-2-patch-notes/),
  [AFK Gaming](https://afkgaming.com/esports/news/escape-from-tarkov-recoil-changes-more-latest-patch-notes)).
- **Convergence (auto-compensation).** After every shot the weapon is pulled back toward the original point of aim;
  higher convergence = faster return ([community guide](https://vk.ru/@metadvijenie-otdacha-v-eft)). Full auto
  therefore climbs for the first few shots and then plateaus into a cluster. SPT's Recoil Overhaul instead made
  convergence near-instant and used a classic FPS "S" pattern, so recoil keeps climbing and must be countered by hand
  ([SPT Recoil Overhaul](https://github.com/space-commits/SPT-Realism-Recoil-Overhaul-Standalone/releases)).
- **Recoil angle + dispersion.** Vertical recoil has a direction (about 90° = straight up, per-gun bias) and the pattern
  has a size (dispersion). Horizontal is a drift, not white noise
  ([SPT Realism mod](https://forge.sp-tarkov.com/mod/422/spt-realism-mod)).
- **Pistols vs stocked guns.** Stocked guns push into the shoulder (camera follows a bit); pistols flip in the hands
  and the camera barely follows the muzzle. BSG's 0.14.1 rework that made sights "leave the screen after one shot" on
  pistols/SKS was rolled back after player backlash
  ([TechRadar](https://www.techradar.com/gaming/pc-gaming/escape-from-tarkov-players-lament-new-recoil-changes-and-upcoming-microtransactions),
  [NME](https://www.nme.com/news/escape-from-tarkov-patch-rollback-3586632)): semi-auto must stay on target.
- **Feel = curve + spring + recovery.** Fast rise, smooth damped return; recovery speed decides snappy vs heavy;
  camera shake short and mostly positional, with an intensity slider
  ([StraySpark](https://www.strayspark.studio/blog/weapon-recoil-camera-shake-ue5-spring-vs-curve),
  [StraySpark FPS feel](https://www.strayspark.studio/blog/fps-game-design-fundamentals-ue5)).

## What ours does today (`tactical/recoil_model.gd`)
One offset drives both the camera and the aim; each shot adds the full `up` instantly (no rise time); side is fresh
random noise every shot; it decays to zero at an ergo-based rate, capped at 10 shots. Result: the screen jerks, the
sight leaves the target, and there is no learnable pattern.

## Proposal (built as a switch, old model stays the default until Gregory rules: CHANGES.md P3)
1. Per-shot **impulse into a spring-damper** (pitch, yaw, kick-back) instead of an instant jump: ~60 ms rise, damped
   return.
2. **Barrel vs camera**: bullets follow the barrel; the camera gets `cam_share` of the barrel pitch (stocked rifles ~0.35,
   SMGs ~0.3, pistols ~0.15, shotguns/bolt 0.5 for weight).
3. **Convergence** per gun (`conv`): pulls the barrel back toward a climb baseline that saturates after ~5 shots, so
   full auto plateaus; the player counters the plateau by pulling down.
4. **Recoil angle** per gun (`angle`, 80–100°) + smoothed horizontal drift (low-pass noise) -> a repeatable pattern.
5. **Visual kick** on the viewmodel (back + rise + small roll) stays strong; positional camera shake tiny.
6. Semi-auto: first shot returns fully before the next if fired at a normal cadence (stays on target).
7. Attachments scale `up` / `side` (vgrip, compensator); ergo drives ADS speed and sway, not recoil size.
8. A `Recoil: classic / Tarkov` toggle in the range Esc menu for A/B; all numbers in `tactical_config.gd` + per-gun columns.
