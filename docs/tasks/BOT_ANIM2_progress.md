# BOT-ANIM2 progress (render-judge-fix rounds)

Sheets: `C:/Users/WINKIN~1/AppData/Local/Temp/claude/c--VSC-projects-creeper-ops/6cf3141a-eadf-4ded-9857-1fdc52c9e324/scratchpad/bots/r<N>/`
(probe scene: one row of rifleman, pistol, shotgunner, marksman, boss per state; `_zoom` = the shotgunner close up,
`_strip` = one kind at staggered times / raise progress). r0 = before.

Scores out of 10 ("a soldier standing / moving like a person": hands on gun, joints, no clipping, weight, balance).

| State | r0 | r1 | r2 | r3 |
|---|---|---|---|---|
| Idle, unalerted (patrol carry) | 4 | 7 | | |
| Idle, alerted (low ready) | 4 | 8 | | |
| Engaged standing | 6 | 6 | | |
| Raise low -> aim | 4 (0.12 s snap) | 8 | | |
| Walk (patrol carry) | 6 | 7 | | |
| Jog / engaged jog | 7 | 7 | | |
| Sprint | 7 | 7 | | |
| Crouch / lean | 7 | 7 | | |

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
