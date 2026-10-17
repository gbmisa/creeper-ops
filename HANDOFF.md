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

## Earlier today (pushed; details in git log / commit bodies)
- Bot crouch + peek lean (0c0e864, `BotPose`, tunables `TacticalConfig.BOT_*`); **CHANGES P12** (cover hold) waits.
- Bot gun hold (ee245ff, `BotHold`: butt in the shoulder pocket, bladed torso). Gregory's verdict on the look pending.

## From creeper-ops: session B's reload WIP is ported (f18d7a9). Port any other on-foot commit there the same way.

## Carried over (still true; split tree verified: 3 scenes boot, suite 1113/1)
- FB-R reloads (brief `docs/tasks/FB_R_reload_anims.md`, log `FB_R_progress.md`, scores `docs/art/reload/SCORES.md`):
  judged >= 8: ak47, m1911, glock18, p90, mp5 plain/fast, scarh/sr25/saiga12/sks plain (+ scarh/sr25 fast).
  Below 8: the 4 rifles' empty reloads (5-6), saiga12/sks fast (7). WIP above fixes the empty tails, not yet judged.
- P9 built; P11 no fractures; **P10** waits for Gregory. Known: kill-house navmesh doorway check can fail; barracks north door split by the inner wall.
- Range suite before split: 1113 pass / 1 fail (`a shot at spawn ... (F88)`, Scav 5 net move 0.6 m; left as is).

## Session D (2026-10-16/17; merged into feat/fb-reload and pushed)
- Insert sound on the `mag_in` mark (0105c26). Arms (dc8304a..): runtime forearm twist bones (`ArmTwist`), M4A1 unbaked
  (IK arms; grip_r = Gregory's posed wrist), `arms_fp.glb` (Blender: arms x1.3, viewmodel only), shoulders 4 cm behind
  the eye (ROOT_POS z -0.02), support hand slides into reach (`left_hold`), Gregory's M4A1 wrap grip on handguard guns.
  Wrist/elbow rings >= 0.72 of rest (probe scratchpad `skin_probe.gd`). **CHANGES P13** (pistol ADS 0.25 -> 0.45 m) waits.
- MAP-3 Town (97ab437, `town.tscn`, title "Skirmish: Town"): 160x160, FOB -> farm/orchard -> town -> yard -> extract,
  20 hostiles, brief/log `docs/tasks/MAP3_*.md`, shots `docs/art/map3/`. No Kestrel dressing yet; bots may chase into FOB.
- Merged: BOT-ANIM2 (3c0a00a: BotIdle/BotLegs/BotHead, low-ready/patrol carry, eased raise, head within 2.5 cm of its
  hitbox when still; moving bots' clips still lean up to 21 cm off, pre-existing) and FB-R2 (750eff6: session B WIP
  ported, review + 2 hand rounds, M4A1/Vector `ar`, AXMC/Mosin `boltbox`; scores `docs/art/reload/SCORES.md`).
- **Merged tree: suite 1234 pass / 0 fail / 0 SCRIPT ERROR** (sniper/mosin harness fix 56577ce; the kill-house navmesh
  doorway check still flakes now and then, pre-existing). Pushed. Reload agent continues on `feat/reload-groups2`
  (worktree `reload-groups`, uncommitted hinge WIP: `reload_hinge.gd`): tube / en-bloc / revolver / PKM belt.

## Next
1. Review + merge reload-groups2 (hinged parts, non-detachable reloads). 2. Gregory: P10, P13, plays Town + arms.
