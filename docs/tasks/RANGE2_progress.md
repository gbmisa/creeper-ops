# RANGE2 progress log

## INV-1 (feat/range-inventory): data model
- Done: `tactical/item_defs.gd` (items, sizes, kg), `inventory.gd` (slots + grids rig_g / pockets / pack_g / ground, fits, place, remove, first_fit, add with stack merge, move, total_kg, find_mags, take_round), `inv_reload.gd` (mag swap: fullest mag from rig then pockets then backpack, old mag returns to the freed spot, fast drops it, cancel, shotgun takes one loose shell), `starter_loadout.gd`. `WeaponDefs` rows gained `inv_w`/`inv_h`.
- `PlayerWeapons` reads guns from the inventory: keys 1/2/3 = primary/secondary/holster (4-6 unused); `give(id)` first-fits a copy (rack keeps its guns, F no longer hides them); extracted helpers in `range/hand_gear.gd`. Viewmodel frees its model when the hand is empty. Bench refill tops up carried mags of the gun's caliber. `carried_kg` = `Inventory.total_kg()`.
- Verified: parse clean, `--range-test` OK 113 (new `inv:` / `reload:` checks in `range_test_inv.gd`), smoke 0 FAIL.
- Behaviour changes inside the brief: start kit is AK + M1911 (not an empty hand); reload needs a mag item; air accel uses full carried weight.
- Open: Gun.spares stays the Gun's own field (empty between reloads); HUD shows no spare-mag count yet.

## INV-2: UI + world items
- Done: `range/inventory_view.gd` (draw + drag/rotate/ctrl-click input), `inventory_ui.gd` (Tab, ground grid, drop/swap/merge/quick-move rules), `world_item.gd` + `world_items.gd` (physics pickups, F pickup via first_fit, drop in front), `range_crate.gd` (supply crate with mags, ammo, bags, armor), `inventory_io.gd` + `Inventory.to_dict/from_dict/load_dict`, `range_loadout.gd` (`RangeLoadout.saved`, loaded by PlayerWeapons.setup when non-empty). Keybinds appended: `inventory` (Tab), `drop` (G). `TacticalConfig.LAYER_ITEM`. Esc closes the inventory first. Help panel lists new keys. `--inventory` shot flag. `fits()` bug for bags on the ground fixed.
- Verified: parse clean, `--range-test` OK 133 (new `inv:` / `inv ui:` checks incl. round trip), smoke 0 FAIL, one Xvfb screenshot of the screen looked right.
- Open: `fires again after the fix` in range_test_logic is flaky (random malfunction roll, failed 1 of 5 runs, pre-existing). player_weapons.gd is 261 lines. Nothing calls RangeLoadout.save yet (map transition hook is the caller's job).
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

## BODY-1b (Sonnet) done: viewmodel arms + stock out of view
- `fp_arms.gd`: second body.glb (only Arms, no shadow) under TacticalViewmodel; manual two-bone IK per arm (pole down/out), hand frame from finger dir + palm normal, fingers curled; left hand lerps to `mag_l` during Reload; shoulders lean up to 0.3 m when a grip is out of reach. `WeaponDefs` rows gained `grip_r`, `grip_l`, `mag_l` (wrist-bone targets, gun space, from side silhouettes) and `butt`.
- Stock: ADS gun z now `-(half_len - butt)` (`TacticalViewmodel.base_pos`), and while aiming the camera near plane rises 0.03 -> 0.25 (`ADS_NEAR`) so the stock is clipped. Hip placement unchanged. ADS x/y unchanged; ADS z changed for AK (7 cm closer), shotgun (5), garand (8), P90 (5 farther); pistol identical.
- `--side=right|top|front` and `--pitch`/`--walk` shot flags. 12 + 1 new `[range] PASS` checks (arms present, data, hands within 2 cm at hip/ADS for all 6 guns). range-test OK 108, smoke 0 FAIL.
- Open: hands are blobby (open-pose glove curled by bone rotation only), right hand sits close to the sights in ADS; near-plane cut shows hollow insides if a gun's cut falls in the receiver (tuned per gun via `butt`); no check/sprint arm poses beyond following the gun.
