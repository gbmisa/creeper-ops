# Brief FB-G: per-gun ADS sight calibration (F32-F38, F42)
Opus task (visual verdicts). Branch `fix/fb-guns` (fb-e + fb-d P4 + mp1). Must not change: hip pose, ADS FOV/zoom/speed,
recoil, any gun's stats. Rubric per gun: an ADS shot at screen centre, sights visible and aligned (auto-fail otherwise),
no mesh through the camera, stock/receiver not filling the view.

## Tools (in `art/guns_src/`)
- `gun_ortho.gd`: `xvfb-run -a godot --path godot --rendering-driver opengl3 -s art/guns_src/gun_ortho.gd -- OUTDIR id...`
  renders gun-space silhouettes, 2000 px/m, centre y 0.05: `_side` (muzzle right), `_rear` (front half, near-cut), `_top`.
- `gun_ortho_annot.py IY_FILE`: draws the 1 cm grid + current `iron_y` (red) + centreline; run inside OUTDIR.
- ADS shot: `godot --path . res://scenes/firing_range.tscn -- --weapon=ID --ads --wait=1.5 --shot=/abs.png` (xvfb,
  opengl3, 1600x900, ~6 s each). The pistols (glock18, revolver) don't equip from `--weapon` (shot shows "put away"): fix the hook.
- Before sheet: `docs/art/ads/ads_sheet_before.jpg`; side views `docs/art/ads/side0..3.png` (m4a1/scarh/sks,
  saiga12/sr25/mosin, mp5/vector/p90, pkm/ak47/garand).

## Root causes found (2026-10-14)
1. **P4 eye is in front of the rear sight on short-stock guns.** `base_pos` puts the eye `butt` (0.30 m) ahead of the butt
   plate, but the rear sight is only ~0.24 (m4a1), ~0.28 (scarh), ~0.295 (mp5, saiga12) from the butt. Proposed: per-gun
   `rear` (rear-sight distance from butt, gun data) and eye = min(butt, rear - relief); relief ~0.08 m aperture, ~0.25 m notch.
   P4's brief allows a per-gun override; check against CHANGES.md P4 wording before building.
2. **`iron_y` = tallest centreline point** (`measure_gun.py`), not the sight line: ak47 0.113 (sights ~0.131, eye inside
   the receiver → gun invisible), mp5 0.101 (sights ~0.12), pkm 0.183 (carry handle; sights ~0.135), m4a1 0.153
   (carry-handle top; aperture a little lower). Fix in `art/gen/mounts.json` `ads_y` per gun, from the side views.
3. **vector**: no stock, rear sight 0.055 from the back → eye must sit behind the gun (negative `butt`, like pistols).
4. **garand**: rear aperture ~0.087, front post ~0.096 → ~1° pitch; needs an ADS pitch (new def key) or lower `ads_y`.
5. **p90**: no irons, its optic is a solid lump → model work (or a default red dot); also F39/F40 models (pkm, mp5).
6. **mosin**: front post is on screen centre already; it reads "sideways" because the low-poly receiver fills the
   lower view at 0.30 m eye-to-butt plus the left-hand IK in front. Mesh is ~8 mm left of centre (x -0.008): set
   `ads_pos.x` +0.008. Rear sight is 0.585 from the butt, so the eye distance is fine. Judge after #1/#2 land.
7. **sr25**: rail top = sight line (0.101), no real rear sight; front post ~1 cm left (x -0.0115). Needs a flip-up rear
   or a default optic: ask Gregory.

## Order
Fix #2 data + #1 code (test: every gun's eye is behind its rear sight), retake the sheet, judge per gun, iterate.
Then #3/#4/#6, then report #5/#7 choices to Gregory.
