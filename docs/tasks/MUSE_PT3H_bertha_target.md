# Brief PT3-H (Muse): Big Bertha manual targeting (playtest 3, item 31)

**Branch:** `pt3/bertha-target` (from `integ/2026-10-09`). Touch `command/weapon_logic.gd` (Bertha only), `command/structure_defs.gd` (`bertha` row), `command/command_input.gd` / `command/command_select.gd` (the order), `command/command_hover.gd` (aim preview), `core/keybinds.gd` (one new action), `ui/info_panel.gd` (button/hint), and a smoke file.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, the `bertha` row in `structure_defs.gd`, Bertha paths in `weapon_logic.gd` (~lines 20-130), how `@lance` targets in `command_hover.gd`/`orbital.gd`, and `level/castle_engines.gd` (trebuchet target dicts).

## Gregory's decision
> "Big Berthas should be able to manually target things, so it can be used to do things like shoot trebuchets on castles. But have a very slow attack speed. And be very expensive."

## Today
Bertha: cost 250, range 200, `fire_rate` 10, 150 ammo per shot, auto-targets **creeper** only.

## Tasks
1. **Order:** select a Bertha (or a group of them), press a new action `bertha_target` (default `T` only if free in `Keybinds.DEFAULTS`; pick a free key and say which) or click a "Target" button on the info panel, then click the ground or an enemy. The Bertha fires at that target until it dies or the order is cleared (right-click / Esc / the same key again), then returns to auto (creeper).
2. **Valid targets:** any ground point in range, plus enemy *structures*: trebuchets / castle engines, enemy-built structures, castle turrets, hive parts. Enemy mortars stay demolition-charge-only (playtest 3, item 10): Bertha splash must not kill them. Shells still remove creeper where they land.
3. **Tuning (config/def, not code):** much slower and much pricier. Start with cost 600, a 30 s interval between manual shots, and the same per-shot ammo. Damage enough that 2-3 shells kill a trebuchet (`castle_defs`). Put the maths in the report.
4. **Feedback:** aim preview ring at the target (terrain shader overlay, like the Lance), a reload bar on the Bertha, and `Bus.say` when the target dies. Uses the existing `whistle` + `boom` sounds.
5. **Smoke rules:** an ordered Bertha fires at a trebuchet in range and kills it within the expected shell count; it never fires faster than the manual interval; it can't kill an enemy mortar.

## Must not change
Other weapons, Lance, mortar demolition rule, Bertha flight/landing.

## Report
AGENTS.md format.
