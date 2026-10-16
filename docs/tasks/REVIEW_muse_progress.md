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

## 3. FB-C range: merged ce338e2
- Conflicts: `range_test.gd` (kept both runners); `range_truck.gd` (same call, kept HEAD); `tactical_viewmodel.gd` (kept
  fix/fb-i `ViewmodelClip.apply(arms)` then FB-C F20 `_on_switched(w.gun)`); `range_session.gd` (kept fix/fb-i
  `set_local_recoil`). F6 duplicated F55: FB-C's `RangeMaps.carried_kit` (range_maps static, writes in save_kit/clear_kit,
  restore line in firing_range `_ready`) dropped in favour of frozen F55 static `_carried`; `range_test_fbc._f6` now reads the
  fresh session's `saved_kit` (same two checks, now exercising F55). Not a behaviour change.
- Tests: parse FAILS: `range_bench.gd:67` `var tube := weapons.gun.def["action"] == "tube"` cannot infer type (Muse's bug,
  also on its branch: same Gun.def typing at 5005bc1). RangeBench does not compile, so the ammo bench / armour station are
  dead and range-test skips its checks yet prints `[range] OK 678`. With a temporary `var tube: bool =` (not committed):
  range-test 687 PASS 0 FAIL. Smoke 1264 PASS 0 FAIL.
- Findings:
  - bug: range_bench.gd:67 parse error above. Fix: `var tube: bool = ...`.
  - bug (harness): range-test prints OK while a script fails to compile; make RangeTest fail on missing classes/script errors.
  - brief gap: F8 (ammo world model) and F15 (meds box / r5-med check) not done and not reported. F20 test covers setup
    only, not deploy and back-to-range transitions. No F7 test; F22 one-shell-at-a-time reload untested.
  - out-of-brief: F23 (`tactical_player.gd:156`) airborne sprint also drains stamina and makes sprint-step noise while
    airborne (brief: stamina unchanged). Fix: skip stamina drain while not on floor.
  - out-of-brief: F22 `hand_gear._refill_tube` sets every carried stack of the caliber to STACK_MAX (all grades), writing
    `it["count"]` directly (no inventory change signal). Brief: "don't change ammo amounts". Fix: go through Inventory API.
  - F11 workbench only opens the inventory UI; fitting still works anywhere, and its F prompt can overlap the ammo bench
    (POS 3.2 vs 5.0, both t_use). Gregory to judge.
  - style: F10 vest and F11 bench sizes hard-coded (placeholders, OK).
