# Handoff: 2026-10-08 (session 15f: military restyle + UI overhaul, Opus, unmerged)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) (new Stage 25 row). Run: [RUN.md](RUN.md). Opus long-horizon plan: [docs/tasks/ART3_OPUS_plan.md](docs/tasks/ART3_OPUS_plan.md).
Repo: https://github.com/gbmisa/creeper-ops (private). **Muse** codes from GitHub branches; **Opus** orchestrates, merges and does the visuals. Opus → Muse notes go in [docs/tasks/MUSE_NOTES.md](docs/tasks/MUSE_NOTES.md); the latest note covers A4/A5 merge order and the new glbs.

## 2026-10-14 late night: gun fixes on `fix/fb-guns` (READ FIRST)
- **New branch `fix/fb-guns`** (worktree `../fb-guns`, pushed, d315b85) = fb-e + Muse's `feat/fb-d-recoil-ads` (P3 Tarkov
  recoil toggle, P4 eye position) + `feat/mp1`. **Gregory plays it:** `godot --path "../creeper fps td-worktrees/fb-guns/godot"`.
  Range 532 PASS / 0 FAIL, smoke 0 failures, parse clean. **Muse:** fb-d and mp1 were broken alone (fb-d lacked mp1's
  RangeBots fix; mp1's `range_truck.gd` still called the removed `RangeLoadout`); both fixed on fix/fb-guns.
- Fixed there: **F44** (hip dot ate the fire click: mouse filter), **F45** (body slides back by the run lean; side effect:
  own shadow up to 0.3 m further back while running), **F35** P90 echo (sample cut before its slapback).
- **FB-F Mosin bolt animation**: brief `docs/tasks/FB_F_mosin_bolt.md`, Sonnet agent running on `feat/fb-f-mosin-bolt`
  (worktree `../fb-f`). The glb is rigged (`Bolt`, `BoltHandle`); the cycle rule already existed. Opus judges its shots.
- **FB-G ADS sights (next Opus job)**: `docs/tasks/FB_G_ads_sights.md` has the root causes and tools. Main ones: P4 puts the
  eye in front of the rear sight on short guns, and `ads_y` = tallest point (AK eye inside the receiver). ADS before-sheet:
  `docs/art/ads/`. Open for Gregory: P90 and SR-25 have no usable irons (model work or a default optic?).
- Still open from before: the m4a1 question below; FB-E models pkm, mp5, vector, sks, saiga12, acog3x, compensator, flashhider.

## 2026-10-14 night: FB-E part 1 + gun feedback F32-F44 (READ FIRST, Gregory: "fix these")
- **FB-E part 1 done**: worktree `../fb-e`, branch `art/fb-e-free-models` (4ea30f4, pushed, NOT merged into integ). Free models for scarh, saiga12, sks, sr25 (MK14), m4a1 (carry handle) + 10 attachments; licenses `art/free_src/LICENSES.md`; sheets `docs/art/free/`. Rails re-measured to receiver top on replaced guns. Part 2 (utility + props) not started.
- **Gregory played fb-e** (`godot --path ../fb-e/godot`) and logged F32-F44 in `docs/playtests/feedback_2026-10-14.md`: ADS sights off/sideways on scarh, m4a1 (no irons), saiga, p90 (+ sound echo), sks, vector, sr25 (rail blocks sight, canted), mosin (sideways); pkm/mp5/vector models bad; **Mosin bolt action + animation (new feature)**; **hip fire doesn't fire while the hip dot (X) is on (F44)**; **looking down while running shows the inside of the body's neck hole (F45)**.
- **Diagnosis**: kept guns fail too, so ADS is systemic: F28 eye position (approved P4) + per-gun `sight`/roll data in `art/gen/mounts.json`. Opus's sheet review used side views and missed it (F43): **every gun verdict needs an ADS shot at screen centre**. Hook: `godot --path . res://scenes/firing_range.tscn -- --weapon=ID --ads [--fit=reddot] --wait=1.5 --shot=/abs.png` under xvfb-run (opengl3). ADS on integ is already broken for m4a1/scarh/ak47.
- **Gregory said "fix these" (2026-10-14)**: Opus does them in fb-e (or a new worktree off it) with Sonnet agents; Gregory tells Muse that fb-e has more pushes. Order: (1) F44 hip-dot fire bug + F45 body clipping + P4 eye position + per-gun sight/roll data, then an ADS sheet of every gun that Opus judges; (2) Mosin bolt action + animation (write a brief); (3) P90 echo; (4) models: pkm, mp5, vector, sks, saiga12, acog3x, compensator, flashhider → hand modelling or Sketchfab CC-BY (needs his API key).
- **Open question to Gregory**: m4a1: keep the old model + hand-model a flat-top (recommended), or the free carry-handle one (re-pose arms, code to hide the handle under optics)? Opus-rejected on fb-e: saiga12, sks, acog3x (revert before any merge unless he wants them kept; he said the SKS "looks good as a gun").

## 2026-10-14 late: briefs FB-A..E
- Pushed on `integ/2026-10-09`: briefs `docs/tasks/FB_A..E_*.md` + MUSE_QUEUE Wave 3 (fb6b7c7), and the M4A1 hand-posed arms + glb (d272c0a).
- **Next: start FB-E** (`FB_E_free_models.md`): make worktree `../fb-e` on new branch `art/fb-e-free-models` from integ, then a Sonnet `feature-dev` agent (guns + attachments first, utility + props as a second agent). Opus judges the sheets; leftovers = Opus hand modelling.
- FB-A..D are Muse's, after `feat/mp1` merges. Ragdoll brief drops the bot's gun as a prop (Gregory may prefer it stays in the hand).

## 2026-10-14 evening: guns, arms, Tarkov handling (Opus)
- **Arms:** Gregory hand-poses in `art/arms_guns.blend` (Ranger arms rig + all game guns; M4A1 under `ViewEye`; cameras `GameView` and `GameView_ADS`). Working rig: IK `lowerarm_*` → `IK_hand_*`, pole `IK_elbow_*`. **Never touch his hand or finger pose unless he asks.**
- **In the game (integ, UNCOMMITTED):** the M4A1 uses hand-posed arms (`WeaponDefs` `arms_pose`, `TacticalViewmodel._add_posed_arms`; glb `godot/assets/models/operative/arms_m4a1.glb`, 39 MB, not for git). Other guns still use IK `FpArms`. The glb holds an old stretched export: re-export from his saved pose when he says so.
- **Approved (CHANGES.md on integ):** P3 Tarkov recoil and P4 ADS eye position (eye about 0.3 m in front of the butt, not behind it). Spec: https://github.com/JuanFNQ/TRP `TRP/docs/spec/weapon-handling.md` (Apache-2.0, measured). Next: Opus writes the brief. P5 (ADS arms pose) waits for P4.
- **Feedback F27-F31** (docs/playtests/feedback_2026-10-14.md): the M4 has no iron sights; the red dot is sideways and floating; the holo sight is solid; the Hunyuan models were never reviewed by Opus.
- **Sights:** replace with free models via the Blender MCP (addon updated to v1.8; Sketchfab and Poly Pizza need API keys in the MCP N-panel). Gregory likes the 6 original guns (Quaternius/TabascoFriday); the 5 Hunyuan guns are bad.

## 2026-10-09 local edits (Opus, not yet pushed to GitHub)
- **CW3 deactivate** (Z, action id still `supply`): `Structure.active` (was `supply_on`) works on any structure but the Node. Off means it requests no packets (`PacketRequests.need`) and the manager tick skips firing, mining, collector field, income and behaviours. Smoke checks are in `smoke_group_select.gd`.
- **Pause menu**: Muse's `feat/pause-menu` applied locally, then moved into `ui/pause_menu.gd` (`PauseMenu`). **Esc** opens it in both modes; in command mode Esc first cancels a tool or selection. Space is still a quick pause. Smoke: all pass.

## 2026-10-14 (Opus, short)
- Pushed the 10-09 edits as `feat/deactivate-pause-menu` (5a7f2f7 + Muse note 0ef7fb8). Muse should base its work on this branch.
- Smoke there: parse clean, 763 pass, 3 fail in `ship` (Fallen Titan hook). The test holds E but loads the player's binds (Use = F). It's a test-only fix, noted for Muse.
- `.claude/settings.json` and `CLAUDE.md` are still uncommitted; I left them alone.

## Done this session (Gregory: "military models + UI overhaul, work continuously")
**`art/3-models`** (pushed, worktree `art3-models`; log in `docs/tasks/ART3M_progress.md`; sheets in `docs/art/military/`):
- Restyled as military, with bone names and pivots kept: cannon, mortar, sniper, beam, collector, relay, command_node, totem, drop_pod, soldier (rifleman, new `flash` bone) and crawler (4x4 armoured car).
- New glbs: miner, reactor, storage, barracks and forge (static-structure contract). **No loader in game yet.**
- `mil_kit.py` (shared parts). `icons.sh` renders the build-menu icons.
- Sonnet grades: cannon 7.5, mortar 8, sniper 7.5, beam 8.5, collector 7, relay 7, soldier 7, Node 8, totem 7, pod 7.5 (all at or above the old fantasy grades).

**`ui/overhaul`** (pushed, worktree `ui-overhaul`, branched from main `7913773`; smoke reports `OK: 0 failure(s)`, parse is clean):
- `UiTheme`: Barlow Condensed and Share Tech Mono (OFL, in `assets/fonts`), olive/charcoal panels, amber accents, square corners. It is set on every HUD child, because a CanvasLayer blocks the Window theme.
- `UiKit`: new palette, plus `header`, `caption`, `mono` and `brackets` (corner marks drawn from the panel's draw signal).
- Top bar: captioned gauges, a Node HP bar, and a status chip that truncates. Packets and Field are hidden below 1400 px.
- `BuildCard` (icon, key, name, cost, lock note; `summary` is for tests) with icons in `assets/icons`; the menu keeps a stable width across tabs.
- `HudOverlay` modals with an amber primary button. The briefing now says five build screens.
- `Crosshair`, bracketed FPS vitals, tag plates on markers and log lines, and markers clamped on screen.
- Stopgaps: a `StructureMeshes.MILITARY` palette for the procedural player meshes (castles unchanged), and military colours on the viewmodels and arms.
- Debug hooks: `--briefing` and `--ended=won|lost`. Screens: `docs/art/ui/` (before/after).
- UI grader: old HUD about 4/10, new HUD about 7/10.

## Not verified
No human playtest of the new HUD or the colours. GPU (Vulkan) rendering not checked, only Xvfb GL. The new glbs are not visible in game until A4/A5 loaders merge.

## Branches waiting (unchanged from 15e)
P (9 smoke failures, fix-up out), A3, C, S (gallery fix-up), Q, T, A4, K: see MUSE_NOTES.

## Next (Opus)
1. Gregory reviews `ui/overhaul` and `art/3-models`. On approval, merge `ui/overhaul` to main (strip `godot/.godot/`), then re-run smoke.
2. Merge A4, then `art/3-models`, keeping the `art/3-models` glbs. Then start A5, which now also loads miner/reactor/storage/barracks/forge.
3. UI follow-ups: icons for `@lance` and the castle turrets (they fall back to stencil glyphs); an info-panel stat grid; FPS ammo readout.
4. Re-review the Muse branches as they land.
