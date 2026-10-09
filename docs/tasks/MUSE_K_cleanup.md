# Brief K (Muse): file-size cleanup

**Branch:** `chore/k-split-files` (from `main`). **Read:** AGENTS.md, CLAUDE.md (the 250-line rule) and the two files below. Pure refactor: no behaviour change.

1. `fps/operative_weapons.gd` is 263 lines. Split one responsibility out into a new `class_name` file (for example the bloom and recoil-climb state, or ammo and reload), so both files stay under ~220.
2. `core/config.gd` is about 311 lines. **Don't rename any constant**: every `Config.X` reference must keep working, and other branches (A3, C, P) edit this file. Instead, move one self-contained group of constants that only a few files read (for example the FX or recoil numbers) into its own config class, and update only those readers. Pick the group that touches the fewest files, and list them in your report. If no group can move without touching more than 6 files, skip this step and say so.
3. Run parse, smoke and L1 `--demo --units --sim=900` before and after; the results must match.

Report in the AGENTS.md format. Commit and push only to `chore/k-split-files`.
