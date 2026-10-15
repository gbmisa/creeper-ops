# F46: Firing Range starts with an invisible AK (Gregory, 2026-10-15)

Worktree `creeper fps td-worktrees/f46`, branch `fix/f46-start-gun` (from integ 6182f1d). Commit there only, never merge.

## Bug
Launching the Firing Range (`godot --path godot res://scenes/firing_range.tscn`) starts holding the AK-47, but no gun
or arms are drawn. Expected: the starting AK is visible from the first frame, exactly as after switching weapons.

## Suspected cause (verify, don't assume)
`firing_range.gd` calls `weapons.setup(...)` (line ~78), which runs `select_slot("primary")` and emits `switched`,
before `vm.setup(weapons, player)` (line ~81) connects `TacticalViewmodel._on_switched`. So the viewmodel never builds
the starting gun. `range_shot.gd:20` already works around this for the screenshot hook by re-emitting `switched`.
Also check the Skirmish start and the deploy/extract path (same scene with `--map=skirmish`) for the same order bug.

## Fix
Smallest fix: after connecting in `TacticalViewmodel.setup`, build the current gun if `w.gun != null`
(call `_on_switched(w.gun)`). Then remove the now-redundant re-emit in `range_shot.gd` only if the shot hook still works.

## Must not change
Draw time/animation, ADS, recoil, sway, arms poses, which gun you start with, inventory, bots, any numbers. No other files
beyond those needed. Do not weaken or delete any test.

## Verify
1. Parse: `godot --headless --path godot --import 2>&1 | grep -A1 "SCRIPT ERROR"` prints nothing.
2. Add a headless check to the range test (`--range-test`): after the scene is ready, the viewmodel has a gun model
   for the starting weapon. Range test OK, main smoke 0 FAIL (`-- --smoke --quit=0.1 | grep -c FAIL`).
3. Do NOT judge screenshots (Opus does). You may save one with the `--shot` hook to `docs/art/f46/start.png` for Opus.

## Report (under 200 words)
Root cause found, files changed, every behaviour change, test results, screenshot path. Then stop.
