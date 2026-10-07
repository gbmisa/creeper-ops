# Task: split command_mode.gd (pure refactor)

`godot/scripts/command/command_mode.gd` is at 247 lines, the size limit. Split it by responsibility into smaller files (for example, input and tool handling vs. selection and info vs. drawing), each well under 250 lines. **No behaviour change.**

- Keep `CommandMode` as the entry class that other code calls. Don't change its public functions or signals, so callers (`game.gd`, `game_flow.gd`, `hud.gd`, `debug.gd`) keep working untouched.
- Prefer static helper classes or small owned objects, matching the existing idiom (see how `structure_manager.gd` delegates to `structure_upkeep.gd`).
- Update the `command/` row in CLAUDE.md's architecture map to list the new files.
- Don't touch any other system's files.

**Verify:** parse check; smoke tests all PASS; `--demo --sim=120 --select=cannon --shot=...` screenshot under Xvfb (CLAUDE.md Testing) looks the same as before the split.

No MASTER_PLAN stage for this. Add one Changelog line instead.
