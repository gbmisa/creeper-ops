# Brief I-002: Paint targets for the network

<!-- gdflow:I-002 -->
**Idea:** I-002 on the [idea board](../design/IDEAS.md). **Pillar:** CW3 core, FPS edge. **Priority:** 4.8
**Branch:** `muse/ideas-i001-i006` (from `claude/game-design-automation-gy0p8q`). **Model:** Muse (long run, phase 3)
**Read only:** AGENTS.md, CLAUDE.md (Key contracts + Conventions), docs/tasks/LONG_RUN_RULES.md, this brief, `docs/tasks/IDEAS_progress.md`, and in `godot/scripts/`: command/weapon_logic.gd (_snipe, _lob), fps/operative_weapons.gd, ui/markers.gd, core/keybinds.gd DEFAULTS. Don't read whole design docs.

## Why
The Operative carries a designator: painting a raider group, Spitter Tower or nest makes Snipers, mortars and the Lance prioritise it for 10 s. First slice: a designate action that sets a priority target read by WeaponLogic target selection.

**Player moment we want:** Calling a Bertha shell onto a tower you're crouched beside

**Enemy swap (DECISIONS D-002):** raiders will be replaced by humanoid enemies who use creeper as a resource. Don't add code keyed to raider type names or the creeper-born rule; read enemies through the existing lists/data so the swap only changes data.

## Scope
Do:
1. `godot/scripts/fps/designator.gd` (new, `class_name Designator`): a new `designate` action in `Keybinds.DEFAULTS` raycasts the crosshair; any agent in the lists `_snipe` already gathers (raiders, guards, `enemy_build.snipe_foes()`) or a nest becomes **the** priority target for `Config.DESIGNATE_TIME` (10 s), cooldown `DESIGNATE_COOLDOWN`. One target at a time.
2. `godot/scripts/command/target_priority.gd` (new, static): `designated(candidates) -> agent or null`. `WeaponLogic._snipe` prefers it over its normal ordering (range and line of sight still required). `_lob` (mortar/Bertha) shells the designated agent's cell when in range, even if dry; otherwise it keeps creeper targeting. Keep `weapon_logic.gd` under 250 lines (logic lives in the new file).
3. Feedback: a red marker (markers contract in CLAUDE.md) on the target and a short `Bus.say`.
4. `Bus.metric.emit("designate", {kind})`.

Must not change:
- Existing action ids, structure ids, `user://keybinds.cfg`, the creeper flow rule, other levels' data.
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- Painting a Spitter Tower in range makes every Sniper that can see it shoot it next, and in-range mortars shell its cell, for 10 s; then targeting returns to normal.
- Smoke: priority beats nearest/ranged ordering, expires after 10 s, ignores out-of-range or unseen targets, a dead target clears it.
- New tunables live in the project's config/data tables, not in logic.

## Verify
1. parse: `cd godot && ! godot --headless --path . --import 2>&1 | grep -A1 'SCRIPT ERROR'`
2. smoke: `cd godot && godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep smoke` (all PASS)
3. Sim (no regressions): `cd godot && godot --headless --path . -- --demo --units --sim=900 --quit=0.1 | grep "\[sim\]"`; paste the line before and after in the progress log.
4. Screenshot (Xvfb, CLAUDE.md Testing §5) of anything visible; with no display write "screenshots: Opus" in the log.

## Report
Stop and report in the AGENTS.md format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
