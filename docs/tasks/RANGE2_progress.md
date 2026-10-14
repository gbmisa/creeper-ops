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
