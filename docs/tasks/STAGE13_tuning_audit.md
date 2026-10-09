# Brief T (Muse): Stage 13 tuning audit (measure and propose, change no numbers)

**Branch:** `stage/13-tuning-audit` (from `main`). **Start now.** Brief P (`fix/playtest2-pressure`) will change L2 balance when it merges (trebuchet range and HP, raider grace). Measure L1 first. For L2, if P has landed on `main` by the time you get there, fetch `main` and measure on that version (you may merge `origin/main` into this branch for that). Say in the report which commit each number came from.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, MASTER_PLAN.md §2 items 13 and 14 only, `level/raider_defs.gd`, `level/flyer_defs.gd`, `command/structure_defs.gd`, `core/config.gd` and the level `RAID_SCHEDULE`s. The only output is `docs/tasks/STAGE13_report.md`, plus at most one new helper flag in `core/` if a number can't be measured otherwise.

## Targets (from MASTER_PLAN 13)
- Every ranged enemy has a counter the player can afford when it unlocks.
- Little Salvage is left over at a win.
- The pressure cap lands after a reasonable winning time.

## Tasks
1. **Baseline runs.** For L1 and L2, run each of these 3 times and record the median of the `[sim] report` fields `time, over, win_time, node_hp, pressure, salvage, salvage_earned, ore_mined, aether, raider_tier, raiders, flyers, coverage, objectives, weapons_dry, unmet`:
   - `--autostart --sim=600`
   - `--demo --units --sim=900`
   - `--demo --units --sim=1800`
2. **Unlock table.** For each ranged or air enemy (Spitter, Lancer, enemy mortar, Spotter, each flyer type, spore launcher), find:
   - when it first appears on each level (schedule or measured), and its counter (Sniper, Beam, Operative weapon …) with that counter's energy or Salvage cost;
   - the player's income at that time in the `--demo --units` run, and how many seconds of income buy one counter;
   - a verdict: OK, tight, or unfair.
3. **Pressure curve.** Give `pressure()` at 0, 5, 10, 15, 20, 30 and 40 min for both levels, the time it reaches its cap, and the `--demo` win time if there is one. Say whether a win lands before the cap.
4. **Salvage.** List total Salvage earned by 15 and 30 min against what the Armoury and castle turrets can spend it on. Is anything left over at the win?
5. **Proposals.** At most 8 concrete changes (file, key, old → new, why, which target it serves). **Don't apply them**; Opus and the user decide.

## Must not change
Any tunable, def or level file. Game code only for one measuring flag, if needed.

## Report
AGENTS.md format, plus the path to STAGE13_report.md. Keep the report under ~150 lines, with tables, not prose.
