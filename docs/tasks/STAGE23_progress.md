# Stage 23 progress

## Items 1-5 (done, smoke green)
- New: fps/viewmodel_motion.gd (spring recoil, bob, sway, sprint, landing, look lag), crossbow_fx.gd, spray_fx.gd, muzzle_flash.gd, hit_feel.gd, hit_overlay.gd, core/smoke_fps_feel.gd, core/debug_fire.gd (`--autostart --fire=rifle|sprayer|rocket[,lead]|hurt`).
- Edited: operative_weapons, rocket_launcher, advanced_weapons, weapon_models, player_controller (kick_pitch), fps_mode (motion/feel wiring; outside the brief list, minimal), fps_hud, effects (tracer, smoke), audio_synth, config (VM_*, SPRAY_*, FIZZ_*, HIT_*), raiders/hive_parts/enemy_mortar_hit/raider_shots (one-line HitFeel.note_source for the hurt arc).
- Decisions: cone mesh radii were reversed (wide at the player); fixed. Old hurt flash lowered 0.3 -> 0.12 since the vignette now carries big hits.
- Smoke OK, 9 feel checks.

## Items 6-7 (added by the user): arm, Pulse Rifle vs real Crossbow
