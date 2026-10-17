# F133: bots shouldn't know which shots are the player's (Gregory ruled 2026-10-16: "bot shots make noise too")
Branch fix/f133-hearing, worktree ../f133. Base play/f98-f107.
## Today
- Only the player's shots emit noise (`player_weapons.gd:215`, session.noise.emit(... "shot", player)); bot shots emit nothing.
- `ScavBot._on_noise` ignores `src is ScavBot`, hears at the exact shot position (percept.hear) and snaps to face it.
- `ScavBot.on_hit` alerts to `session.nearest_player(...)` = the player's exact position.
## Build
1. Bot gunshots emit "shot" noise at the bot's position (same SHOT_R * gun noise rule as the player). Bots ignore
   shots from themselves and from squad-mates they currently know about (ally / same squad), but hear other bots'.
2. Heard shot position gets an error that grows with distance (e.g. ~5% of distance, min 1 m, cap 15 m) and is larger
   while several shots are heard at once (a few seconds window). Bots investigate/turn to that rough spot, not the shooter.
   Tunables in a def table / TacticalConfig, not logic.
3. `on_hit`: alert toward the bullet's origin direction with the same error, not nearest_player().
## Don't change
Footstep hearing, F87 reaction timings (x0.35 / +1.5 s), vision, cover, squad logic, bot accuracy, any player code
besides nothing. No new HUD. Keep files under ~250 lines.
## Done
Parse clean, Skirmish boots with no new SCRIPT ERROR, existing range_test_hearing still passes (update it only if a
check asserted the exact-position behaviour; say so). Run the range suite once (background, summary line only;
1 known pre-existing FAIL: f127 shells conserved). Commit on your branch. Report under 200 words: every behaviour change.
