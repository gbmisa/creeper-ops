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

## 2. FB-B skirmish: merged (no conflicts)
- Merge broke one check: `bleed-out death falls` FAILED deterministically. Cause: FB-A's `RangeTestBotMesh.run` called
  `_death_physics()` without `await`, so it ran concurrently with FB-B's new F19 test, which pauses the tree and froze the
  ragdoll. Fixed (separate commit): `await _death_physics(...)` in `range_test_botmesh.gd:26`. Test-only, no game change.
- Tests after merge + fix: parse clean, range-test 678 PASS 0 FAIL, smoke 1264 PASS 0 FAIL.
- Findings:
  - bug: F19 pause freezes `InputState` (child of the pausable firing_range), so mouse-button releases during the menu are
    lost: hold LMB, Esc, release, Resume -> `left` stays true and the gun keeps firing. Fix: InputState
    `process_mode = ALWAYS` (or clear `left/right` in `RangeMenu.close`).
  - out-of-brief: F5 LOS gate (`bot_shooting.gd:20`) also blocks SUPPRESS fire at a last-known spot behind cover; brief
    said suppressing fire is fine if it hits cover. Fix: skip the LOS gate when `not b.percept.seeing`.
  - out-of-brief/test: `range_test_roster.gd` marksman check moved from (-10,0,8) firing -Z to (0,0,20) firing +Z
    (setup change to an existing check; not weakened, but note it).
  - brief gap: F18 asked for hit rate at 10/50/100 m before/after; test only checks spread ratios, no hit-rate report.
    F18 adds a second reaction delay (`react_t`) on top of the existing `BotPerception.reaction_delay`.
  - style: `range_test_fbb.gd` 308 lines, `look_scatter.gd` 258; `LookKestrel.gate_collider` hard-codes the hut box
    (8.0, 1.3, 47.0) duplicating `_gate` values; tree trunk 0.28/5.5 in logic; `tree_colliders` rebuilds the whole
    ground scatter into a throwaway node just to replay the rng (cheaper: split the rng streams).
  - `range_menu.gd:75` raw `KEY_ESCAPE` (Esc is the allowed fixed key; OK).
