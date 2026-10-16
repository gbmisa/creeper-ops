# Handoff: 2026-10-16 evening (Linux, Opus; branch play/f98-f107, NOT pushed)

**Play build:** `play/f98-f107` (worktree `../creeper fps td-worktrees/f98-f107`) = `feat/fb-reload` d3b08d6
+ fix/kit-persist + the fixes below. Range suite **OK 1130**, Skirmish boots with 0 script errors, parse clean.
Run: `cd "<repo>-worktrees/f98-f107/godot" && godot --path .` (or `res://scenes/skirmish.tscn`).
Feedback: `docs/playtests/feedback_2026-10-16.md` F98-F114. Rulings: CHANGES.md end (P10 B, P13 A+B).

## Start here (next session): ask Gregory, then work the list
1. Did he play play/f98-f107? Log new notes as F115+ in the feedback file (same table).
2. Push play/f98-f107 to GitHub? (asked, not answered yet)
3. F97 squad AI + F114 reaction rule: Muse (brief `feat/enemy-ai` docs/tasks/ENEMY_AI_F97_brief.md, commit
   2bdae05, NOT pushed) or a Claude agent? Push the brief either way.
4. F110 sound: by ear, are the muffle numbers right (1000 Hz low-pass, -5 dB, reverb wet 0.15 in `SoundDefs`)?
5. F102: has he edited `art/reload_hands/reload_hands.blend` and exported? If so, render reload strips and judge.
6. F105 part 2: name for the current "SKS" model, and go-ahead for a real SKS (fixed 10-rd, stripper clip).
7. Then build: F104 P90 mag path (bullpup plan, `reload_rigs.gd` p90 offsets go through the receiver).

## Changelog for this build (what Gregory should notice)
- Kit you set up in the range carries into Skirmish (kit-persist; F98 not reproducible on top of it, test added).
- Reusable IFAK (300 HP pool), helmet slot, Skirmish Restart reloads your walk-in kit (F94-F96, kit-persist).
- Red dot / holo now sit on the bullet's line: you hit what the dot covers (F99; was 17-21 mm low).
- Skirmish map: +25 cover pieces, 3 strongpoints left/centre/right with fallback cover (F100, F109).
- Skirmish brighter in shadows and interiors, hotel most (F101).
- Reload: seat click when the mag seats (F106); SCAR-H well no longer see-through (F103); SKS mag no longer
  carries well parts (F105).
- Bots make footsteps: walk 8 m, run 20 m (F107).
- Sound by space: each building its own zone; inside<->outside or building<->building is muffled; no echo
  outside next to walls; range kill-house zone no longer leaks into Skirmish (F110).
- Esc menu > Controls: rebind every key, Reset to defaults; a taken key moves (F112).
- Worn helmet/armor protect you like bots (P12); bots' head hits on you x0.5 (P13); a blacked leg slows you and
  bots to x0.6 (P10). Skirmish is easier with gear on.
- Tooling: reload hand lineup in Blender (F102) -> `art/gen/reload_hands.json` overrides ReloadRigs at runtime.
  Rebuild: `godot --headless --path godot -s ../art/reload_hands/dump_anchors.gd`, then
  `blender -b --python art/reload_hands/build_hands.py`. "mag" marker is posed with the mag seated.

## Branches merged into play/f98-f107
fix/kit-persist, fix/f98-audio, fix/f99-reddot, fix/f100-map, fix/f110-sound, fix/f102-hands, fix/f112-rebind,
fix/p13-damage, fix/f103-f105-mags (worktrees of the same names under ../). Briefs: docs/tasks/F98_F107_brief.md,
F110_sound_brief.md.

## Known issues
- `reload_timeline.gd:196` SCRIPT ERROR spam ('lock' anchor, MP5 empty) in the suite: pre-existing. The Windows
  session's uncommitted WIP had a `HANDS["lock"]` default; that WIP (rifle empty reloads) touches
  reload_anims/rigs/timeline and will conflict with F102/F103/F105.
- MAP-2 pathing for the new centre/right strongpoints only checked by overlap script, not by bots.
- P12: no armor durability readout on the body HUD yet.
- Main checkout HANDOFF.md is stale; this file (on play/f98-f107) is current.
