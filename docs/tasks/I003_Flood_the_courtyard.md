# Brief I-003: Flood the courtyard

<!-- gdflow:I-003 -->
> **ON HOLD (parked 2026-10-14, DECISIONS D-002).** Enemies will harvest creeper, so flooding a castle may feed them. Not part of the Muse run; don't build it.
**Idea:** I-003 on the [idea board](../design/IDEAS.md). **Pillar:** CW3 core, FPS edge. **Priority:** 3.29
**Branch:** `muse/ideas-i001-i006` (from `claude/game-design-automation-gy0p8q`). **Model:** Muse (long run, phase 6)
**Read only:** AGENTS.md, CLAUDE.md (Key contracts + Conventions), docs/tasks/LONG_RUN_RULES.md, this brief, `docs/tasks/IDEAS_progress.md`, and in `godot/scripts/`: level/hives.gd + hive_spawning.gd (crown nest), the CastleGuards file, command/terp.gd. Don't read whole design docs.

## Why
Creeper already ignores gates, so a Terp channel can steer the tide into a hostile castle: wet raiders take damage and the crown nest's spawns drown. Turns the enemy's own weapon into a siege tool, with the risk that the flood comes back at you. First slice: creeper contact damages raiders (RAIDER_WET_DPS in config), then a smoke test that a channelled flood clears a courtyard.

**Player moment we want:** Breaking a dam and watching the creeper pour through the gatehouse

## Scope
Do:
**Design rule (DECISIONS D-001):** creeper still must not hurt nest-bred raiders (`raiders.gd`: creeper-born). The flood hits the castle itself:
1. **Drown the crown nest:** while any cell within `Config.CROWN_WET_RADIUS` of a crown nest is wet deeper than `CROWN_WET_DEPTH`, it spawns nothing and takes `CROWN_WET_DPS`. Put the check where the crown nest ticks/spawns (or a small new helper). `Bus.metric.emit("crown_wet", {castle})` once per flood.
2. **Sentinel guards** (`CastleGuards`, not nest-bred) take `SENTINEL_WET_DPS` while standing wet.
3. No new terrain code: the player floods with existing Terp Earth and the existing rule that creeper ignores gates. Smoke sets creeper through `CreeperSim.add/set_depth` (never `depth[...]`).
4. One line in the castle briefing/tooltip text: 'Creeper drowns a crown nest.'

Must not change:
- Existing action ids, structure ids, `user://keybinds.cfg`, the creeper flow rule, other levels' data.
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- A crown nest under creeper stops spawning and loses HP, and resumes once dry. Sentinels in creeper lose HP. Nest raiders are unaffected (assert it).
- Smoke covers all three using `CreeperSim` setters only.
- New tunables live in the project's config/data tables, not in logic.

## Verify
1. parse: `cd godot && ! godot --headless --path . --import 2>&1 | grep -A1 'SCRIPT ERROR'`
2. smoke: `cd godot && godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep smoke` (all PASS)
3. Sim (no regressions): `cd godot && godot --headless --path . -- --demo --units --sim=900 --quit=0.1 | grep "\[sim\]"`; paste the line before and after in the progress log.
4. Screenshot (Xvfb, CLAUDE.md Testing §5) of anything visible; with no display write "screenshots: Opus" in the log.

## Report
Stop and report in the AGENTS.md format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
