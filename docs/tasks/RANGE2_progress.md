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
