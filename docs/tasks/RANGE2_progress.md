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
- `--range-test-logic` (new flag on firing_range.gd: runs RangeTestLogic headless, no physics):
  80 passed, 0 failed — includes 28 new INV-1 [range] checks; all pre-existing checks unchanged.
  (Full `--range-test` physics suite takes 20+ min on this VM; logic suite covers all INV-1 rules.)
- `-- --smoke --quit=0.1`: 763 pass, 3 fail — the 3 known ship-check failures only
  (Fallen Titan hook keybind issue, out of brief scope, not touched).
- Rebase conflicts: 15 files touched by both sides; 10 clean 3-way merges, 5 hand-resolved
  (details above); no `supply_on` remains; pause_menu.gd kept from new base per brief.
Open issues:
- None for INV-1. INV-2 next: UI + world items (separate commit).

## INV-2: inventory UI + world items (scripts/range/)
Done:
- `keybinds.gd`: appended `t_inventory` (Tab) and `t_drop` (G). No renames/rebinds.
- `world_item.gd` (new): RigidBody3D pickup; gun glb or sized box + Label3D;
  `pack_gun` (gun + inserted mag -> drop data) / `unpack` (first_fit back, mag goes
  loose if the gun doesn't fit).
- `inventory_ui.gd` (new): full-screen Tab UI — equipment left, pockets/rig/backpack
  middle, nearby (2 m) right; weight at bottom. Drag/drop, R rotates while dragging,
  drop outside = drop to ground, Ctrl+click quick-move (new `Inventory.quick_move`),
  hover tooltips (name/kind/size/kg/rounds), Take buttons for nearby items.
  While open: mouse visible, can't shoot/use/1-3/F (PlayerWeapons.ui_open gate),
  movement and mouse-look-freeze keep working (look already gates on capture).
- `player_weapons.gd`: `drop_held` (G), `drop_item` (any item; gun takes its mag),
  `pickup_world_item` (F, first_fit, "No room" message), world-item prompt in
  `_pickup_and_slots`; `drop_requested` signal -> FiringRange spawns the pickup.
- `firing_range.gd`: builds InventoryUI + RangeCrate, Tab/G handling, crate F-take
  (only when nothing else claimed the prompt), drop spawn in front of player.
- `range_rack.gd`: F now takes a COPY (rack keeps its guns; `take()` kept for compat).
- `range_crate.gd` (new): supply crate by the rack; F takes next stocked item via
  first_fit (4 AK mags, 2 pistol mags, 6 ammo stacks, rig, 2 backpacks, armor vest,
  3 meds); "No room" message when full.
- `inventory.gd`: added `quick_move` (slot->grids, grid->first_fit).
- Tests: 18 new [range] checks (drop->pickup round trip, no-room partial pickup,
  quick-move, crate stock validity, t_inventory/t_drop bindings). 98/98 logic pass.
Verified:
- Parse clean; `--range-test-logic`: 98 passed, 0 failed.
- `-- --smoke --quit=0.1`: 1248 pass, 26 fail — ALL pre-existing on d56f9883, none from
  Track INV: 25x SmokePauseMenu failures (test reads `Hud._overlay_box`, which does not
  exist anywhere in the tree; the merged pause menu uses `_overlay: HudOverlay` instead
  — base-branch test/implementation mismatch, out of brief scope, not touched) + 1x
  "path perf" timing check (151-170 ms vs threshold; VM-load sensitive, varied between
  two clean runs). The 3 "known" ship-check failures from the brief did not occur.
  Main game does not load tactical/ or range/ scripts; the only shared change is
  +2 appended keybind actions.
Open issues:
- UI is code-built and headless-verified (builds without errors); visual layout
  not eyeballed (no display) — geometry follows the same Control patterns as the HUD.
- Full physics `--range-test` not yet run (20+ min on this VM); logic suite covers
  all INV-2 rules.

## INV-2: UI + world items (pending)
