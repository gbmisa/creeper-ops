# Merge feat/fb-reload into the play build

Execute this. Do not re-survey the repos. Written 2026-10-17 from the Linux checkout.

## Result

One play branch, `play/merge-2026-10-17`, that has both:

- Linux play build `port/play-f98-f135` @ **959d7e6** (local; 3 commits ahead of `tactical/port/play-f98-f135` @ 368e1f2): F98–F145, gunsmith, loadout room, ragdoll split, Skirmish 2 perf, F146 bow **art only**, F147/F148 rigs.
- Windows `tactical/feat/fb-reload` @ **4900a08**: longer viewmodel arms, ArmTwist, M4A1 unbaked, MAP-3 Town, BOT-ANIM2, FB-R2 reloads. Suite there was 1234 pass / 0 fail.

Merge base is **17d1ef0** (`HANDOFF: session D pushed`). 30 commits on fb-reload are not in port. 27 commits on port are not in fb-reload.

## Do not

- Do not merge **creeper-ops** into tactical-ops. `git filter-repo` rewrote hashes. A rev-list of creeper `feat/fb-reload` against tactical shows ~600 commits; those are the pre-split history under old ids. `play/f98-f107` content is already in port as **7da3968**. Creeper `origin/feat/fb-reload` tip `d3b08d6` (2026-10-16 12:44 -0700) is the pre-split base, not new work.
- Do not re-merge `feat/bot-anims` (ee245ff), `feat/bot-pose` (0c0e864), or `perf/bot-think` (b3026e9). They are ancestors of port.
- Do not push over `feat/fb-reload`. It stays the Windows default branch until Gregory plays the merge.
- Do not build F146 bow gameplay in this merge. Art is already on the port tip.
- `feat/reload-groups2` (Windows hinge WIP: tube, en-bloc, revolver, PKM belt, worktree `tactical ops-worktrees/reload-groups`) is **not on GitHub**. If `gh api repos/gbmisa/tactical-ops/branches` still has only the five branches below, merge without it and say so in HANDOFF. Do not wait.

GitHub branches today: `feat/bot-anims`, `feat/bot-pose`, `feat/fb-reload`, `perf/bot-think`, `port/play-f98-f135`.

## Where

The tactical remote already lives on the creeper clone. Do not re-clone.

```
cd "/home/gregory-milligan/AI projects/creeper fps td"
git fetch tactical
git worktree add "../creeper fps td-worktrees/tac-merge" -b play/merge-2026-10-17 port/play-f98-f135
cd "../creeper fps td-worktrees/tac-merge"
git merge tactical/feat/fb-reload -m "Merge feat/fb-reload: Town, arms, BOT-ANIM2, FB-R2 into the play build"
```

Leave `creeper fps td-worktrees/tactical-port` on `port/play-f98-f135`. Do not switch that checkout. Godot binary: `~/.local/bin/godot` 4.7.

18 files changed on both sides since 17d1ef0. If git auto-merges one of them, still open it and apply the rule. Silent auto-merges of `bot_body.gd` and `reload_*.gd` are the likely breaks.

## Conflict rules

**HANDOFF.md.** Rewrite. Do not keep conflict markers or both session logs. Under 60 lines. Play build = `play/merge-2026-10-17`. Run line, what the suite printed, F146 gameplay still unstarted, hinge WIP absent or merged.

**CHANGES.md.** Keep the port's numbers. They collide with Windows:

| Id on port | Meaning | Windows used the same id for |
|---|---|---|
| P12 | Worn armor/helmet (ruled, via P13 A+B) | Cover hold |
| P13 | Player headshots, **ruled A+B** | Pistol ADS 0.25 → 0.45 m, unruled |
| P15 | M870 tube won't take another 12ga grade | — |
| P16 | Cover hold (Windows P12), unruled | — |

Add the pistol-ADS proposal as **P17**. Do not replace the ruled P13 text.

**range_maps.gd.** Union. `SCENES` keeps port's `skirmish_large` and `staging` and adds `town`. `is_skirmish` is true for `skirmish`, `skirmish_large`, and `town`. Keep `staging_target` and `go_staging`.

**title_menu.gd.** Keep `DisplaySettings.apply()` and the two `go_staging` buttons. Add Town as `RangeMaps.go_staging("town")` so the loadout room runs for every Skirmish map. Assumption, already decided: Town does not skip the room.

**look_materials.gd, range_layout.gd.** Use `RangeMaps.is_skirmish(...)`, not `pending == "skirmish"`.

**player_weapons.gd.** Keep the port diff (F135 `busy_t /= PLAYER_RELOAD_SPEED` and the rest). The Windows hunk is one line: `SkirmishKit.deploy` must run when `RangeMaps.is_skirmish(selected)`, so Town and skirmish_large get it too.

**range_menu.gd.** Keep the port's Esc menu (about +99 lines). Windows only changed `== "skirmish"` to `is_skirmish`. Use `is_skirmish`.

**weapon_defs.gd.** Keep the port's `SecretArms.ROWS` fallback in `of()`. On the `m4a1` row take Windows: delete `arms_pose`, set `grip_r` to `Vector3(0.041,-0.022,0.221)`.

**bot_body.gd.** Hard one. Keep the **port** file (233 lines). Ragdoll construction lives in `bot_ragdoll.gd` (`BotRagdoll`); do not bring back `_make_pbone` / `_build_ragdoll`. Windows (356 lines) changed `update` to `(delta, speed, raise, gun, crouch, lean, calm, head_at)` and `bot_mesh.gd` calls that. Copy that update-body behavior into the port file. Port's `bot_mesh.gd` still calls `body.update(delta, speed, pitch, gun, crouch, lean)` — use the Windows call. New Windows files come in clean: `arm_twist.gd`, `bot_head.gd`, `bot_idle.gd`, `bot_legs.gd`. Port already has `bot_hold.gd` / `bot_pose.gd` from before the split; if both sides edited them they were not in the 18-file overlap, so take the merge result only if the signatures still match `update`.

**skirmish_layout.gd.** Keep both. Windows added `_opt()` so Town can share the layout. Port added `RangeSpace.add_building`, the hotel extra lights (F101), and `light_energy` 2.2. Do not drop either.

**skirmish_game.gd.** Keep the port hunks: `cheats`, `session.bots = bots.duplicate()`, bot log gated on `HudSettings.on("bot_log")`, F134 `ItemDefs.CRATE_GEAR`. Keep any Windows hunk that still applies.

**skirmish_scene.gd.** Keep port's `session.mark_walk_in()`. Keep Windows additions.

**reload_mag.gd.** Windows owns the mag cut (`mag_parts`, whole-part cut). Re-apply port F103 if that path still exists: `well_plug` handling and `_add_plug` (dark box left in the well).

**reload_rigs.gd.** Windows owns the new rigs (M4A1, Vector, AXMC, Mosin). Re-apply onto those rows if still present: scarh `well_plug` (F103) and the sks `mag_box` / `pivot` from F105 (`AABB(Vector3(-0.02, -0.16, -0.025), Vector3(0.04, 0.11, 0.104))`, pivot y -0.05).

**reload_anims.gd.** Windows owns plans. Keep port `rig()` overlay that reads `art/gen/reload_hands.json` (F102, `_hand_edits`). If Windows replaced `rig()`, run the overlay on top of the Windows lookup.

**reload_timeline.gd.** Windows owns the timeline. Re-apply the port F135 line: `TacticalConfig.CHAMBER_TIME / TacticalConfig.PLAYER_RELOAD_SPEED` when empty. Keep the Windows `stop()` that sets `_next` so a cancelled reload does not fire marks it never reached. `PLAYER_RELOAD_SPEED` (`1.0/0.7`) is in port `tactical_config.gd`, which is not in the overlap.

**tactical_viewmodel.gd.** Keep both hunks (port's reload follow and Windows' arm placement).

## Comes from one side (no rule unless the merge conflicts)

Windows only: `scenes/town.tscn`, `town_*.gd`, `arm_twist.gd`, `bot_head.gd`, `bot_idle.gd`, `bot_legs.gd`, `reload_plans_more.gd`, `docs/tasks/MAP3_*`, `BOT_ANIM2*`, `FB_R2_reload_groups.md`, the arms glb.

Port only: `staging.tscn`, `skirmish_large`, `gunsmith_*.gd`, `bot_ragdoll.gd`, `gear_presets.gd`, `perf_*.gd`, F137–F148.

## Check

From `godot/` in the tac-merge worktree:

```
godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"
godot --path .    # title buttons: Firing Range, Skirmish, Skirmish (large), Skirmish: Town, Quit
```

Skirmish buttons open staging. Then one suite, in the background, summary line only:

```
godot --headless --path . res://scenes/firing_range.tscn -- --range-test
```

Known before this merge: port fails **f127** only (M870 tube, pre-existing, 1410 passed). Kill-house doorway check flakes; rerun once if that is the only new failure. Do not screenshot. Do not write new tests.

## Push

`git push -u tactical play/merge-2026-10-17`. Do not force-push. Do not update `feat/fb-reload`.

Rewrite HANDOFF on that branch. Tell Gregory the play path:

`godot --path "/home/gregory-milligan/AI projects/creeper fps td-worktrees/tac-merge/godot"`
