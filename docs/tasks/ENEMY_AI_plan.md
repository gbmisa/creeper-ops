# Enemy AI plan: cover, peeking, fire discipline (2026-10-16)

Gregory's ask: bots should choose cover, decide when to fire, crouch and lean, and feel like
"a multiplayer opponent who is not quite as good as the player". Today they run into the open, stop at a
fixed distance and shoot, and some Skirmish bots never fire.
Code base: play build `night/2026-10-15` (`../night`), `godot/scripts/range/bot_*.gd` + `scav_bot.gd`.

## What the code does today (read 2026-10-16)
- `BotBrain` is an 8-state FSM (Patrol/Investigate/Engage/TakeCover/Heal/Flank/Search/Suppress).
- **Engage** (`bot_engage.gd`) walks straight at `last_known` until inside `hold` metres (rifleman 30, pistol 12,
  shotgun 8), then stands still and fires. Cover only matters when reloading, hurt below 80 %, or outgunned.
- **Cover** (`BotShooting.find_cover`) = the nearest marker whose *crouched* eye (0.9 m) can't see the threat.
  Markers are 0.9 m off each box face (`skirmish_layout._cover`). But **bots never crouch**: eye stays at 1.6 m,
  hitboxes stay standing, so behind a 1.1 m barrier (most Skirmish cover is 1.1-1.5 m) their head is in the open.
  "TakeCover" then waits 1.5 s and walks back out into Engage.
- No cover types (half vs full), no lean, no peek, no cover reservation (two bots can pick the same spot).
- Flank = last_known + 10 m sideways, ignoring cover. Suppress = shots at last_known ± 1.2 m at ground level.

### Likely causes of "some bots never fire" (Phase 0 confirms with logs, don't trust these blind)
1. `fire()` needs a clear ray muzzle → **chest**, but sight only needs head *or* chest. Player crouched behind
   half cover: bot sees the head, can't shoot the chest, stands there forever (`bot_shooting.gd:22`).
2. Suppress aims at last_known ± jitter at chest/ground height, so behind cover the ray is always blocked.
3. Pistol `fire` 20 m / shotgun 25 m: they only fire once close, and they walk in a straight line to get there.
4. Out-of-combat top-up reloads whenever `mag < 10` (`scav_bot.gd:218`): the shotgun tube and M1911 hold fewer
   than 10, so they may be reloading in a loop and `gun.busy()` blocks firing.
5. Marksman: if its overwatch spot is unreachable on the navmesh it waits out `reloc_t` (10 s) silent.

## Target behaviour (how a decent-but-beatable human plays)
1. **Spot → react → get to cover.** On first contact: snap 1-3 shots only if the shot is good, otherwise sprint to
   the best nearby cover. Never stand in the open trading shots past ~2 s.
2. **Peek cycle from cover:** hidden (reload, wait 1-3 s) → peek (stand up over half cover, or lean out past the
   edge of full cover) → re-acquire with a short reaction delay → 1-3 bursts → hide again. Hide early when hit,
   mag low, or the player is aiming at them. Sometimes peek from the other side or the other edge.
3. **Fire discipline:** shoot only at a visible hit point (head or chest, whichever ray is clear, aim at that one).
   Hold fire when the player is fully hidden: pre-aim where they disappeared and wait. Suppress only at the cover
   *top edge* the player hid behind, and only to cover an ally who is moving.
4. **Cover choice:** a scored pick, not just "nearest hidden spot" (see Phase 2). Leave cover that gets flanked.
5. **Squad:** paired bots bound: one fires/suppresses while the other moves cover to cover; flankers move along
   cover, not the open.
6. **Beatable:** human-like reaction (0.35-0.7 s on re-peek), first shots of a burst less accurate, spread grows
   inside a burst, aim lags a moving target, and small mistakes (re-peeking the same spot, reloading while
   exposed now and then). All numbers in one skill table so they can be tuned without code changes.

## Phases (each: 1 agent, own worktree off `night/2026-10-15`, smoke + the new bot tests green, report and stop)
| # | What | Agent / model | Visual judge |
|---|---|---|---|
| P0 | **Diagnose no-fire.** Headless test: each kind faces a standing player at 15 m and 40 m in the open and behind a 1.1 m barrier; log the reason every `fire()` returned early (busy, cd, LOS, react, windup, out of `fire` range, gun refused). Fix only the confirmed bugs. Add the regression check "every kind fires within 3 s at a visible player". | stage-runner (Sonnet) | none |
| P1 | **Posture: crouch + lean.** `bot_posture.gd`: stance (stand/crouch) and lean (-1/0/1) with smooth blend. Moves eye, muzzle, and hitboxes (copy `tactical_player.gd:118` crouch scaling; add lean offset), plays `crouch_idle`/`crouch_walk`, rolls the spine bones for lean. Debug hook `--botpose=crouch|lean_l|lean_r`. | stage-runner (Sonnet) | Opus judges screenshots vs a reference |
| P2 | **Cover points + scoring.** `bot_cover.gd`: build points from the layout boxes with normal, height class (half ≤1.5 m: crouch-cover; full: lean-cover), usable lean edges, owner box. Score = hidden from threat at cover stance (+), can peek to threat (+), distance to me (−), preferred range per kind (±), reserved by ally (reject), angle to threat (flanked → reject), exposed path midpoint (−). Reservation table shared per session. Kill-house markers get the same data. | stage-runner (Sonnet) | Opus: overlay screenshot of points coloured by score |
| P3 | **Combat loop.** Replace Engage's "walk to `hold` and stand" with sub-states MoveToCover / Hidden / Peek / Reposition in a new `bot_combat.gd` (keep `BotBrain.next()` pure and testable). Fire discipline rules from Target 3. Per-kind roles from Gregory's ruling 3 (preferred range band, rush, overwatch, fall back). Brain transitions designed by Opus in the brief, coded by Sonnet. | stage-runner (Sonnet), brief by Opus | Opus: short screenshot sequence of a peek cycle |
| P4 | **Squad + flank along cover.** `bot_squad.gd`: pairs/boss group bound and suppress; flank picks a cover chain round the player's side. | stage-runner (Sonnet) | none |
| P5 | **Skill table + tuning.** `skill` block per row in `bot_defs.gd` (reaction, burst spread growth, tracking lag, mistake rates, peek times). Balance-tester runs headless duels and reports time-to-kill and hit rates; Gregory playtests the feel. | balance-tester (Haiku, numbers only) + Gregory | Gregory |

File rules: `scav_bot.gd` is already 306 lines, so new logic goes in the new files and P1 moves posture code out
of it; nothing grows past ~250.

## Must not change (every brief repeats this list)
Player movement, guns, ballistics, damage and armour, bot guns/armour/HP per kind, map geometry and loot,
extraction, the kill-house layout, keybinds. Perception cone/range and sound hearing stay as they are unless
Gregory says otherwise. Smoke and range tests are never weakened.

## Gregory's rulings (2026-10-16)
1. **All bots share one AI system:** kill house and Skirmish both get it. No per-map gating.
2. **One difficulty** to start ("a bit worse than you"); a setting may come later from the skill table.
3. **Each kind plays differently** (a role block per row in `bot_defs.gd`, read by the shared system):
   - **Marksman:** keeps range. Never comes down to the ground floor and never pushes; holds and relocates between
     overwatch spots, falls back if the player closes in.
   - **Breacher:** rushes. Uses cover only to get close, then pushes the last stretch with the shotgun.
   - **Rifleman (Scav), boss followers:** hold an appropriate distance for the AK, fight from cover with peeks, back
     off if the player gets too close, advance cover to cover if too far.
   - **Runner (pistol), Warlord (boss):** not ruled yet; the brief proposes values and Gregory confirms.
4. **Current accuracy and reaction numbers:** to be decided. Until he rules, P5 only tunes the *new* numbers
   (peek, burst, tracking lag, mistakes) and leaves aim error 9°→1.2° over 3 s and react 0.6-1.1 s as they are.

## F97 additions (Gregory 2026-10-16): "lose sight of me", no conga line, defend, decide, flank
- **P3 gets a Lost-contact path:** a bot that loses sight keeps a *last-known position* (decaying certainty), not
  a live fix on the player. It searches there (cautious, cover to cover), then gives up and returns to a defensive
  post. A sound gives a rough position (error grows with distance), never the exact spot.
- **No single-file convergence (P4):** a heard shot alerts a group, but the group gets one plan: some hold or take
  defensive cover, some approach on separate cover chains, one or two flank. Reserved paths/cover so two bots never
  take the same route; spacing rule so they can't stack in one line of fire.
- **Defensive posture (P2/P3):** "kill all enemies" mode means bots don't all have to come to you; per-kind role
  decides defend vs push (marksman/rifleman default to holding defensible cover when the player's position is unsure).
- Needs a ruling before P3/P4 briefs: how long a bot remembers you (proposal 20 s to search, then give up) and how
  many of a group may push vs hold (proposal: at most half push, at most 1 flanks).
