# F147 + F148: full magazines from the gunsmith, bigger rigs

Worktree `../creeper fps td-worktrees/ov-mags`, branch `feat/f147-mags-rigs` (off `port/play-f98-f135`).

## F147: gunsmith offers full magazines (one commit)
Gregory: "the gunsmith should also offer full magazines that you can place directly in your tactical rig."
- In `range/gunsmith_view.gd` (F145 picker), add one extra row under the slots: **Magazines**. Clicking it lists
  every mag item that fits the selected gun (`ItemDefs` kind `mag` with that `gun`), each loaded **full** with
  the gun's default ammo grade (`TacAmmoDefs.CALIBERS[cal][0]`), from supply (unlimited, like parts).
- Click a mag: a new full mag goes into the **tactical rig** (first free spot), else the bags, else say "no
  room" (do not drop to the floor). Dragging a mag onto the rig in the inventory screen keeps working as today.
- Keep `gunsmith_view.gd` under ~250 lines: put the mag list/placement in a new `gunsmith_mags.gd`.
- Use the same inventory call the stash/crate uses to place an item; don't add a new placement rule.

## F148: larger rigs (data, same commit or a second)
- `tactical/item_defs.gd`: add two rigs, larger than `rig_assault` (grid [6,3]):
  `rig_plate` "Plate carrier rig" w3 h3, kg 1.6, grid [8,3]; `rig_heavy` "Heavy assault rig" w4 h3, kg 2.2, grid [8,4].
- Make them available wherever rigs are: the range crate (`range_crate.gd`) and the loadout-room stash/supply.
- Check the inventory UI draws an 8-wide rig grid without overlapping (inventory_ui.gd); if it overlaps, widen
  that panel only.

## Don't change
Existing rigs, Skirmish kit swap (`skirmish_kit.gd`), mag rules, the parts picker behaviour, any other UI.

## Verify
Parse check, boot `staging.tscn` and the range. No new tests (Gregory plays it). Report under 150 words:
commits, files, every behaviour change.
