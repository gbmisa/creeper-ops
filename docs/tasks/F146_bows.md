# F146: compound bow + crossbow (code)

Gregory (2026-10-16/17): "Add a compound bow. Crossbow, and animations for them." Rulings 2026-10-17:
**arrows can be picked up** again, and the bow takes **a couple of optics for zoom, with iron sights on it**.
Worktree `../creeper fps td-worktrees/ov-bow`, branch `feat/f146-bows` (off `port/play-f98-f135`).
Models + viewmodel animation art are Opus's (Blender). You build the code with **placeholder meshes**
(simple boxes/cylinders, the way `model_fallback` works) so Opus can drop the glbs in later by name:
`compound_bow.glb`, `crossbow.glb`, `arrow.glb`, `bolt.glb` under the same folder the gun glbs load from.

## Phase 1: the bow and arrows (one commit)
- `tactical/weapon_defs.gd`: rows `compound_bow` and `crossbow`, new `"action": "bow"` / `"crossbow"`,
  `"slots": ["sight"]`, new calibers `arrow` / `bolt` in `ammo_defs.gd` (a few grades each: field point,
  broadhead (high bleed, low pen)). Numbers in the def tables only, nothing in logic.
- **Bow fire = draw and hold:** hold fire to draw (~0.8 s to full draw), release to shoot. Speed and damage
  scale with draw fraction; full draw holds cost stamina, and after ~4 s held the aim starts to shake. RMB = ADS
  as usual. Releasing before ~25 % draw lets down without shooting. No recoil curve; a small bow-hand kick.
- **Crossbow:** fire shoots one bolt; reload = cock + load a bolt (~3.5 s, x `PLAYER_RELOAD_SPEED`). One shot.
- **Ammo:** arrows/bolts are inventory stack items (like loose rounds) loaded one at a time from the bags/rig
  (a quiver item is not needed). The ammo counter shows arrows left. Range bench refills them like mags.
- **Projectile:** use `Ballistics` with the new ammo rows (slow: bow ~90 m/s, crossbow ~110 m/s, visible drop,
  high drag). Show the arrow in flight (placeholder mesh, nose along velocity).
- **Arrows stick and can be picked up:** on hitting world geometry the arrow stays stuck (Node3D at the hit
  point, nose into the surface). Looking at it in reach shows the usual use prompt; use puts it back in the
  inventory (same grade). Arrows that hit a bot go into that bot's loot (body) so they can be taken back.
  Cap stuck arrows at ~60 per scene (oldest removed).

## Phase 2: sights, gunsmith, where to get them, sounds (one commit)
- **Iron sights:** the bow has a pin sight (3 pins: 20/40/60 m) as its built-in irons; the crossbow has a
  simple rear notch + front post. Use the existing ADS rule (sight points in `mounts.json`, `AdsPose`).
- **Optics:** both take the existing sight-slot optics that make sense (red dot, holo, a low-power scope;
  check `AttachmentDefs.why_not` + rail rows) so they show in the gunsmith slot picker (F145) and fit there.
  At most 3 options, Opus will judge which look right.
- Range: add both to the gun rack (`range_rack.gd`) and arrows/bolts to the crate (`range_crate.gd`) and the
  ammo bench. Loadout room supply/gunsmith gets them the same way other guns do. Bots don't use them.
- Sounds: procedural or existing samples (string twang, crossbow thunk, arrow impact thud). Quiet: bots hear
  a bow shot at ~1/5 of a suppressed gun's range (use the F133 noise rows).

## Don't change
Any existing gun, ammo grade, recoil, reload, bot or UI behaviour. Keybinds: reuse fire/ADS/reload/use;
add no action ids. Files under ~250 lines (new `bow_*.gd` files are fine).

## Verify (per CLAUDE.md)
Parse check, boot the range, one quick headless check that a full-draw arrow flies, drops and sticks, and one
pickup returns it to the inventory (add to a new `range_test_bow.gd`). Run `--range-test` once at the end,
summary line only (known pre-existing fail: f127).

## Report (under 250 words)
Commits, files, every def row added, anything guessed, what Opus must supply (model names, sight points).
