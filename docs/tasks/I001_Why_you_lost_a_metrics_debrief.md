# Brief I-001: Why you lost: a metrics debrief

<!-- gdflow:I-001 -->
**Idea:** I-001 on the [idea board](../design/IDEAS.md). **Pillar:** Race the pressure. **Priority:** 6.33
**Branch:** `muse/ideas-i001-i006` (from `claude/game-design-automation-gy0p8q`). **Model:** Muse (long run, phase 1)
**Read only:** AGENTS.md, CLAUDE.md (Key contracts + Conventions), docs/tasks/LONG_RUN_RULES.md, this brief, `docs/tasks/IDEAS_progress.md`, and in `godot/scripts/`: core/play_metrics.gd, core/metrics_summary.gd, the end of core/game_flow.gd. Don't read whole design docs.

## Why
The end screen turns PlayMetrics into a short timeline: when the bank ran dry, which weapons starved, when each raider tier unlocked, where the Node took damage. First slice: three auto-picked 'turning points' from the existing metrics JSON on the loss screen.

**Player moment we want:** 'Your snipers ran dry at 6:50, two minutes before the Brutes arrived' and you instantly know what to try next

**Enemy swap (DECISIONS D-002):** raiders will be replaced by humanoid enemies who use creeper as a resource. Don't add code keyed to raider type names or the creeper-born rule; read enemies through the existing lists/data so the swap only changes data.

## Scope
Do:
1. `godot/scripts/core/metrics_turning_points.gd` (new, `class_name MetricsTurningPoints`, static): `pick(m: PlayMetrics) -> Array[String]` scans `m.samples` and `m.events` and returns at most 3 plain sentences, ordered by time, from these detectors:
   - **Bank dry:** first sample where `energy < 1` while any weapon exists, lasting at least `Config.DEBRIEF_DRY_SECS`.
   - **Starved weapons:** first moment 2+ weapons are out of ammo (use what samples/events already carry; add one `Bus.metric.emit("ammo_dry", {type})` in the weapon tick only if nothing existing covers it).
   - **Tier unlock:** each enemy tier unlock from the level's `RAID_SCHEDULE` (names from the schedule/roster data, never hard-coded) that happened before the end.
   - **Node hit:** the first node-hit/`structure_lost` event and whether it was creeper (`wet`) or raiders.
   Example: "6:50 - your Snipers ran dry, 2 min before Brutes arrived."
2. `PlayMetrics.end_text()` appends the lines under a **Turning points** header on a **loss** only (wins keep today's text).
3. New tunables `DEBRIEF_DRY_SECS`, `DEBRIEF_MAX_LINES` (3) in `config.gd`.

Must not change:
- Existing action ids, structure ids, `user://keybinds.cfg`, the creeper flow rule, other levels' data.
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- On a loss, the end screen shows 1-3 dated, specific sentences; on a win it is unchanged.
- Smoke: a hand-built PlayMetrics (samples/events) yields the expected sentences in time order; an empty run yields none without errors.
- New tunables live in the project's config/data tables, not in logic.

## Verify
1. parse: `cd godot && ! godot --headless --path . --import 2>&1 | grep -A1 'SCRIPT ERROR'`
2. smoke: `cd godot && godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep smoke` (all PASS)
3. Sim (no regressions): `cd godot && godot --headless --path . -- --demo --units --sim=900 --quit=0.1 | grep "\[sim\]"`; paste the line before and after in the progress log.
4. Screenshot (Xvfb, CLAUDE.md Testing §5) of anything visible; with no display write "screenshots: Opus" in the log.

## Report
Stop and report in the AGENTS.md format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
