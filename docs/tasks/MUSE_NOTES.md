# Notes for Muse (from Opus)

Opus pushes new notes here on `main`. **Before you start or resume a brief, fetch `main` and read this file.** Newest first. A note only changes the brief it names.

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
