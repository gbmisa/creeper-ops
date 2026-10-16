# FB-I F59: some guns will not fire (P90 named)
Worktree `/home/gregory-milligan/AI projects/creeper fps td-worktrees/fb-i` (branch `fix/fb-i`). Follow AGENTS.md.
Gregory: "Some of the guns will not fire, like the P90." He named only the P90; test every gun anyway.

## Do
1. Repro in the player path, not just `Gun.fire()`: the range scene's operative with the gun equipped, hip and ADS,
   semi and auto, through the same code a mouse click reaches (`scripts/tactical/`, `scripts/range/`, `scripts/fps/`).
   Known context: P90 is the only gun with a def default `fit` (`{"sight": "reddot"}`, weapon_defs.gd:27, applied in
   `Gun._init`). Earlier bug F44: the hip dot Control ate the fire click (mouse filter). Check both, but find the
   real cause; don't guess.
2. Fix the cause with the smallest change.
3. Add a range check (in a `scripts/range/range_test_*.gd` file, under ~250 lines each) that, for EVERY gun in
   `WeaponDefs.ORDER` (+ rack guns), equips it on the player as the game does, fires N rounds through the player fire
   path, and checks the magazine dropped by N (tube/en-bloc handled correctly).

## Must not change
ADS pose/alignment (FB-H is frozen), recoil, spread, damage, rpm, magazine sizes, sounds, viewmodels, any def number.
Never weaken or delete an existing check.

## Verify (from godot/)
- `godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"` prints nothing.
- Range test: see `scripts/range/range_test.gd` for the hook (`--range-test`); all OK, 0 FAIL.
- `godot --headless --path . -- --smoke --quit=0.1 | grep -c FAIL` is 0 (pre-existing `ship` failures: report, don't fix).
Commit on fix/fb-i. Report under 250 words: cause, fix, every gun that failed before, check counts, any behaviour change.
