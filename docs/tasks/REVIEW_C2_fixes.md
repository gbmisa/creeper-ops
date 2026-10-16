# C2: fix the bugs the review found (review/muse-fb-abc)
Worktree `/home/gregory-milligan/AI projects/creeper fps td-worktrees/review-muse`. Follow AGENTS.md. Findings in
`docs/tasks/REVIEW_muse_progress.md`. One commit per item. Do NOT touch the CHANGES.md M1-M6 items (Gregory rules).

1. `range_bench.gd:67`: `var tube := ...` can't infer its type -> `var tube: bool = ...` (the bench and armour station
   don't compile today).
2. Range-test harness reports OK while a test script fails to compile: make a script that fails to load count as a
   FAIL with its path (stronger, never weaker). Prove it by temporarily breaking a file, then revert.
3. FB-A ragdoll: `bot_body.gd` `_tick_sleep` stops the simulation after 4 s and the corpse may snap back to its
   standing pose until freed at 8.5 s. Keep the corpse in its last ragdoll pose (freeze the bones / keep the final
   transforms) until it is freed. Check: bone poses at 4.5 s equal those at 3.9 s within 1 cm.
4. FB-B pause: mouse releases are lost while the pause menu is open (hold fire, Esc, release, resume -> keeps firing).
   Make held inputs see the release (e.g. `InputState` processes always, or held state clears on pause). Check it.
5. Behaviour-identical: move `bot_body.gd`'s hard-coded nudge 25.0, gun mass 3.0, toss 1.5 into `TacticalConfig`.

Must not change: anything else in FB-A/B/C or fix/fb-i (FB-H ADS, F55, F58, F62), any def number, any check's
strength. Verify: parse clean, `--range-test` (scene res://scenes/firing_range.tscn) 0 FAIL, smoke 0 failures.
Commit on review/muse-fb-abc, never push. Report under 200 words with every behaviour change.
