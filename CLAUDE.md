# CLAUDE.md: Creeper Ops (working title)

## Start of a session
Read `HANDOFF.md` first. Read [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) only if HANDOFF points you there.
When you finish a large task, overwrite `HANDOFF.md` (**under 60 lines**: state, how to run, open issues, next steps).

## Current focus (2026-10-16): the on-foot tactical game
Work is on the **Firing Range** and the **Skirmish** (Tarkov-style guns, inventory, recoil, ADS, bots, extraction).
Gregory playtests them and logs feedback as F-numbers in `docs/playtests/feedback_<date>.md`.
The command-mode tower defense (CW3 creeper, structures, castles) is **paused**. Its architecture, contracts and
tests are in [docs/COMMAND_MODE.md](docs/COMMAND_MODE.md). Read it only when a task touches that side.

## Change only what Gregory asked for (hard rule)
- Change only the behaviour he named. Everything else stays as it is: rules, numbers, timings, AI, UI, level data.
- Fixed means frozen. Don't touch an accepted fix again unless he asks.
- Refactors and performance work must not change what the player sees. If they would, stop and ask.
- If a fix needs a change he didn't name, don't build it. Write it in `CHANGES.md` (today / proposed / why / what
  else it touches), end your reply with "please review CHANGES.md", and wait for his ruling.
- Every report lists every behaviour change, side effects included.

## Testing: Gregory is the playtester (2026-10-16)
Gregory plays every build. Don't spend tokens proving things he can check in a minute of play.
- **Always:** the parse check, and boot the scene you changed. That's the default "done".
- **Don't** write new tests or screenshot-judge for things he can see in play (reload works, gun feels, sounds, UI).
- **Do** run the existing range suite (`--range-test`, in the background, read only the summary line) once before
  merging a branch that touches shared systems (inventory, guns, bots, session).
- Add a test only when a bug is hard to see in play or keeps coming back (like the ammo bugs, F66–F81).
- Don't read code "to prove nothing else changed". Keep diffs narrow; Gregory's playtest catches regressions.

## Which agent (cheapest that can do it)
Default: **do small things yourself** (a few files, under ~30 min of work). Spawning costs a full cold start.
| Work | Agent | Model |
|---|---|---|
| Find code, list files, answer "where is X" | `Explore` | haiku |
| Run tests/sims, git or worktree status, read logs | `auditor` / `balance-tester` | haiku |
| Data-only edits (numbers in a def table, level props, cover placement) | `feature-dev` | haiku |
| One scoped feature or bug fix that follows an existing pattern | `feature-dev` | sonnet |
| Phases of a written brief in `docs/tasks/` | `stage-runner` | sonnet |
| New level content | `level-builder` | sonnet |
| Cross-system design, judging screenshots or models, Blender art | Opus (you, or an Opus agent; say why) | opus |
- Never `general-purpose`. Haiku never judges images.
- Batch related F-items into one agent. At most 2 brief phases per agent; brief = exact files + what not to change
  + a report length cap.

## Roles
Opus orchestrates: writes briefs in `docs/tasks/`, reviews, and is the only one who merges. Delegated agents follow
[AGENTS.md](AGENTS.md): only their brief, commit only on their own branch, never merge.

## Branches
Gregory plays the branch named in HANDOFF ("Play build"). Branch new work from it in a worktree under
`../creeper fps td-worktrees/`; the main checkout may be in use by another session, so don't switch its branch.

## Code
- `godot/` is the game (Godot 4.7, GDScript). `src/` + `index.html` is a dead Three.js prototype; don't touch.
- Files under ~250 lines; split by responsibility. `class_name`, small classes, data tables, static helpers.
- Tunables go in a def table or config (`tactical/tactical_config.gd`, `*_defs.gd`), not in logic.
- Keys: add actions to `Keybinds.DEFAULTS`, read with `input.act(id)`. Never touch `user://keybinds.cfg`, never
  rename an action id. Tests set `Keybinds.persist = false`.
- After adding a `class_name` file: `godot --headless --path godot --import`.

## On-foot map (godot/scripts/)
| Folder | Owns |
|---|---|
| `range/` | Scenes: `tactical_scene.gd` (shared base: args, tests, Esc, build steps), `firing_range.gd` (`firing_range.tscn`), `skirmish_scene.gd` (`skirmish.tscn`); `range_maps.gd` (map ids → scenes, `RangeMaps.go`); player (`tactical_player.gd`, `player_weapons.gd`, `fp_body.gd`, `fp_arms.gd`), viewmodel/reload anims (`tactical_viewmodel.gd`, `reload_*.gd`), HUD/menus (`range_hud.gd`, `range_menu.gd`, `inventory_ui.gd`), bots (`bot_*.gd`, `scav_bot.gd`), Skirmish (`skirmish_game/data/layout/kit/end.gd`), look (`look_*.gd`), tests (`range_test_*.gd`) |
| `tactical/` | Rules with no scene: guns, mags, ammo, inventory, reloads (`inv_reload.gd`, `range_reload.gd`), recoil (`recoil_*.gd`), ballistics/penetration, body health, session (`range_session.gd`), defs tables |
| `fps/` | The Operative inside command mode (older FPS layer) |

## Run and check (from `godot/`)
```
godot --path . res://scenes/firing_range.tscn            # range   (tools/range.sh)
godot --path . res://scenes/skirmish.tscn                # skirmish
godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"      # parse: prints nothing
godot --headless --path . res://scenes/firing_range.tscn -- --range-test | tail -3   # range suite
```
