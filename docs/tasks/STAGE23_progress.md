# Stage 23 progress

## Items 1-5 (done, smoke green)
- New: fps/viewmodel_motion.gd (spring recoil, bob, sway, sprint, landing, look lag), crossbow_fx.gd, spray_fx.gd, muzzle_flash.gd, hit_feel.gd, hit_overlay.gd, core/smoke_fps_feel.gd, core/debug_fire.gd (`--autostart --fire=rifle|sprayer|rocket[,lead]|hurt`).
- Edited: operative_weapons, rocket_launcher, advanced_weapons, weapon_models, player_controller (kick_pitch), fps_mode (motion/feel wiring; outside the brief list, minimal), fps_hud, effects (tracer, smoke), audio_synth, config (VM_*, SPRAY_*, FIZZ_*, HIT_*), raiders/hive_parts/enemy_mortar_hit/raider_shots (one-line HitFeel.note_source for the hurt arc).
- Decisions: cone mesh radii were reversed (wide at the player); fixed. Old hurt flash lowered 0.3 -> 0.12 since the vignette now carries big hits.
- Smoke OK, 9 feel checks.

## Items 6-7 (added by the user): arm, Pulse Rifle vs real Crossbow
- 6: fps/arm_models.gd (sleeve, bracer, glove; off hand on the foregrip) built into every weapon model, so arms kick/sway/hide with the weapon.
- 7: slot 1 `rifle` = Pulse Rifle (fps/rifle_model.gd, cyan pulse tracer, muzzle glow, coil flare; no string). New `Crossbow` (fps/crossbow.gd; model = the old crossbow; physical bolt, gravity drop, sticks 5 s, 1.2 s reload with string/bolt animation, 4 dmg). Config.CROSSBOW, new action id `crossbow` on **KEY_Y** (free: checked every default incl. adv_* and build_1-9; 7 avoided because build_7 uses it).
- Labels: Config.RIFLE.name, keybind label, FPS HUD, help line say Pulse Rifle / crossbow.
- Smoke 472 PASS, 0 FAIL (core/smoke_fps_feel.gd, smoke_fps_arms.gd). Screenshots in scratchpad/stage23: rifle_arm, xbow_reload, xbow_flight, sprayer, rifle, rocket, hurt.
- Debug: `--autostart --fire=rifle|crossbow|sprayer|rocket[,lead]|hurt`.
- Suggestions: arms are static poses (no reload hand animation); crossbow not in Armoury/upgrades.
