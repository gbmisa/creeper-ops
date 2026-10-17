# Handoff: 2026-10-16 night (Tactical Ops; Linux Opus session)

**Repo:** gbmisa/tactical-ops (private). On-foot game split from creeper-ops with filter-repo (same paths).
**Play build:** branch `port/play-f98-f135` (pushed) = tactical `feat/fb-reload` (split + bot crouch/peek + bot gun hold)
+ the whole creeper-ops play build `play/f98-f107` @ 0ecc4d0 (RANGE5 meds/grapple/grenades/binocs, cheat menu,
skirmish_large, kit-persist, F98-F135) + perf overlay. `feat/fb-reload` untouched (the Windows session's branch).
Linux worktree: `../creeper fps td-worktrees/tactical-port` (remote `tactical` in the creeper repo).
Run: `godot --path godot` -> title (Range / Skirmish / Skirmish (large) / Quit). Windows zip only when Gregory asks.
Suite: `--range-test` FAILED 1 (1357 passed): f127 "shells conserved" (M870 tube), pre-existing in creeper play build.

## START HERE next session: Skirmish 2 frame drops (Gregory: investigate + fix bot thinking)
- Overlay: F3 (action t_perf) or `-- --perf`. `[perf]` log line every 5 s, `[perf] SPIKE` per frame > 33 ms with
  the top PerfProbe costs. Probes: bots.think/pose/move/mesh (ScavBot._physics_process), weapons, player.*, utils,
  skirmish_large. Add `PerfProbe.add("name", t0)` around sub-steps to drill in.
- Headless 40 s, skirmish_large, 24 bots, ~5000 nodes: avg 7 ms, but spikes 35-112 ms; bots.think up to 74 ms in one
  frame, bots.move 5-16 ms; engine physics time 80-117 ms in those frames (physics catch-up steps make spikes cluster).
- Suspects: path queries / BotCover.pick / BotSquad cover scoring / perception raycasts several bots in one frame;
  move_and_slide + NavigationAgent. Fix = spread work across frames (stagger, cache, budgets), behaviour-identical
  (CLAUDE.md: perf must not change what the player sees; if it would, write CHANGES.md and ask).
- Measure: `timeout 40 godot --headless --path godot res://scenes/skirmish_large.tscn -- --perf | grep perf`.

## This session (all in the port)
- F128 I/O utility keys latched (missed above 60 fps). F129/F130 display mode applied once at the title, only if
  chosen in Esc (Skirmish 2 no longer changes the window); truck L deploys to skirmish_large with the kit.
- F131 bot steps louder (max_db cap). F132 Esc > HUD switches (HudSettings). F133 bot shots make noise, heard/hit
  positions fuzzed (BotTacticsDefs). F134 Comtac earmuffs, Headset slot (HearingMods; flashbang compressed too).
- F135 player reloads x0.7 (PLAYER_RELOAD_SPEED, bots unchanged); sounds on timeline marks; tube/en-bloc/bolt/revolver
  at RELOAD_SND_AT fractions (guesses); vector/m4a1/pkm still start/end. P14 ruled: on-foot keybinds saved.
- Port merges: cover fight with a live contact = F97 BotCombat, else BotEngage.peek; bot speed = leg loss x crouch
  speed; KeybindMenu (Esc > Controls) restored from creeper ui/; tactical's P12 (cover hold) renumbered **P16**.
- Feedback log F98-F135: creeper-ops `play/f98-f107` docs/playtests/feedback_2026-10-16.md (not in this repo).

## Open / waiting on Gregory
- CHANGES P15 (M870 tube won't take a different 12ga grade), P16 (bots hold cover longer while peeking).
- Reload sound fractions untested by ear. Bot crouch/gun-hold look not yet judged by him.
- Windows session's uncommitted reload WIP (reload_anims/rigs/timeline) in creeper-ops main checkout: will conflict
  with F102/F103/F105/F135 here; port with care.
- Known: kill-house navmesh doorway check can flake; reload_timeline.gd:196 'lock' SCRIPT ERROR spam in the suite.

## Carried over (still true)
- FB-R reload scores: docs/art/reload/SCORES.md. P9 arm loss built; P11 no fractures; P10 B + P13 A+B built.
