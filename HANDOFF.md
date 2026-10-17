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

## Bot gun hold (ee245ff on feat/bot-anims, merged into feat/fb-reload, pushed; Gregory: arms behind them)
- Cause: BotBody placed the gun with the viewmodel's `butt` (eye-to-butt at ADS), so stocks sat 0.3 m behind the
  shoulder (P90 inside the Warlord, pistols at the shoulder), and the elbow pole was world-fixed (swung back by heading).
- Now `range/bot_hold.gd` (BotHold): butt in the right shoulder pocket, torso bladed 0.55 rad (head turned back), head
  drops onto the stock when engaged; pistols out in front of the chest; elbow poles in the bot's frame; left hand slides
  back along the gun if the handguard is out of reach (sniper, shotgun). `FpArms.solve` takes an optional pole.
- Clips, speeds, hitboxes, eye/shot origin unchanged. Side effect: muzzle flash / shot-sound position moves with the gun.
- Renders judged (scratchpad): every kind, idle/jog/sprint, lowered/engaged, crouch+lean; both hands on target 0 mm.
- Parse clean, skirmish boots; range suite 1114 pass / 0 fail (a first run flaked: navmesh doorway + bleed-out fall;
  30-bot probe: every bleed-out falls, old and new). Not verified: Gregory's play. Next: his verdict on the look.

## Not yet ported from creeper-ops (reload WIP: being ported by the reload-groups agent)
- Session B's **uncommitted reload WIP** (`reload_anims.gd`, `reload_rigs.gd`, `reload_timeline.gd`) is still in the
  creeper-ops main checkout. Port it (and any on-foot commit there after d3b08d6): `format-patch -1 <sha> | git am`.

## Carried over (still true; split tree verified: 3 scenes boot, suite 1113/1)
- FB-R reloads (brief `docs/tasks/FB_R_reload_anims.md`, log `FB_R_progress.md`, scores `docs/art/reload/SCORES.md`):
  judged >= 8: ak47, m1911, glock18, p90, mp5 plain/fast, scarh/sr25/saiga12/sks plain (+ scarh/sr25 fast).
  Below 8: the 4 rifles' empty reloads (5-6), saiga12/sks fast (7). WIP above fixes the empty tails, not yet judged.
- P9 built; P11 no fractures; **P10** waits for Gregory. Known: kill-house navmesh doorway check can fail; barracks north door split by the inner wall.
- Range suite before split: 1113 pass / 1 fail (`a shot at spawn ... (F88)`, Scav 5 net move 0.6 m; left as is).

## Session D (2026-10-16; merged into feat/fb-reload, not pushed yet)
- Insert sound on the `mag_in` mark (0105c26). Arms (dc8304a..): runtime forearm twist bones (`ArmTwist`), M4A1 unbaked
  (IK arms; grip_r = Gregory's posed wrist), `arms_fp.glb` (Blender: arms x1.3, viewmodel only), shoulders 4 cm behind
  the eye (ROOT_POS z -0.02), support hand slides into reach (`left_hold`), Gregory's M4A1 wrap grip on handguard guns.
  Wrist/elbow rings >= 0.72 of rest (probe scratchpad `skin_probe.gd`). **CHANGES P13** (pistol ADS 0.25 -> 0.45 m) waits.
- MAP-3 Town (97ab437, `town.tscn`, title "Skirmish: Town"): 160x160, FOB -> farm/orchard -> town -> yard -> extract,
  20 hostiles, brief/log `docs/tasks/MAP3_*.md`, shots `docs/art/map3/`. No Kestrel dressing yet; bots may chase into FOB.
- Running agents (worktrees `../tactical ops-worktrees/`): `bot-idle` (BOT_ANIM2 brief), `reload-groups` (FB_R2 brief,
  ports session B's reload WIP: don't port it again from creeper-ops). Orchestrator reviews + merges them.
- Verified merged tree: parse clean, town/skirmish/range/title boot; arms branch suite 1114/0. Not: Gregory's play.

## Next
1. Merge bot-idle and reload-groups after review; suite; push. 2. Gregory: P10, P13, plays Town + arms.
