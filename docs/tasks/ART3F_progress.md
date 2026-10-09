# ART3 F progress: gun feel (branch `art/3-gun-feel`)

## Baseline (2026-10-08)
Branch was at 08423e2c. Stage 23b items 1-3 (arms, Pulse Rifle model, spray brightness cap)
were already in the tree from earlier work; item 4 (crossbow reload hand) and the whole
recoil-feel set were missing. New work below is feel-only: no damage, HP, fire rate,
range or ammo numbers touched.

## Changes
- `fps/recoil_defs.gd` (new, class_name RecoilDefs): per-weapon recoil data {kick, cam,
  yaw, bloom_add, bloom_max, bloom_recover}. Values keep current kick strengths
  (rifle 0.85, crossbow 2.0, rocket 2.4, sprayer 0.15).
- `core/config.gd`: new `VM_YAW_KICK` (0.006 rad random camera yaw per unit of kick).
- `fps/viewmodel_motion.gd`: yaw punch spring `ky/kyv` with random direction per shot,
  `cam_yaw()`, included in `at_rest()`; `kick(strength, yaw_kick)`.
- `fps/player_controller.gd`: `kick_yaw` var, applied in `_sync()` (never accumulates).
- `fps/fps_mode.gd`: sets `controller.kick_yaw` from `motion.cam_yaw()` each frame.
- `fps/operative_weapons.gd`: `kick(id)` reads RecoilDefs; Pulse Rifle `bloom` grows per
  shot while LMB held, recovers on release; spread applied as small random rotation of
  the shot direction. Layered sounds: rifle+crack+tail, crossbow+clack, launch+rumble.
- `fps/arm_models.gd`: glove wrapped in named `hand_r`/`hand_l` nodes (visual identical).
- `fps/crossbow_fx.gd`: off hand grabs the slack string, draws it back during reload,
  returns to the foregrip as the bolt is placed (bolt still appears at reload > 0.75).
- `core/audio_synth.gd`: new voices `rifle_crack`, `rifle_tail`, `crossbow_clack`,
  `launch_rumble`.
- `core/smoke_fps_feel.gd`: `_gunfeel` — recoil data sanity, yaw punch fires and
  recovers with no drift, TTK rule (4 shots kill at max bloom, exactly 4 shots).
  Existing `kick(1.0)` calls updated to `kick("rifle")`.

## Decisions where the brief was silent
- Bloom numbers: +0.28 deg/shot, max 1.4 deg, recover 6 deg/s. At 25 m the worst-case
  offset is ~0.6 m vs a 1.5 m test radius, so the TTK smoke is deterministic.
- Yaw punch is random-sign per shot (brief: "slight random yaw"), capped at 0.06 rad.
- Reload hand motion reuses the string's slack curve so hand and string stay together.

## Verify
- Parse: `godot --headless --path . --import` clean, zero SCRIPT ERRORs (Godot 4.7.2-stable).
- Smoke: full suite `[smoke] OK: 0 failure(s)` — 709 PASS, 0 FAIL, incl. 4 new gunfeel
  checks: recoil data sane, every weapon has recoil data, yaw punch fires and recovers
  with no drift (peak 0.0054 rad), rifle TTK unchanged with bloom at max (4 shots kill,
  4 shots / 4 hits).
- No screenshots taken (Xvfb visual judging is Opus's step per the brief; feel changes
  are motion/audio, verified by the spring-recovery and no-drift smoke checks).
