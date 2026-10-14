## BODY-0 (Opus) done
- `godot/assets/models/operative/body.glb`: armature `Operative` (65 bones, Unreal-style names: pelvis, spine_01-03,
  neck_01, Head, clavicle/upperarm/lowerarm/hand_{l,r}, fingers, thigh/calf/foot/ball_{l,r}). 1.82 m tall, feet at y=0,
  faces +Z (glTF), so rotate 180 deg to face the player's -Z. Meshes: `Head` (hide from own camera), `Arms` (sleeves +
  gloves; viewmodel arms and world arms), `Body`, `Body.001`, `Body.002`, `Legs`, `Boots`.
- Clips (AnimationPlayer): idle, walk, jog, sprint, crouch_idle, crouch_walk, jump_start, jump, jump_land, pistol_idle,
  pistol_aim, pistol_reload, death. No rifle clips: rifles need IK hands. No strafe/backward clips: play walk/jog
  with the legs yawed toward the move direction (clamp ±70 deg) and reversed for backward.
- Player eye height `EYE_STAND` 1.62; the model's eyes are at ~1.68, so scale the body ~0.965 or drop it 6 cm.
- Grip targets in WeaponDefs (`grip_r`, `grip_l`) are NOT done: BODY-1 derives them from each gun mesh (pistol grip =
  the low part just behind the trigger/magazine; support hand = handguard under the barrel; P90 = front grip ring).

## BODY-1a (Sonnet) done: world body + legs
- `scripts/range/fp_body.gd` (child of the player, wired in `firing_range.gd`): body.glb scaled 0.965, 0.26 m behind the camera, yawed 180. Clip by speed: idle <0.3, walk <2, jog <4.5, sprint; crouch_idle/crouch_walk; jump airborne. Playback rate = speed / CLIP_SPEED (measured stance speeds: walk 0.9, jog 3.35, sprint 3.6, crouch_walk 0.5 m/s). Backward = negative speed; strafe = legs yawed toward move dir, clamp 70 deg. Head + Arms on render layer 2, camera cull_mask excludes it (shadows kept).
- `range_test_body.gd`: 9 PASS checks. `--pitch=deg` and `--walk=W+shift` flags in `range_shot.gd`.
- Verified: range-test OK 89, smoke 0 FAIL, looking-down screenshot (legs/boots visible, no near-plane clip).
- Open: walk clip is very slow (0.9 m/s), so player WALK 3.2 plays jog; crouch_walk plays ~3.5x fast.
