# RANGE2 progress log

## INV-1 (feat/range-inventory): data model
- Done: `tactical/item_defs.gd` (items, sizes, kg), `inventory.gd` (slots + grids rig_g / pockets / pack_g / ground, fits, place, remove, first_fit, add with stack merge, move, total_kg, find_mags, take_round), `inv_reload.gd` (mag swap: fullest mag from rig then pockets then backpack, old mag returns to the freed spot, fast drops it, cancel, shotgun takes one loose shell), `starter_loadout.gd`. `WeaponDefs` rows gained `inv_w`/`inv_h`.
- `PlayerWeapons` reads guns from the inventory: keys 1/2/3 = primary/secondary/holster (4-6 unused); `give(id)` first-fits a copy (rack keeps its guns, F no longer hides them); extracted helpers in `range/hand_gear.gd`. Viewmodel frees its model when the hand is empty. Bench refill tops up carried mags of the gun's caliber. `carried_kg` = `Inventory.total_kg()`.
- Verified: parse clean, `--range-test` OK 113 (new `inv:` / `reload:` checks in `range_test_inv.gd`), smoke 0 FAIL.
- Behaviour changes inside the brief: start kit is AK + M1911 (not an empty hand); reload needs a mag item; air accel uses full carried weight.
- Open: Gun.spares stays the Gun's own field (empty between reloads); HUD shows no spare-mag count yet.
