# Handoff: 2026-10-16 evening (Linux, Opus; branch play/f98-f107, NOT pushed)

**Play build:** `play/f98-f107` (worktree `../creeper fps td-worktrees/f98-f107`) = `feat/fb-reload` d3b08d6
+ fix/kit-persist + the fixes below + F115-F119/F97 + Muse RANGE5. Range suite **OK 1350**, Skirmish boots with 0 script errors, parse clean.
Run: `cd "<repo>-worktrees/f98-f107/godot" && godot --path .` (or `res://scenes/skirmish.tscn`).
Feedback: `docs/playtests/feedback_2026-10-16.md` F98-F114. Rulings: CHANGES.md end (P10 B, P13 A+B).

## Start here (next session)
1. Playtester (Windows) on builds/2026-10-16/CreeperOps.zip (`tools/export_windows.sh <out>`; build id in log + reports).
   F121 crash with NO guns left (Windows only, Linux fine): switched Windows to Vulkan (guess). Need his
   %APPDATA%/Godot/app_userdata/Creeper Ops/logs/ newest log or an Esc > Report a bug folder.
2. Rulings waiting: CHANGES P14 (on-foot keybinds never saved), P15 (F127 M870 tube won't take a different 12ga grade).
3. Push play/f98-f107 + move main to it (repo PUBLIC; cousin got old main). Not yet answered.
4. SKS (F105b): he wants an earlier SKS with a detachable mag; ART-2 Hunyuan one was "SKS bad". Ask what he means.
5. Notes-branch merge (origin/feat/deactivate-pause-menu, docs only) was blocked by permission check: ask.

## 2026-10-16 night (Opus): playtester round F120-F127, range OK 1350
- Esc menu: typed mouse sensitivity, Display (windowed/borderless/fullscreen), HUD safe zone width/height %
  (SafeZone; ultra-wide), Report a bug (mic voice.wav + note + screenshot + log -> user://reports). All saved in
  user://settings.cfg. Sliders always get typed boxes (memory).
- HUD pinned to corners / safe zone; hip dot projected on the bullet line; guns start on auto; shotgun pump -10 dB;
  Skirmish spares that don't fit swap in an Assault rig (6x3); drop lag fixed (material caches, F124);
  bot_cover freed-instance errors fixed.

## 2026-10-16 evening (Opus): Muse RANGE5 merged, range OK 1348
- merge/r5-a: r5-med (18 meds, status effects; no fractures/splint) + r5-util (grapple, grenades, binocs). Keys:
  med_quick_1..4 = F5 F6 7 0, t_util_1/2 = I O. New meds don't set hands_busy.
- merge/r5-b: cheat menu Ctrl+KP5, Tempest hidden (Ctrl+Alt+P); second map `skirmish_large` (main menu button,
  --map=skirmish_large; own files, navmesh climb 0.5 on that map only). Current Skirmish unchanged.
- Not merged (superseded or paused WIP): fb-h-recoil, fb-g-reddots, range-inventory, r5-viewfix, mp1, r5-artfix,
  r5-look3, f46/f48/f50 WIP, 8 command-mode branches, claude/game-design-automation (docs).

## 2026-10-16 late (Opus): F115-F119 + Muse F97 merged, range OK 1201, Skirmish 0 script errors
- eba63b0 F119 red dot/holo glb shifted onto the reticle (AttachmentDefs glb_off; window measured by raycast).
- 5689da5 F116 range ammo bench refills only (no ammo cycling). bcd2dea F118 bot steps louder/further.
- be72f16 merged origin/feat/enemy-ai (F97 phases A-D: contact memory, cover reservation, squad, combat).
- 735e2b2 F115 RangeInfoPanel at the workbench (guns + wall materials); rack/wall labels removed; distance
  boards one billboarded sign per line, alternating sides.

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
