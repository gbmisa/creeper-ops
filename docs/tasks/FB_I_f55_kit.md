# FB-I F55: deploying to skirmish loses the range kit (was F48)
Worktree `/home/gregory-milligan/AI projects/creeper fps td-worktrees/fb-i` (branch `fix/fb-i`). Follow AGENTS.md.
Gregory: the loadout he builds in the range (guns, fitted parts) is gone after deploy to skirmish. Regression from
MP-1: the session is rebuilt on every map load. The F51 part (recoil toggle resets per map) was in the same WIP.

## Do
1. `git cherry-pick a657366` (branch fix/f48-deploy-kit: stopped WIP, untested; its brief is
   `docs/tasks/F48_deploy_kit.md` in that commit). Resolve conflicts, then review it from zero: don't trust it.
2. Finish it so the player's kit survives range -> deploy -> skirmish -> back: every gun in each slot, the fitted
   parts (`Gun.fit`), mags and ammo in the pack, the recoil toggle. Smallest change; state lives where the session
   design intends (read `scripts/tactical/range_session.gd`).
3. Range checks (extend `range_test_deploy.gd`, keep files <250 lines): build a kit with 2 guns + a pistol, a sight
   and a muzzle fitted, deploy, load skirmish, check each item and fit; return and check again.
4. Play the flow in the real scenes (not only unit calls): `--weapon` / `--fit` hooks in `range_shot.gd`, then the
   deploy path the game uses. Say exactly how you ran it.

## Must not change
ADS (FB-H frozen), recoil numbers, fire/reload logic, skirmish rules, bot loadouts, the new vector/pkm models, any
def number. Never weaken or delete an existing check.

## Verify (from godot/)
Parse clean; `godot --headless --path . res://scenes/firing_range.tscn -- --range-test` 0 FAIL;
smoke `godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep -E "OK:|FAIL"` (allow 600 s) 0 failures.
Commit on fix/fb-i. Report under 250 words: cause, fix, how you played it, every behaviour change.
