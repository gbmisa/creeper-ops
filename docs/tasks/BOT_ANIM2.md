# BOT-ANIM2: enemy animations and standing states (orchestrator brief 2026-10-16)

Gregory: "improve the enemy animations and regular standing states", up to 3 iterations.
Worktree: `../tactical ops-worktrees/bot-idle`, branch `feat/bot-idle`. Follow AGENTS.md. Agent: Opus (judges renders).

## Scope (presentation only)
Files: `range/bot_body.gd`, `range/bot_hold.gd`, `range/bot_pose.gd`, `range/bot_mesh.gd`, plus new small helper
files if needed (e.g. `bot_idle.gd`). Read HANDOFF.md's "Bot crouch + peek lean" and "Bot gun hold" sections first:
those are the current state (BotHold: butt in the shoulder pocket, bladed torso, head on the stock when engaged).

Improve how the Scavs look while:
1. **Standing still, unalerted** (guard/patrol pause): today they likely freeze in one pose. Want a believable idle:
   low-ready or patrol carry (muzzle down 30-45 deg), weight on one leg, slow breathing in the chest, occasional head
   turns / glances, small sway; variety between bots (seeded per bot, not all in sync).
2. **Standing alert/engaged**: stable shooting stance (feet apart, knees soft, torso into the gun), clean change from
   low-ready to aim (raise the gun over ~0.2-0.35 s, not a snap).
3. **Walking / jogging / sprint with the gun**: the gun and arms follow the gait without the hands leaving the gun;
   no foot sliding visible at normal speeds if the clip/speed match allows it (report if it needs speed changes).
4. **Transitions**: idle <-> move <-> crouch <-> lean blend (no pops).

## Must not change (gameplay)
Bot AI, decisions, timings, speeds, sight/eye position and shot origin, hitbox sizes and how hitboxes follow the
pose, reaction delays, accuracy. If a look change would move the eye or hitboxes more than ~3 cm, stop and report it
instead. Don't touch the player's viewmodel arms (`fp_arms.gd` is shared: bots call `FpArms.solve`; do not change its
behaviour for bots, roll stays 0 for them).

## Method: up to 3 iterations
Each round: render a sheet of bots (several kinds/guns: rifle, pistol, sniper, PKM if bots carry it) in each state
above from 2-3 angles (the existing `--shot` / `--engage` / `--side` tools in `range_shot.gd`, or a scratchpad probe
script run with `godot --path godot -s <script>`; windowed renders, max 3 at once, never during the headless suite).
Judge each against "a soldier standing / moving like a person": hands on the gun, natural joint angles, no
interpenetration, weight and balance. Fix the worst issues, re-render. Stop after 3 rounds or when nothing scores
below 8/10. Keep the sheets (scratchpad paths in the report) and per-round scores in `docs/tasks/BOT_ANIM2_progress.md`.

## Done means
Parse clean; skirmish boots; range suite in the background, summary only (baseline 1114 pass / 0 fail; 38 known
`ReloadTimeline 'lock'` SCRIPT ERRORs); commit per round on your branch. Report (max 40 lines): what changed per
round, final scores per state, sheet paths, every behaviour change incl. side effects ("none outside the brief" if so).
