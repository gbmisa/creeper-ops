# Handoff: 2026-10-08 (session 15b: Muse merges, model grading, integration)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). **Opus long-horizon plan: [docs/tasks/ART3_OPUS_plan.md](docs/tasks/ART3_OPUS_plan.md).**
Repo: https://github.com/gbmisa/creeper-ops (private). **Muse** (Fount) codes from GitHub branches; **Opus** orchestrates, merges, and does visual work only. Prompts for the user: [muse1.md](muse1.md). Memory: `muse-does-coding` (never move a branch Muse has started; strip `godot/.godot/` at merge).

## Merged to main this session
- Playtest 1C hive sites (Muse). Opus sims: L1 undefended 341 s, L1 demo 734 s, L2 demo 400 s (no balance change).
- `art/3-gun-feel` (Muse): recoil defs, rifle bloom, yaw punch, sounds, crossbow reload. Sonnet review: no damage/rate/ammo change. Feel needs the user's play test.
- `fount/ui-pass` (Muse, unbriefed): HUD panels, buttons, HP bar. Opus screenshot: command HUD reads well.

## Branches
| Branch | Owner | Status |
|---|---|---|
| `art/3-integration` | Muse brief **A2** | Opus merged A + models here. **Smoke has 5 expected failures** (tests assume no .glb). Gallery camera broken. A2 fixes both + adds `--creatures=near` and the trebuchet hook. **Then Opus takes in-game shots and merges.** |
| `fix/playtest2-pressure` | Muse P | running (top priority gameplay fix) |
| `art/3-fx` | Muse X | running |
| `fix/muse-b-bugs` | Muse B | queued: FPS camera starts inside an orange mesh (`--demo --sim=60 --surface`), RecoilDefs.cam unused, weapon label, split hud.gd |
| `stage/21b-castles-detail` | Muse C | queued after P/A/X |
| `art/3-models` | Opus | 17 glbs (16 creatures/units + trebuchet). Merged into integration. |

## Model grading (Sonnet grader, 3 iterations done, as the user asked)
Average 6.1 → 6.8 → 7.4. At 8: brute, crawler, sentinel, soldier, spore_bat, warden; the rest at 7. Open notes in `docs/tasks/ART3M_progress.md`, to fix during the **in-game** pass (real scale + tier glow).

## Next (Opus)
1. When A2 lands: shots with `--gallery=anim` and `--creatures=near` (RTS + `--surface`), a grader subagent judges in-game readability (target 8), fix in Blender, tune the per-type scale table, merge `art/3-integration`.
2. Review P, X, B, C as they land (Sonnet reviewer for code, Opus screenshots for visuals).
3. New models: hive structures (pit, spitter tower, launcher, mortar, roost), Command Node / Totem / drop pod (plan §3).

## Open questions for the user
- The Art 3 feedback was cut off at "Holding down left...": how does it end?
