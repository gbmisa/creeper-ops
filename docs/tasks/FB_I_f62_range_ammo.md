# FB-I F62: infinite ammo in the range
Worktree `/home/gregory-milligan/AI projects/creeper fps td-worktrees/fb-i` (branch `fix/fb-i`). Follow AGENTS.md.
Gregory: "Make it so that the player has infinite ammo in their range so I can see the reload animations."

## Do
- Range map only (the firing range, not skirmish or any deployed map): the player's reloads never run dry. Each
  reload plays exactly as today (same action, timing, animation, sounds, mag swap) and the incoming mag/shells are
  full. Every action kind: detachable, tube (shell by shell), en-bloc, bolt/stripper, revolver.
- Rounds in the magazine still count down while firing (the mag must empty so he can reload).
- Smallest change, in the session/map layer (e.g. a flag the range map sets), not scattered checks. Tunable/flag in
  data, not hard-coded per gun.
- Range check (new or extended `range_test_*.gd`, <250 lines): in the range, every gun fires its mag dry and reloads
  3 times in a row, each reload full; in a skirmish session the same gun runs out of spares as today.

## Must not change
Skirmish/deployed ammo rules, bots, reload durations, fire logic, ADS (FB-H frozen), the kit carry from F55 (do not
let range-refilled spares leak into the carried kit beyond what the player actually had: say what you chose), any
def number. Never weaken a check.

## Verify (from godot/)
Parse clean; `godot --headless --path . res://scenes/firing_range.tscn -- --range-test` 0 FAIL; smoke 0 failures
(allow 600 s). Commit on fix/fb-i. Report under 200 words: how, the kit-leak choice, every behaviour change.
