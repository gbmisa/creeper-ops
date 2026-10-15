# Brief PT3-B (Muse): structures can be built on creeper (playtest 3, item 22)

**Branch:** `pt3/build-on-creeper` (from `integ/2026-10-09`). Touch placement/build files and a new smoke file only.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, `command/placement.gd`, `command/drag_build.gd`, `fps/operative_build.gd`, `command/command_select.gd` (move), `command/mover.gd` (land), `sim/creeper_gpu.gd` (header comment only: CPU copy of `depth`).

## Gregory's report
> "I am able to build on Creeper." (He first said anti-creeper; corrected: plain creeper.)

## What Opus found
`Placement._ground_rules` rejects `creeper.depth_at > MIN_DEPTH` (placement.gd ~55), but only when `not flying`. So the check exists; some path skips it or reads stale depth.

## Tasks
1. **Find the path.** Test every way a structure gets onto a cell, on a wet cell (`creeper.set_depth` 2.0): command click, drag-build chains/rows (`DragBuild`, including the `planned` list), Operative build (`OperativeBuild`, B and the build wheel), `@move` and `@land` for movable weapons and the Node, and the `flying` flag in each. Report which pass.
2. Also check: placing on a dry cell at the creeper's edge while it advances (is the ghost validated once and placed later?), and the GPU sim's CPU copy (`READBACK_TICKS`; a just-placed check could read a copy up to ~0.3 s old). You can't run the GPU sim; reason from the code and say what you found.
3. **Fix** every path so none places on wet cells. Landing a flying weapon on creeper is also refused (CW3).
4. **Smoke rule** (new `smoke_build_wet.gd`): every path above is refused on a wet cell and allowed on the same cell once dry.

## Must not change
The CW3 contact rule (an unfinished structure that creeper reaches later loses progress; that is correct and is not this bug). Anti-creeper cells stay buildable.

## Report
AGENTS.md format: the list of paths and which leaked.
