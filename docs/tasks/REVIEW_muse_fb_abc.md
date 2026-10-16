# Review: Muse's FB-A / FB-B / FB-C onto fix/fb-i (overnight track C)
Worktree `/home/gregory-milligan/AI projects/creeper fps td-worktrees/review-muse`, branch `review/muse-fb-abc`
(off fix/fb-i 87e1d58). Follow AGENTS.md, except: you may `git merge` the three origin branches INTO THIS review
branch (that is the task). Never push, never merge anywhere else. Progress log: `docs/tasks/REVIEW_muse_progress.md`.

## The branches (all based on 5005bc1, MP-1 era; fix/fb-i is newer: FB-F Mosin bolt, FB-G/FB-H ADS rule, F55 kit
carry, F58 eye clearance, F59 fire check, F60/F61 PKM/Vector, F62 range ammo)
1. `origin/fix/fb-a-ragdoll`  brief `docs/tasks/FB_A_ragdoll.md` (on origin/integ/2026-10-09: `git show origin/integ/2026-10-09:docs/tasks/FB_A_ragdoll.md`)
2. `origin/fix/fb-b-skirmish` brief `FB_B_skirmish_fixes.md` (F5/F18/F19/F25/F26)
3. `origin/fix/fb-c-range`    brief `FB_C_range_fixes.md`

## For each, in order
1. `git merge --no-ff origin/<branch>`. Resolve conflicts keeping fix/fb-i's behaviour for anything fix/fb-i
   changed (FB-H ADS is frozen; F55 kit carry; F62 range ammo). Note every conflict and how you resolved it.
2. Review the branch's own diff (`git diff 5005bc1 origin/<branch>`) against its brief and CLAUDE.md "Change only
   what Gregory asked for": flag anything outside the brief, any behaviour change not asked for, weakened or deleted
   checks, hard-coded tunables, files over ~250 lines, raw keycodes, broken contracts.
3. `godot --headless --path godot --import`, then parse check, `--range-test` (scene `res://scenes/firing_range.tscn`),
   smoke (allow 600 s). Record counts. If the merge breaks something, fix only what the merge broke (separate commit,
   say so); leave Muse's own bugs as findings.

## Report (<300 words) and stop
Per branch: conflicts + resolutions, test counts, findings ranked (bug / out-of-brief behaviour change / style), each
with file:line and a one-line fix suggestion. Don't fix findings (track C2 does). Every behaviour change you made.
