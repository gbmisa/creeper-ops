# Brief FB-H: Tarkov recoil mechanics implementation (recoil v2)

Muse task (headless: parse, `--range-test`, unit probes). Branch `fix/fb-h-recoil` (from `integ/2026-10-09` @ `6182f1d1`).
Opus judges feel on GPU after: sight picture during kick, viewmodel shake, whether the camera climb reads right.

Must not change: damage, fire interval / rpm, ammo behavior and reserves, hip pose, ADS FOV/zoom/speed,
any gun's stats other than the recoil keys named below, timings, AI, UI, level data, sounds.

2026-10-16 (Gregory): Tarkov recoil is the ONLY mode. The Classic model and the per-player mode toggle
are removed (this follow-up); there is no opt-in and no Classic fallback.

## Goal

Replace the Tarkov-mode recoil's single spring (barrel rises, camera follows by a fixed share) with the
mechanics the community reverse-engineered from EFT (research: `~/workspace/research_notes/tarkov-recoil-reverse-engineered-20261016-0434/report.md`):
two separately-parameterized channels (gun kick vs camera recoil), automatic recoil compensation on full-auto,
per-shot pseudo-random horizontal bounce, per-weapon convergence, a camera that does not fully recenter, and a
visual-only shake layer that cannot affect aim.

## Background: implementation (6182f1d1 base; single model since 2026-10-16)

`godot/scripts/tactical/recoil_model.gd` — `RecoilModel`, one model for every player (the old Classic
path and the Esc-menu toggle in `range_menu.gd` were removed 2026-10-16; `PlayerState.recoil_mode` is gone).
The model:
- `shoot(def, rng)`: adds an impulse to a barrel target `_tgt`: vertical `up * RECOIL_T_UP_MULT` along the
  gun's `angle` (80..100, 90 = straight up), horizontal = low-passed drift noise (`_drift`) scaled by `side`.
  Every shot adds the SAME impulse; there is no shot-count compensation.
- `update(dt, ergo, def)`: `_tgt` decays at per-gun `conv`; a critically-damped spring (`RECOIL_T_OMEGA` = 55)
  drives `barrel` (bore angle) toward `_tgt`. The camera is `offset = barrel * cam_share` — a pure share of
  the bore, with no independent dynamics. Because `_tgt` decays to zero, the camera ALWAYS recenters fully.
- `aim_basis(cam)`: bullets leave along the camera rotated by `barrel - offset` (the bore the camera didn't follow).
- `player_weapons.gd`: `recoil.shoot(gun.eff_def(), rng)` per shot (attachments scale `up`/`side`);
  `recoil.update(delta, gun.def["ergo"], gun.def)` per frame (base def: `conv`, `cam_share` unscaled);
  `player.recoil_off = recoil.offset` drives `tactical_player.gd` head rotation.
- `tactical_viewmodel.gd`: the gun model follows the bore via `rest = barrel - offset` scaled by
  `RECOIL_T_VM_PITCH/YAW/ROLL` (visual), plus a deterministic `_kick` spring on shot (visual only).
- FB-D P3 (29712e71) added TRP-spec citations and 3 tests; it changed no behavior. The `up`/`side` columns are
  this game's own tuning, not BSG's values.

## Research summary

Solidly known (datamined / mod-verified):
1. Two channels with separate per-weapon scalars: gun kick (`RecoilForceUp/Back`) and camera recoil
   (`CameraRecoil`, `CameraSnap`). BSG patches them independently.
2. Automatic recoil compensation: first ~1-5 shots kick hardest, then the PMC pulls the muzzle down so
   sustained full-auto self-limits vertically. Tapping re-triggers the harsh kick.
3. Horizontal is per-shot pseudo-random bounce (`RecolDispersion`, shaped by `RecoilAngle`), largely
   uncontrollable — this is what spreads groups sideways.
4. `Convergence` = settle-back speed of gun/camera toward the aim point (engine: `Recoil.ReturnSpeed`).
5. The camera does NOT fully recenter on its own; the player re-aims.
6. 0.16 added a visual-only randomness layer (sway, bolt-hit, buttstock shake) separate from mechanical recoil.
7. `dank/tarkov` (Rust) is only the backend web-API client — no gun mechanics. Not used.

Judgment calls (NOT in the research; tuned approximations, marked as such in code comments):
- Exact BSG per-shot constants were never published (no faithful open-source reimplementation exists;
  Fontaine's SPT Realism overhaul is a replacement model, used here only as a design reference).
- Compensation curve: linear ramp of the added impulse from 1.0 (shot 1) to 0.45 (shot 5+). Rate chosen so
  the existing plateau character survives; the number 0.45 is a feel pick, not a datamine.
- `cam_up` / `cam_snap` / `disp` per-gun values below are class-based estimates, not BSG data.
- Permanent camera climb keeps 35% of each shot's camera impulse, capped at 6 deg. BSG's `CameraSnap`
  semantics are unconfirmed; this models "view stays displaced, player re-aims".
- Attachment stacking stays multiplicative (community convention; BSG never documented it).

## Changes

### `godot/scripts/tactical/recoil_model.gd`
New state: `_cam` (camera spring angle), `_cam_tgt` (recoverable camera target), `_cam_vel`, `_climb`
(permanent camera climb, capped), `_shots` (burst shot counter), `_since_shot`. `offset` keeps its meaning:
the camera's total recoil angle, now `offset = _cam` with the spring target `_cam_tgt + _climb`.
- `shoot()`: `_shots += 1`; `comp = lerpf(1.0, RECOIL_T_COMP_MIN, clamp((shots-1)/(COMP_SHOTS-1)))`.
  Bore impulse: vertical `up * comp * UP_MULT` along `angle`; horizontal = `randf(-1,1) * side * disp * SIDE_MULT`
  PLUS the existing low-passed `_drift` wander term (kept). Camera impulse (separate channel):
  `_cam_tgt += Vector2(up * cam_up * comp, randf(-1,1) * side * cam_up * disp)`; `_climb += that * CLIMB_FRAC`,
  clamped to `CLIMB_MAX` vector length.
- `update()`: `_since_shot += dt`; burst counter resets after `BURST_GAP`. Bore spring unchanged (conv decay +
  critically-damped OMEGA spring). Camera: `_cam_tgt *= exp(-cam_snap * dt)`; critically-damped spring of
  `_cam` toward `_cam_tgt + _climb` with omega = per-gun `cam_snap`; `offset = _cam`.
- `reset()`: zeroes bore, camera, climb, targets, velocities, counters, drift. Called on weapon switch.
- `aim_basis()`: unchanged (`barrel - offset`).
- Manual pull-down interaction (documented, not coded): compensation only scales the ADDED impulse in
  [0.45, 1.0] — it never subtracts, and pitch impulses are never negative (`angle` in 80..100), so the model
  can never drag the aim low by itself. Mouse-look stays independent and additive; no auto-pull-up, so the
  model never fights the player's own correction.

### `godot/scripts/tactical/tactical_config.gd`
New: `RECOIL_T_COMP_MIN 0.45`, `RECOIL_T_COMP_SHOTS 5.0`, `RECOIL_T_BURST_GAP 0.3`,
`RECOIL_T_CLIMB_FRAC 0.35`, `RECOIL_T_CLIMB_MAX 6.0` (deg), `RECOIL_T_CAM_SNAP 8.0` (default),
`RECOIL_T_SHAKE_DEG 0.35`, `RECOIL_T_SHAKE_DECAY 12.0`. All existing `RECOIL_T_*` unchanged.

### `godot/scripts/tactical/weapon_defs.gd`
Replace `cam_share` with `cam_up` (camera impulse scalar), `cam_snap` (camera return rate), `disp`
(per-shot dispersion multiplier) on all 17 rows. `up`/`side`/`angle`/`conv` untouched. Header comment updated.

| gun | cam_up | cam_snap | disp | gun | cam_up | cam_snap | disp |
|---|---|---|---|---|---|---|---|
| m1911 | 0.5 | 10 | 1.2 | mp5 | 0.7 | 8 | 1.0 |
| glock18 | 0.5 | 10 | 1.2 | vector | 0.7 | 8 | 1.0 |
| revolver | 0.6 | 9 | 1.2 | ak47 | 0.85 | 8 | 1.0 |
| p90 | 0.7 | 8 | 1.0 | m4a1 | 0.8 | 8 | 1.0 |
| shotgun | 1.3 | 6 | 1.4 | scarh | 0.9 | 8 | 1.0 |
| saiga12 | 1.2 | 6 | 1.3 | garand | 0.9 | 8 | 0.9 |
| mosin | 1.5 | 6 | 0.8 | sks | 0.9 | 8 | 0.9 |
| sniper | 1.5 | 6 | 0.8 | sr25 | 0.9 | 8 | 0.9 |
| pkm | 1.0 | 7 | 1.1 | | | | |

### `godot/scripts/tactical/gun.gd`
`eff_def()`: add `"cam_up"` and `"disp"` to the attachment-scaled keys (no current attachment mods reference
them — no-op today, future-proof). `conv`/`cam_snap` stay base-def (update-time keys, same as `conv` today).

### `godot/scripts/range/player_weapons.gd`
`select_slot()`: `recoil.reset()` after `switched.emit(gun)` (covers `give()` → `HandGear.give` → `select_slot`).
Without this the permanent climb would leak between guns. Nothing else changes.

### `godot/scripts/range/tactical_viewmodel.gd` (visual-only shake layer)
On shot, add a small random rotational impulse to a new `_shake` spring
(`RECOIL_T_SHAKE_DEG`, decay `RECOIL_T_SHAKE_DECAY`), applied to the MODEL rotation in `_process` only.
It never touches `RecoilModel`, `aim_basis`, or bullet directions — aim-affecting and non-aim-affecting stay
in distinct code paths.

### `godot/scripts/range/range_test_recoil.gd`
Keep `_rise`, `_plateau` (bounds re-measured), `_plateau_m4_exact`, `_determinism`, `_semi_returns`,
`_semi_returns_exact`, `_aim_basis`, `_classic`, `probe`. Rewrite `_camera_vs_barrel` for the new channel
(every gun has `conv`/`cam_up`/`cam_snap`/`disp`; camera kick scales with `cam_up` by construction test).
New checks:
- `_compensation`: mean per-shot barrel kick of shots 6-30 < mean of shots 1-5 (ak47, m4a1).
- `_dispersion_bounds`: 30-shot spray, all `|barrel.y| <= side * disp * 3`, and yaw varies (not constant).
- `_settle_time`: after a 10-shot burst, barrel under 10% of peak; sks (conv 10) settles faster than ak47 (conv 4.6).
- `_climb`: 200-shot spray, `_climb.length() <= CLIMB_MAX + eps`; after 2 s settle, `offset.length() > 0.2`
  (camera kept its climb) while `barrel.length() < 0.05` (bore returned).
- `_burst_reset`: shots spaced wider than `BURST_GAP` each kick like shot 1 (tapping re-triggers full kick).
- `_no_self_drag`: 30-shot spray, `barrel.x >= -0.001` throughout (model never pushes pitch below zero).

## Test plan
Parse clean. `--range-test` all PASS, zero new failures vs the 6182f1d1 base (run base for comparison).
`--recoil-probe` spray printout for the report (ak47/m4a1/vector/pkm). No Classic-vs-Tarkov comparisons:
all assertions target the single model.

## Open questions (for Opus / Gregory, not this branch)
- Do the `cam_up` values feel right per class? The numbers are estimates; GPU-side judgment.
- Should attachments scale `cam_up`/`disp` (they will once a mod references them), or stay mechanical-only?
- The p90 red-dot `ads_mult` 0.9 also scales ADS time, not recoil — no interaction.
- Long-term: per-ammo recoil modifiers (research: e.g. 5.45 US -15%) — out of scope; ammo behavior must not change.
