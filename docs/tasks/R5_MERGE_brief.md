# R5 merge brief (2026-10-16, Opus): bring Muse's finished RANGE5 tracks into the play build

Gregory asked for these to be merged. They were finished on origin 2 days ago and never merged; the play build
(`play/f98-f107`) has moved a long way since. Each merge conflicts.

## Rule for every conflict
**The play build wins for everything that already exists.** Keep play's behaviour, numbers, AI, UI, keybinds and
fixes exactly as they are (F-fixes are frozen). From the branch, take only the NEW feature: its new files, its new
defs/keybind entries, its new hooks into existing files. If the branch changed an existing behaviour that play has
since changed too, keep play's version and list it in your report. Never rename an action id; new keys go in
`Keybinds.DEFAULTS` and must not collide with existing defaults (check the list).

## Agent A (worktree `../r5-merge-a`, branch `merge/r5-a` off play/f98-f107)
1. `git merge origin/feat/r5-med` (meds + build-up status effects). Resolve, parse check, run range suite, commit.
2. `git merge origin/feat/r5-util` (grapple, grenades, binoculars, bot reactions). Same.

## Agent B (worktree `../r5-merge-b`, branch `merge/r5-b` off play/f98-f107)
1. `git merge origin/feat/r5-cheats` (cheat menu Ctrl+KP5 + WIP Tempest gun). Same rule. If Tempest doesn't parse
   or breaks tests, keep the cheat menu and leave Tempest out of the rack/loot (say so).
2. Second Skirmish map from `origin/feat/r5-expand` (~220 m, four districts). **Do not merge the branch.** The current
   Skirmish map stays byte-identical (skirmish_layout.gd, skirmish_data.gd, skirmish_game.gd behaviour for map
   "skirmish"). Add the expanded map as a NEW map id `skirmish_large` in `RangeMaps.SCENES` (its own .tscn), with
   its own layout/data files (copy the district files; rename classes where they would clash). Reachable the same way
   the current Skirmish is chosen (the range map choice / menu that lists maps). Bots, kit, extraction: reuse the
   current Skirmish systems. Add its test (from range_test_expand.gd) to the suite.

## Done = for each step
`godot --headless --path godot --import 2>&1 | grep -A1 "SCRIPT ERROR"` prints nothing; range suite
(`godot --headless --path godot res://scenes/firing_range.tscn -- --range-test 2>&1 | grep "^\[range\]" | tail -2`)
prints OK; for B2 also boot `skirmish_large` 20 s with 0 SCRIPT ERROR. Commit each step on your branch. Never merge
into play, never push.

## Report (under 250 words)
Commits, suite counts, every conflict where you kept play's version over the branch's, new keybinds, anything left out.
