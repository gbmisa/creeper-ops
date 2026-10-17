# BOT-ANIM2 progress (render-judge-fix rounds)

Sheets: `C:/Users/WINKIN~1/AppData/Local/Temp/claude/c--VSC-projects-creeper-ops/6cf3141a-eadf-4ded-9857-1fdc52c9e324/scratchpad/bots/r<N>/`
(probe scene: one row of rifleman, pistol, shotgunner, marksman, boss per state; `_zoom` = the shotgunner close up,
`_strip` = one kind at staggered times / raise progress). r0 = before.

Scores out of 10 ("a soldier standing / moving like a person": hands on gun, joints, no clipping, weight, balance).

| State | r0 | r1 | r2 | r3 |
|---|---|---|---|---|
| Idle, unalerted (patrol carry) | 4 | 7 | 7.5 | 7.5 |
| Idle, alerted (low ready) | 4 | 8 | 8 | 8 |
| Engaged standing | 6 | 6 | 8 | 8 |
| Raise low -> aim | 4 (0.12 s snap) | 8 | 8 | 8 |
| Walk (patrol carry) | 6 | 7 | 7 | 7 (clip cadence, see report) |
| Jog / engaged jog | 7 | 7 | 8 | 8 |
| Sprint | 7 | 7 | 7 | 8 (gun tucked in) |
| Crouch / lean | 7 | 7 | 7.5 (crouch-walk heads level; marksman lean: head off the scope) | 8 (gun follows the head; peek raises the gun) |

## Round 1
- New `BotIdle` (seeded per bot, own RNG): breathing in the chest, slow sway, weight moving leg to leg every 3.5-8 s,
  head glances (30 % spine, 70 % neck; alerted bots look round twice as often). Off while aiming.
- New `BotLegs`: pelvis shift / drop with two-bone leg IK so the feet stay where the clip put them (weight on one
  leg; soft knees when aiming).
- Lowered gun: low ready (muzzle -31 deg) when alerted, patrol carry (-36 deg, 26 deg across the body) on patrol
  (`BotMesh.calm`, set by BotPose). Torso no longer hunches with the muzzle (lean into the gun is its own number).
- Raise eased over 0.28 s (smoothstep), lower over 0.5 s (was linear 0.12 s).
- Worst left: aimed stance holds the gun at chest height, head well above it (no cheek weld); gait roll on the
  shoulders. Patrol walk cadence: walk clip at 2x (clip speed 0.9 m/s vs WALK 1.8), see report.

## Round 2
- Aimed: gun up to the eye line (lift 0.04 -> 0.09 m rifles, 0.05 -> 0.12 m pistols), head onto the stock
  (0.18 -> 0.24 rad), torso into the gun (0.14 rad rifles, 0.12 pistols): cheek weld instead of chest-height gun.
- New `BotHead`: neck yaw + gaze levelled (80 %) before the stock drop / glance pitch; crouch-walkers no longer
  look at the sky. The neck code moved out of BotBody into it.
- Moving: the spine takes back 60 % of the clip's pelvis roll (steadier shoulders and gun).
- Lowered: torso lean 0.12 rad (rifles) / 0.1 (pistols) so the visible head stays near r0's spot (see report).
- Visible head bone vs r0 (bot frame, m): idle r0 (-0.013, 1.565, 0.03) -> r2 x -0.06..0.01, y 1.545..1.565,
  z 0.045..0.1 (sway / weight shift); engaged r0 (-0.04, 1.557, 0.09) -> (-0.02, 1.535, 0.04). Hitbox head (0, 1.66, 0) r 0.12.

## Round 3
- Lean: the hold tilts with the torso and follows the head's extra travel (vs the last unleaned head-to-shoulder
  offset), and the neck rolls back 45 % of the lean: the cheek stays near the stock (was: gun 9 cm above the head
  leaning left, below it leaning right).
- Peek: `BotMesh.peek` (set by BotPose while it wants to lean out) raises the gun like engaged; peek shots used to be
  fired from the low ready.
- Running lowered (3.0 -> 4.2 m/s, eased): gun tucked in toward the chest (`run_at`), pistols most.
- Left as is: sniper support hand wraps the scope (reach_back on long guns), walk / crouch-walk cadence (report).
