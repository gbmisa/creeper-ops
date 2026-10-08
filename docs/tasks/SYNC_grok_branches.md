# Sync: bring Stages 7c, 10a and 11a up to date with main

**Agent:** Grok Build, **one session per worktree** (three sessions can run at the same time).
| Stage | Worktree | Branch |
|---|---|---|
| 7c traversal | `creeper fps td-worktrees/stage7c` | `stage/7c-traversal` |
| 10a armoury | `creeper fps td-worktrees/stage10a` | `stage/10a-armoury` |
| 11a terp | `creeper fps td-worktrees/stage11a` | `stage/11a-terp` |

**Exception to AGENTS.md rule 2, for this brief only:** you may run `git merge main` *inside your own worktree, on your own branch*. Nothing else from rule 2 changes: no rebase, no push, never commit to `main`, never touch another branch.

## Why
All three branches started before Stages 15-17 and 18a were merged. Opus will review and merge them into `main`. With conflicts already resolved and the tests re-run, that review is quick.

## Do
1. `git merge main` in your worktree. Resolve conflicts **keeping both sides' intent**. Known hot spots:
   - `config.gd`, `structure_defs.gd`, `debug.gd`, `smoke_test.gd`: keep every line from both sides (main's Stage 17 values win where the same constant changed; list each such case in your report).
   - `level01.gd` (7c): main retuned emitter intervals/`start` in Stage 17; keep main's emitter rows and add your ramps.
   - 11a: main already has a Terp tower model `TitanMeshes.terp`. Delete your old Terp case in `structure_meshes.gd` and use `TitanMeshes.terp`. 11a also touches `terrain.gdshader`, which main rewrote in 18a (terrain_look include, `plans` uniforms). Re-apply your Terp paint overlay as a small addition to the new file; don't revert 18a.
   - 10a: `fps_mode.gd`, `operative_weapons.gd`, `fps_hud.gd`, `hud.gd`. Keep main's art (Stage 15 crossbow etc.) and your armoury logic.
2. `godot --headless --path godot --import`, then the parse check.
3. Full smoke. Everything must PASS (the castle-garrison check flakes ~1 in 10 on main too; re-run once if only that fails).
4. The sim from your original brief, plus `--demo --units --sim=900` (report the Node HP and compare with main: 500/500 at session 11).
5. Commit the merge on your branch.

## Report (AGENTS.md)
Each conflict file and how you resolved it, any constant where main's value replaced yours, test output, commit hash. Say "committed on branch X". Don't edit HANDOFF.md.
