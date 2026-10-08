# Handoff: 2026-10-07 (session 12: visual pass 1, drag-build, Grok briefs out)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). Rules: [docs/CREEPER_SPEC.md](docs/CREEPER_SPEC.md). `docs/CW4_SPEC.md` (user's, untracked) still unread.
**Roles:** Opus orchestrates and merges; Grok follows [AGENTS.md](AGENTS.md). The user is low on Opus/weekly budget: **give Grok everything a lesser model can do**; Opus does review, merges, and design calls.

## This session (Opus, on main, commit 797bf37 + docs commit)
- User verdict on the merged build: graphics bad: ground, creeper, first person, UI clutter (all four).
- **Stage 18a:** `shaders/terrain_look.gdshaderinc` (grass patches/dirt/pebbles, near-camera blade detail, rock strata with ledge cracks and dark wall feet, grass lip, castle ashlar walls + flagstone tops, Blight cracks, bump via `bumped()`), `shaders/noise.gdshaderinc` (shared noise/voronoi/bump). Surface kind rides in vertex colour ALPHA (`TerrainMesh._colour`: 1 natural, .66 Blight, .33 stone, 0 spire). Creeper: deep navy, ripple + churn normals, gloss, low fresnel, contours kept.
- **DragBuild** (`command/drag_build.gd`, user request): with a structure tool, drag = Collector/Relay chain at max link along the line (backs off from bad cells) or a row of other structures edge to edge. Preview discs + link lines (`plans` uniform), "Release to place N". `Placement.can_place(..., planned)`. Debug `--drag=T,x0,z0,x1,z1` (after `--sim=3`).

## Out to Grok (parallel; briefs in docs/tasks/, table in docs/tasks/README.md)
| Brief | Worktree / branch |
|---|---|
| STAGE18b_fps_visuals (weapon models, sky, haze, SSAO) | `stage18b` / `stage/18b-fps-visuals` |
| STAGE18c_hud_declutter (compact objectives J, fading log, banner, "Crossbow") | `stage18c` / `stage/18c-hud-declutter` |
| STAGE18d_dragbuild_polish (ghosts, field outlines, cost, Operative, smoke) | `stage18d` / `stage/18d-dragbuild-polish` |
| SYNC_grok_branches (merge main into 7c, 10a, 11a; one session each) | `stage7c`, `stage10a`, `stage11a` |

## Verified
- Smoke **235/235 PASS** after 18a. Xvfb screenshots of ground (L1 top/FPS, L2 castle), creeper, and drag previews (collector chain, relay chain, cannon row with cliff cells red).

## NOT verified
- 18a on the real GPU (Forward+) or in motion: creeper glint strength, bump, near grass. Drag-build by a human (only debug hook + code path).
- Commit path of drag-build ran only through smoke-less code review (18d adds the tests).

## Known issues
- Creeper sparkles may be noisy in motion; tune `bumped(... 0.08)` and `SPECULAR` in creeper.gdshader.
- At frame 0 after `--autostart` the Node isn't connected yet, so a drag preview is all red (not an issue in play).

## Next (Opus, morning)
1. Ask the user how 18a looks on their GPU and how drag-build feels.
2. Review + merge SYNCed 7c, 10a, 11a, then 18b/18c/18d (expect small conflicts: 18b and 10a both touch `operative_weapons.gd`; 18c and 10a touch `fps_hud.gd`/`hud.gd`).
3. Later art: structures in motion, terrain far LOD, cave look.
