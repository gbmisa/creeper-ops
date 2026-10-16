# Brief: enemy squad tactics (F97) for Muse, branch `feat/enemy-ai`

**Base:** `feat/enemy-ai` = `origin/feat/fb-reload` d3b08d6 (the play build). Work and push only this branch.
Follow [AGENTS.md](../../AGENTS.md). Background plan: [ENEMY_AI_plan.md](ENEMY_AI_plan.md) (P0 is done; this brief
covers its P2-P4 plus Gregory's F97). Code: `godot/scripts/range/` (`scav_bot.gd`, `bot_*.gd`).

## What Gregory said (F97, 2026-10-16)
"There has to be a way that they can lose sight of me and not just hear me once, then all converge on me in a
line. If the goal is to kill all of the enemies, then it doesn't make sense for them to line up and wait for me
to shoot through an entire line of them. They can take up defensive positions and have to be able to make
decisions, including being able to flank."

## Why it happens today (read the code to confirm)
1. `BotPerception.hear()` sets `last_known` to the **exact** shot position for every bot within 150 m.
2. Engage without sight (`BotEngage.engage`) and Search just `_go(last_known)`: every bot takes the **same navmesh
   path** to the same point, so they arrive single file.
3. No group decision: each bot decides alone; `ally` is only a pair link, flank is a fixed 10 m side offset.
4. `find_cover` = nearest marker hidden from `last_known`; no reservation, so two bots can pick the same spot.

## Target behaviour
- **Contact memory, not a live fix.** A bot knows a *contact*: position, error radius, age, source
  (sight / hit / shot / ally). Seen: error 0. Lost sight: error grows with age (player's move speed). Heard shot:
  position offset randomly within an error that grows with distance (e.g. 15 % of distance, 2-20 m). Contact is
  **forgotten** after `CONTACT_FORGET` s with no new info: the bot goes to a defensive post (not straight back to
  patrol), stays alert, and only resumes patrol after a calm period.
- **One plan per squad.** A squad (pair, boss + followers, or bots spawned near each other) shares one contact and
  gets roles from a planner: **HOLD** (defend from good cover facing the contact), **ADVANCE** (cover to cover toward
  the contact), **FLANK** (wide arc, at least ~60° off the direct line, cover to cover). Caps: at most half the squad
  pushes (ADVANCE + FLANK), at most 1 FLANK. Re-plan on events (new contact, member down, contact lost) and every
  few seconds, not every frame.
- **Never a conga line.** Movers in a squad take different routes (reserve cover points and route corridors; FLANK
  goes the side away from the ADVANCE route). Keep spacing (~4 m) and never stand in an ally's line of fire or
  directly behind an ally relative to the contact (minimum angular separation seen from the contact).
- **Defend when unsure.** In "kill all enemies" Skirmish the bots don't all need to come to you. With an old or
  fuzzy contact, riflemen and marksmen prefer HOLD on defensible cover with a view of the approaches.
- **Fight from cover.** At cover: peek (step to a nearby sample point with LOS to the contact), fire a burst for
  1-3 s, hide 1.5-4 s, repeat; reposition after a few peeks, when flanked (contact angle vs the cover's hidden side
  too wide) or when the cover is no longer hidden. No crouch/lean animation exists yet (plan P1, separate work):
  peek is a sidestep out of cover; do not add posture or animation here.
- **Per-kind roles** (ENEMY_AI_plan.md ruling 3): Marksman always HOLD/overwatch, never pushes, falls back if the
  player closes. Breacher prefers ADVANCE and pushes the last stretch. Runner (pistol, `flank_eager`) prefers FLANK.
  Rifleman HOLD or ADVANCE by range band. Warlord: HOLD with followers screening; propose values in your report.

## Starting numbers (tunables, all in one new defs file, e.g. `bot_tactics_defs.gd`)
`CONTACT_FORGET` 20 s (search, then give up) · calm period before patrol 45 s · push cap ceil(n/2) · flank cap 1 ·
re-plan 3 s · spacing 4 m · min angular separation 12° · hearing error 15 % of distance, clamped 2-20 m ·
lost-sight error growth 3 m/s, cap 25 m. Gregory may retune; keep them out of logic.

## Phases (commit each with the parse check clean and the range suite run; push after each)
- **A. Contact memory + fuzzy hearing + forget/defend.** New `bot_contact.gd`; perception and brain use it
  (`last_known` becomes the contact position). Bots that lose you search, then give up and hold a post.
- **B. Cover scoring + reservation.** New `bot_cover.gd`: score markers (hidden from the contact +, can peek to it +,
  distance −, preferred range band per kind ±, reserved by ally reject, flanked angle reject, exposed path −).
  Reservation table per session (`RangeSession`, rule 1: no statics/autoloads for per-session state).
- **C. Squad planner.** New `bot_squad.gd` (build squads from `ally`/`leader` links + spawn proximity; one squad per
  isolated bot is fine). Roles, caps, separate routes, flank arcs, spacing, line-of-fire rule.
- **D. Combat loop at cover.** Peek / hide / reposition sub-states (new `bot_combat.gd`; keep `BotBrain.next()` a pure
  function testable from facts). Engage stops being "walk at `last_known` and stand at `hold`".

## Tests (headless, `range_test_*.gd`; these are hard to see in play, so they are wanted)
One heard shot with 4+ bots: no two movers share a route (path overlap below a threshold), at most one FLANK,
pushers ≤ half. A lost contact is forgotten after `CONTACT_FORGET` and the bot ends at a hold post. Heard-shot
contact is not the exact shot spot. Two bots never reserve the same cover. Movers keep spacing and stay out of
allies' lines of fire. Update existing checks that encode the old behaviour (e.g. `range_test_hearing`) and list
each one you changed and why. Known failing before you start: "a shot at spawn: every bot that has somewhere to go
moves within 4 s (F88): Scav 5 Search" (fails on the base too); fix it if your work touches it, else leave it.

## Must not change
Player movement, guns, ballistics, damage, armour, body health, bot guns/armour/HP/speed per kind, aim error
(9° → 1.2° over 3 s) and reaction times, view cone/range, which sounds are heard and how far, map geometry, cover
marker positions, loot, extraction, the kill-house layout, keybinds, UI. Navmesh, `BotMotion`, `BotUnstick` only if a
phase can't work without it (say so in the report). Both maps use the same system (no per-map gating).

## Rules
Files under ~250 lines (`scav_bot.gd` is 329: move logic out, don't grow it). `class_name` files, then
`godot --headless --path godot --import`. Parse check must print nothing. Range suite:
`godot --headless --path godot res://scenes/firing_range.tscn -- --range-test | tail -3`. Never merge.

## Report (under 300 words, in `docs/tasks/ENEMY_AI_F97_progress.md`, updated per phase)
Per phase: commit, what each bot kind now does in a fight, every behaviour change (side effects included), tests
added/changed, suite summary line, anything you had to touch from the Must-not-change list and why, open questions.
