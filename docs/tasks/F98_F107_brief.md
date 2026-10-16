# Brief: playtest F98-F107 (2026-10-16)

Base: `play/f98-f107` (= `fix/kit-persist` c60f50c = play build feat/fb-reload + reusable IFAK, helmet slot,
Skirmish Restart kit). Feedback text: `docs/playtests/feedback_2026-10-16.md` rows F98-F107. Follow
[AGENTS.md](../../AGENTS.md): only your items, commit on your own branch, never merge, never push.

**Must not change (all agents):** bot difficulty/AI tuning (Gregory: "difficulty is feeling really good"), death
screen, guns' recoil/ADS numbers, reload animations, inventory rules, anything not named in your items.
If a fix needs a change not named here, don't build it: write it in `CHANGES.md` and say so in your report.
Done = parse clean (`godot --headless --path godot --import 2>&1 | grep -A1 "SCRIPT ERROR"` prints nothing),
the changed scene boots, and `--range-test` summary line OK (run once at the end, read only `tail -3`).
Don't write tests for things Gregory sees in play. Files under ~250 lines.

## Agent A (branch `fix/f98-audio`): F98, F106, F107
- **F98** Range -> walk into the deploy van -> Skirmish gives the DEFAULT kit (AK-47 + 3 mags, 2 M1911 mags,
  M1911A1, chest rig, no armor) every time; the guns/armor/items set up in the range are gone. Since F82 Skirmish
  is its own scene (`range/skirmish_scene.gd`, `range/range_maps.gd`, `range/range_truck.gd`,
  `tactical/range_session.gd`, `range/skirmish_kit.gd`). `skirmish_scene.gd` calls `session.mark_walk_in()`:
  find where the range kit is lost on the scene change and carry it. `range_test_deploy.gd` exists: extend it so
  a non-default kit (other gun + armor) survives deploy (this bug keeps coming back: F48, F96). Keep F90 (spare
  mags top-up) and F96 (Restart reloads walk-in kit).
- **F106** Every reload: the mag-seat click plays when the reload ends, not when the mag seats. Find where the
  insert sound is triggered (`range/reload_timeline.gd`, `reload_anims.gd`, `range_audio.gd`, `sound_defs.gd`,
  `tactical/inv_reload.gd`) and fire it at the timeline's seat moment. Don't change animation timing or curves.
- **F107** Bots make no footsteps, so they sneak up. Add 3D footstep sounds for bots (`scav_bot.gd` / a new
  `bot_steps.gd`), rate by speed, quieter crouched, silent when still; reuse the player's step sound if one exists.
  Audible range like the player's (`bot_noise.gd`: sprint 20 m, walk 8 m). Bots' hearing logic is unchanged.

## Agent B (branch `fix/f100-map`): F100, F101 (Skirmish MAP-2 only: `range/skirmish_layout.gd`,
`skirmish_parts.gd`, `skirmish_data.gd`, `look_env.gd`; layout notes `docs/tasks/SKIRMISH_MAP2.md`)
- **F100** Not enough cover. Add cover at the player spawn and along every lane, most of all on the route from
  spawn to the first building on the right, where Gregory gets killed. Use the existing cover kinds (concrete
  blocks, sandbags, containers, crates). Don't move buildings, spawns, bot spawns or extract. Bots must still path
  (rebake navmesh if the layout bakes it; check no lane gets sealed).
- **F101** "Too dark in the dark areas, I can't see the enemies." Raise ambient/fill light in the Skirmish so
  shadowed areas and building interiors are readable; keep the outdoor look. Skirmish only, not the range.
  Render 3-4 screenshots (xvfb-run, opengl3) of the darkest spots, before and after, to
  `docs/art/skirmish/f101_*.png`; Opus judges them, you don't.

Report (under 200 words): commits, every behaviour change incl. side effects, test summary line.
