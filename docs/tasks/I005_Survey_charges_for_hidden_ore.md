# Brief I-005: Survey charges for hidden ore

<!-- gdflow:I-005 -->
**Idea:** I-005 on the [idea board](../design/IDEAS.md). **Pillar:** RTS scale later. **Priority:** 3.4
**Branch:** `muse/ideas-i001-i006` (from `claude/game-design-automation-gy0p8q`). **Model:** Muse (long run, phase 5)
**Read only:** AGENTS.md, CLAUDE.md (Key contracts + Conventions), docs/tasks/LONG_RUN_RULES.md, this brief, `docs/tasks/IDEAS_progress.md`, and in `godot/scripts/`: level/level01.gd ores rows, the Miner placement rule in command/placement.gd, the interactables contract in CLAUDE.md. Don't read whole design docs.

## Why
Ore veins beyond network reach are hidden until the Operative plants a survey charge on foot; found veins become Outpost sites, so exploring on foot shapes where the network expands. First slice: hidden flag on level ore rows plus a survey interactable that reveals one vein.

**Player moment we want:** Finding a rich vein behind a castle and deciding whether it's worth a second front

## Scope
Do:
1. Level data: an ore row may carry `"hidden": true`. Mark 1-2 L1 ores beyond the starting network reach as hidden (log which and why).
2. A hidden ore draws nothing (no prop, marker or ground tint) and refuses Miner/Outpost placement until revealed.
3. `godot/scripts/level/ore_survey.gd` (new, `class_name OreSurvey`): an **interactable** (contract in CLAUDE.md) near each hidden ore, offset by `Config.SURVEY_FUZZ` cells; hold E for `SURVEY_TIME` to plant a survey charge, which reveals the ore (props, marker, placement allowed) with `Bus.say` and `Bus.metric.emit("survey", {id})`. Operative-only.
4. Command mode: a faint minor `?` marker near unrevealed survey sites.

Must not change:
- Existing action ids, structure ids, `user://keybinds.cfg`, the creeper flow rule, other levels' data.
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- On L1 the hidden ore can't be seen or built on until the Operative surveys it on foot; afterwards a Miner works there normally.
- Smoke: placement refused while hidden and allowed after reveal; reveal is idempotent; levels without hidden ores are unchanged.
- New tunables live in the project's config/data tables, not in logic.

## Verify
1. parse: `cd godot && ! godot --headless --path . --import 2>&1 | grep -A1 'SCRIPT ERROR'`
2. smoke: `cd godot && godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep smoke` (all PASS)
3. Sim (no regressions): `cd godot && godot --headless --path . -- --demo --units --sim=900 --quit=0.1 | grep "\[sim\]"`; paste the line before and after in the progress log.
4. Screenshot (Xvfb, CLAUDE.md Testing §5) of anything visible; with no display write "screenshots: Opus" in the log.

## Report
Stop and report in the AGENTS.md format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
