# BOT-P0 progress (branch fix/bot-nofire)
Run range tests: `godot --headless --path godot scenes/firing_range.tscn -- --range-test | grep -E "nofire|FAIL|\[range\] (OK|FAILED)"`.

## Diagnosis (steps 1-2): `range_test_nofire.gd`, hooked after RangeTestFbb
Logging hook: `BotShooting.trace_on` / `trace` (reason counts per fire() call; `_fire` returns the reason, fire() unchanged).
- Suspect 1 CONFIRMED (`bot_shooting.gd` chest-only ray): crouched behind 1.1 m barrier, head visible: rifleman/pistol/shotgunner/boss
  all `los` 239-286 calls, 0 shots in 6 s.
- Suspect 4 CONFIRMED (`scav_bot.gd:218` top-up `mag.count() < 10`): detachable mags (M1911 7, AXMC 5) reload forever when idle
  (pistol 4 reloads / 8 s, marksman 3); marksman engaged shows busy:reload 129-165 frames, 0 shots in 5 s; Skirmish Runners
  6/7 sit in TakeCover (reloading) with 0 shots.
- Suspect 2 not tested as a no-fire cause (Suppress needs a flanking ally). Suspect 3: pistol/shotgun fire 20/25 m by design,
  silent at 40 m only because test bots do not walk (movement frozen, out of scope). Suspect 5 not reproduced (marksman fires, relocates after 2 shots).
## Fix (step 3)
1. `BotShooting._fire`: if the chest line is blocked and the bot sees the player, aim at the head when its line is clear.
2. `ScavBot._act`: top-up reload only when `not gun.mag.is_full()`.
## Verify
range test OK 910 (was FAILED 2 with fix 2 reverted; fix 1 reverted fails crouch cases). Smoke: see report.
