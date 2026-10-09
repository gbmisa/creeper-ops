# Notes for Muse (from Opus)

Opus pushes new notes here on `main`. **Before you start or resume a brief, fetch `main` and read this file.** Newest first. A note only changes the brief it names.

## 2026-10-08 (night, later): T, A4 and K start now
- **T** no longer waits for P: measure L1 now and L2 on whatever `main` has (see the brief).
- **A4** branch is up with the models: cannon/mortar/sniper/beam (`_base`, `_turret`, `_arm`) `collector.glb` and `relay.glb` (added in `a4468a5`; pull if you cloned earlier). Don't touch A3's files.
- **K** (`chore/k-split-files`): small refactor of `operative_weapons.gd` and `config.gd`.

## 2026-10-08 (night): X and B merged; P needs fixes before merge
- **Merged to `main`:** `art/3-fx` and `fix/muse-b-bugs` (smoke 0 failures after the merge). Those branches are done.
- **B follow-up (any later brief that touches it):** `operative_weapons.gd` is now 263 lines; split it next time it grows. `config.gd` is about 311 lines; don't add to it without moving a group out.
- **P (`fix/playtest2-pressure`) fails smoke with 9 failures** (main is clean):
  1. Six `L2: hive X has an access kind` failures plus `access kinds are mixed { "": 6 }`. Your `level02.gd` diff dropped the `"access"` tags from the hive rows (for example `"access": "cavemouth"` on Rift). Restore them; your branch must have started from an older `level02.gd`.
  2. Two `castles2 engines` failures: "a target that stays is hit (0.0)" and "an Operative who walks out takes nothing". These are most likely the `engine_range` 40 → 12 change. Update the test setup to stand inside the new range, or keep the rule; say which in the report.
  3. The branch commits 9 `godot/.godot/` files. Remove them (`git rm -r --cached godot/.godot`).
  4. Merge conflict risk: `flyer_ai.gd` changed on both P and `main` (X/B). Rebase or merge `origin/main` into P first, and keep both changes.
  Push again and Opus merges.

## 2026-10-08 (night): new briefs S, T, A4
- **S** (`tools/shot-tour`, branch is up): a `--tour=` file that takes many screenshots in one launch. Start any time.
- **T** (`stage/13-tuning-audit`): measure the balance and propose changes; change no numbers. Opus creates the branch after P is merged.
- **A4** (`art/4-structure-models`): weapons, Collector and Relay use Opus models. Opus creates the branch after A3 and the models are done.
- P, B and X are pushed; Opus is reviewing them now.

## 2026-10-08 (late): A3 task 9 added (Command Node)
`command_node.glb` and task 9 are on `art/3-hive-models` (`997942b`). If you cloned before that commit, pull first.

## 2026-10-08 (late): in-game pass on `art/3-hive-models` → A3 task 0 details
- **Cream glow:** the tier colours are pale (`a8ff5a`, `e6d2ff`, …), and `StructureMeshes.glow(tier.color, 1.0)` makes the emission bloom out to near white. For the creature glow, try an albedo of `tier.color.darkened(0.3)` with an emission energy around 0.5–0.6, so the hue survives. Don't change the tier colours themselves; the UI uses them.
- **Gallery:** `--gallery=anim:wyvern --sim=2 --shot=…` shows the base, not the wyvern, so the camera misses it. Flyers hover, so aim at the model's AABB centre.
- **Wyvern rebuilt** (bigger wings, fire-breath cone on a `fire` bone, shown only in `attack`). It's already on the A3 branch.

## 2026-10-08 (late): A2 merged; A3 branch is up
- Opus merged `art/3-integration` into `main`, plus your `022b25a` (speed_scale, loop at load, flap, the `die()` tree fix), cherry-picked.
- **Don't push `fa76b02` from `art/3-creature-anim` anywhere.** Besides the `.godot` cache it deleted real files (`PLAYTEST2_pressure.md`, `smoke_hive_sites.gd`, `muse1.md`, the L2 playtest json): your push rebuilt the tree from an old base. Before every push, check `git diff --stat origin/<branch>` for deletions you didn't intend. `art/3-creature-anim` is finished; don't use it again.
- The A2 leftovers (gallery camera, perf numbers, low-tier glow colour) are now A3 task 0.
- `art/3-hive-models` exists: start A3.

## 2026-10-08: A3 extended (not started yet, so this is safe)
A3 now also covers `totem.glb` (structure `beacon`) and a new falling `drop_pod.glb` for `@drop` (tasks 7–8). The trebuchet model has also been updated on `art/3-models` (fire-pot payload); Opus brings it in when it creates the A3 branch.

## 2026-10-08: A2 first push checked by Opus (`f59ef5a`)
Parse is clean and smoke reports `OK: 0 failure(s)`. Opus's in-game shot with `--creatures --look=40,74,22` looks good. Two things are left for A2:
- `smoke_creature_anim.gd:138` calls `CreatureAnim.die()` on a node that isn't in the tree, so `creature_anim.gd:157` logs `get_tree: data.tree is null`. Guard it with `is_inside_tree()` in `die()`, or add the test node to the tree.
- Still to do from the brief: task 2 (gallery camera, `--gallery=anim:<id>`) and task 5 (perf numbers). Also check whether the `glow` material on low tiers is meant to come out cream/white in game; Opus expected the tier colour (green on skitters).

## 2026-10-08: hive structure models ready → new brief A3
Opus finished the animated models for the hive core, pit, spitter, launcher, mortar and roost (graded on contact sheets; average 7.75 of 10). The brief is [ART3_A3_hive_models.md](ART3_A3_hive_models.md). Its branch `art/3-hive-models` only appears after A2 is merged, so finish A2 first.

## 2026-10-08: hold-to-fire (Gregory) → brief B (`fix/muse-b-bugs`)
Gregory: "You shouldn't be able to hold down left click permanently. It should build up spread and recoil."
Right now the Pulse Rifle bloom tops out at `bloom_max` 1.4°, and the camera punch recovers between shots, so holding LMB is still a laser.
- **Spread:** held fire should be clearly inaccurate after about 6–8 shots. Raise `bloom_add`/`bloom_max` in `recoil_defs.gd` (try a max of about 5–6°). Keep `bloom_recover` fast, so tapping or short bursts stay accurate.
- **Recoil climb:** add a sustained vertical climb (plus a small random yaw) that accumulates while LMB is held and eases back after release. This is where `RecoilDefs.cam` (task B2) gets used. Add the def keys `climb` and `climb_max`; the numbers are yours to pick.
- Apply the same idea to any other weapon that auto-fires on hold (check plasma and sprayer; the sprayer can stay forgiving).
- **Unchanged:** damage, fire interval, ammo. Time-to-kill when tap-firing must stay the same. Say in your report what the hold-fire accuracy is after 10 shots.
- Ammo reserves are a later design. Don't build them.

## 2026-10-08: S review → one fix (`tools/shot-tour`)
Parse is clean, smoke reports `OK: 0 failure(s)`, and a 4-line Xvfb tour saved every PNG. `look=`, `select=` and `fps=` frame correctly.
**Bug:** `gallery=anim:wyvern clip=attack t=0.5` (after `--demo --sim=60`) saves a wide battlefield view, not a close-up of the wyvern. No `[tour] skip` is printed, so the model is spawned. Likely causes (check, don't guess):
- `_world_aabb` uses `get_aabb()` on skinned meshes; that can be bind-space or huge, which pushes `dist` to the 90 clamp. Print the box size and `dist`.
- The command camera may still be easing toward the previous `select=`/`look=` target, or `cam.update` drifts `target.y` (`smooth_y` lerp) after focus.
- The pad (43, 87) may be off the playable area or hidden under props.
**Fix and prove it:** print `[tour] gallery <id> aabb=<size> dist=<d>` per gallery line. Smoke check: after `_apply_gallery` the camera target is within 1 m of the model, and `dist` is ≤ 3 × the AABB size. Push to `tools/shot-tour` and report. Opus re-screenshots.

## 2026-10-08: playtest → brief Q (`fix/q-spitter-towers`)
Gregory: enemy Spitter Towers on L1 sit underground, shoot from where Snipers can't reach, and pile up. See [MUSE_Q_spitter_towers.md](MUSE_Q_spitter_towers.md). Start now.
