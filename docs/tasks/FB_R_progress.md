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
- [x] code  - [x] range check  - [x] frame sheets + verdict  - [x] parse / range / smoke  - [x] commit

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

## Phase 1 finished (2026-10-15, second Opus session; resumed from the handover, kept the WIP design)
Fixes to the WIP:
- Mag node was invisible / misplaced: the importer leaves the mesh in gun-model space, so a skinned vertex renders
  at bone rest * bind pose, not the identity. `ReloadMag` now puts `Mag` at that pose; the timeline composes on it.
- M1911 split failed: its 0.5/0.5 weights are stored as 0.49999 -> `MIN_W` 0.45. A surface that is all mag is kept
  as one degenerate triangle so surface indices and the gun AABB stay the glb's (AABB check caught it).
- Left hand had a fixed handguard frame: `ReloadAnims.HANDS` gives each anchor finger / palm directions (mag turns
  with the Mag node), anchors are palm centres, wrist = palm - f*WRIST_BACK - n*WRIST_OFF. FpArms takes them.
- AK charge: overhand rack (left hand over the receiver to the right-side handle), gun rolled left.
- M1911 empty: the left-hand slide rack put a huge hand over the camera (pistol rear faces the eye). Replaced with
  a slide lock: `empty_bolt` 1.0 holds the slide back the whole empty reload, support hand regrips, slide drops
  (`charged`). Slide verts are 0.5 Slide, so bone travel 0.06 shows 3 cm. Pistol pose moved forward/up/left.
- `RangeTestReload` (new, registered in range_test.gd): per ak47 / m1911 x plain / fast / empty: timeline exists,
  gun AABB unchanged, length = logic secs, mag leaves >= 8 cm, left wrist reachable every frame, marks, mag
  seated + bolt home + both hands on grips at the end. Range OK 612, smoke OK 0 failures, parse clean.
Sheets (8 frames each, labelled with phase + game time): `docs/art/reload/{ak47,m1911}_{plain,fast,empty}.jpg`.
Verdict (Opus, against EFT's AKM / M1911 reloads as I know them and the TRP AKM timing: mag out 0.24, in 0.75):
hands on gun/mag every frame PASS; no camera/body clipping PASS (AK rack arm crosses the upper left, as EFT's
over-the-top rack does); mag visibly leaves and arrives PASS (AK mag model is short, reads small); pose readable
PASS; timing = secs PASS (checked). Weak spots: the AK mag well hides behind the right hand at seat; the pistol
fast-drop mag leaves frame in ~2 frames; no slide lock on the last shot (fire visuals frozen) so the 1911 slide
snaps back at the start of an empty reload.

## M1911-style follow-ups / open (for the orchestrator)
- Slide lock on the last shot would need a fire-visual change (out of brief).
- M4A1 posed arms (`arms_pose`): proposal, NOT built, ask Gregory: keep his posed arms for idle/fire, and during a
  reload hide them and show the IK arms (FpArms) driven by the timeline, cross-fading at start/end. His glb and
  hand poses stay untouched. Alternative: keep posed right arm, IK only the left arm (needs his rig's bone names).
- vector / pkm: timeline data only in phase 2; mag split after fix/fb-i lands.

## Builder pass A2a (2026-10-15): round-1 judge notes, AK47 + M1911
- AK mag "10 cm stub": NOT a split bug. Measured: all 20 `Magazine` verts move (1.0 weight), the mag object is ~20 cm
  along its curve, ~11 cm of it below the well at idle (the glb's mag is short/sits deep). A longer 25 cm mag would
  change the gun's idle look: left for the orchestrator. Readability fixes instead: hold point lower on the mag
  (`hold` -0.115/-0.085) so most of it shows; new gun pose yaws the side to the camera.
- AK pose (`RIFLE_POSE`): gp (-0.10, 0.10, -0.10), gr (0.15, 0.55, -0.85): muzzle left, rolled right, mag well
  ~1/3 up the screen. Learned: roll alone turns the gun end-on; yaw is what shows the side.
- AK rock: `pivot` = front lip (-0.002, -0.04, -0.062); new mag states rock / slip / near; phases rock -> out and
  near -> hook (front lip in) -> seat (rock back).
- Returns: every plan has a `hold` then `ready` 0.20-0.22 of secs (starts at ~0.78-0.80), smoothstep.
- Drops: slip (slides out, ease out) then drop (ease in, falls): 2 sheet frames show it under the gun.
- AK empty: underhand rack (EFT AK): palm on the receiver's right side at the handle, gun rolled right side up
  (reach gr z +0.25), sleeve stays low. `charge_takes: "hold"`: an empty reload spends the hold phase on the
  swing into the rack (total = secs still). Regrip phase puts the hand on the handguard before the return.
- M1911 empty: `empty_lock` 0.12 s, slide eases back at reload start (no fire-visual change). Slide travel 0.12
  (6 cm shown). `stop_hand` low on the frame (an anchor on the slide put the back of the hand over the gun);
  gun stays canted through the slide drop, cant eases out over ready (0.4 s).
- M1911 fast/plain: `hold` 3 cm forward (z 0.065).
- RangeTestReload: + bolt/slide starts home (no pop), + mag never moves >10 cm in a 1/60 s frame.
- Sheets regenerated (12-20 frames, labelled phase + time): `docs/art/reload/*.jpg`. Maker script was a scratch
  python (strip + PIL join), not committed.
- Verified: parse clean, range OK 624 / 0 FAIL, smoke 0 FAIL.
