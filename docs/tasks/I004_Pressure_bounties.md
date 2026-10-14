# Brief I-004: Pressure bounties

<!-- gdflow:I-004 -->
**Idea:** I-004 on the [idea board](../design/IDEAS.md). **Pillar:** Race the pressure. **Priority:** 3.5
**Branch:** `muse/ideas-i001-i006` (from `claude/game-design-automation-gy0p8q`). **Model:** Muse (long run, phase 4)
**Read only:** AGENTS.md, CLAUDE.md (Key contracts + Conventions), docs/tasks/LONG_RUN_RULES.md, this brief, `docs/tasks/IDEAS_progress.md`, and in `godot/scripts/`: level/pressure.gd, level/level01.gd RAID_SCHEDULE + objectives rows, ui/objectives.gd. Don't read whole design docs.

## Why
Mid-level, timed side objectives appear (kill nest X in 3 min, hold a ridge for 60 s); success pays Aether and knocks the pressure curve back, failure pulls the next raider tier forward. Punishes turtling with choices, not just bigger numbers. First slice: one bounty type driven from the level's RAID_SCHEDULE data.

**Player moment we want:** Gambling your Operative on a 90-second dash to buy the base another minute

## Scope
Do:
1. `godot/scripts/level/pressure.gd`: add `static var offset := 0.0` (reset at level start) and use `t + offset` in `value()`; clamp so the effective time never goes below 0.
2. `godot/scripts/level/bounties.gd` (new, `class_name Bounties`): reads a new `BOUNTIES` array in `level01.gd` (2 rows; none in other levels yet). Row: `{ id, kind: "kill_nest" or "hold", target (nest id, or x, z, radius), at, limit, reward_aether, relief, penalty }` (times in s).
3. At `at` the bounty appears in the objectives panel with a countdown (through `ui/objectives.gd`'s existing API). Success: pay Aether, `Pressure.offset -= relief`. Failure: `Pressure.offset += penalty`. `Bus.say` + `Bus.metric.emit("bounty", {id, result})` either way.
4. Only `kill_nest` must fully work; skip `hold` if blocked (log why).

Must not change:
- Existing action ids, structure ids, `user://keybinds.cfg`, the creeper flow rule, other levels' data.
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- On L1 a bounty appears on time with a visible countdown; finishing it pays Aether and lowers pressure, missing it raises pressure.
- Smoke: offset math and clamp, kill_nest resolving both ways, no rows means no effect.
- The `--autostart` undefended L1 sim ends within 10% of its old time.
- New tunables live in the project's config/data tables, not in logic.

## Verify
1. parse: `cd godot && ! godot --headless --path . --import 2>&1 | grep -A1 'SCRIPT ERROR'`
2. smoke: `cd godot && godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep smoke` (all PASS)
3. Sim (no regressions): `cd godot && godot --headless --path . -- --demo --units --sim=900 --quit=0.1 | grep "\[sim\]"`; paste the line before and after in the progress log.
4. Screenshot (Xvfb, CLAUDE.md Testing §5) of anything visible; with no display write "screenshots: Opus" in the log.

## Report
Stop and report in the AGENTS.md format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
