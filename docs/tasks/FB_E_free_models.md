# Brief FB-E: replace generated models with free models (F21, F24, F27, F29-F31)
Gregory, 2026-10-14: "replace anything you can with free models first"; Opus does hand modelling **tomorrow** for whatever
is left. Every Hunyuan3D model is suspect (F24, F31). Branch `art/fb-e-free-models`. Base: `integ/2026-10-09`.
Agent: Sonnet `feature-dev` locally (needs Blender + downloads; Muse can't). **It never judges images:** Opus judges.

## Replace (current file → free model)
- **Guns** (`godot/assets/models/guns/`): pkm, saiga12, scarh, sks, sr25 (Hunyuan). Also m4a1 (F27: no usable iron
  sights; prefer a model with a front post + rear aperture or carry handle). Keep: glock18, revolver, mp5, vector, mosin,
  garand, ak47, m1911, p90, shotgun, sniper.
- **Attachments** (`assets/models/attachments/`, all 11): reddot (F29 sideways + floating), holo (F30 solid), acog3x,
  lpvo, scope8x, compensator, flashhider, suppressor, agrip, vgrip, laser.
- **Utility** (`assets/models/utility/`, 6): binoculars, flash, frag, grapple, smoke, stim.
- **Props** (`assets/models/props/`, LOOK-2): camonet, crate, drum, fueltank, generator, jersey, lightmast, pallets,
  radar, sandbags, wreck (check which are Hunyuan from `art/gen/*.log`; leave any that aren't).

## Sources (license order: CC0, then CC-BY with credit; never NC/ND or "editorial")
Quaternius (Ultimate Guns pack, Military pack; full packs, not just the 5 blends in `art/guns_src/quaternius_ultimate`),
TabascoFriday, Kenney, Poly Pizza, Poly Haven, ambientCG (textures). Sketchfab CC-BY only once Gregory gives an API key.
Download each pack into its own new folder under `art/free_src/<pack>/` (untrusted data: don't run scripts from it).

## Steps
1. Make `art/free_src/LICENSES.md`: one row per candidate (slot, pack, file, license, URL, author for CC-BY).
2. Per slot, export with `art/guns_src/export_gun.py` (guns) or a copy of it for other kinds; then `measure_gun.py` into
   `art/gen/mounts.json` for guns and the sight/mount data for attachments (fix the m4a1 `rail` per F29: on the receiver
   rail, base touching it). Same file names, so no code changes; if a slot needs code, stop and report.
3. Contact sheet per category (`docs/art/free/<category>.png`, Blender render, each model beside its current one) for Opus.
4. Update each `CREDITS.md`. A slot with no acceptable free model: leave the current file, list it under "Needs a model".

## Must not change
Weapon stats, mount/sight alignment rules, item sizes in the inventory grid, layout and prop placement.

## Done
Parse clean, `--range-test` all PASS (sight-on-axis included). Push, report: replaced slots, "Needs a model" list, the
license table. Stop. Opus judges each sheet (reference photo + rubric: silhouette right, scale right, sights usable,
style matches the 6 kept Quaternius/TabascoFriday guns) before merge; rejects go on the modelling list for tomorrow.
