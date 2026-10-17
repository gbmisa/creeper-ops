# Overnight 2026-10-16: F137-F144 (Gregory: "create a plan and work on all of these overnight")
Base: `port/play-f98-f135` @ 7bc8502+. One worktree + branch per track under `../creeper fps td-worktrees/`.
Agents follow AGENTS.md: only their brief, commit on their branch, never merge. Opus reviews, judges images, merges.
Every agent: parse check clean, boot the scene it changed, run `--range-test` once at the end (expect FAILED 1 =
the old f127), report under 250 words: files, every behaviour change, anything left. New/changed tunables go in a
def table or TacticalConfig. Files under ~250 lines. Never touch user://keybinds.cfg. Don't change anything not
named in your brief; if a fix needs it, write it in CHANGES.md (next free P number) and stop that part.

## OV-RAG (F144) ragdoll: ../ov-rag, feat/f144-ragdoll, feature-dev sonnet
Files: godot/scripts/range/bot_body.gd (RAGDOLL tables, _make_pbone, die()), tactical_config.gd RAGDOLL_*, a
new small helper if bot_body grows past ~250 lines, range_test_ragdoll.gd.
Known cause: physical bones have collision_layer 0 and mask WORLD only, so limbs pass through the torso and each
other; joint ranges are 0.35x anatomical (F77) and capsules may overlap at rest.
Do: (1) new LAYER_RAGDOLL in TacticalConfig (next free bit; bullets, player, bots and items must still ignore
corpses); bones on it, mask WORLD|RAGDOLL; add collision exceptions only between jointed neighbours and pairs that
overlap at rest (clavicles/spine/neck/upperarms, thighs/pelvis), so arms hit the torso and legs hit each other.
(2) Joint limits back to anatomical-ish per bone (no global 0.35 cut): knees/elbows hinge one way, spine small
cone, neck limited, shoulders/hips wider; joint softness/bias so it doesn't jitter. (3) Logical fall: start the
ragdoll with the bones' current velocities (from the last two animated poses) plus the existing kill impulse, so
the body crumples from the pose it was in; mass per bone stays from the table. (4) More physics solver
iterations only if needed for stability (project setting; say so in the report).
Shot hook: add `--ragdoll-shots=/abs/dir` (or reuse an existing hook) that kills a bot standing, one crouched, one
running, and saves frames at 0.0/0.3/0.7/1.5/3.0 s from a side camera under xvfb-run (opengl3). Do NOT judge them
yourself; list the paths. Test: no limb capsule centre inside the torso capsule after 3 s, for the 3 cases.
Don't change: hitboxes, bot animation while alive, death timing/sleep (RAGDOLL_SLEEP), loot on corpses.

## OV-MAP (F137) Skirmish 2 stairs: ../ov-map, fix/f137-stairs, level-builder sonnet
Map = skirmish_large (scripts/range/skirmish_large_*.gd, skirmish_parts.gd ramp()). Player spawns are in
skirmish_large_data/game. Find every "stairs" ramp (SkirmishParts.ramp draws treads on a sloped box) and any
stair-looking geometry; for each, report slope vs the player's floor_max_angle and step/snap settings, and
whether a bot path uses it. Fix the ones near the player spawns first, then all others: every ramp the player
and bots can walk up and down (lengthen/landing, or real step boxes within the player's step height). Re-bake
check: the navmesh covers them. Don't move buildings, cover, loot, bots or extracts. Shots: one per fixed ramp
(under xvfb-run) listed for Opus; don't judge them.

## OV-ZERO (F142) sight zero pass: ../ov-zero, fix/f142-zero, feature-dev sonnet
Files: art/gen/mounts.json (sight points, rails), attachment_mounts.gd, attachment_rig.gd, ads pose code, tests.
Rule (FB-H, frozen): ADS puts the gun's rear+front sight points on the camera axis. Optic reticles (red dot,
holo, any scope) must sit on that same axis when fitted on every gun that takes them: the reticle centre projects
to screen centre in ADS, and the bullet at the zero distance lands on it. Do: a test that, for every gun x every
optic it accepts, fits the optic, enters ADS, and checks (a) reticle quad centre within 2 px of screen centre at
1920x1080, (b) the bore line at zero range hits within 2 px of the reticle; fix failing data (mount heights,
optic eye offsets), not the rule. Then an ADS contact sheet of every gun x optic (existing --weapon/--ads/--fit/
--shot hook) for Opus. Don't change iron sights that pass, recoil, FOV, or the ADS rule itself.

## OV-SMITH (F141, F143) gunsmith station: ../ov-smith, feat/f141-gunsmith, stage-runner sonnet (2 phases)
Files: range_workbench.gd, range_bench.gd, inventory_ui.gd (+ new gunsmith_*.gd files), station props.
P1 (F141): the range stations (workbench, ammo bench, armor station, deploy truck) stop being coloured boxes with
floating text: use prop models (assets/models/props, or simple built low-poly bench/rack/locker shapes in the
look_* style) with a small sign. Using the workbench opens a gunsmith screen: gun list (the player's guns) on the
left, a live 3D preview of the selected gun with its fitted attachments in the middle (SubViewport, drag to
rotate, uses the same glb + AttachmentRig placement as the viewmodel), slots + the player's spare attachments on
the right; fitting/removing works as the inventory drag does today (same rules, same data). The text prompt
stays as the in-world hint only.
P2 (F143): while an attachment is dragged (gunsmith and inventory UI), every slot/gun it can go on turns green and
every one it can't turns red; colours clear on release or cancel. Uses the existing compatibility check.
Don't change: attachment rules/compatibility, inventory grid rules, keybinds, the ammo/armor behaviours.

## OV-STAGE (F139, F140) waiting room: ../ov-stage, feat/f139-staging, stage-runner sonnet (2 phases)
Start after OV-SMITH P1 merges (uses the new stations); branch from the play build at that point.
P1 (F139): new scene staging.tscn (RangeMaps id "staging"): a small loadout room (hideout look) with the stash /
inventory, gunsmith workbench, ammo bench, med/utility pickups as on the range, and a deploy board: choose
Skirmish or Skirmish (large), then deploy with the kit (same kit-persist + SkirmishKit.deploy path the truck uses).
Title "Skirmish" and "Skirmish (large)" go to staging with that map preselected; the range truck also goes there.
P2 (F140): three mannequins in the room. Each shows a saved gear preset on a body model (worn armor/rig/helmet/
guns). Interact: Save current kit to this mannequin / Equip this preset (items come from what's available as
on the range today) / Rename. Presets saved in user://presets.cfg (new file; tests use a temp path).
Don't change: the Skirmish maps, the range layout except the truck target, kit-persist rules.

## OV-CRIT (F138) Opus: map critique
Opus screenshots skirmish_large (spawns, lanes, districts) and writes docs/tasks/SKIRMISH2_redesign.md: what's
bad, a proposed redesign, for Gregory's ruling in the morning. No rebuild without his ruling.

## Merge order
OV-ZERO -> OV-SMITH -> OV-STAGE; OV-RAG and OV-MAP any time. Range suite on the play build after each merge.
