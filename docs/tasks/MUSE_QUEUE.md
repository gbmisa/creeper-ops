# Muse queue (2026-10-14, after Gregory paused the local agents)
Muse codes (headless Godot: parse, `--range-test`, smoke). Opus keeps everything that needs the local GPU or
ComfyUI: Vulkan screenshots, judging, Hunyuan models, graphics. Every branch below is pushed on GitHub.
Rules for every Muse task: `AGENTS.md`, `docs/MULTIPLAYER.md` "Rules for all code", the brief named. Checks: parse
clean, `godot --headless --path . res://scenes/firing_range.tscn -- --range-test` all PASS (integ: 513), main
`--smoke` 0 FAIL. Push the branch, report, stop. Opus reviews, judges visuals and merges.

## Wave 1 (parallel)
| Branch | Task | State | Notes |
|---|---|---|---|
| `feat/mp1` | MP-1 refactor (`docs/tasks/MP1_brief.md`) | not started | Touches everything: finish and rebase onto integ **last** in wave 1 |
| `feat/r5-cheats` | Tempest (Ctrl+Alt+P) + cheat menu (Ctrl+KP5) (`docs/tasks/RANGE5_cheats.md`) | WIP 6696585: Tempest code, model, FX, tests written but not run; cheat menu not started | Tempest: 0 kg, holster slot 2x1, previous sidearm restored on toggle off (tests) |
| `feat/r5-med` | Meds + build-up status effects (`RANGE5_brief.md` "Track MED") | not started | Use placeholder boxes for item models; Opus makes the Hunyuan models. Owns the stim |
| `feat/r5-viewfix` | View data for the 11 new guns from `art/gen/mounts.json`, sight-on-axis tests, flash test, `--weapon` holster-gun bug, rack labels (`RANGE5_judge.md` round 1) | not started | Numbers + tests only; Opus checks hands/ADS on the GPU after |

## Wave 2 (after `feat/mp1` merges: these build on the players list)
| Branch | Task | Notes |
|---|---|---|
| `feat/r5-util` | Utility items + grappling hook (`RANGE5_brief.md` "Track UTIL") | Skip `stim` (MED owns it); models exist |
| `feat/r5-expand` | Skirmish ~220 m: districts, spawns, 3 extracts, ~24 bots, navmesh, tests (`RANGE5_brief.md` "Track EXPAND", phase 1 only) | Graphics dressing of the districts is Opus's phase 2 |

## Opus (local)
- Finish `feat/r5-look3` (WIP 9fd79ef, map graphics fixes) and `feat/r5-artfix` (WIP 42d034e, model shading/textures).
- Hunyuan models for MED items; EXPAND district props + dressing after Muse's phase 1.
- Judge round 2, then up to round 3 (`RANGE5_judge.md`).
