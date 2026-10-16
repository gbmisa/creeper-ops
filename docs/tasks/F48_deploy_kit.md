# F48: Deploy no longer carries the kit (REGRESSION from MP-1, Gregory 2026-10-15)

Worktree `creeper fps td-worktrees/f48`, branch `fix/f48-deploy-kit` (from integ 6182f1d). Commit there only, never merge.

## Bug
Pick up a gun in the Firing Range, deploy to Skirmish (truck F or Esc menu): you arrive with the default AK + pistol.
Before MP-1 (integ d272c0a) the kit carried over.

## Cause (confirmed)
MP-1 (`fa47669`) replaced `RangeLoadout` (a `static var saved`, survives scene changes) with `RangeSession.saved_kit`.
`firing_range.gd` `_ready` builds a new `RangeSession` on every map load, so the saved kit is lost.
`range_test_deploy.gd` only checks the same session object, so it never saw this.

## Fix
Make the carried kit survive a map change again, the same way `RangeMaps.pending` does (a static carried across the
reload), while keeping the MP-1 session API (`session.deploy`, `session.saved_kit`, KIA clear, extract keep) working.
Keep the change small; read only `range_session.gd`, `range_maps.gd`, `player_weapons.gd` (~line 55),
`firing_range.gd` (~line 115), `range_test_deploy.gd`.

## Must not change
KIA resets to the default kit; extract keeps the carried kit plus loot; the default kit itself; reset range behaviour;
anything outside the kit carry. Do not weaken or delete any test.

## Verify
1. Parse: `godot --headless --path godot --import 2>&1 | grep -A1 "SCRIPT ERROR"` prints nothing.
2. Extend `range_test_deploy.gd`: deploy from one session, then build a NEW `RangeSession` (as a map load does) and check
   it loads the same kit; same for extract (kit + loot survives) and KIA (new session has the default kit).
3. `--range-test` OK, main smoke 0 FAIL (`-- --smoke --quit=0.1 | grep -c FAIL`).

## Report (under 200 words)
Files changed, every behaviour change, test results. Then stop.
