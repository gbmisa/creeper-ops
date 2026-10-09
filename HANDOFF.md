# Handoff: 2026-10-08 (session 15e: X+B merged, 5 new Muse briefs, player structure models)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). **Opus long-horizon plan: [docs/tasks/ART3_OPUS_plan.md](docs/tasks/ART3_OPUS_plan.md).**
Repo: https://github.com/gbmisa/creeper-ops (private). **Muse** (Fount) codes from GitHub branches; **Opus** orchestrates, merges, and does visual work only. Prompts for the user: [muse1.md](muse1.md). Memory: `muse-does-coding` (never move a branch Muse has started; strip `godot/.godot/` at merge). **Opus → Muse messages go in [docs/tasks/MUSE_NOTES.md](docs/tasks/MUSE_NOTES.md) on main.**

## Merged to main this session
- `art/3-fx` (X) and `fix/muse-b-bugs` (B: spawn off the gear, hold-fire bloom max 5.5° plus climb, RecoilDefs.cam, hud split). Parse is clean; smoke 0 failures after the merge.

## Branches
| Branch | Owner | Status |
|---|---|---|
| `fix/playtest2-pressure` | Muse P | **Not mergeable yet: 9 smoke failures.** L2 hive `access` tags dropped, 2 castles2 engine tests, `.godot` files, `flyer_ai.gd` overlap with main. Fix list is in MUSE_NOTES; the fix-up prompt is in muse1.md. |
| `art/3-hive-models` | Muse A3 | running |
| `stage/21b-castles-detail` | Muse C | running (P0–P8) |
| `tools/shot-tour` | Muse S | Reviewed: smoke OK; `look=`/`select=`/`fps=` work. **The `gallery=` framing is broken**, so there's a fix-up (MUSE_NOTES). |
| `fix/q-spitter-towers` | Muse Q | up: enemy Spitter Towers on L1 (underground, out of Sniper reach, no cap) |
| `stage/13-tuning-audit` | Muse T | up: measure and propose only, writes STAGE13_report.md |
| `art/4-structure-models` | Muse A4 | up (`a4468a5`, models included): weapons as 3 glbs, plus collector and relay |
| `chore/k-split-files` | Muse K | up: split operative_weapons.gd (263 lines) and one group out of config.gd (~311) |
| `art/3-models` | Opus | Latest `941c08f`: also the military Bertha 7, Thor 7, Terp 8, Nullifier 7, Outpost 8 (`weapon_kit.run(parts=)`). Brief A5 is on main; **Opus creates `art/5-military-models` after A4 merges.** Log: `docs/tasks/ART3M_progress.md`. |

## Grading this session (Sonnet grader, up to 3 rounds)
Cannon 7, mortar 7, sniper 6.5, beam 7.5, collector 7, relay 7. Each weapon is 3 glbs (`_base`, `_turret`, `_arm`) whose pivots match WeaponMeshes' Turret and Arm, so the aim code is unchanged. Preview: `art/blender/wreview.sh <id> <png>` (assembled weapon). Recurring grader note: the hit clips are subtle on static structures; X's hit flash covers that in game.

## Next (Opus)
1. Re-review P after the fix-up and merge it. Then review S, T, K, A3, A4 and C as they land: Sonnet for code; for visuals, Opus takes screenshots and a grader judges them, using S's tour once it's merged.
2. In game: hives, Totem, pod and Node (A3), and the weapons, collector and relay (A4).
3. **Restyle as military (Gregory approved; don't start until asked):** redo cannon, mortar, sniper, beam, collector and relay in the military palette (olive, gunmetal, concrete, sandbags, hazard; glow only for gameplay cues), so they match the titans. Keep the pivots and bone names so A4's loader still works. Same grading loop, and push to `art/3-models`.
