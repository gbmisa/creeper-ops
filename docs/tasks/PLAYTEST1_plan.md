# Playtest 1 (2026-10-08): feedback log and plan

User feedback, recorded as given. Nothing below is built yet except item 1, which is parked on a branch.

## Feedback
1. Snipers shoot through castle walls and clear castles before the Operative gets in. Snipers must not shoot through terrain.
2. Snipers keep shooting Spitter Towers that sit "underground", which wastes very expensive ammo. The user can't find or kill those towers in first person. Pressing E on them seems to do nothing.
3. The Sniper is far too expensive (250 energy). Together with item 2, it killed the run "and any fun".
4. Spore nests (hive cores) take about 30 s of holding fire. Cut their HP drastically. Make nests hard **to reach** instead of slow to kill.
5. "The enemies are insane right now." Overall raider pressure is far too high.

## Causes found (Opus)
- **1, 2:** `WeaponLogic._snipe` shot the nearest foe with no sight check. The enemy builder (`EnemyBuildPlan._open`) could place towers under Castles 2.0 roofs, which look underground from both views.
- **2, E:** sabotage works, but it's a silent 3 s channel that cancels if you're more than 2 m from the tower's centre, so it feels like nothing happens.
- **4:** core HP = `HIVE_CORE_BASE + HIVE_CORE_PER_P × pressure` (`hives.gd base_hp`). It grows with mission time.

## Work items, and who does them
| # | Item | Agent / model | Why this model | Files |
|---|---|---|---|---|
| A | **Review and merge** branch `fix/playtest1-sniper-los`, already written. It adds sniper line of sight (`WeaponLogic.sees`), no enemy builds under roofs, a sabotage progress prompt, start and interrupt messages, a 3 m reach, and `smoke_sniper_los.gd`. Smoke 0 failures. | **Opus** (merge only) | Merging is the orchestrator's job. The diff is small. | done, awaiting merge |
| B | **Numbers pass.** Hive core time to kill with the crossbow goes from about 30 s to about 4-6 s at any pressure (lower `HIVE_CORE_BASE`/`PER_P`). Sniper cost 250 → about 120 (the user approves the value). Cut overall raider pressure: spawn interval, caps and tier unlock times (`NEST_*`, `RAIDER_TIERS`, level `RAID_SCHEDULE`). Use the user's own `user://metrics` files plus sims: first loss after 5 min or later on L1 with a reasonable build, and the L1 undefended run still dies. | **Haiku 4.5** `balance-tester` | Config and level-table numbers only, measured with sims and the metrics report. No new code. | `config.gd`, `structure_defs.gd` (cost only), `level01/02.gd` schedule rows |
| C | **Nests hard to reach.** Move hive sites to places that take effort: plateaus reached only by a stair or ramp, behind Blight, across creeper channels, cave mouths, guarded chokepoints. Each L1 and L2 hive gets a route the Operative can walk (check with `RaiderField.reachable` / the walk smoke). | **Sonnet** `level-builder` | Level content against a written spec, using existing tools (`LevelRamps`, terrain shaping). No new systems. | `level01.gd`, `level02.gd` |
| D | **Visibility check** after A: screenshots of every enemy structure kind in command and first-person views. Verdict in words: is each one visible and reachable? | **Haiku** `balance-tester` (screenshots) | Pass/fail verdicts only. | none |

**Order:** A first. Then B and C at the same time (different files, except the level schedule rows: B touches only the `RAID_SCHEDULE` row, C only hive positions). D after C.
**Conflict warning:** the unreviewed `stage/9b-content` branch also edits level placement and tuning. Merge or close 9b before C starts, or C starts from 9b.
**Needs the user before B starts:** the Sniper price, and how hard "insane" should drop to (e.g. "L1 survivable for 10 min with a sensible build on the first try").
