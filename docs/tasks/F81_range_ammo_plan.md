# F81 plan: the firing range must never run dry (2026-10-16)

Gregory: "I'm still running out of ammo in the firing range." Required behaviour, **range map only**: pressing reload
throws the current magazine away (it disappears) and a brand-new **full** magazine of the gun's ammo type appears in
the gun. Nothing comes from or goes to the inventory. Tube guns (shotgun) load a fresh shell per press as today;
en-bloc (Garand) gets a fresh full clip. Skirmish reloads stay exactly as they are.
Base: `night/2026-10-15` (`../night`, 0261b66). One branch `fix/f81-range-ammo`, worktree `../f81`.

## What exists (read 2026-10-16)
- `RangeMaps.INFINITE_AMMO = ["range"]`. `PlayerWeapons.setup` (`player_weapons.gd:56`) sets
  `reloader.infinite` once, from `session.maps.selected`.
- `InvReload.begin/finish/cancel` hand off to `RangeReload` when `infinite` (`tactical/range_reload.gd`): it builds a
  fresh full `Magazine` (`fill(g.ammo_pick)`), puts it in `g.spares`, `Gun.reload()` runs the timed reload, `Gun._finish_reload`
  swaps it in, then `RangeReload.finish` clears the old mag out of `spares`.
- On paper this is already the behaviour Gregory wants, so **the bug is in the live path, not the design.**
- `range_test_rangereload.gd` calls `InvReload` directly with a fresh `inv.make(id)` gun. It never goes through
  `PlayerWeapons`, the `infinite` flag, a kit loaded from `saved_kit`, input timing, or the range bench. That is why it
  passes while the game fails (same story as F66).

## Suspects (P1 confirms which; fix only what the repro shows)
1. **`infinite` is false in play:** setup runs before `maps.selected` is "range" (direct `firing_range.tscn`
   launch, or the Skirmish → range trip), or the flag is never re-set when the map changes in-session.
2. **`ammo_pick` is empty or not a valid id** for a gun restored from a kit (`InventoryIO.gun_from_dict`,
   `Gun.from_dict` defaults to `""`). The new mag is then filled with `""` rounds and fires as empty.
   The range bench's grade change (`range_bench.gd:84`) is the other path that changes it.
3. **A stale `staged` key** left on the gun item by a reload that never reached `finish` or `cancel` (switching or
   dropping a gun mid-reload, opening a menu on the finishing frame). After that, every R goes down the
   "second R during a reload" branch, `Gun.reload` refuses, and nothing happens.
4. **Double-tap R (fast reload) during the animation** (Gregory's F66 steps): check that `_fast` dropping the old mag
   still leaves the fresh one in the gun.
5. **Wrong player build:** only `night` has `RangeReload`. Confirm Gregory launches
   `godot --path "<repo>-worktrees/night/godot" res://scenes/firing_range.tscn`.

## Phases
| # | What | Agent |
|---|---|---|
| P1 | **End-to-end repro through the real path.** Headless test that loads the range scene the way the game does (fresh launch, and after a Skirmish → range trip), equips every rack gun through `PlayerWeapons`, and drives real reload presses (`start_reload` as `range_shot.gd:88` does). Each gun, 10 cycles of: fire dry or fire part of the mag, R; plus double-tap R mid-animation, switch weapon mid-reload, menu open on the finishing frame, bench ammo change. Log `infinite`, `ammo_pick`, `staged`, mag count after each cycle. Report which suspect(s) fire. No fixes. | stage-runner (Sonnet), report under 200 words |
| P2 | **Fix.** Make the range rule hold however the gun got into the player's hands: read "is this the range?" at reload time (not once at setup), never fill with an empty or invalid ammo id (fall back to the gun's first grade), and clear any stale `staged` on draw/switch on the range. Keep the "mag disappears, fresh full mag appears" rule in `RangeReload` only. Turn the P1 repro into a permanent range test. | stage-runner (Sonnet) |
| P3 | Orchestrator (Opus) reviews the diff against the must-not-change list, merges into `night`, runs range + smoke, and Gregory plays. | Opus |

## Must not change
Skirmish reload rules and inventory, reload timings and animations, the reload sounds, recoil, ballistics, ammo
types and loadout choice, the range bench, the F66 "R on the finishing frame" fix, keybinds. No smoke or range
check is weakened or removed.

## Need from Gregory if P1 can't reproduce it
Which gun(s), how you started the game (the exact command or shortcut), whether you came from the Skirmish, and what
you see when it fails: R does nothing, a "No magazine" message, or the reload plays and the gun is still empty.

## Gregory's answers (2026-10-16)
**All** guns run dry. Launched fresh with the `night` command above (`res://scenes/firing_range.tscn`). He did **not**
come from the Skirmish. So suspects 1 (Skirmish trip) and 5 (wrong build) are unlikely; focus on 2-4 and anything
else in the live path. Fresh-launch kit comes from `StarterLoadout.fill(inv)` (`player_weapons.gd:58`).
Progress log: `docs/tasks/F81_progress.md` (create it).
