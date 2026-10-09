# Opus visual plan (long horizon, 2026-10-08)

Opus does visual work only. Muse codes (see [muse1.md](../../muse1.md)). Grading is done by a Sonnet subagent that reads images; Opus reads the verdict in words, plus at most one image per fix. **Target: every item ≥ 8/10, at most 3 grade→fix iterations per item.**

## 1. Creature models (branch `art/3-models`): grade loop
Sheets: `art/blender/review.sh <id> <png>` (5 clips × 4 frames). Grader prompt: score 1-10 per model, fixes for any under 8. Iterate ≤ 3 times. Log scores in `ART3M_progress.md`.

## 2. In game (after Muse's brief A `art/3-creature-anim` lands)
Merge A + `art/3-models` in a scratch worktree → parse/smoke → Xvfb shots: `--gallery`, then `--demo --sim=120 --look=x,z` on a raid. Grade in-game readability from the RTS camera and the FPS view (≥ 8). Fix scale and contrast problems in Blender (tier glow visibility from above, silhouette size). Perf: `--demo --units --sim=900` wall time ≤ +10% vs main. Merge, push main.

## 3. New models (same pipeline, after 2)
- **Enemy structures** (`hive_meshes.gd` parts): pit, spitter tower, launcher, mortar, roost. Idle pulse + `attack` (fire) + `die` (collapse). Muse adds the loader hook (one brief).
- **Castle trebuchet** (`castle_engine_meshes.gd`): wind-up and throw animation. Pairs with playtest-2's trebuchet TTK fix.
- **Command Node, Totem, drop pod**: landing, lift-off and deploy animations.
Each one gets a grader pass (≥ 8) before its Muse hook brief is written.

## 4. Visual review of Muse's visual-code branches
`art/3-fx` (X), `fount/ui-pass`, `stage/21b-castles-detail` (C): Xvfb before/after shots → grader ≥ 8 → findings go back to Muse as a fix brief (Muse doesn't edit by look; it gets concrete notes).

## 5. Logged for Muse (not yet briefed)
- FPS view: camera ends up inside large orange structure geometry (seen in the UI-pass shots). Repro + fix.
- Weapon label shows "[1] Pulse Rifle" where STAGE18c wanted "Crossbow" (check which is right after 23's Pulse Rifle + crossbow on Y).
- Seed the RNG for `--sim` runs (part of brief P).

## Rules learned
- Once Muse starts a branch, never move it (Opus fast-forwarding briefs onto it showed up as a "concurrent push" for Muse). Put brief fixes in a new note on main and tell the user to paste it.
- Strip `godot/.godot/` at merge; Muse's API push ignores `.gitignore`.
