# Brief I-006: Last-stand overdrive

<!-- gdflow:I-006 -->
**Idea:** I-006 on the [idea board](../design/IDEAS.md). **Pillar:** Race the pressure. **Priority:** 3.6
**Branch:** `muse/ideas-i001-i006` (from `claude/game-design-automation-gy0p8q`). **Model:** Muse (long run, phase 2)
**Read only:** AGENTS.md, CLAUDE.md (Key contracts + Conventions), docs/tasks/LONG_RUN_RULES.md, this brief, `docs/tasks/IDEAS_progress.md`, and in `godot/scripts/`: command/weapon_logic.gd (fire_interval only), core/keybinds.gd DEFAULTS, ui/top_bar.gd. Don't read whole design docs.

## Why
Once per level, when the Node falls below 25% HP, the player can overclock: every weapon fires twice as fast for 20 s, then the network stalls for 30 s. A real comeback decision with a sharp cost. First slice: an Overdrive action with OVERDRIVE_* tunables multiplying WeaponLogic.fire_interval.

**Player moment we want:** Hitting overdrive with the creeper at the Node's feet and pushing it back

## Scope
Do:
1. `godot/scripts/command/overdrive.gd` (new, `class_name Overdrive`, state reset per level): `ready -> active -> stalled -> spent`. Usable once per level, only while the Command Node is below `Config.OVERDRIVE_NODE_HP` (0.25) of max HP.
2. **Active** (`OVERDRIVE_TIME` 20 s): `WeaponLogic.fire_interval()` also divides by `Overdrive.fire_mult()` (`OVERDRIVE_FIRE_MULT` 2.0). **Stalled** (`OVERDRIVE_STALL` 30 s): no sender launches packets (one guard where packets launch; name the function in the log).
3. New action `overdrive` in `Keybinds.DEFAULTS` (an unbound key; follow the keybind rules in CLAUDE.md), read with `input.act("overdrive")` in command mode. A top-bar chip shows READY / seconds left / STALLED, hidden when locked or spent.
4. `Bus.metric.emit("overdrive", {state})` on each transition (feeds I-001).

Must not change:
- Existing action ids, structure ids, `user://keybinds.cfg`, the creeper flow rule, other levels' data.
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- Above 25% Node HP the action does nothing and says why (`Bus.say`); below it weapons fire twice as fast for 20 s, then no packets launch for 30 s, then it is gone for the level.
- Smoke: state timings, fire-interval halving, the stall blocking a launch, once per level.
- New tunables live in the project's config/data tables, not in logic.

## Verify
1. parse: `cd godot && ! godot --headless --path . --import 2>&1 | grep -A1 'SCRIPT ERROR'`
2. smoke: `cd godot && godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep smoke` (all PASS)
3. Sim (no regressions): `cd godot && godot --headless --path . -- --demo --units --sim=900 --quit=0.1 | grep "\[sim\]"`; paste the line before and after in the progress log.
4. Screenshot (Xvfb, CLAUDE.md Testing §5) of anything visible; with no display write "screenshots: Opus" in the log.

## Report
Stop and report in the AGENTS.md format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
