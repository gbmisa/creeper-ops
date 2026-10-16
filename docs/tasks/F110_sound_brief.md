# Brief F110: indoor / outdoor sound (Gregory: "sound design has to come next")

Branch `fix/f110-sound` off `play/f98-f107`. Follow [AGENTS.md](../../AGENTS.md); commit on your branch only, never
merge or push. Feedback: `docs/playtests/feedback_2026-10-16.md` F110, F113.

## What Gregory hears
"There can be echoes as if you're inside when you're standing near a building, and shots can ring out from outside
when you're inside a building." He was shot from behind by a bot in his own room without hearing it coming.

## Today (confirm in code)
- `range/range_audio.gd`: `_zones` is a STATIC list of AABBs; `indoor(pos)` picks the reverb bus by the SOURCE
  position only. Only `range/kill_house.gd` adds a zone. Zones are never cleared, so after the range the kill-house
  box stays live in the Skirmish (open ground there echoes) and Skirmish buildings have no zones at all.
- F107 (just merged) added bot footsteps (`range/bot_steps.gd`) as 3D sounds.

## Build
1. Zones are per scene: clear them when a tactical scene loads (`range/tactical_scene.gd` build steps), then the
   range adds the kill house and the Skirmish adds one zone per building interior from its layout
   (`range/skirmish_layout.gd` / `skirmish_data.gd` / `skirmish_parts.gd`). Zone = the interior box (walls in, roof
   height), so standing next to a wall outside is NOT indoor.
2. Pick the sound treatment by BOTH listener and source space (`zone id`, -1 = outside):
   - same room (both in the same zone): room reverb bus (today's ROOM_BUS).
   - both outside: dry/outdoor, today's distance tail.
   - different spaces (one inside, the other outside or another building): muffled = a low-pass bus (cutoff about
     800-1200 Hz) and a few dB down; the listener's own room adds a light reverb when the listener is inside.
   Apply it to shots, tails, bot footsteps, impacts and any other 3D world sound that goes through `RangeAudio.play`.
   Local player sounds (own gun, own steps, reloads, UI) stay as they are, except that the player's own shots indoors
   keep using the room bus (as today).
3. Keep `shot()`'s loudness, delay and tail numbers otherwise unchanged; tunables (cutoff, dB) go in `SoundDefs` or
   `TacticalConfig`, not in logic.

## Must not change
Bot hearing (`bot_noise.gd`, `BotPerception`), AI, sample choice per gun, F106 reload click timing, F107 step
rates/ranges, anything visual. If something else seems needed, write it in `CHANGES.md` and say so.

## Done
Parse clean, Skirmish and range boot, `--range-test` once at the end (`tail -3`; the known fail "Scav 5 Search" (F88)
is pre-existing). Add one small logic test for the space rule (same room / both outside / split) and the zone reset
between scenes: this bug is invisible in code review. Files under ~250 lines. Report under 200 words: commits, every
behaviour change incl. side effects, test line.
