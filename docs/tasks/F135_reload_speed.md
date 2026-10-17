# F135: player reloads 30% faster on every gun + reload sounds in sync (Gregory ruled 2026-10-16: player only)
Branch fix/f135-reload, worktree ../f135. Base play/f98-f107.
## Today
Per-gun "reload"/"reload_fast" seconds in tactical/weapon_defs.gd (bots use them too). Player reload animations:
range/reload_timeline.gd (marks: mag_out, mag_hide, mag_show, mag_in, charged -> sound hooks), reload_anims/rigs,
tactical/inv_reload.gd, range_reload.gd, tube/en-bloc/bolt paths. Gregory: "The sounds are still really off. Timing-wise."
## Build
1. One tunable PLAYER_RELOAD_SPEED = 1/0.7 in TacticalConfig. Player reload time x0.7 for every action type (detachable
   normal + fast, tube per shell, en-bloc, bolt/stripper, revolver), and the animation plays in exactly that time.
   Bots' reload times unchanged.
2. Find why sounds are off: list per gun when each reload sound fires vs when the matching visual event happens
   (mag leaves well, mag seats, bolt/charging handle moves). Make every sound fire from the visual moment (timeline
   mark at the actual pose time), never from a separate fixed delay. Gun-state changes (mag count, chamber) must stay
   in step with the anim (ammo bugs F66-F81: don't regress; range_test_f81 and the reload tests must pass).
## Don't change
Reload anim poses/hand positions (F102 hand lineup), ADS, recoil, ammo rules, bot behaviour, sound samples/volumes.
## Done
Parse clean, range boots; range suite once (background, summary only; known FAIL f127). Commit on your branch.
Report under 250 words: per-gun table of what was off and the fix, every behaviour change.
