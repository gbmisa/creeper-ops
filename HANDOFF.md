# Handoff: 2026-10-16 (branch feat/fb-reload, main checkout; two Opus sessions share it)

**Play build:** `feat/fb-reload` (pushed up to `194f425`; local is ahead: `a0b68d6` + merge `bfd4aad`, not pushed).
Run: `godot --path godot` -> level select -> Firing Range / Skirmish (Skirmish is its own scene since F82:
`godot --path godot res://scenes/skirmish.tscn`). Windows machine: Godot 4.7.2 via winget, Blender 5.2.2 portable,
Blender MCP registered (user scope). After pulling new `class_name` files: `godot --headless --path godot --import`.

## Session A (Skirmish gameplay; committed a0b68d6)
- **P9 arm loss APPROVED + built** (player and bots): `TacticalConfig.ARM_LOSS`, `BodyHealth.arms_down/arm_loss`.
- Meds crate -> IFAK + bandage into the inventory; quick-use keys 4/5 (`QuickUse`, `QuickBar`).
- Skirmish MAP-2 layout (`docs/tasks/SKIRMISH_MAP2.md`): CQC old town west, open east, cover kind `container`.
- CHANGES.md: new **P10** (bots ignore leg damage) and **P11** (arm fracture sway is dead code), waiting for Gregory.
- Known: kill-house navmesh doorway check can fail (pre-existing); barracks north door split by the inner wall.

## Session B (reloads + F89-F93 + merges)
- **F89-F93** (`fix/f89-f93`, pushed, merged into fb-reload): spare mags on deploy (F90), `BotUnstick` (F91, safety
  net; no real snag reproduced), death screen bottom-left + 1 s click grace (F92), spawn/lane cover (F93), P9 written.
- **Merge `bfd4aad`** of `origin/feat/skirmish-scene` (F82 + CLAUDE.md refresh): `firing_range.gd` conflict resolved
  by taking F82's `TacticalScene` split; `a0b68d6`'s QuickUse/QuickBar wiring moved into `TacticalScene._add_hud`.
- **FB-R reloads** (brief `docs/tasks/FB_R_reload_anims.md`, log `FB_R_progress.md`, scores `docs/art/reload/SCORES.md`):
  judged >= 8: ak47, m1911, glock18, p90 (all), mp5 plain/fast (empty 7: structural), scarh/sr25/saiga12/sks plain
  (+ scarh/sr25 fast). Below 8: the 4 rifles' empty reloads (5-6), saiga12/sks fast (7).
- **Uncommitted WIP** (`reload_anims.gd`, `reload_rigs.gd`, `reload_timeline.gd`): empty-tail fix for the 4 rifles
  (charge phases skip `pose_shift`, AR press = catch +1.5 cm in + hold, SKS/Saiga charge points from a mesh probe,
  swing-in >= 0.35 s on rifle/ar plans) + `HANDS["lock"]` default (fixes the `_anchor 'lock'` SCRIPT ERROR spam).
  Sheets rendered in the session scratchpad, **not yet reviewed or judged**; commit after a judge round.
- Tools (scratchpad, not in git): `sheet.py` (frame strips -> labelled sheet, 3 renders in parallel max, never while
  the headless suite runs: it hangs), `grid.py` + tall ortho (mag coordinates), `mag_probe.gd` / side probes.

## Verified (merged tree incl. WIP)
Parse clean; `--range-test` 1113 pass / 1 fail; smoke 0 FAIL. The fail is `a shot at spawn ... (F88)`: Scav 5 runs to
cover and back on MAP-2, net move 0.6 m (not stuck; check measures net distance; left as is, report-don't-loosen).
Not verified: Gregory's play of any of this; bots over a full match on MAP-2; GPU perf with the new map.

## Next
1. Push `feat/fb-reload` (a0b68d6 + bfd4aad) when the user says so.
2. Reloads: review the WIP sheets, judge round 2 for the 4 rifles' empty + fast, then commit. Then sniper (AXMC, bones),
   M4A1 (`ar` plan; ask Gregory about hiding his posed arms during reloads), then tube / en-bloc / revolver plans.
3. Gregory rules on CHANGES P10 / P11 and plays Skirmish (MAP-2, F90-F93).
