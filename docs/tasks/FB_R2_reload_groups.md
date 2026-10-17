# FB-R2: reload review, hand placement rounds, new reload groups (orchestrator brief 2026-10-16)

Gregory: "review all the gun positions and reload animations, plan out and enact more groups of animations ... up to 3
iterations for hand placement on reload animations". Worktree `../tactical ops-worktrees/reload-groups`, branch
`feat/reload-groups` (base: viewmodel arms with forearm twist bones, `ArmTwist`, and the M4A1 unbaked: it now uses
the IK arms like every gun). Follow AGENTS.md. Agent: Opus (you judge every sheet yourself).
Read first: this brief, `FB_R_reload_anims.md` (original brief: goal, must-not-change list still applies),
the tail of `FB_R_progress.md`, `docs/art/reload/SCORES.md`, `FB_R_judge_rubric.md`. Log: append to FB_R_progress.md.

## Step 0: port session B's uncommitted WIP (it is the base for the rifle work)
`git apply "C:/Users/WINKIN~1/AppData/Local/Temp/claude/c--VSC-projects-creeper-ops/6cf3141a-eadf-4ded-9857-1fdc52c9e324/scratchpad/sessionB_reload_wip.patch"`
(from creeper-ops; same paths): the 4 rifles' empty-tail fix (charge phases skip `pose_shift`, AR press = catch +1.5
cm in + hold, SKS/Saiga charge points from a mesh probe, swing-in >= 0.35 s) and `HANDS["lock"]` (fixes the 38
`_anchor 'lock'` SCRIPT ERRORs). Commit it alone ("port session B reload WIP"), then judge it in round 1.

## Step 1: review (all rigged guns, plain / fast / empty)
ak47, m1911, glock18, mp5, p90, scarh, sr25, saiga12, sks. Re-render sheets with the current arms (the twist bones
change how wrists/forearms look) and score them with the rubric. Hand placement is the focus: palm and fingers on
the mag / mag well / charging handle / bolt catch, wrists natural, forearms not crossing the camera, the left hand
never floating off the part it moves.

## Step 2: up to 3 hand-placement rounds
Fix the lowest scores (anchors in `reload_rigs.gd`, `HANDS` frames, plan poses/weights), re-render, re-score. Stop
at 3 rounds or when all are >= 8. Scores per round in SCORES.md.

## Step 3: new reload groups (plan + enact, in this order; stop when out of budget and list the rest as next)
1. **m4a1**: `ar` plan rig (mag region cut, bolt-catch points from a mesh probe).
2. **vector**: detachable, straight mag (pistol-like well under the receiver): a rig on an existing plan or a small
   new one. **mosin** and **sniper** (detachable box mag + bolt, `cycle` > 0): box-mag rig; on empty the bolt is
   worked (reuse `BoltCycle` / the bolt hand if that is the simplest honest route).
3. **pkm**: belt box: box off/on, cover open, belt laid, cover closed (new `belt` plan; long reload, 7 s).
4. Non-detachable actions (today `ReloadTimeline.make` returns null unless `action == "detachable"`): **shotgun**
   tube (shell by shell from a side carrier/pouch, loop per round, pump on empty), **garand** en-bloc (clip pressed in
   with the thumb, hand clears, bolt slams), **revolver** (cylinder out, eject, speedloader/rounds in, close). The
   logic's reload seconds and when rounds count must not change; the animation follows `secs` as today.
Each new group: a sheet per variant, judged >= 8 or listed with its score and what blocks it. Add each new gun to
`RangeTestReload.IDS` if the existing checks fit it (they are the safety net for mag/hand/bolt returning home).

## Must not change
Everything in FB_R's list (ADS/sight alignment, recoil, fire, def numbers incl. reload seconds, round counting,
sounds except existing hooks, bots, keybinds). The viewmodel arms' gun-hold grip points (`grip_r`/`grip_l`, hip and
ADS poses) belong to the orchestrator's parallel branch: don't edit them; if a reload needs one moved, report it.
Sounds: the `mag_in` mark now plays the insert sound when the mag seats (0105c26): keep a `mag_in` mark on the
phase where the mag seats in every plan you add.

## Done means
Parse clean; firing range boots; range suite in the background, summary only (baseline 1114 pass / 0 fail; the 38
`'lock'` SCRIPT ERRORs should drop to 0 after step 0); commit per step on your branch. Renders: windowed, max 3 at
once, never while the headless suite runs (it hangs). Report (max 50 lines): per gun/variant final score, sheet
paths, groups done/not done, every behaviour change incl. side effects.
