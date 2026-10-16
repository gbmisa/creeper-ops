# FB-H progress (brief: FB_H_ads_rule.md)

## Phase 1 — Opus, 2026-10-15 (done, branch fix/fb-h-ads-rule)
- **Sight picture rule (correction to the brief):** notch sights align the front post tip with the **top of the rear
  blades** (equal height, equal light), not the notch bottom. Apertures use the hole centre. Scopes use the tube axis.
- **Data:** `art/gen/mounts.json` per gun: `sight_rear`, `sight_front` (gun space, m) and `sight_kind`
  (notch / aperture / none / scope / optic). Measured from rear-view slab renders at 0.25 mm/px:
  `art/guns_src/sight_slab.gd` (`-- OUTDIR id:z0:z1:tag ...`, z0 > z1, renders that z slab from behind).
- **No sight (Gregory's rule):** garand (no rear), shotgun (bead only): the missing point is at the other one's height.
- **Modelled sights** (`art/guns_src/add_irons.py`, headless Blender, edits the glb in place; unrigged guns only):
  m4a1 A2 aperture on the carry handle + front post raised to 0.158; mp5 drum aperture + hooded post (line 0.1365);
  vector flip-up aperture + post (0.2048); sr25 flip-up rear on the receiver rail + front on the handguard (0.117,
  x -0.0107). Slab re-measure: every aperture centre and post tip on its line within 0.3 mm.
- **PKM:** carry handle folded 115° down to the left (hinge x 0.010, y 0.120). A 1 mm sliver at y 0.133 remains 1-2 mm
  left of the line near z 0: judge in the Phase 3 ADS shot.
- **P90:** def key `fit` (parts a new gun comes with) = red dot; `Gun._init` applies it. mounts.json `p90.rail`
  [0, 0.081, -0.095] = top of the optic housing (x not measured; check in the ADS shot).
  Side effects to report: a new P90 weighs +0.15 kg and gets the red dot's ergo change; the dot can be taken off and
  moved to another gun (a free red dot per P90 picked up).
- **Not modelled:** garand (rigged, animated; uses the no-sight rule). Pitches the rule will apply: pkm 0.8° (rear
  blade 11.6 mm under the front post; possibly a rear-leaf model issue), revolver 0.9°, glock 0.4°.
- Offsets the rule absorbs: mosin x -7.9 mm, sr25 -10.7, pkm -15 to -17, scarh -4.8, sniper -3.9, ak47 -2.0.

## Phase 2 - Sonnet, 2026-10-15 (done, committed)
- `AdsPose` (tactical/ads_pose.gd) solves the pose; `AttachmentMounts.ads_pose(def, sid, half)` delegates. Viewmodel lerps
  hip -> ads origin and adds the (pitch, yaw, 0) euler * a into rot. No sight points (P90 with the dot off) = old ads_pos + warning.
- `TacticalConfig.ADS_RELIEF` (pistol .138, pistol_optic .193, notch .160, aperture .1465, optic .286, scope .295): medians of the old
  eye-to-rear distances; Opus tunes in Phase 3. `VM_Z_CLIP` 0.3. `ViewmodelClip` (range/viewmodel_clip.gd) sets z-clip on duplicated
  materials (gun glb, rig parts, posed arms, FpArms "Arms" mesh). `ads_near()`/`ADS_NEAR` removed; cam.near stays 0.03.
- Tests: `RangeTestAds` (range/range_test_ads.gd): 83 gun x sight setups within 0.02 deg (worst 0.0007), pure math, z-clip.
