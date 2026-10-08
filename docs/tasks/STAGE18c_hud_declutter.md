# Stage 18c: HUD declutter

**Agent:** Grok Build. **Worktree:** `creeper fps td-worktrees/stage18c` · **Branch:** `stage/18c-hud-declutter`
Runs alongside 18b (FPS visuals) and 18d (drag-build). **Stay inside** `scripts/ui/*`, plus `core/keybinds.gd` (one new action) and `core/config.gd` (new HUD tunables). Don't touch `scripts/command/*` or `scripts/fps/*` logic.

## Why
In every screenshot the objectives panel covers the top-left quarter, the message log fills the bottom-left with 10 lines that never go away, and "COMMAND NODE LANDED" stays big in the middle of the screen. The user says the UI is cluttered.

## Do
1. **Objectives (`ui/objectives.gd`).** Default to a **compact** panel: one line per *open* objective (who tag + title, no hint text), completed ones hidden. A new rebindable action `objectives_toggle` (default **J**, add to `Keybinds.DEFAULTS`; read with `input.act`) expands it to today's full view with hints. When an objective completes or a new one appears, briefly expand that one line's hint for `Config.HUD_OBJ_FLASH` s. In first person the panel is compact always unless toggled.
2. **Message log.** Cap visible lines at `Config.HUD_LOG_LINES` (5). Each line fades out after `Config.HUD_LOG_LIFE` (8 s); warnings and errors last twice as long. Repeated identical messages collapse into "x3" (there's already "Relay destroyed x2"; keep that). The full history stays scrollable or viewable while the objectives panel is expanded, if that's easy; otherwise skip it and say so.
3. **Banner** ("COMMAND NODE LANDED" etc.): smaller (about 60% of the current font size), and it fades out after `Config.HUD_BANNER_LIFE` (3 s).
4. **Weapon label:** the FPS HUD says "[1] Pulse Rifle" while the Operative holds a crossbow. Change the **display label** to "Crossbow" (labels only; never rename ids or actions). Grep for other player-facing "Pulse Rifle" strings and change those too.
5. **Bottom hint line** (the tiny key-help row at the screen bottom, which overlaps the build menu): either show it only for the first 60 s of a mission, or move it so it doesn't overlap the build panel. Pick the simpler option and say which.
6. Keep `user://keybinds.cfg` untouched; tests set `Keybinds.persist = false`.

## Verify
- Parse check, full smoke (all PASS). Add `core/smoke_hud.gd` (register one line in `smoke_test.gd`): log caps at 5 lines, a line is gone after its life, the objectives toggle action exists and isn't bound to a key another action uses by default.
- Xvfb screenshots before/after: `--demo --sim=120 --shot=...` (command) and `--demo --sim=120 --surface --shot=...` (first person). Compare in the report.

## Report (AGENTS.md)
Files, new config values, new action id, screenshots, anything unsure. Set Stage 18c to ⚠ in MASTER_PLAN.md and add one Changelog line. Don't edit HANDOFF.md.
