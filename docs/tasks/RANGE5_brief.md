# Brief RANGE5: armoury expansion, attachments + sights, utility (grappling hook), graphics of the hub maps

Base: `integ/2026-10-09` at this brief. Four tracks, own branches/worktrees. Progress log per track:
`docs/tasks/RANGE5_<track>_progress.md`. Read `AGENTS.md`, this brief (your track + "Shared rules"), your log, and only
the files you change or call.

## Gregory's words (2026-10-14)
"Upgrade the graphics and make the firing range and skirmish area look nice, it will be a place players return to.
Create additional weapons with variety in stats, there will be level progression so some weapons should be balanced,
some should be specialized, and some should be gradually better. Each weapon should have a clear use case and
advantage, with a few modular attachments for different play styles. Add a few options for attachable sights.
Use hunyuan and clean them up. Add utility items including a grappling hook."

## Shared rules
- Must NOT change: the main game (anything outside `scripts/range/`, `scripts/tactical/`, `scenes/firing_range.tscn`,
  `assets/`, `art/`, appended ids in `keybinds.gd`), existing gun numbers/feel (the 6 current rows keep their stats),
  ballistics/armor/health formulas, bot AI and roster numbers, player movement. Main smoke 0 FAIL, `--range-test` all
  PASS (currently OK 211); never weaken a check. Need something outside? stop and report.
- Checks (from `godot/`): parse `godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"` empty;
  `godot --headless --path . res://scenes/firing_range.tscn -- --range-test 2>&1 | grep -E "\[range\] (OK|FAIL)"`;
  `godot --headless --path . -- --smoke --quit=0.1 2>&1 | grep -c FAIL` = 0. Pipe all output through grep/tail.
- **Screenshots on the real GPU** (Forward+, shows real lighting): `godot --path . --rendering-driver vulkan
  --resolution 1600x900 res://scenes/firing_range.tscn -- [--map=skirmish] --wait=2 --shot=/abs.png [flags in
  range_shot.gd]`. View them yourself, downscaled to ≤800 px wide. Xvfb/opengl3 only for quick layout checks.
- **3D models: Hunyuan pipeline**, see `art/tools/README.md`: `gen3d.py` (prompt -> concept PNG -> raw GLB, ~40 s,
  ComfyUI on :8188, one job at a time, other tracks share it), `glb_cleanup.py` (remesh + decimate + scale + colour),
  `glb_preview.py`. Raw meshes `*_raw.glb` stay out of git. Credit: generated locally (Krea 2 + Hunyuan3D 2).
- Keep files under ~250 lines; data in def tables; commit per phase; don't merge/push/touch CHANGES.md.

## Track ART (Sonnet `stage-runner`): gun, sight, attachment and utility models. Branch `feat/r5-art`
**ART-1 texturing tool.** Add `art/tools/glb_texture.py`: planar projection of the concept image onto the cleaned mesh
along its thinnest axis (guns are flat side-profiles; both sides get the same image, mirrored), fitting the concept's
non-white silhouette bbox to the mesh bbox in the other two axes; bake to a 1024 texture with UVs; fallback flat colour
for faces nearly parallel to the projection. Add `--rotate x,y,z` and `--flip` to `glb_cleanup.py` for orientation.
Prompts for guns: "orthographic side view, muzzle pointing right, entire weapon in frame, plain white background".
**ART-2 models** into `godot/assets/models/guns/<id>.glb` (muzzle along -Z, real length, origin bbox centre, like the
existing six), `assets/models/attachments/<id>.glb`, `assets/models/utility/<id>.glb`. Target 3–6k tris per gun,
0.5–1.5k per attachment. For every gun also write measured mount data to `art/gen/mounts.json`: `muzzle` (tip),
`rail` (top centre where a sight sits), `under` (underbarrel point), `grip_r`, `grip_l`, `mag_l`, `ads_y` (iron sight
line height). Judge each in a Vulkan render; regenerate (new seed / prompt) when a model is wrong or unreadable, max 3
tries each. Guns: the 11 new ids in Track GUNS. Sights: `reddot`, `holo`, `acog3x`, `lpvo`, `scope8x`. Muzzle:
`suppressor`, `compensator`, `flashhider`. Underbarrel: `vgrip`, `agrip`, `laser`. Mags: reuse gun mag shapes (skip).
Utility: `grapple` (launcher + hook head), `frag`, `smoke`, `flash`, `stim`, `binoculars`.

## Track GUNS (Sonnet `stage-runner`, 2 agents in sequence): roster + attachments. Branch `feat/r5-guns`
New columns on every `WeaponDefs` row: `tier` (1–3), `unlock` (player level, data only; no progression system yet),
`role` (one line shown in the rack/inventory tooltip), `slots` (attachment slots the gun takes).
**New guns** (numbers are yours, consistent with the existing rows; each line is the use case and advantage to keep):
| id | name | tier/line | role |
|---|---|---|---|
| mp5 | MP5 | 1, balanced | accurate, low-recoil SMG; the safe CQB pick |
| glock18 | Glock 18 | 2, specialized | full-auto pistol: holster CQB burst, poor range and pen |
| revolver | .44 Magnum | 3, specialized | 6 rounds, one-shot limbs, slow reload, big recoil |
| vector | KRISS Vector | 3, specialized | 1100+ rpm, tiny recoil, short range, eats mags |
| m4a1 | M4A1 | 2, gradually better (after AK) | low recoil, most attachment slots |
| scarh | SCAR-H | 3, gradually better | 7.62 NATO pen, heavier, slower ADS |
| saiga12 | Saiga-12 | 2, specialized | mag-fed semi shotgun, room clearing |
| sks | SKS | 1, balanced | cheap semi 7.62x39, iron sights, early DMR |
| sr25 | SR-25 | 3, gradually better (after Garand) | 20-rd semi DMR, best mid-range |
| mosin | Mosin-Nagant | 1, balanced | cheap bolt sniper, iron sights, strong round |
| pkm | PKM | 3, specialized | 100-round belt, suppression, very heavy, slow reload |
New calibres/ammo where needed (`9x19`, `556x45`, `762x51`, `762x54r`, `44mag`), 2–3 ammo rows each like the others,
plus mags/belt in `item_defs.gd`. Lines: pistol M1911 → Glock/Revolver; SMG MP5 → P90 → Vector; rifle AK → M4A1 →
SCAR-H; shotgun M870 → Saiga; DMR SKS → Garand → SR-25; sniper Mosin → AXMC; LMG PKM.
**Attachments** (`scripts/tactical/attachment_defs.gd`, items in the inventory, fitted by dragging onto the gun in the
inventory screen or at the bench): slots `sight`, `muzzle`, `under`, `mag`.
- Sights: `reddot` (1x, fast ADS), `holo` (1x, wider window), `acog3x` (3x, slower ADS), `lpvo` (1–6x, toggle with a new
  action `t_zoom`), `scope8x` (8x, sniper rails only). Each has its own `ads_y` sight line from mounts.json and a reticle
  (2D overlay for magnified, emissive dot/ring on the glass for 1x). Iron sights when nothing is fitted.
- Muzzle: `suppressor` (bot hearing range x0.4, no flash, -5 % muzzle velocity, +length), `compensator` (vertical
  recoil -20 %, louder), `flashhider` (no flash, horizontal recoil -10 %).
- Under: `vgrip` (vertical recoil -15 %), `agrip` (ADS time -15 %), `laser` (hip spread -30 %, visible beam bots can see).
- Mag: `extmag` (+50 % capacity, slower reload) per gun family where sensible.
Modifiers flow through one place (e.g. `Gun.stat(name)`), never by editing the base def. Viewmodel mounts the models
at mounts.json points; ADS uses the fitted sight's line. The rack shows all guns with tier/role; the supply crate holds
the attachments. Until ART lands, use placeholder boxes at the mount points so this track never waits.
GUNS-1: roster + ammo + mags + tests. GUNS-2: attachments (data, stat modifiers, inventory fitting, viewmodel mounts,
sights/zoom) + tests. Tests: every gun builds, fires, reloads; each line's later tier beats the earlier on its stated
advantage; each attachment changes exactly its stat; sight changes ADS line/zoom.

## Track UTIL (Muse, in parallel with MP-1): utility items. Branch `feat/r5-util`
Follow `docs/MULTIPLAYER.md` rules: items act through request functions, server-owned state (grenades, grapple
attach point, smoke volumes) in entities with ids + to_dict, players list (not one player), seeded RNG, effects as
events; sounds via `RangeAudio.util(...)` events already mapped in `scripts/range/sound_defs.gd`. Models exist in
`godot/assets/models/utility/`. MP-1 refactors the same files on `feat/mp1`; keep your edits to shared files small.
Items in a new inventory slot pair `utility1`/`utility2` (keys new actions `t_util_1` = 4, `t_util_2` = 5) plus grids.
- **Grappling hook** (`grapple.gd`): aim, fire (hook projectile, 35 m), attaches to world geometry (not bots), reels the
  player toward the point (pull speed ~12 m/s, release on jump/use key or arrival, keeps momentum so you can swing up
  onto roofs and the watchtower), visible rope line, 4 s cooldown, unlimited uses. Works in both maps.
- `frag` (cooked fuse 4 s, throw arc preview, fragment damage through the existing ballistics/health), `smoke` (blocks
  bot sight lines for 25 s), `flash` (blinds bots in view for 4 s; the player too if facing it), `stim` (stamina refill
  + 20 s faster regen), `binoculars` (8x look, range readout).
- Bots react: they flee frags in radius, lose the player in smoke, stagger when flashed. No other bot changes.
Tests per item (grapple attaches and moves the player onto a roof; frag damages in radius; smoke blocks perception).

## Track LOOK (Sonnet `stage-runner`): graphics + hub feel of both maps. Branch `feat/r5-look`
The range is the hub players return to; Skirmish is the field. Make both look good at 1440p on the 5090, ≥90 fps.
- Environment: Forward+ `WorldEnvironment` per map: ACES/AgX tonemap, SDFGI or VoxelGI, SSAO, SSIL, glow, volumetric
  fog (light), a real sky (CC0 HDRI from Poly Haven, download via its API, 2k), sun with good shadows (cascades tuned).
- Materials: CC0 PBR textures from Poly Haven (concrete, asphalt, brick, corrugated metal, plywood, gravel, grass,
  dirt) on the existing geometry with triplanar mapping. Keep layout and collision exactly as they are; this is a
  visual pass (moving cover changes gameplay: don't).
- Props (Hunyuan, cleaned): sandbags, jersey barriers, oil drums, pallets, ammo crates, fuel tank, generator, light
  masts, camo netting, wrecked car/truck. Replace the existing box crates/trucks/cars visually only where the
  collision box stays the same; add decorative props only outside play paths. Grass/foliage via MultiMesh outside
  paths; a few trees (Hunyuan or CC0 Quaternius nature pack).
- Range hub: proper shooting booth (roof, lights, bench details), lit signage for lanes and the deploy truck, an
  armoury wall for the rack, flags/banners, soft evening light; it should feel like a base.
- Skirmish: a run-down military compound at dusk; buildings get facades (windows, doors, trims) as visuals over the
  same collision.
- Performance: keep draw calls sane (MultiMesh, shared materials). Report fps from the Vulkan run (`--fps-report` flag
  if you add one). Screenshots: 4 per map from the player's eye.
LOOK-1: environment + materials (both maps). LOOK-2: props, foliage, hub dressing, facades.

## Track RECOIL (Sonnet): Tarkov-style recoil as an A/B toggle. Branch `feat/r5-recoil`
Spec: `docs/research/RECOIL_TARKOV.md` "Proposal". CHANGES.md P3: Classic stays the default until Gregory rules.
Esc-menu toggle "Recoil: Classic / Tarkov" (static, persists across map switches). Per-gun columns `conv`, `cam_share`,
`angle` for all 17 guns; numbers in `tactical_config.gd`. Bullets leave along the barrel. Tests: impulse rise time,
plateau after ~5 auto shots, camera moves less than the barrel, semi-auto returns to the aim point, classic unchanged.

## Track SOUND (Sonnet): sounds match every item. Branch `feat/r5-sound`
Gregory: "Make sure sounds match all items." Every gun its own report by calibre/class (pistol crack vs .44 boom vs
5.56 vs 7.62 vs .338 vs 12 ga vs PKM), suppressed variant, distance/indoor tail, mechanical layers (mag out/in, bolt,
pump, slide, belt, dry fire, fire-mode switch, attachment fit), inventory (pick up/drop/move per item kind), utility
(grapple fire/reel/impact, grenade pin/throw/bounce/blast, smoke hiss, flash bang + player tinnitus, stim, binoculars).
Prefer CC0 recorded samples (OpenGameArt/Freesound CC0, Sonniss GDC bundle is royalty-free) over the procedural synth
for guns; credit every file. A table `sound_defs.gd` maps item ids/events to sounds; a test asserts every gun, ammo
calibre, attachment and utility id has its events mapped.

## Track EXPAND (Sonnet): bigger Skirmish. Branch `feat/r5-expand`
Gregory (2026-10-14): "Improve the graphics on and expand the skirmish area." Grow the map from 120 m to ~220 x 220 m
around the existing compound (which stays as is, at the centre; only its outer perimeter wall/fence opens up). Four
new Outpost Kestrel districts, each with its own landmark and fight style, built in new files (`skirmish_district_*.gd`):
- **North: radar hill** (the dome moves up here or a second, bigger array): elevation, switchback road, bunker
  entrances, marksman positions; long sightlines.
- **East: motor pool + fuel depot**: hangars you can enter, fuel tanks, rail siding with wagons; mid-range cover.
- **South: checkpoint town**: the gate becomes the town entrance; a short street of 2-storey houses, a shop, a
  church/water tower; CQB.
- **West: birch forest + river**: trees, rocks, a river with a road bridge and a footbridge, a ruined pump house;
  flanking routes.
Spawns: 3 player spawn points around the edge (random); extracts: 3 (one per non-spawn side, each with a condition
icon: always open / open after the boss dies / costs time to call). Enemies ~24: roster rows unchanged, new patrol
routes and posts per district; the Warlord moves between 2 districts. Navmesh over everything, stairs/ramps like the
hotel. Graphics: same Kestrel look (LookEnv/LookMaterials, Hunyuan props, MultiMesh foliage), fps ≥ 90 at 1600x900.
Tests: every district reachable from every spawn (navmesh path), each extract works, bot count, fps report.

## Track MED (Sonnet): Tarkov-style medicine + status effects that build up. Branch `feat/r5-med`
Gregory (2026-10-14): "Add healing items and things that can affect status effects that build up similar to Tarkov."
MED owns all medical/consumable items **including the stim** (UTIL: skip `stim`, or leave a stub MED replaces).
**Status model** (`scripts/tactical/status_effects.gd`, per player in PlayerState-compatible form, to_dict):
- Wounds (exist in BodyHealth): light bleed, heavy bleed, fracture, blacked-out limb (0 HP; surgery restores it at a
  lower max HP).
- **Build-up meters** (0..1, rise with exposure, decay slowly, trigger an effect at 1, warning icon from 0.5):
  pain (damage, fractures, heavy bleeds), radiation (hot zone around the Kestrel radar array; damage over time when
  full), toxication (stim side effects, poison), dehydration/energy (drain over time, faster when sprinting or
  bleeding), fatigue (sprinting/jumping while low on energy), contusion (explosions, helmet hits).
- Effects: pain -> tremor (sway x2) + slower ADS; dehydration -> stamina regen halved, then HP loss; low energy ->
  slower stamina regen; contusion -> muffled audio + blur, 10 s; tunnel vision (low HP/dehydrated); radiation full ->
  slow HP drain + reduced max stamina; toxication full -> HP drain + nausea wobble; overweight already exists.
**Items** (`item_defs.gd` rows, kind `med`/`food`/`stim`; Hunyuan models for the main ones; sounds via
`sound_defs.gd`): Bandage (light bleed, 2 s), Esmarch tourniquet (heavy bleed, limb, 3 s), Splint (fracture, 5 s), CMS
surgical kit (restores a blacked limb at 60 % max, 15 s, 3 uses), AI-2 (100 HP pool, 2 s), Car kit (220 HP, stops light
bleeds), Salewa (400 HP, light + heavy bleeds), Grizzly (1800 HP, all wounds, slow), Analgin painkillers (pain off 95 s,
4 uses), Morphine (pain off 300 s; dehydration side effect), Propital (regen 1 HP/s for 300 s; tremor at 240 s), SJ6
(stamina +, faster regen 240 s; fatigue + tremor after), Adrenaline (pain off + stamina refill 60 s; dehydration),
eTG-c (big regen 6.5 HP/s for 60 s; toxication build-up), Iodine pills (radiation build-up -60 % for 300 s), Water
bottle, Juice, Crackers, MRE (hydration/energy).
**Use:** right-click Use in the inventory, choose body part when relevant; quick-use keys for rig/pocket meds (new
action ids, free keys; shown in Controls); using takes time, slows you (x0.6), interrupts on sprint/aim/swap; HP pools
heal the worst zone first. Medkits/stims spawn in Skirmish loot crates and the range crate.
**HUD:** health panel in the inventory (body silhouette, zone HP, wound icons) and status icons with timers +
build-up bars on the main HUD (only when > 0).
**Bots:** keep their Heal state; they can use bandages/medkits from their loot (no number changes).
Multiplayer rules apply (requests, per-player state, events for sounds/visuals). Tests per item and per build-up.
