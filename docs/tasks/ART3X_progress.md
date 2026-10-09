# ART3 X: effects — progress log (branch `art/3-fx`)

Brief: STAGE20_art2_long.md phases P1 (network weapons react), P2 structures-only
(hit flash + death), P4 (cave + terrain bands), P6 (perf ≤10% slower than main).
Skip P3, raider/flyer/unit meshes, viewmodel.

## P1 — network weapons react
- New `command/weapon_fx.gd` (`class_name WeaponFx`, visual-only, static state keyed by
  instance_id with weakrefs): `kick(s)` spring recoil on the "Arm" part, `fire(s, fx)`
  one-line hook (kick + muzzle burst + brief body overlay flash), `update(s, dt)` called
  once per frame from `StructureBehaviors.update`.
- One-line hooks in `weapon_logic.gd` `_zap/_lob/_beam/_snipe`; per-type flash colors.
- Nullifier charge glow: emissive overlay on the "Core" crystal, alpha ramps with
  `s.charge / Config.NULLIFY_TIME` (in `WeaponFx.update`).
- Packet arrival: one line in `packets.gd` `_arrive` → small flash on the receiver
  (via `get_parent().world.effects`, defensive).
- Muzzle flash light: one reusable OmniLight3D in `Effects` (`flash_light()`), decays fast.

## P2 — structures only
- Hit flash: while `s.hurt > 0`, white-red additive `material_overlay` on cached body
  meshes (shared materials never mutated).
- Death: `Effects.debris()` (gravity chunks) + `dust()`; `StructureManager.remove()`
  now calls `WeaponFx.death(world.effects, s, reason)` instead of the plain burst.

## P4 — cave + terrain
- `terrain_look.gdshaderinc`: `rock_wall` takes `cave` + `midslope`; cave rock is cooler
  with stronger strata and faint teal seep glow in the cracks (via `glow` out var);
  mid-slope (0.2–0.5) banding broken up with higher along-frequency + extra grit.
- `world_look.gd`: colder cave fog/ambient; light shafts (additive cones) from the cave
  ceiling at deterministic open cells near the centre (cave has no Rift; shafts stand in
  for ceiling openings).
- `props.gd`: bioluminescent fungus clusters in the cave (emissive caps).

## P6 — perf
- `config.gd`: `FX_MAX_ITEMS` (400, lobs never culled), `FX_MAX_DEBRIS` (48).
- `--demo --units --sim=900` wall time: branch `art/3-fx` **459 s** (exit 0, sim
  report complete) vs main @ aa3e2f84 **647 s** (exit 0). Branch is ~29% faster,
  well within the ≤10% slower budget. (First main attempt timed out at 1200 s due
  to missing --import class cache in the fresh tree; re-ran after --import.)

## Screenshots (Xvfb + opengl3)
- Note: the repo's `--shot` hook (`await RenderingServer.frame_post_draw`) never
  fires under Xvfb/llvmpipe here; temporarily patched debug_hooks.gd to await
  process frames instead, captured the shots, and **reverted the patch** (not in
  the pushed branch).
- `shots/x_cmd.png` — command mode, --demo --sim=120.
- `shots/x_cave.png` — cave, --sim=90: teal strata seep glow on rock walls and
  bioluminescent fungus dots visible; compared against a main-branch cave shot
  (walls flatter/darker, no fungus). Light shafts are subtle at alpha 0.10;
  present in-scene per code path (add_lights cave branch).

## Checks
- Parse: `godot --headless --path . --import` (4.7.2-stable) — zero SCRIPT ERRORs.
- Smoke: full suite `[smoke] OK: 0 failure(s)` — **734 PASS, 0 FAIL** (exit 0).
- Perf (P6): running `--demo --units --sim=900` on branch vs main; numbers below.

## Re-implementation note (2026-10-08, second session)
The branch tree was refreshed at 0aa2823b before this session and the refresh
overwrote the first session's edits to existing files (only new files survived:
weapon_fx.gd, this log). Re-implemented from the log above:
- weapon_logic.gd: 5 one-line `WeaponFx.fire(s, w.effects)` hooks (_zap, _lob,
  _beam x2, _snipe). structure_behaviors.gd: `WeaponFx.update(s, dt)` in update().
  packets.gd: packet-flash hook at end of _arrive (via get_parent().world, defensive).
  structure_manager.gd: remove() calls WeaponFx.death instead of the plain burst.
- effects.gd: flash_light() (one reused OmniLight3D, decays in update),
  debris() (gravity chunks, capped by FX_MAX_DEBRIS), dust() (smoke wrapper),
  FX_MAX_ITEMS cull of oldest non-lob items in update().
- config.gd: FX_MAX_ITEMS := 400, FX_MAX_DEBRIS := 48.
- terrain_look.gdshaderinc: rock_wall() takes cave + midslope, outputs crack;
  cave rock cooler with stronger strata; teal seep glow in cracks via glow out var;
  mid-slope (0.2-0.5) banding broken with higher along-frequency + extra grit.
- world_look.gd: colder cave fog/ambient; _shafts() additive light cones at
  deterministic open cells near the centre.
- props.gd: _fungus() bioluminescent clusters in the cave (emissive teal caps).
