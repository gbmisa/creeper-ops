# Brief FB-A: enemy death ragdoll (F14)
Gregory, 2026-10-14: "make enemy death ragdoll." Skirmish/range bots fall as ragdolls when killed, not a canned clip.
Branch `fix/fb-a-ragdoll`. Base: `integ/2026-10-09` after `feat/mp1` merges (if not merged yet, base on `origin/feat/mp1`).
Agent: Muse or Sonnet `feature-dev`. Read `AGENTS.md`, this brief, and the files below only.

## Today
- `ScavBot._die()` (`range/scav_bot.gd:254`): zeroes hitbox + body collision layers, calls `mesh.die()` → `BotBody.die()`
  (`range/bot_body.gd:98`) which plays the `death` clip; after 8.5 s the bot is freed.
- `ScavBot.on_hit(res)` gets the Ballistics hit dict (`pos`, `origin`, `zone`, ...). Bleed-out deaths come from `think()`.
- The gun hangs off `BotBody.pivot` (right shoulder); FpArms IK holds both hands on it. `update()` already stops IK when dead.

## Build
1. **Physical bones** on the bot skeleton (`BotBody`, at `_init`): a `PhysicalBoneSimulator3D` under the `Skeleton3D`
   with `PhysicalBone3D` capsules for pelvis, spine_01, spine_03, head, upperarm/lowerarm/hand l+r, thigh/calf/foot l+r.
   Sensible joint limits (cone/hinge) so knees and elbows don't bend backwards. Masses roughly human (~80 kg total).
   Ragdoll bodies: `collision_layer = 0`, `collision_mask = TacticalConfig.LAYER_WORLD` only (no player, bullets or bots).
2. **`BotBody.die(impulse := Vector3.ZERO, zone := "")`**: stop the AnimationPlayer, start simulation from the current pose
   (`physical_bones_start_simulation()`), apply `impulse` to the bone for `zone` (fallback spine_03).
   `ScavBot` passes `(res.pos - res.origin).normalized() * TacticalConfig.DEATH_IMPULSE` from `on_hit`; bleed-out passes none.
   New tunables in `tactical_config.gd`: `DEATH_IMPULSE` (start ~250 N·s for a rifle round, scaled by bullet damage if easy),
   optional `RAGDOLL_SLEEP` time after which bones freeze to save physics.
3. **Gun:** on death it detaches into a `RigidBody3D` (layer `LAYER_ITEM`, mask `LAYER_WORLD`), visual only: not lootable,
   freed with the corpse.
4. Ragdoll is a **local cosmetic**: no multiplayer sync (note it in the code per `docs/MULTIPLAYER.md`).

## Must not change
Damage, kill timing, the `died` signal and its timing, the 8.5 s corpse removal, hitboxes off at death (corpses stay
unshootable), loot, kill counts, bot AI, alive bots' animation and IK.

## Tests (`range/range_test_botmesh.gd`)
The "plays death" check tests the old behaviour Gregory replaced: change it to "ragdoll simulating". Add: after a death
with impulse +X and 2 s of physics, the pelvis moved in +X and sits below 0.6 m; no bone below the ground; a bleed-out
death also falls. Don't weaken any other check. Parse clean, `--range-test` all PASS, main `--smoke` 0 FAIL.

## Report
Push the branch, list every behaviour change (the gun drop included), stop. Opus judges the fall on the GPU
(rubric: falls with the shot, limbs within human limits, no jitter or stretched bones, no sinking into the ground).
