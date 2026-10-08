# Stage 18d: Drag-build polish

**Agent:** Grok Build. **Worktree:** `creeper fps td-worktrees/stage18d` · **Branch:** `stage/18d-dragbuild-polish`
Runs alongside 18b and 18c. **Stay inside** `command/drag_build.gd`, `command/command_overlay.gd`, `command/command_input.gd`, the Operative build file (`fps/operative_build.gd` or wherever `OperativeBuild` lives), and a new `core/smoke_dragbuild.gd`. Don't touch shaders except the `plans` block in `terrain.gdshader` if you really need to.

## What exists (Opus, Stage 18a, on main)
`DragBuild` (`command/drag_build.gd`): with a structure tool armed, press, drag, release.
- **Collector / Relay** lay a *chain* from the press cell toward the cursor. Each piece goes as far along the line as its `link` allows from the previous one, backing off in 0.5-cell steps when the cell fails `Placement.ground_reason`. A short last hop is added only if it covers half a link.
- **Everything else** lays a *row* of footprints edge to edge along the drag.
- Preview: green/red discs (+ link lines for chains) via `CommandOverlay.show_plan` and the `plans` uniform in `terrain.gdshader`; HUD reason shows "Release to place N (M blocked)". `Placement.can_place(..., planned)` counts earlier planned relaying pieces as network so the preview matches what commit() places.
- Debug: `--drag=T,x0,z0,x1,z1` (needs `--sim=3` first so the Node is connected). Example: `--autostart --sim=3 --drag=collector,36,64,60,52 --look=45,60,60,1.0 --shot=/abs/a.png`.

## Do
1. **Smoke checks** in new `core/smoke_dragbuild.gd` (register one line in `smoke_test.gd`): on Level 1 after autostart + a few ticks, a relay chain from the Node toward open ground has consecutive spacing ≤ link and ≥ link − 1.5 on flat ground; a collector chain likewise with link 6; a cannon row has no overlapping footprints and pieces touch (Chebyshev distance = width); commit() places exactly the ok pieces and they are all connected or planned in the network afterwards; a chain that crosses a cliff backs off instead of placing on the wall; Esc / right-click during a drag places nothing.
2. **3D ghosts per piece.** `CommandOverlay` has one translucent ghost model. While a plan is shown, show a translucent ghost model at every planned piece (reuse `StructureMeshes.ghost(type, true)`, pool up to `DragBuild.MAX`, tint green/red like the single ghost). Hide them in `hide_plan()`.
3. **Collector field preview** for collector chains: draw the 7x7 field outline of each planned collector (the terrain shader already has `field_preview` for one; either extend to an array of up to 48 or skip and say why).
4. **Cost line:** the HUD reason becomes "Release to place N: X energy total" (sum of `def.cost` of ok pieces).
5. **Operative build mode (first person, B):** if `OperativeBuild` places with a click, add the same drag behaviour there, preview included. If that would need large changes to the FPS build code, skip it and describe what it would take.

## Verify
- Parse check, full smoke (all PASS, including the new file).
- Xvfb screenshots: collector chain, relay chain, cannon row, chain crossing a cliff (pick cells from `level01.gd`), each with ghosts visible.

## Report (AGENTS.md)
Files, screenshots, anything unsure or skipped. Set Stage 18d to ⚠ in MASTER_PLAN.md and add one Changelog line. Don't edit HANDOFF.md.
