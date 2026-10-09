# Handoff: 2026-10-08 (session 15c: hive/player models, A2 check, Muse notes)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). **Opus long-horizon plan: [docs/tasks/ART3_OPUS_plan.md](docs/tasks/ART3_OPUS_plan.md).**
Repo: https://github.com/gbmisa/creeper-ops (private). **Muse** (Fount) codes from GitHub branches; **Opus** orchestrates, merges, and does visual work only. Prompts for the user: [muse1.md](muse1.md). Memory: `muse-does-coding` (never move a branch Muse has started; strip `godot/.godot/` at merge). **Opus → Muse messages go in [docs/tasks/MUSE_NOTES.md](docs/tasks/MUSE_NOTES.md) on main** (Muse reads it before each brief).

## Merged to main this session
- Playtest 1C hive sites (Muse). Opus sims: L1 undefended 341 s, L1 demo 734 s, L2 demo 400 s (no balance change).
- `art/3-gun-feel` (Muse): recoil defs, rifle bloom, yaw punch, sounds, crossbow reload. Sonnet review: no damage/rate/ammo change. Feel needs the user's play test.
- `fount/ui-pass` (Muse, unbriefed): HUD panels, buttons, HP bar. Opus screenshot: command HUD reads well.

## Branches
| Branch | Owner | Status |
|---|---|---|
| `art/3-integration` | Muse brief **A2** | First push `f59ef5a` checked: parse clean, smoke OK (0 failures), `--creatures --look=40,74,22` shot looks good. Still to do: gallery camera, perf numbers, `die()` get_tree error in the test (MUSE_NOTES). **When Muse reports done, Opus merges to main, then creates `art/3-hive-models` (integration + art/3-models) for A3.** |
| `art/3-hive-models` | Muse brief **A3** | not created yet: hive parts, Totem, drop pod hookup ([ART3_A3_hive_models.md](docs/tasks/ART3_A3_hive_models.md)) |
| `fix/playtest2-pressure` | Muse P | running (top priority gameplay fix) |
| `art/3-fx` | Muse X | running |
| `fix/muse-b-bugs` | Muse B | queued: FPS camera inside an orange mesh, RecoilDefs.cam, weapon label, split hud.gd, **plus hold-to-fire spread and recoil climb** (Gregory, MUSE_NOTES) |
| `stage/21b-castles-detail` | Muse C | queued after P/A/X |
| `art/3-models` | Opus | 25 glbs: 16 creatures/units, trebuchet, 6 hive parts (`hive_*`), `totem`, `drop_pod`. Progress and grading log: `docs/tasks/ART3M_progress.md`. |

## Model grading (Sonnet grader, 3 iterations done, as the user asked)
- Creatures: 6.1 → 6.8 → 7.4.
- Hive parts: 6.7 → 7.3 → 7.75; core 8.5, spitter and launcher 8.
- Totem, pod and trebuchet: each ends at 7.5.
- An open-notes pass ran on the burrower, skitter, behemoth and wyvern. The contact sheets are limited by the camera now; judge them **in game** next. The wyvern is the weakest.

## Next (Opus)
1. When A2 is reported done: merge `art/3-integration` to main (strip `.godot`), create `art/3-hive-models` from it plus `art/3-models`, push, and tell the user to paste prompt A3.
2. In-game grading: `--creatures --look=40,74,22` (L1 node at 40,66) plus a surface FPS view. Check the glow on low tiers (it came out cream) and the wyvern.
3. Review P, X, B and C as they land (Sonnet for code, Opus screenshots for visuals).
4. Still to model: an animated Command Node (lift-off and landing). The procedural one is decent, so it's low priority.
