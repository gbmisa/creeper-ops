# Handoff: 2026-10-16 (Tactical Ops: new repo, split from creeper-ops today)

**What happened:** the on-foot game (Firing Range + Skirmish) was split out of `../creeper ops` (gbmisa/creeper-ops)
into this repo with `git filter-repo` (history kept, same paths). Base: creeper-ops `feat/fb-reload` @ d3b08d6.
Split commit on `feat/fb-reload` here. GitHub: **gbmisa/tactical-ops** (private, default branch feat/fb-reload).
Run: `godot --path godot` -> title (Range / Skirmish / Quit). Windows: Godot 4.7.2 via winget (`godot_console.exe`
in `%LOCALAPPDATA%/Microsoft/WinGet/Links/`), Blender 5.2.2 portable, Blender MCP registered (user scope).

## Split changes (the only behaviour changes)
- New `scenes/title.tscn` + `range/title_menu.gd` (main scene). Skirmish end "Level select" -> title (was main.tscn).
- Copied from the creeper game, now ours: `core/` audio_synth + sfx_render/voices, input_state/frame, keybinds;
  `ui/` ui_kit, ui_theme, build_card; `fps/muzzle_flash.gd`.
- `Keybinds.DEFAULTS` trimmed to the Tactical group (ids unchanged). No in-game Controls menu (was the creeper F10).
- `MuzzleFlash` has its own glow material (was `Effects.glow_mat`, same settings). `BuildCard` glyph fallback = id.
- `Bus` autoload dropped (unused here). Own `user://` dir ("Tactical Ops"): old keybinds.cfg rebinds don't carry over.
- CHANGES.md keeps M1-M9, P2-P11; creeper entries stayed in creeper-ops.

## Bot crouch + peek lean (0c0e864, merged into feat/fb-reload; branch feat/bot-pose)
- `range/bot_pose.gd` (BotPose): crouch in cover (TakeCover/Heal once there; Heal's 0.8 squash gone), crouch-walk
  in Investigate/Search/Flank (x0.55), crouch-fire standing still > 25 m; in TakeCover face the threat, lean out the
  side that sees it (0.3 s checks) and shoot (`BotEngage.peek`, react delay rolled on cover entry). Eye (sight + shot
  origin) and hitboxes follow the pose; BotBody plays crouch clips, rolls the spine, cants the gun 12 deg.
  Tunables `TacticalConfig.BOT_*`. Probe: leaned head bone +0.32 m vs hitbox +0.35 m; crouched head 1.10 vs 1.107.
- Range suite 1114 pass / 0 fail (38 SCRIPT ERRORs: the known `ReloadTimeline 'lock'` spam, fixed by the WIP below).
- **CHANGES P12** (hold cover longer while peeking; today cover lasts 1.5 s) waits for Gregory. Pushed.

## Not yet ported from creeper-ops (do this before more on-foot work there)
- Session B's **uncommitted reload WIP** (`reload_anims.gd`, `reload_rigs.gd`, `reload_timeline.gd`) is still in the
  creeper-ops main checkout. Once committed there: `git -C "../creeper ops" format-patch -1 <sha> --stdout | git am`.
- Any other on-foot commit made in creeper-ops after d3b08d6 ports the same way.

## Carried over (from creeper-ops HANDOFF, still true)
- FB-R reloads (brief `docs/tasks/FB_R_reload_anims.md`, log `FB_R_progress.md`, scores `docs/art/reload/SCORES.md`):
  judged >= 8: ak47, m1911, glock18, p90, mp5 plain/fast, scarh/sr25/saiga12/sks plain (+ scarh/sr25 fast).
  Below 8: the 4 rifles' empty reloads (5-6), saiga12/sks fast (7). WIP above fixes the empty tails, not yet judged.
- P9 arm loss built; P11 no fractures; **P10** (bots ignore leg damage) waits for Gregory.
- Known: kill-house navmesh doorway check can fail; barracks north door split by the inner wall.
- Range suite before split: 1113 pass / 1 fail (`a shot at spawn ... (F88)`, Scav 5 net move 0.6 m; left as is).

## Verified (this repo, split tree)
Parse clean; title / firing_range / skirmish boot headless, no script errors; `--range-test` 1113 pass / 1 fail
(the same pre-existing F88 check as before the split).
Not verified: Gregory's play of the title screen; windowed run.

## Next
1. Port the reload WIP once session B commits it (above), then continue FB-R (rifle empties, AXMC, M4A1, ...).
2. Gregory rules on CHANGES P10 and plays Skirmish (MAP-2, F90-F93).
