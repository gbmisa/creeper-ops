# Progress: REVIEW_muse_fb_abc (branch review/muse-fb-abc, off fix/fb-i 87e1d58)

## 1. FB-A ragdoll: merged c29caa6
- Conflict: `tactical/tactical_config.gd` (fix/fb-i BOLT/ADS block vs FB-A ragdoll block, same spot). Kept both, unchanged.
- Tests after merge: parse clean, range-test 662 PASS 0 FAIL (ragdoll checks pass), smoke 1264 PASS 0 FAIL.
- Findings:
  - bug (likely, verify on GPU): `bot_body.gd` `_tick_sleep` calls `physical_bones_stop_simulation()` after RAGDOLL_SLEEP (4 s);
    stopping the simulator stops writing bone poses, so the corpse can snap back to its pre-death pose for 4.5 s before
    the 8.5 s free. Fix: freeze/sleep the PhysicalBone3Ds instead of stopping the simulator.
  - out-of-brief: `scav_bot.gd:_move` skips `BotMotion.move` once dying (corpse body no longer moved). Probably invisible; confirm.
  - style: `bot_body.gd` 292 lines (>250); hard-coded tunables in logic: bleed-out nudge 25.0 (bot_body die), gun mass 3.0 /
    toss 1.5 / 0.05 (bot_mesh `_drop_gun`) -> TacticalConfig.
  - `scav_bot.gd:on_hit` indexes `res["pos"]`/`res["origin"]` directly (errors if a hit dict lacks them); use `.get`.
