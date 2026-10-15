# Brief FB-F: Mosin-Nagant bolt-cycling animation (F41)
Gregory, 2026-10-14: "Mosin-Nagant must be bolt-action, with a bolt-cycling animation after each shot."
Branch `feat/fb-f-mosin-bolt`, base `fix/fb-guns`. Agent: Sonnet `feature-dev`, one phase. Read `AGENTS.md`, this brief,
and only the files named here. **Never judge screenshots yourself:** take them and list the paths; Opus judges.

## What exists (don't rebuild it)
- The rule is already bolt action: `"cycle": 1.3` in `tactical/weapon_defs.gd` (`mosin`), `Gun.needs_cycle` / busy kind
  `"cycle"` (`tactical/gun.gd`), HUD "Release trigger to cycle", `PlayerWeapons.action.emit("cycle", secs)`, bolt sound.
- `TacticalViewmodel._on_action("cycle")` only animates guns whose glb has a `FireWBullet` clip. The Mosin glb has none,
  so nothing moves. **But `assets/models/guns/mosin.glb` is rigged:** Skeleton3D bones `Bolt` (rest (0,0,0.6)),
  `BoltHandle` (child, rest (0,0,0.101)), `neutral_bone`.
- Right hand: `range/fp_arms.gd` (`FpArms`) solves IK to the gun's `grip_r` each frame (`update`), and already moves the
  left hand to `mag_l` during a reload (`reload(secs)`): copy that pattern.

## Build (new file `range/bolt_cycle.gd`, class `BoltCycle`; keep `tactical_viewmodel.gd` changes to a few lines)
1. On the `"cycle"` action, for a gun whose model skeleton has a `Bolt` bone and no `FireWBullet` clip, play a procedural
   cycle over `secs` with bone pose overrides: handle **up** (~80-90° about the bore axis, `BoltHandle`), bolt **back**
   (~0.09 m along +Z gun space, `Bolt`), **forward**, handle **down**. Rough split of `secs`: 20 / 30 / 30 / 20 %, eased.
   Measure the true rotation axis and travel on the mesh (the handle must not pass through the stock) and note them.
2. The right hand leaves `grip_r`, follows the bolt handle's knob through the stroke, and returns. Add a per-gun def key
   `bolt_knob` (gun space, the knob at rest) to `mosin`; the hand target = knob transformed by the current bone poses.
3. Small gun roll toward the hand (~8-12°) during the stroke, as in real bolt cycling. Tunables in
   `tactical/tactical_config.gd`.
4. Bots: a bot's Mosin animates the bolt too if the bot body holds a world model with the same skeleton; skip if not
   trivial and say so.

## Must not change
Cycle time, fire rate, damage, recoil, sounds, the AXMC (`sniper`) and every other gun, the ADS pose and sight line
when no cycle is playing, the left hand, `FireWBullet` guns' existing animation, hip/ADS positions.

## Tests (`range/range_test_bolt.gd`, hook into `range_test.gd`)
Mosin fire → `needs_cycle` → cycle: bolt bone z offset peaks ≥ 0.07 m mid-stroke and returns to rest (< 1 mm) by the end;
handle angle peaks ≥ 70°; right hand within 3 cm of the knob at mid-stroke and within 2 cm of `grip_r` after; AXMC
unchanged. Existing range tests untouched.

## Done
Parse clean, `--range-test` 0 FAIL, main `--smoke` 0 FAIL. Shots for Opus (xvfb, opengl3, 1600x900):
`res://scenes/firing_range.tscn -- --weapon=mosin --fire=1 --wait=T --shot=/abs/bolt_T.png` at 4 points of the stroke
(add a hook if `--fire` + `--wait` can't land mid-stroke), hip and ADS. Commit, report every behaviour change, stop.
