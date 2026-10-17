# Handoff: 2026-10-17 (Tactical Ops; Linux Opus session)

**Repo:** gbmisa/tactical-ops (private). **Play build: `play/merge-2026-10-17`** (pushed) = Linux `port/play-f98-f135`
(F98-F148, loadout room, gunsmith, ragdoll, Skirmish 2 perf, bows) + Windows `feat/fb-reload` @ 45e0989 (longer arms,
ArmTwist, M4A1 unbaked, MAP-3 Town, BOT-ANIM2, FB-R2 + FB-R2b hinged reloads). Merge plan: docs/tasks/MERGE_play_and_fb_reload.md.
Worktree: `../creeper fps td-worktrees/tac-merge`. `feat/fb-reload` and `port/play-f98-f135` left as they were.
Run: `godot --path "/home/gregory-milligan/AI projects/creeper fps td-worktrees/tac-merge/godot"` -> title (Firing Range /
Skirmish / Skirmish (large) / Skirmish: Town / Quit). Every Skirmish button opens the loadout room first; its deploy
board (L) now cycles Skirmish / Skirmish (large) / Town. Windows zip only when Gregory asks.
Suite: `--range-test` FAILED 2 (1685 passed): f127 (pre-existing) + NEW after the merge: "ragdoll stays connected"
(impulse 0) upperarm_l 0.051 m vs 0.05 tolerance (likely Windows bot arm poses x port BotRagdoll; test not loosened).

## Merge rulings applied (from the plan)
- CHANGES: port numbers kept (P12 armor, P13 headshots ruled A+B, P15 tube, P16 cover hold); Windows' pistol-ADS
  proposal is **P17** (unruled). RangeMaps: SKIRMISH_MAPS = skirmish, skirmish_large, town. Kit deploy, look and Esc menu
  use is_skirmish. Reload: Windows plans/timeline/hinges + port F102 hand overlay, F103 plug, F105 SKS cut, F135 speed.
- Viewmodel marks: port's mag_out/charged/mag_in sounds + Windows' "bolt" mark (boltbox reloads).
- bot_body auto-merged cleanly: port's BotRagdoll + Windows' update(delta, speed, raise, gun, crouch, lean, calm, head_at).

## 2026-10-17 new (Gregory's requests)
- **F146 bows** (brief docs/tasks/F146_bows.md): compound bow (hold LMB to draw 0.8 s, release; below 25 % lets down;
  stamina drain + shake after 4 s at full draw) and crossbow (one bolt, R = cock + load 3.5 s). Arrows/bolts are loose
  stacks (field point / broadhead), stick in the world and can be picked up (F); arrows in a Scav drop when it dies.
  Opus scratch models (art/guns_src/scratch_parts.py + scratch_compound_bow/crossbow.py): bow 3-pin sight + peep on
  the string, crossbow ghost ring + post; irons hide under an optic (red dot, holo, ACOG only). BowRig moves the string
  (draw / cock blend shapes), the nocked arrow and the right hand. Rack row 7, crate, ammo bench. Bots don't use them.
  Open: R after every shot to nock (no auto-nock; ask Gregory). Draw pose never judged on screen. Sounds procedural.
- **F147** gunsmith Magazines row: full mags of the selected gun into the rig, else bags, never the floor.
- **F148** rigs: Plate carrier (8x3), Heavy assault (8x4); crate + loadout stash. Inventory ground panel moves right for 8-wide rigs.

## Open / waiting on Gregory
- CHANGES P15 (M870 tube grade), P16 (cover hold), P17 (pistol ADS 0.25 -> 0.45 m). F138 Skirmish 2 redesign questions.
- Not played: the merge as a whole, Town via the loadout room, bows, gunsmith mags, bot crouch/gun-hold/BOT-ANIM2 look.
- Known: f127 "shells conserved" (M870 tube) fails; kill-house navmesh doorway check flakes; reload_timeline 'lock'
  SCRIPT ERROR spam in the suite; pause-menu "Deploy to Skirmish" in the room skips the room logic.

## Carried over
- FB-R reload scores: docs/art/reload/SCORES.md (FB-R2b plans score 7). P9 arm loss built; P11 no fractures; P10 B + P13 A+B built.
- Measure perf with `-- --perf --god` (to a file). Feedback log F98-F148: docs/playtests/feedback_2026-10-16.md.
