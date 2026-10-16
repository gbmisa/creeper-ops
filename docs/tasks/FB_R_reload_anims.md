# FB-R brief: clean reload animations (Opus 5.5 agent, own VS Code session)
Worktree `/home/gregory-milligan/AI projects/creeper fps td-worktrees/fb-reload`, branch `feat/fb-reload` (off
`fix/fb-h-ads-rule` 1f799cf, the FB-H ADS rule). Read in this order and nothing else up front: `AGENTS.md`, this brief,
`CLAUDE.md` section "Change only what Gregory asked for", `docs/tasks/FB_R_trp_reload_spec.md`. Then only the files
you change. Progress log: `docs/tasks/FB_R_progress.md` (create it; update after every step so a fresh session resumes).

## Gregory's words (2026-10-15)
"I need to do animations for reloads. They need to really be cleaned up."
Standing tastes: Tarkov is the target feel (weighty, readable, hands do real work); he likes scratch low-poly Blender
work; every visual verdict needs a picture judged against a reference, by Opus (you), never a cheaper model.

## What exists today (verify, don't trust)
- Logic: `scripts/tactical/gun.gd` (reload / reload_fast seconds per def, `inv_reload.gd`, actions detachable / tube /
  en-bloc / bolt). The viewmodel hears `_on_action("reload", secs)` (`scripts/range/tactical_viewmodel.gd` ~l.117).
- Gun clips: only ak47, garand, m1911, p90, shotgun, sniper glbs carry a `Reload` clip (skinned). glock18, m4a1, mosin,
  mp5, revolver, saiga12, scarh, sks, sr25, vector, pkm have none: single mesh, nothing moves.
- Arms: `scripts/range/fp_arms.gd` IK. During a reload the left hand only lerps `grip_l` -> `mag_l` and back
  (~l.100). The magazine never leaves the gun. The M4A1 uses Gregory's hand-posed arms glb (`arms_pose`,
  `TacticalViewmodel._add_posed_arms`), which has no reload at all.
- Screenshot hook: `scripts/range/range_shot.gd`, e.g. `--weapon=ak47 --reload=0.6 [--fast] --shot=/abs.png`
  (shot taken 0.6 s into the reload). Run under `xvfb-run -a -s "-screen 0 1600x900x24" godot --path godot
  --rendering-driver opengl3 --resolution 1600x900 res://scenes/firing_range.tscn -- ...`.

## Goal
Every player gun reloads with a clean, readable first-person animation, Tarkov style, in phases (spec excerpt):
start (gun rolls/tilts toward the off hand) -> mag out -> old mag hidden/dropped/pouched -> new mag shown from the
body -> mag in (seat push) -> charge on empty only (charging handle / slide release / bolt) -> back to ready.
Both hands follow real points on the gun and the magazine for the whole reload. Per action kind:
- detachable (rifles, SMGs, pistols, PKM box): above; empty vs not-empty reload differ by the charge step;
  quick reload (`reload_fast`) drops the mag instead of pouching it.
- tube (shotgun, saiga if tube): shell by shell, loop per round, pump/rack on empty.
- en-bloc (garand): clip in with the thumb, bolt slams forward. bolt (mosin, sniper): per their real loading method.
- revolver: per its def's action.

## How (your design; keep it data-driven and small)
- One reload timeline per action kind in a data table (phase names, normalized times, gun pose offsets, hand
  targets, mag node visibility), scaled to the logic's `secs`. Don't change any reload duration.
- The magazine must be its own node so it can leave the gun. For glbs without one: split the mag in Blender
  (headless `blender -b`; the Blender MCP may not be connected) and re-export with a `Mag` node, keeping the gun
  mesh's AABB, origin and orientation identical (the game reads size and sight points from them). Reuse the
  existing `Reload` clips only if they look right; replacing them is fine.
- Hands: drive `FpArms` targets from the timeline; fingers stay as they are. For the M4A1 posed arms, propose the
  approach in the progress log and ask Gregory before touching it.
- Files under ~250 lines, `class_name` style of the repo, tunables in data, not logic.

## Must not change
ADS pose and sight alignment (FB-H, frozen, its range checks stay green), recoil, fire, Gun logic and every def
number (reload seconds included), when rounds count, sounds (you may only add hooks a sound could use later), bots,
keybind ids and `user://keybinds.cfg`. **Never touch Gregory's hand or finger poses** in `art/arms_guns.blend` or
the posed-arms glb. **vector.glb and pkm.glb are being replaced on `fix/fb-i`** (scratch models from
`art/guns_src/scratch_gun.py`): don't edit those two; give them the timeline data only and list their mag split as a
follow-up. If a goal needs any of the above to change, stop and write it in the progress log for the orchestrator.

## Phases (stop and report after each; Gregory plays between them)
1. System + AK47 and M1911 (one rifle, one pistol): empty and tactical reloads. Proof: a frame strip per reload
   (6+ `--reload=T` shots, joined into one sheet under `docs/art/reload/`), judged by you against a Tarkov reference
   still or clip you name, with a short rubric (hands on the gun/mag every frame, no clipping into the camera or
   body, the mag visibly leaves and arrives, the pose is readable, the timing matches `secs`).
2. Every other gun except vector/pkm, same proof per gun, one sheet per action kind.

## Verify each phase (from godot/)
Parse: `godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"` empty. Range: `--range-test` all OK,
0 FAIL (add a check per gun: reload ends with the mag node back in place and the hands on their grips).
Smoke: `godot --headless --path . -- --smoke --quit=0.1 | grep -c FAIL` 0 (pre-existing `ship` failures: report only).
Commit on `feat/fb-reload` only, never merge, never push to another branch. Report under 250 words: what changed,
the sheets, any check you added, and every behaviour change, side effects included.
