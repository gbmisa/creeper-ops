# RANGE5 LOOK progress
## LOOK-1 (done): env + PBR materials
- `scripts/range/look_env.gd` (HDRI sky, AgX, SDFGI, SSAO/SSIL, glow, volumetric fog, 4-split sun), `look_materials.gd` (world-triplanar Poly Haven materials per map, STYLE table; `RangeLayout.box` routes through it; headless falls back to flat colours). Credits: `godot/assets/CREDITS.md`.
- Added `--fps-report` to range_shot.gd. Self-scores: range ~6/10, skirmish ~6.5/10. Weak: range berms flat/dim, range sky flat pink-grey, skirmish buildings dark flat brown (LOOK-2 facades), slab/walls need paint stripes/trim.
- Skirmish "Outpost Kestrel" theme: rogland_sunset HDRI, low sun heading 150, cold ambient, mist; range: clean warm qwantani_dusk_2.
- Screenshot cmd (from godot/): `godot --path . --rendering-driver vulkan --resolution 1600x900 res://scenes/firing_range.tscn -- --map=range --look=0,1.6,-50 --pos=0,0.05,4.5 --wait=3 --fps-report --shot=/tmp/x.png`
  - range: `--look=0,1.2,12 --pos=0,0.05,-3` (booth), `--look=-6,1.5,-20 --pos=8,0.05,-2`; skirmish: `--map=skirmish --look=-25,1.5,-8`, `--look=25,1.5,5 --pos=0,0.05,25`.
- fps (5090-class, Vulkan, 1600x900): 113-180.
