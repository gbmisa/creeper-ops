# Handoff: 2026-10-16 evening (Linux, Opus; branch play/f98-f107, NOT pushed)

**Play build:** `play/f98-f107` (worktree `../creeper fps td-worktrees/f98-f107`) = `feat/fb-reload` d3b08d6
+ fix/kit-persist + everything below. Range suite **OK 1130**, Skirmish boots with 0 script errors, parse clean.
Run: `cd "<repo>-worktrees/f98-f107/godot" && godot --path .` (or `res://scenes/skirmish.tscn`).
Feedback: `docs/playtests/feedback_2026-10-16.md` F98-F113. Rulings: CHANGES.md P10 B, P13 A+B (end of file).

## Merged into play/f98-f107 (each on its own fix/ branch)
- F98 deploy kit: not reproducible with kit-persist; new deploy test with a custom kit (fix/f98-audio).
- F99 AK red dot/holo sat 17-21 mm low: ADS pose used eff_def (optic height counted twice). ADS test now checks
  the visible reticle (fix/f99-reddot).
- F100/F109 MAP-2 cover: +25 pieces, plus 3 L-shaped strongpoints (left/centre/right). F101 brighter Skirmish
  (ambient, fill, hotel ceiling lights) (fix/f100-map). Pathing checked only in the west by the tests.
- F106 reload seat click at the timeline's mag_in mark; F107 bot footsteps (`bot_steps.gd`, sound only).
- F110 indoor/outdoor sound: `range_space.gd`, zones per scene (reset on load), one per Skirmish building;
  split spaces = low-pass 1000 Hz, -5 dB (untuned, by ear next) (fix/f110-sound).
- F112 Controls button in the Esc menu -> existing KeybindMenu (fix/f112-rebind).
- P12 worn helmet/armor protect the player; P13 B player head dmg x0.5 from bots; P10 B blacked leg x0.6 for
  player and bots (fix/p13-damage).
- F103 SCAR-H `well_plug` (dark box closing the cut well); F105 SKS mag_box top lowered to the band, pivot moved
  (fix/f103-f105-mags).
- F102 tooling (fix/f102-hands): `art/reload_hands/reload_hands.blend` lines up the 9 reload guns with a hand
  marker per anchor (Y arrow = fingers, Z = palm). Gregory moves them, runs the `export_hands.py` text block ->
  `art/gen/reload_hands.json`, which `ReloadAnims.rig` reads over ReloadRigs (no code edit). Rebuild the file:
  `blender -b --python art/reload_hands/build_hands.py` (after `godot -s ../art/reload_hands/dump_anchors.gd`).
  The "mag" marker is posed with the mag seated; it moves with the mag in play.

## Open
- F104 P90 mag path through the receiver (bullpup plan, reload_rigs p90 offsets): not started.
- F105 part 2: add a real SKS (fixed 10-round, stripper clip) as a new gun; current gun keeps its model (needs a
  name: it is not an SKS). Model + en-bloc/stripper plan.
- F108 done via P12+P13; F111 via P10. F97 squad AI brief is Muse's (`feat/enemy-ai`).
- `reload_timeline.gd:196` SCRIPT ERROR spam ('lock' anchor, MP5) in the suite: pre-existing; the Windows
  session's uncommitted WIP had a `HANDS["lock"]` default. Not fixed here.
- Windows session WIP (rifle empty reloads) touches reload_anims/rigs/timeline: expect conflicts with F102/F103/F105.
- Main checkout HANDOFF.md is stale (old 10-08 file); this one is current.

## Next
1. Gregory plays play/f98-f107 (sound by ear, map positions, rebind page, helmets), fixes hands in Blender.
2. Push play/f98-f107 when he OKs; F104, real SKS.
