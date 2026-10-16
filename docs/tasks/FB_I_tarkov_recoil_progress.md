# FB-I recoil progress (brief: FB_I_tarkov_recoil.md)

## Phase 1: the model (done, Opus agent, 2026-10-15)
Source: the spec excerpt plus TRP's own code, fetched with `gh api` (Apache-2.0, credited in headers):
`TRP/crates/trp-sim/src/recoil.rs` (Recoil, RotationProcess, Process) and `breath.rs` (SmoothRandom, hip gain).
Ported line by line; nothing invented in the formulas.

Files: `godot/scripts/tactical/recoil_defs.gd` (class **TacRecoilDefs**: `RecoilDefs` is already taken by
`scripts/fps/recoil_defs.gd`), `recoil_springs.gd` (RecoilSpring: position/camera process, curve + Unity clamp),
`recoil_rotation.gd` (RecoilRotation: stable mode, multiplier, return path, settle point), `hip_wander.gd`
(HipWander), `recoil_model.gd` (rewritten: 60 Hz accumulator, blend of last two steps, curves, hip wander).
Checks: `range_test_recoil.gd` rewritten; classic checks rewritten in `range_test_logic.gd` (`_recoil`) and
`range_test_attach.gd` (`_first_kick`, `_climb`, base-kick and per-attachment checks). Dead classic consts
removed from `tactical_config.gd` (RECOIL_CAP_SHOTS, RATE_*, T_UP/SIDE_MULT, T_DRIFT, T_OMEGA).

### AKM values: what the spec gives vs what was worked back
Given and used as-is: angle 85 +-11, group shots 1-200 narrowing +6/-6 (80..90), convergence 2.4, damping 0.86,
category 0.19, stable shot 5, camera snap 3.5, cam-to-weapon 0.1..0.2 / step 0.1, pivot (0,-0.25,0), hip gain
0.16 / 0.2 s / 7, all prefab numbers (ranges, 0.1399, bonuses 20, stance factors, routing, springs).
**Not in the spec or repo (SPT template data):** worked back from the spec's measured shots:
- force_back 270: spec's worked-back kick 18.49..29.78 mm = POS_STRENGTH x (B+20) x 0.1399 x 0.0007.
- force_up 104 and camera 0.05: fitted to hip peak mean 1.77 / aimed 1.34 and camera force mean 0.906
  (both fits agree; 0.05 is also TRP's rifle test value).
- stable_step 2.5, stable_angle 0..28, post_v -1.5..0, post_h -1.5..1.5, return_offset 0.01, return_damping 0.48:
  TRP's assault-rifle test settings (`recoil.rs` tests). The angle spread from shot 5 matches the spec's 66..90.
- Hip prefab: HIP_PENALTY 1 (spec: "drifts about a degree"), throw 0.2..0.7, hardness speed 0.1: guesses.
- Weapon curves (shape from spec): multipliers unmeasured: roll 1.0 (aim 0.5), back 0.001 m (0.0005), camera
  roll 0.25 (0.125), time mult 1. Linear between keys (Unity tangents unknown). Tuning-panel candidates.

### Other guns (TacRecoilDefs.row): AK row, force_up/force_back x (up / AK up), dispersion and the group's
narrowing x (side / AK side). AK up 0.75 side 0.45 -> e.g. m4a1 force_up 69.3 back 180 disp 7.3; pkm 124.8 /
324 / 14.7; glock18 332.8 / 864 / 26.9; sniper 485 / 1260 / 19.6. The old `angle`, `conv`, `cam_share` def
columns are no longer read (left in weapon_defs; phase 2 may drop them).
Attachments: parts = stat(up)/def up (scales force_up AND force_back, as the spec's `parts`); stat(side)/def side
scales the angle spread (base dispersion and group narrowing).

### Checks (40 seeds, AK47 standing) vs spec
hip peak 1.54..1.95 mean 1.78 (spec sim 1.56..1.99, 1.77); at 0.133 s (0.141; TRP's extra frame of kick delay
not modelled); back 15.4..24.5 mm mean 19.9 (15.3..24.5, 19.8); camera 0.79 (0.79); aimed 1.15..1.46 mean 1.34
(1.17..1.51, 1.34); hip auto shots 2-5 1.61/2.56/3.69/5.25 (1.67/2.62/3.73/5.27); held shots 7-10 5.3..9.3 mean
7.3 (5.3..9.5, 7.1); aimed auto probe 1.26/1.97/2.77/3.90 (1.16/1.92/2.74/3.85). Hip at rest 0.0000 deg.
Decisions: muzzle peak is measured on the rotation process's `current` (excludes hip wander); kick back on the
position spring (the spec works it back from that spring); bursts stand 0.5 s first (sets the return rate,
as a player standing before firing does). `--range-test` 653 PASS / 0 FAIL. Smoke 1264 PASS, 0 failures.

### Interim state (until phase 2)
Game uses the new model whatever the Esc toggle says (`RecoilModel.tarkov` is a stub that reads true).
player_weapons does not yet set `aiming`, `pose` or `auto_fire`, so in game every shot is "shot 1, hip"
(no stable mode) until phase 2 wires them. Camera follow-while-aiming, CameraSnap and the viewmodel kick
back/roll are phase 2. `aim_basis` keeps the old "barrel minus camera" formula for now.

### Suggestions
- Phase 2: set `recoil.auto_fire` while the trigger is held in auto, `aiming` from ads_amt, `pose` from stance.
- After a shot the muzzle settles near, not at, rest (TRP settle point): the ADS-at-rest alignment check in phase 2
  must allow for that or the settle point must be read as "where the sights now are".
