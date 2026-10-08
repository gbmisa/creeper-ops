# Task briefs for delegated agents

One file per task. Start a **fresh** agent session in the task's worktree and give it this one line:

> Read AGENTS.md, CLAUDE.md, HANDOFF.md, docs/MASTER_PLAN.md and docs/tasks/<FILE>.md, then do that task and nothing else.

## Rules for every task
**[AGENTS.md](../../AGENTS.md) applies first:** do only this brief, never merge, report and stop.
- Work only in your worktree, on its branch. Commit there. Never commit to `main` (Opus reviews and merges).
- Godot 4.7, GDScript. Match the existing style. Keep every file under ~250 lines.
- After adding a new `class_name` file, run `godot --headless --path godot --import`.
- Put new smoke checks in the **new** smoke file named in the brief, and register it with one line in `smoke_test.gd`, the way `smoke_raiders.gd` is registered.
- Verify before reporting: the parse check, smoke tests all passing, and the sim command in the brief (CLAUDE.md Testing).
- In docs/MASTER_PLAN.md, set your stage's status to ⚠ and add one Changelog line. **Don't edit HANDOFF.md.**
- Never touch `user://keybinds.cfg`. Never rename an existing action id or structure id.
- Finish by reporting: files changed, config values added or changed, test output, and anything you weren't sure about.

| Brief | Worktree | Branch |
|---|---|---|
| [GROK_command_mode_split.md](GROK_command_mode_split.md) | `creeper fps td-worktrees/grok-command-mode` | `grok/command-mode-split` |
| [STAGE6_packet_senders.md](STAGE6_packet_senders.md) | `creeper fps td-worktrees/stage6` | `stage/6-packet-senders` |
| [STAGE10b_deployment.md](STAGE10b_deployment.md) | `creeper fps td-worktrees/stage10b` | `stage/10b-deployment` |
| [STAGE7c_traversal.md](STAGE7c_traversal.md) | `creeper fps td-worktrees/stage7c` | `stage/7c-traversal` |
| [STAGE10a_armoury.md](STAGE10a_armoury.md) | `creeper fps td-worktrees/stage10a` | `stage/10a-armoury` |
| [STAGE11a_terp_earth.md](STAGE11a_terp_earth.md) | `creeper fps td-worktrees/stage11a` | `stage/11a-terp` |
| [STAGE15_fantasy_art.md](STAGE15_fantasy_art.md) (+ judge: [JUDGE_art_rubric.md](JUDGE_art_rubric.md)) | `creeper fps td-worktrees/stage15` | `stage/15-fantasy-art` |
| [STAGE16_level02.md](STAGE16_level02.md) | `creeper fps td-worktrees/stage16` | `stage/16-level02` |
| [STAGE18b_fps_visuals.md](STAGE18b_fps_visuals.md) | `creeper fps td-worktrees/stage18b` | `stage/18b-fps-visuals` |
| [STAGE18c_hud_declutter.md](STAGE18c_hud_declutter.md) | `creeper fps td-worktrees/stage18c` | `stage/18c-hud-declutter` |
| [STAGE18d_dragbuild_polish.md](STAGE18d_dragbuild_polish.md) | `creeper fps td-worktrees/stage18d` | `stage/18d-dragbuild-polish` |
| [SYNC_grok_branches.md](SYNC_grok_branches.md) (one session each) | `stage7c`, `stage10a`, `stage11a` | their own branches |
| [STAGE8_enemies_long.md](STAGE8_enemies_long.md) (**long, overnight**) | `creeper fps td-worktrees/stage8` | `stage/8-enemies` |
| **Long runs** (rules: [LONG_RUN_RULES.md](LONG_RUN_RULES.md)) | | |
| [STAGE9b_content_long.md](STAGE9b_content_long.md) | `creeper fps td-worktrees/stage9b` | `stage/9b-content` |
| [STAGE19_flyers_long.md](STAGE19_flyers_long.md) | `creeper fps td-worktrees/stage19` | `stage/19-flyers` |
| [STAGE20_art2_long.md](STAGE20_art2_long.md) | `creeper fps td-worktrees/stage20` | `stage/20-art2` |
| [BENCH512_long.md](BENCH512_long.md) | `creeper fps td-worktrees/bench512` | `stage/bench512` |
| [STAGE23_fps_feel.md](STAGE23_fps_feel.md) | `creeper fps td-worktrees/stage23` | `stage/23-fps-feel` |
| [STAGE23b_viewmodel_polish.md](STAGE23b_viewmodel_polish.md) | `creeper fps td-worktrees/stage23b` | `stage/23b-viewmodel-polish` |
| [STAGE24_metrics.md](STAGE24_metrics.md) | `creeper fps td-worktrees/stage24` | `stage/24-metrics` |
| [PLAYTEST1_C_hive_sites.md](PLAYTEST1_C_hive_sites.md) (Muse calibration) | `creeper fps td-worktrees/playtest1c` | `fix/playtest1-hive-sites` |
| [STAGE21b_castles_detail_long.md](STAGE21b_castles_detail_long.md) (after Stage 21 is merged) | `creeper fps td-worktrees/stage21b` | `stage/21b-castles-detail` |
