# Brief RANGE2: Tarkov inventory, first-person body (legs + arms), stock out of view

Base: `integ/2026-10-09` at the commit that adds this brief. Two independent branches, one worker each:
- **Track INV** (Muse): branch `feat/range-inventory`. Phases INV-1, INV-2.
- **Track BODY** (Muse code, Opus art): branch `feat/range-body`. Phase BODY-0 is Opus (asset), then BODY-1 (Muse).
Progress log: `docs/tasks/RANGE2_progress.md` (one short block per phase: done, verified, open issues).
Read: `AGENTS.md`, this brief, the progress log, and only the files you change or call. Range code: `godot/scripts/range/`,
module: `godot/scripts/tactical/` (must not depend on `range/`).

## Gregory's words (2026-10-14)
"The player character shouldn't see the butt of the gun. Add arms holding the guns and a character, use free assets
if available. When the player looks down, he should be able to see his legs moving. Add an inventory system similar
to Tarkov to test. Not being able to drop guns and holding 6 of them is brutal."

## Must NOT change (hard rule, CLAUDE.md)
- Nothing outside `scripts/range/`, `scripts/tactical/`, `scenes/firing_range.tscn`, `assets/models/operative/`, and
  appended ids in `scripts/core/keybinds.gd` (append only; never rename/rebind; tests set `Keybinds.persist = false`).
- Ballistics, damage, armor, recoil numbers, bot AI, targets, layout, HUD panels you don't own. Ground movement stays
  inertia-free (current `tactical_player.gd`); `carried_kg` keeps its current use in air accel only.
- Main game smoke all PASS; `--range-test` all PASS. Never weaken or delete a check. If a change can't be made without
  touching something else, stop and report it.

## Checks every phase (from `godot/`)
Parse clean (`godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"` empty), `res://scenes/firing_range.tscn
-- --range-test` OK, `-- --smoke --quit=0.1 | grep -c FAIL` is 0. Add new `[range] PASS ...` checks for every rule below.
Commit each phase. No screenshots needed from Muse; Opus judges visuals.

## Track INV: Tarkov-style inventory
**INV-1: data model** (`scripts/tactical/`, no UI; pure logic, testable headless)
- `item_defs.gd`: items with `w`, `h` (grid cells), `kg`, `kind` (`gun`, `mag`, `ammo`, `armor`, `rig`, `backpack`,
  `med`). Guns read size/kg from `WeaponDefs` (add `inv_w`/`inv_h`: pistol 2x1, P90 3x2, AK 4x2, shotgun/garand/sniper 5x2).
  Rigs/backpacks define their own grids (e.g. rig 4x2, small backpack 4x4, big 5x6). Pockets: four 1x1.
- `inventory.gd` (`Inventory`): equipment slots `primary`, `secondary`, `holster`, `armor`, `rig`, `backpack`, plus
  pockets and the grids of the equipped rig/backpack. Item instances are dicts `{ id, uid, rot, count?, rounds? }`.
  API: `fits(grid, item, x, y, rot)`, `place`, `remove`, `first_fit(item)` (slot first, then rig, pockets, backpack),
  `move(item, to)`, `total_kg()`, `equipped(slot)`. Long guns only in primary/secondary or a grid they fit; pistol in
  holster or any grid. Stacks for loose ammo (`count`, max per def).
- **Magazines are items**: `mag` items hold `rounds`. Reload takes the fullest compatible mag from rig, then pockets,
  then backpack, and puts the old one back where the new one was (or first fit). No mag found = no reload, HUD says so.
- `PlayerWeapons` reads guns from the inventory: keys 1/2/3 = primary / secondary / holster. The 6-gun loadout goes.
  Player starts with AK in primary, M1911 in holster, a rig with 3 AK mags + 2 pistol mags.
- `carried_kg` = `Inventory.total_kg()`.

**INV-2: UI + world items** (`scripts/range/`)
- `Tab` (new action `inventory`) opens a full-screen inventory: equipment slots left, pockets/rig/backpack grids middle,
  **ground / nearby** grid right (items within 2 m). Mouse visible, player can't shoot; movement keys still work.
- Drag and drop between slots/grids; `R` while dragging rotates; drop outside the window = drop to ground;
  Ctrl+click = quick move to first fit; hover shows name, kg, rounds. Weight total at the bottom.
- Dropped items spawn as physics pickups (`world_item.gd`: the gun glb or a box, RigidBody3D) in front of the player.
  `F` on a world item picks it up via `first_fit`; no room = HUD message. A new action `drop` (default `G`) drops the
  gun in hand.
- Weapon rack: `F` takes a copy into the inventory via `first_fit` (rack keeps its guns). Add a crate by the rack with
  spare mags, loose ammo, rig/backpacks and armor to test with.
- Tests: fits/rotation/overlap, first_fit order, reload mag swap, drop -> pickup round trip, weight sum, slot rules.

## Track BODY: legs and arms
**BODY-0 (Opus, art, not Muse):** CC0 Quaternius base character + Universal Animation Library, exported to
`assets/models/operative/body.glb` (humanoid skeleton, clips idle/walk/run/strafe L/R/backward/crouch walk, rifle and
pistol hold poses) and `arms.glb` (arms only, same skeleton). Per-gun hand targets go in `WeaponDefs` as `grip_r`,
`grip_l` (Vector3 in gun space). Credits in `assets/models/operative/CREDITS.md`. Opus pushes these to `feat/range-body`
and writes "BODY-0 done" in the progress log; Muse starts BODY-1 only after that.

**BODY-1 (Muse):**
- `fp_body.gd`: the full body under the player, driven by velocity (AnimationTree blend: speed x direction, crouch).
  The local camera never renders the head/neck/arms (render layer or bone scale on a culled copy); shadows still cast
  from the whole body. Looking down shows the legs walking in step with movement; the camera sits at the eyes, so the
  body never clips into view at any pitch or lean.
- `fp_arms.gd`: viewmodel arms on `TacticalViewmodel`, hands placed on `grip_r`/`grip_l` with two-bone IK; arms follow
  ADS, reload (left hand to the magwell during `Reload`), sprint and check poses.
- **Stock out of view:** at hip and ADS the butt is shouldered (sits behind the camera near plane or under the arms),
  never visible. Replace the `ADS_BUTT`/`HIP_BUTT` placement with per-gun data if needed. Sight picture unchanged.
- Tests: body exists and its animation speed follows velocity; arms present for every weapon; hand bones within 2 cm of
  grip targets at hip and ADS.

## Open question for Gregory (do not build)
Inertia scaled by carried weight, once the inventory makes weight real. Logged in `CHANGES.md`.
