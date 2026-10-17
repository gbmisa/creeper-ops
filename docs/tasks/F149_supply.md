# F149–F151: ground grid, open bags on the ground, loadout-room SUPPLY selector

Branch from `play/merge-2026-10-17` in a worktree: `git worktree add "../creeper fps td-worktrees/f149" -b feat/f149-supply play/merge-2026-10-17`.
Godot 4.7 (`~/.local/bin/godot`). Follow AGENTS.md. Commit per phase on your branch; never merge.
Done per phase = parse check prints nothing + boot `res://scenes/staging.tscn` and `res://scenes/firing_range.tscn` headless for a few s with no SCRIPT ERROR.
Range suite once at the end (background, summary line only). Known fails: f127, "ragdoll stays connected". Report any other.
Feedback: docs/playtests/feedback_2026-10-16.md F149–F151. Gregory's rulings (2026-10-17) are in each phase.

## Cause (already found, don't re-survey)
In the loadout room (staging_scene.gd) `RangeCrate.build` drops ~80 world items in front of the crate. `InventoryUI.refresh_ground`
(range/inventory_ui.gd:167) places items within 2 m into the 10x14 ground grid (Inventory.GROUND_SIZE) in list order; the grid
fills up, so a rig dragged onto it has no free 4x3 (F149) and a rig dropped by a swap (`_into_slot` → `world.drop_front`) never
shows (F150). Rigs/backpacks may only live in their slot or on "ground" (Inventory.fits). Ground bags can't be opened.

## Phase 1: ground grid nearest-first + open a bag on the ground (F149, F150). Applies on every map.
- **F149 as Gregory hit it:** he dragged the equipped rig off his character, as he drops everything else, and nothing happened.
  `InventoryUI._on_drop` → `_into_grid` / `_into_slot` refuse a rig on any grid or the full ground panel and do nothing, silently.
  Rule: a rig or backpack dropped anywhere it can't go (any grid, a wrong slot, the full ground panel) is dropped on the ground
  (`_to_world`), contents kept. Any other refused drop shows a short message (`weapons.message`) instead of nothing.
- `refresh_ground`: when every nearby item can't fit, rebuild the ground grid in order of distance from the player (nearest
  first). Items that don't fit are simply not shown (as today). When everything fits, keep today's "existing cells kept" behaviour.
  Something just dropped lands in front of the player, so it is near and shows up.
- A rig or backpack on the ground grid gets an "open" action: **double-click** it (pick one and say which). It opens its grid as a
  panel under the ground panel titled `OPENED: <name>`, inside the same inventory screen. Drag in/out, Ctrl+click quick move,
  same rules as rig_g/pack_g (no bags inside bags). It closes when the bag leaves the ground or the screen closes.
  Implement as a new grid loc (e.g. `"open_g"`) in Inventory backed by that bag's `items`, so weights/fits reuse the existing code.
  Don't add it to `Inventory.GRIDS` (it is not carried: carried weight unchanged; `first_fit` must not put things in it).
- inventory_ui.gd is already 321 lines: put the new code in a new file (e.g. `range/inventory_ground.gd`, static helpers).

## Phase 2: SUPPLY selector in the loadout room, opened at the ammo bench (F151 + supply panel)
Gregory: "a loadout selector that lets the player select guns, attachments, meds, supplies, grenades, without them being on
the ground, including full mags". And: the crate's items go in a SUPPLY panel, not on the floor.
- **Loadout room only** (`staging_scene.gd`): stop calling `RangeCrate.build` there. Firing Range keeps its crate + floor loot.
- New data table `tactical/supply_catalog_defs.gd`: categories in this order: Guns, Magazines, Ammo, Attachments, Meds,
  Grenades & utility, Gear (rigs, packs, armor, plates, helmets, headset), Bows (bows, crossbow, arrows, bolts). Build the
  lists from ItemDefs/AttachmentDefs/WeaponDefs kinds where possible, not hand lists. Unlimited supply.
- Ammo bench in the room (`StagingAmmo`): Use (F) opens the inventory screen with the right-hand panel showing **SUPPLY**
  instead of GROUND: category tabs + a scrolling list (rows like GunsmithMags.draw_row). Tab/Esc closes as usual. Opening the
  inventory with Tab elsewhere still shows GROUND.
- Click a row: make the item (`inv.make`, mags full with the default grade, guns with their default fit) and add it:
  equipment kinds go to their empty slot if free, else rig, pockets, backpack (reuse GunsmithMags.give's loop; generalise it).
  No room: message "No room for <name>", nothing on the floor. Drag a row onto a slot or grid works too.
- Dragging an inventory item onto the SUPPLY panel returns it (deleted). Say so in the panel footer.
- Keep today's bench refill as a "Refill held gun + mags" button at the top of the SUPPLY panel (same code as now).
- Panel code in new files (e.g. `range/supply_panel.gd` draw/input, `range/supply_give.gd` placement); InventoryView regions
  gain the supply region only while the bench opened the screen.

## Do not change
Ground/rig rules besides the above, the Firing Range crate and bench, gunsmith (incl. F147 Magazines row), mannequins/presets,
deploy board, weights, item defs numbers, keybinds (no new action ids; use t_use and mouse). No new tests unless something is
hard to see in play. Report (under 250 words): files, every behaviour change incl. side effects, parse/boot/suite results.
