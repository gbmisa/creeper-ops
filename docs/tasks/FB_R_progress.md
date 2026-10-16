# FB-R progress (clean reload animations)
Brief: `FB_R_reload_anims.md`. Branch `feat/fb-reload`. Update after every step.

## Phase 1: system + AK47, M1911 (in progress, 2026-10-15)
Findings (measured, not assumed):
- ak47.glb: skinned, bones Bolt / Magazine / neutral_bone; mag triangles weighted 1.0 to `Magazine`. Reload clip 1.52 s.
- m1911.glb: skinned, bones Control / Magazine (child of Control) / Slide / Trigger. The `Magazine` surface is weighted
  0.5 Control + 0.5 Magazine, so moving the bone only moves the mag half way (the old clip could never pull it out).
- Logic: `PlayerWeapons.start_reload` emits `action("reload", busy_t)`; empty detachable adds `CHAMBER_TIME` 0.4 s.
  ak47 3.0 / fast 2.1 s, m1911 2.0 / 1.3 s. Viewmodel knows empty = `gun.chamber == ""` at that moment, fast =
  `weapons._reload_fast`.
- `range_shot.gd --reload=T` waits T and then `--wait` (default 1 s) more: pass `--wait=0` for a shot at T.

Design:
- `ReloadMag.split(glb)`: at weapon switch, triangles whose `Magazine` bone weight >= 0.5 move into a new static
  `Mag` MeshInstance3D (child of the Skeleton3D, so it renders where the skinned mag did). The gun mesh is a new
  ArrayMesh per viewmodel instance with `custom_aabb` = the original AABB (size / sight code unchanged). No glb edited.
  Phase 2 guns without a `Magazine` bone get one in Blender (or a mag object), then the same split applies.
- `ReloadAnims`: data. Phase lists per action kind / class (normalized weights, gun pose offset, mag state, left-hand
  anchor, bolt fraction) + per-gun rig points (mag pivot / out / pouch / drop, charge point, bolt bone + travel).
- `ReloadTimeline`: plays the phases scaled to the logic's `secs` (empty adds the charge phases over CHAMBER_TIME),
  moves the `Mag` node and the bolt/slide bone, gives the viewmodel a pose offset and FpArms the left-hand target.
  Emits `mark(name)` at mag_out / mag_hide / mag_show / mag_in / charged (sound hooks; nothing connected).
- Guns without a ReloadAnims entry keep today's clip + mag_l lerp exactly.

Steps:
- [x] code (parse clean)  - [ ] range check  - [ ] frame sheets + verdict  - [ ] parse / range / smoke  - [x] WIP commit

## Handover (2026-10-15, session stopped by Gregory: the main instance takes this over)
Done, parse clean, NOT verified by range test / smoke / pictures:
- `scripts/range/reload_mag.gd`, `reload_anims.gd`, `reload_timeline.gd` (design above).
- `fp_arms.gd`: `reload_tl`; while it plays, the left hand follows `reload_tl.hand_l` (the old mag_l lerp stays for
  guns without a timeline). `tactical_viewmodel.gd`: builds the timeline at switch, starts it on "reload" (empty =
  `_gun.chamber == ""`, fast = `weapons._reload_fast`; a running fire clip is finished first), adds its gun pose
  offset in `_process`, and stops it if the logic's `busy_kind` is no longer "reload".
- `range_shot.gd`: `--empty` (empties mag + chamber first) and `--strip=t1,t2,..` (with `--reload --shot=X.png`:
  frames at game times into the reload, saved as X_NN.png; time runs at 1/20 because Xvfb software GL is ~2 fps).
  Run: `xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 --resolution 1600x900
  res://scenes/firing_range.tscn -- --weapon=ak47 --reload --strip=0.36,0.7,1.2,2.25 --shot=/abs/ak.png`.
Where the tuning stands (AK pictures only, M1911 not looked at yet):
- The AK's gun pose numbers in `ReloadAnims.PLANS.rifle` are 3rd guesses. Learned: the butt sits 0.1 m behind
  the eye at the hip, so yaw/pitch swing the stock across the camera; the gun must go forward (gp.z about -0.14)
  before it rotates. Roll must be negative (top right) so the mag well turns toward the left hand.
- Last frames (gp (-0.08, 0.07, -0.14), gr (0.10, 0.18, -0.50)): the gun reads, but the mag well and the Mag node
  are still at or below the bottom edge, and the left hand looks short of the mag. Next: raise gp.y / lower pitch
  until the mag well is about 25% above the bottom edge, then check with `--side=right` that the Mag node really
  leaves (split + K transform are unverified in pictures) and the hand meets the `hold` point.
Still to do for phase 1: the M1911 pass, a range check (RangeTestReload: mag back in place, hands on grips, the
timeline lasts `secs`, the gun's AABB is unchanged by the split), sheets in `docs/art/reload/` + verdict against
the EFT AKM / M1911 reloads (TRP timing), the full parse / range / smoke run.
Behaviour changes so far: AK47 and M1911 reloads only (procedural instead of the glb Reload clip). Nothing else.
