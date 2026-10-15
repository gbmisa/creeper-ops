# RANGE2 progress log

## INV-1: inventory data model (2026-10-14)
Done:
- Rebased `feat/range-inventory` onto `feat/deactivate-pause-menu` @ d56f9883 (was 0ef7fb8b;
  base moved mid-task). 15 files touched by both sides merged: 10 clean via 3-way merge,
  5 resolved by hand (packet_requests: keep both drop_pod + self_build flags;
  info_panel: floori + deactivated tag; game_flow/smoke_test: keep branch additions;
  HANDOFF.md: take new-base docs). pause_menu.gd / smoke_pausemenu.gd kept from new base
  per brief ("don't re-apply"). No `supply_on` leftovers anywhere.
- `scripts/tactical/weapon_defs.gd`: added inv_w/inv_h (pistol 2x1, P90 3x2, AK 4x2,
  shotgun/garand/sniper 5x2).
- `scripts/tactical/item_defs.gd` (new): kinds gun/mag/ammo/armor/rig/backpack/med;
  per-caliber mags, ammo stacks, rig 4x2 / small 4x4 / big 5x6 grids, per-round kg.
- `scripts/tactical/inventory.gd` (new): Inventory — slots
  primary/secondary/holster/armor/rig/backpack, grids pockets/rig_grid/pack_grid;
  fits/place/remove/first_fit (slot, rig, pockets, backpack)/move/total_kg/equipped;
  slot rules (long guns primary/secondary, pistol holster); mag items with rounds/ammo/in_gun.
- `scripts/tactical/gun.gd`: added `external_mag` flag only — PlayerWeapons does the mag
  swap via the inventory, Gun just runs the reload timer. Existing Gun tests untouched.
- `scripts/range/player_weapons.gd`: reads guns from inventory (1/2/3 =
  primary/secondary/holster; 6-gun loadout gone); start loadout AK primary + M1911 holster
  + rig with 3 AK + 2 pistol mags; reload takes fullest compatible mag (rig, pockets,
  backpack), old mag back where the new was (or first fit), fast reload drops it;
  no mag = HUD message; tube feeds shells from ammo stacks; carried_kg = total_kg();
  bench ammo-grade cycle refills inserted + spare mag items.
- `scripts/range/range_test_inv.gd` (new): 25 checks — defs, fits/rotation/overlap,
  slot rules, first_fit order, reload swap (fullest first, old mag home, fast drop,
  no-mag message), tube feed, weight sum.
Verified:
- Parse: `godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"` prints nothing.
- `-- --range-test`: all PASS including 25 new [range] checks; pre-existing checks unchanged.
- `-- --smoke --quit=0.1`: 763 pass, 3 fail — the 3 known ship-check failures only
  (Fallen Titan hook keybind issue, out of brief scope, not touched).
Open issues:
- None for INV-1. INV-2 next: UI + world items (separate commit).

## INV-2: UI + world items (pending)
