# Playtest 2 (2026-10-08): L2 raider pressure + trebuchet time to kill

Branch `fix/playtest2-pressure`, progress `docs/tasks/PLAYTEST2_progress.md`. Follow `AGENTS.md`. Push only this branch.

## User feedback (as given)
"I got completely overwhelmed by enemies and lost in under six minutes while trying to raid the first castle. The trebuchets take way too long to kill. And the enemies are coming out too fast to handle with any amount of sniper towers or even operative interaction."

## Evidence (metrics file `docs/playtests/L2_20261008-165004.json`, level 2 The Crown Marches)
Lost at 351 s, Node killed by creeper. First structure lost at **22 s**; 18 losses by 148 s, then a collapse at 307-351 s. 37 lost: **30 to "other"** (raiders/engines/mortars; the event has no cause), 7 to creeper. Built: 21 collectors, 5 reactors, 2 beams, **1 sniper**, 1 storage, 1 totem. 44 raiders alive at the end, pressure only 0.27. 215 s on foot (two incursions), 86 s starved of energy.

## Tasks
1. **Metrics first:** the `structure_lost` event must say what killed it (`by`: raider tier name, `engine`, `mortar`, `creeper`, `spitter_shot`...). Re-read the file above for anything else useful and report the numbers.
2. **Find the cause with seeded sims.** Add a seed option if sims aren't seeded (HANDOFF says demo sims are noisy). Measure on L2: when the first raider reaches the player's base, raiders alive at 1, 2, 3, 4 and 5 min, and spawn rate per nest over time. Compare L1. Check whether L2's `RAID_SCHEDULE`, the castle reprisal/siege (`CastleRaids`), the hostile-castle nest speed-up (`nest.rate`) and the trebuchets stack in the first minutes.
3. **Tune (data only: `config.gd`, `level02.gd`, `castle_defs.gd`, `raider_defs.gd`).** Targets:
   - Nothing hostile reaches the starting base before **~2:00** on L2 (the first raid can be a few Skitters).
   - A player who builds **3 snipers** near the Node by 3:00 holds the base on their own until ~6:00 (seeded sim with a scripted build; add one to `debug.gd` if needed).
   - Raider count alive at 5:00 with that defence: report it, aim for under 15.
   - **Trebuchets:** the Operative kills one with the Pulse Rifle in **≤ 8 s** of sustained fire (or one Demo Charge). Today: measure and report it. Snipers and mortars can hurt them too if they don't already.
   - Raiding the first castle stays dangerous but beatable: its reprisal should not land while the Operative is still taking it.
4. Keep L1 roughly where it is (undefended L1 sim ±15%), and keep the smoke tests green. Don't change player weapon damage (that's the Art 3 F brief's rule).

## Report
Before/after table: first contact, raiders at 1-5 min, trebuchet TTK, sniper-defence survival time, L1 undefended time. List every number you changed (old → new).
