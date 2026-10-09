# Brief PT3-C (Muse): pause button in command mode (playtest 3, item 24)

**Branch:** `pt3/pause-button` (from `integ/2026-10-09`, which now includes the `ui/overhaul` HUD). Touch `ui/top_bar.gd`, `ui/hud.gd` if needed, `core/game_flow.gd` (pause only) and a smoke file.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, `ui/top_bar.gd`, `ui/ui_kit.gd` (`UiKit` palette/helpers), `ui/ui_theme.gd`, `core/game_flow.gd` lines 45-70, `core/keybinds.gd` (`pause` action).

## Gregory's report
> "There's no pause button when in command mode."

Pause exists only as the `pause` key (Space) in `game_flow.gd`.

## Tasks
1. A clickable **pause/resume button** on the top bar next to the speed readout (mission clock area), in the new military style: icon + `Keybinds.short("pause")`. Clicking it does exactly what the key does (one shared function in `GameFlow`).
2. The game speed buttons belong with it: `<<` / `>>` buttons calling `cycle_speed(-1/1)` if they don't exist yet.
3. While paused: a clear **PAUSED** banner (amber, top centre, under the bar) that doesn't block clicks on the map; planning and building still work while paused, as now.
4. Hidden in FPS mode (Esc already pauses there).
5. Smoke rule: pressing the button toggles `g.paused`, and the banner shows only while paused.

## Must not change
Keybinds (never rename `pause`), the briefing pause (`paused` starts true until dismissed).

## Report
AGENTS.md format. Opus takes the screenshot.
