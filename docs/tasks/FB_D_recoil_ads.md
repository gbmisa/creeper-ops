# Brief FB-D: Tarkov recoil (P3) + ADS eye position (P4)
Both approved by Gregory in `CHANGES.md` (P3, P4) on 2026-10-14. P5 (ADS arms pose) is **not** in this brief.
Branch `feat/fb-d-recoil-ads`. Base: `integ/2026-10-09` after `feat/mp1` merges (else `origin/feat/mp1`).
Agent: Muse or Sonnet `feature-dev`, one phase each. Read `AGENTS.md`, this brief, `docs/research/RECOIL_TARKOV.md`
("Proposal"), and the TRP spec https://github.com/JuanFNQ/TRP `TRP/docs/spec/weapon-handling.md` (Apache-2.0: use its
numbers and model, copy no code). Opus has uncommitted `arms_pose` edits in `tactical_viewmodel.gd` / `weapon_defs.gd`
on integ: keep your diff to those files small and clearly separated so Opus can rebase.

## Phase 1: P3 recoil (`tactical/recoil_model.gd`, per-gun columns in `tactical/weapon_defs.gd`)
Build the 8 points of `RECOIL_TARKOV.md` "Proposal": spring-damper kick (~60 ms rise, damped return), bullets follow the
barrel while the camera takes `cam_share` of it, per-gun convergence `conv` so full auto plateaus, per-gun `angle` plus
smoothed horizontal drift (a learnable pattern), strong visual gun kick and tiny camera shake, semi-auto returns between
normal-cadence shots, attachments scale `up`/`side`, ergo drives ADS speed and sway (not recoil size).
- **Toggle** `Recoil: Classic / Tarkov` in the range Esc menu (`range/range_menu.gd`). **Classic stays the default** until
  Gregory rules on the default. Classic must behave exactly as today.
- Tunables in `tactical/tactical_config.gd` and the def columns; where TRP gives measured values, use them and cite the
  section in a comment.
- Must not change: damage, rpm, fire modes, ammo, `moa` accuracy, bot recoil.
- Tests (`range_test_recoil.gd`): Classic unchanged (existing checks untouched); Tarkov: camera pitch < barrel pitch;
  30-shot M4A1 burst plateaus (shots 20-30 climb < 10 % of shots 1-10); same seed gives the same pattern; semi at 2 shots/s
  returns within 0.1° of the start.

## Phase 2: P4 ADS eye position (`range/tactical_viewmodel.gd` `base_pos`, `ADS_NEAR`)
Today ADS puts the gun at `-(half_len - butt)`, so the eye sits at or behind the stock end (M4A1: 3 cm behind) and the
0.25 m near plane hides it. Change: eye ~0.30 m forward of the butt plate (cheek weld), per-gun override key if a gun
needs it (pistols keep arm's-length hold: check TRP). Lower the ADS near plane so the visible stock doesn't clip
(keep the sight on the screen centre: re-run every sight-on-axis test).
- Must not change: hip position, ADS FOV/zoom, ADS speed, sights' alignment with the screen centre.
- Tests: for every gun, ADS eye-to-butt distance within the per-class range; all sight-on-axis checks still pass.

## Done
Parse clean, `--range-test` all PASS, main `--smoke` 0 FAIL. Push, report every behaviour change, stop.
Opus judges ADS on the GPU with the rubric: sights visible and centred (auto-fail otherwise), stock in the shoulder,
no mesh through the camera, recoil reads like the TRP/EFT reference.
