# RANGE5 RECOIL progress

## RECOIL-1 (done)
- `RecoilModel.tarkov` (static, toggled by "Recoil: Classic / Tarkov" in the range Esc menu; default Classic, persists across maps).
- Tarkov: shot = impulse (up x 0.7 along `angle`, plus low-passed side drift) into a target that decays at `conv`; the barrel follows it
  through a critically damped spring (omega 55, ~50 ms to 90%). Camera gets `cam_share` of the barrel; `aim_basis()` turns the shot
  direction by the rest (bore minus camera), used in `PlayerWeapons._shoot`. Viewmodel rotates by the same rest (x3.5 pitch, x2 yaw, roll) + extra kick-back.
- Per-gun columns `conv`, `cam_share`, `angle` in `weapon_defs.gd`; constants `RECOIL_T_*` in `tactical_config.gd`.
- `RecoilModel.kick_stats(def)` is the single read of `up`/`side` (route through `gun.stat` there).
- Classic untouched: test replays the old formula. `--range-test` OK 410 (was 396, +14 in `range_test_recoil.gd`).
- Not done: positional camera shake (spec item 5, tiny), attachment scaling of up/side (other agent).

## Spray probe (`-- --range-test --recoil-probe`): 30 shots at rpm, "pitch/yaw" deg per shot, bore angle at the moment of firing
(Classic = camera offset = bullets; Tarkov = barrel; camera in Tarkov is only cam_share of it)
```
ak47 classic pitch/yaw per shot: 0.00/0.00 0.50/-0.04 0.81/0.10 0.99/0.31 1.10/0.31 1.17/0.39 1.21/0.41 1.23/0.01 1.25/-0.18 1.25/0.10 1.26/-0.01 1.26/-0.28 1.26/-0.27 1.27/-0.22 1.27/-0.10 1.27/-0.05 1.27/0.17 1.27/0.11 1.27/0.35 1.27/0.31 1.27/0.23 1.27/0.09 1.27/-0.01 1.27/0.10 1.27/-0.04 1.27/0.24 1.27/0.35 1.27/-0.05 1.27/0.04 1.27/0.28 
ak47 tarkov pitch/yaw per shot: 0.00/0.00 0.37/0.04 0.61/0.10 0.76/0.20 0.86/0.26 0.92/0.32 0.96/0.36 0.99/0.28 1.00/0.18 1.01/0.19 1.02/0.17 1.02/0.09 1.02/0.04 1.03/0.02 1.03/0.04 1.03/0.07 1.03/0.14 1.03/0.17 1.03/0.25 1.03/0.29 1.03/0.30 1.03/0.26 1.03/0.22 1.03/0.21 1.03/0.18 1.03/0.23 1.03/0.29 1.03/0.22 1.03/0.20 1.03/0.25 
m4a1 classic pitch/yaw per shot: 0.00/0.00 0.36/-0.03 0.59/0.07 0.73/0.22 0.83/0.23 0.89/0.29 0.93/0.32 0.96/0.03 0.97/-0.11 0.98/0.08 0.99/0.01 0.99/-0.19 1.00/-0.19 1.00/-0.17 1.00/-0.08 1.00/-0.05 1.00/0.11 1.00/0.08 1.00/0.25 1.00/0.23 1.00/0.18 1.00/0.09 1.00/0.01 1.00/0.08 1.00/-0.01 1.00/0.18 1.00/0.26 1.00/-0.02 1.00/0.04 1.00/0.21 
m4a1 tarkov pitch/yaw per shot: 0.00/0.00 0.24/0.00 0.41/0.03 0.52/0.08 0.59/0.11 0.64/0.15 0.67/0.18 0.68/0.12 0.70/0.06 0.70/0.06 0.71/0.05 0.71/-0.01 0.71/-0.05 0.71/-0.06 0.71/-0.05 0.71/-0.03 0.71/0.02 0.71/0.04 0.71/0.10 0.71/0.13 0.71/0.13 0.71/0.11 0.71/0.08 0.71/0.07 0.71/0.05 0.71/0.08 0.71/0.12 0.71/0.08 0.71/0.06 0.71/0.10 
vector classic pitch/yaw per shot: 0.00/0.00 0.14/-0.01 0.23/0.03 0.29/0.09 0.33/0.10 0.36/0.13 0.38/0.15 0.40/0.03 0.41/-0.03 0.41/0.04 0.42/0.01 0.42/-0.08 0.42/-0.08 0.42/-0.07 0.42/-0.04 0.43/-0.03 0.43/0.04 0.43/0.03 0.43/0.11 0.43/0.10 0.43/0.08 0.43/0.05 0.43/0.01 0.43/0.04 0.43/0.00 0.43/0.08 0.43/0.12 0.43/0.00 0.43/0.02 0.43/0.09 
vector tarkov pitch/yaw per shot: 0.00/0.00 0.08/-0.01 0.14/-0.01 0.19/0.01 0.21/0.02 0.23/0.03 0.24/0.04 0.25/0.02 0.25/-0.01 0.26/-0.01 0.26/-0.01 0.26/-0.03 0.26/-0.05 0.26/-0.06 0.26/-0.05 0.26/-0.05 0.26/-0.03 0.26/-0.02 0.26/0.00 0.26/0.02 0.26/0.02 0.26/0.01 0.26/-0.00 0.26/-0.00 0.26/-0.01 0.26/-0.00 0.26/0.01 0.26/0.00 0.26/-0.01 0.26/0.00 
pkm classic pitch/yaw per shot: 0.00/0.00 0.68/-0.06 1.15/0.14 1.47/0.47 1.68/0.51 1.83/0.66 1.93/0.73 2.00/0.15 2.05/-0.17 2.08/0.20 2.10/0.05 2.12/-0.38 2.13/-0.41 2.13/-0.37 2.14/-0.21 2.14/-0.13 2.14/0.20 2.14/0.16 2.15/0.54 2.15/0.51 2.15/0.43 2.15/0.23 2.15/0.07 2.15/0.21 2.15/0.00 2.15/0.41 2.15/0.59 2.15/0.02 2.15/0.12 2.15/0.47 
pkm tarkov pitch/yaw per shot: 0.00/0.00 0.44/0.02 0.74/0.09 0.93/0.20 1.05/0.28 1.12/0.35 1.17/0.40 1.20/0.30 1.22/0.16 1.23/0.17 1.23/0.15 1.24/0.04 1.24/-0.03 1.24/-0.06 1.24/-0.03 1.25/0.01 1.25/0.10 1.25/0.15 1.25/0.26 1.25/0.31 1.25/0.32 1.25/0.27 1.25/0.21 1.25/0.20 1.25/0.15 1.25/0.22 1.25/0.30 1.25/0.21 1.25/0.18 1.25/0.25 
```
