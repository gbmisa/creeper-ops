# Handoff: 2026-10-08 (session 15d: A2 merged, A3 branch up, wyvern + Command Node models)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). **Opus long-horizon plan: [docs/tasks/ART3_OPUS_plan.md](docs/tasks/ART3_OPUS_plan.md).**
Repo: https://github.com/gbmisa/creeper-ops (private). **Muse** (Fount) codes from GitHub branches; **Opus** orchestrates, merges, and does visual work only. Prompts for the user: [muse1.md](muse1.md). Memory: `muse-does-coding` (never move a branch Muse has started; strip `godot/.godot/` at merge). **Opus → Muse messages go in [docs/tasks/MUSE_NOTES.md](docs/tasks/MUSE_NOTES.md) on main.**

## Merged to main this session
- `art/3-integration` (A2), plus Muse's `022b25a` cherry-picked from `art/3-creature-anim` (speed_scale ÷ model scale, idle/walk loop at load, `flap()`, `die()` tree fix), plus an Opus smoke fix (`hive_core.glb` path). Smoke: 0 failures.
- **Don't merge `fa76b02`** (`art/3-creature-anim`): Muse's API push deleted real files (PLAYTEST2 brief, smoke_hive_sites, muse1.md). That branch is finished.

## Branches
| Branch | Owner | Status |
|---|---|---|
| `art/3-hive-models` | Muse **A3** | **Created and pushed (`997942b`); the user can paste prompt A3.** Hive parts, Totem, drop pod, Command Node (task 9). Task 0 holds the A2 leftovers: gallery camera, perf numbers, cream glow (diagnosis in MUSE_NOTES). |
| `fix/playtest2-pressure` | Muse P | running, nothing pushed yet |
| `art/3-fx` | Muse X | running, nothing pushed yet |
| `fix/muse-b-bugs` | Muse B | running (includes hold-to-fire); only the brief so far |
| `stage/21b-castles-detail` | Muse C | queued after P/A/X |
| `art/3-models` | Opus | 27 glbs. Latest: rebuilt wyvern, `command_node`. Log: `docs/tasks/ART3M_progress.md`. |

## Grading this session (Sonnet grader, 3 rounds each)
- **preview.py fixed:** it now frames the posed idle mesh plus a margin. Before, hidden parts at full size shrank every sheet and dropped the ground plane, so older grades were partly limited by the camera.
- Wyvern rebuild: 6 on the fixed framing. Command Node: 7.5. Trebuchet: pot was under ground, now rests in the sling trough, 6.5. Re-check: pod 6 (its fall flame is under the preview ground; fine in game), Totem 7.
- All of these are on `art/3-hive-models` too (`44a42e7`); Muse hadn't started it.
- In game, `--creatures --look=40,74,22`: 6/10. The creatures are grounded and well scaled; the glow bleaches to cream (Muse A3 task 0).

## Next (Opus)
1. Review P, X, B and C as they land (Sonnet for code, Opus screenshots for visuals). For B, check the hold-to-fire spread number in the report.
2. When A3 lands: in-game shots of the hives, Totem, drop pod and Node; re-grade the wyvern with the fixed gallery camera.
3. Optional art: player structures (cannon, mortar, collector, relay) as animated glbs, using the same pattern as the Command Node.
