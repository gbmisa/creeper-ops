# Stage 11a: Terp (Earth only)

**Agent:** Grok Build (Sonnet-class). **Worktree:** `creeper fps td-worktrees/stage11a` · **Branch:** `stage/11a-terp`
Spec: [STRONGHOLDS_DESIGN.md](../STRONGHOLDS_DESIGN.md) §6. Runs alongside Opus's **7b** (castle raids), Grok's **7c** (Level 1 terrain) and Grok's **10a** (Armoury).
**Stay out of:** `level/*` (all of it, including `level01.gd`), `fps/*`, `ui/info_panel.gd`, `ui/fps_hud.gd`, `world/terrain_edit.gd` (use it, don't change it). **Not in this stage:** Metal (needs Ore, Stage 9a), mortar damage by material, the "sealing the last route" warning tint. Leave a `# 11b:` comment where Metal will plug in.

## Why
Terraforming is the CW3 tool for walls, moats and ramps. `TerrainEdit` (Stage 5) already updates the creeper sim, chunks, flow field, unit paths and the Operative, so the Terp is a structure + a paint tool on top of it.

## Do
1. **Grid:** add `terp_target: PackedFloat32Array` (-1 = not painted) and `terp_mat: PackedByteArray` to `world/grid.gd`, sized with the other arrays. If `grid.gd` would pass ~230 lines, put helpers in a new static `world/terp_cells.gd` instead.
2. **Structure `terp`** (`command/structure_defs.gd` row, **Titans** tab MENU, `structure_meshes.gd` case): 25 packets, link 6, works on cells within 7 cells (`work_range` in the def), not movable, `"unlock": "terp"`. Tooltip with real numbers.
   - **Locked unless unlocked:** the build menu greys it out with "Not available on this level" unless the level dict's `"unlocks"` array contains `"terp"`. Level 1 doesn't (don't edit it); add a `--unlock=terp` debug hook so it can be tested. Read the unlock list through one helper, not by poking level files.
3. **Paint tool** (new `command/terp_paint.gd`, an `@terp` action in the Titans tab next to the Terp):
   - Drag a rectangle to paint a **target level** (whole levels 0..`MAX_LEVEL`). The target starts at the level under the drag's first cell; new actions `terp_up` / `terp_down` (e.g. PageUp/PageDown, Command group) change it, and the hover text shows it. A third action `terp_erase` held while dragging clears paint.
   - Can't paint Spire cells, castle stone, gates or Blight (say why, like placement does). Painting over a structure is allowed; the Terp just skips occupied cells.
   - The tool stays armed (CW3); right-click/Esc cancels, like every build tool.
   - Add actions to `Keybinds.DEFAULTS` only. Check `~/.local/share/godot/app_userdata/Creeper Ops/keybinds.cfg` first if it exists; never rename an existing action.
4. **Working** (new `command/terp.gd`, called from `structure_behaviors.gd`):
   - A built, connected Terp picks the nearest unfinished painted cell in range with no structure on it and moves it **one level** toward the target.
   - Each step needs `TERP_PACKETS` (4) packets: a new request kind `"terp"` in `PacketRequests.need/rate` and its arrival in `packets.gd` (add a packet colour). **Packets have no priority** (round robin, see CLAUDE.md), so the Terp just joins the rotation. Rate `Config.REQ_TERP`.
   - Once paid, the step takes `TERP_STEP_TIME` (3 s) with a visible beam/pulse, then `TerrainEdit.raise(world, [cell], ±1, Grid.Mat.EARTH)`. When a cell reaches its target, clear its paint.
   - Several Terps in range must not work the same cell at once.
   - Keep state saveable: per-Terp `{ cell, paid, timer }` as plain data.
5. **Shader:** painted cells get a hatched tint in `terrain.gdshader` (a small R8/RG texture like `claim_tex`, driven from `terp_paint.gd`/`CommandOverlay`): one colour for raise, another for lower. Ground visuals are shader tints, never quads.
6. Tunables in `config.gd` (`TERP_PACKETS`, `TERP_STEP_TIME`, `REQ_TERP`) or the def row.

## Checks: new `core/smoke_terp.gd`, registered with one line in `smoke_test.gd`
- Locked without the unlock, buildable with it.
- Painting sets targets; Spire/Blight/castle cells refuse paint; erase clears it.
- A built Terp requests `"terp"` packets, and after enough sim time a painted cell is one level higher, then reaches its target and loses its paint. Lowering works too. Material becomes `EARTH`.
- An occupied cell in range is skipped. Two Terps never step the same cell together.
- A raised ring around a pool holds creeper back (the creeper sim saw the change), and `RaiderField` re-plans (reuse the approach in `smoke_terrain.gd`).

## Verify
Parse check, full smoke (all PASS, report the count), `--demo --units --sim=900` (Node HP unchanged vs `main`). Xvfb screenshots with `--unlock=terp`: painted cells with the hatch tint, and a finished raised wall.

## Report (AGENTS.md)
Files, every new tunable and keybind, test output, screenshot paths, anything unsure. Set Stage 11 to "⚠ 11a" in MASTER_PLAN.md and add one Changelog line. Don't edit HANDOFF.md.
