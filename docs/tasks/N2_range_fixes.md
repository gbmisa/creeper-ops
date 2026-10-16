# N2: range/Skirmish fixes (playtest 2026-10-16, F69-F80)

Base: `night/2026-10-15`. Each agent owns ONE section, works only in its worktree `creeper fps td-worktrees/n2-<name>` on branch `fix/n2-<name>`, follows `AGENTS.md`, commits there, never merges, reports and stops. Gregory's quotes are in `docs/playtests/feedback_2026-10-16.md` (main repo), rows F69-F80.

## Rules for every section
- Change only what your section names. Must NOT change: recoil curves/feel (Glock 18 climb from 3046a89, Garand recoil, F64 fix da0a47e except where section D says), ADS sight data of guns other than the PKM, Skirmish AI, maps, HUD, keybinds.
- If the fix needs a behaviour change outside your section, stop and report it (the orchestrator writes CHANGES.md; you never do).
- Run `godot --headless --path godot --import` once first (fresh worktree, new class cache).
- Tests: `godot --headless --path godot res://scenes/firing_range.tscn -- --range-test 2>&1 | grep -E "FAIL|PASS|\[range\]" | tail -40` (exits by itself; all must PASS; never weaken or delete a check). Add a check for each fix in a `range_test_*.gd` file, wired in `range_test.gd`.
- Pipe all output through grep/tail. Files under ~250 lines.
- Report (under 250 words): commits, what changed, every behaviour change including side effects, tests run, anything unverified.

## A. Freeze (n2-freeze): F80
Range → Skirmish switch freezes the game for good (last frame: still the range, gun/body against the camera). Path: in-session `RangeMaps.change("skirmish")` (range_menu / firing_range.gd:140) → `change_scene_to_file`, then `FiringRange._ready` with `session.maps.selected == "skirmish"` → `SkirmishGame.start`. A cold headless `--map=skirmish` load showed no errors in 60 s, so suspect the in-session switch: old scene's nodes/statics (static vars, `RangeMaps.pending`, Keybinds, RangeAudio, threads, awaits), or an infinite loop in Skirmish setup with carried-over state. Repro headless by scripting the switch (a debug flag that calls `session.maps.change("skirmish")` after N frames and prints a frame counter after the reload), find the hang, fix the cause (not a timeout). Add a test.

## B. Ammo part 1 (n2-ammo1): F79 then F69
1. **F79: one ammo type per mag.** Gregory: remove per-round ammo grades loaded individually; "people can choose to bring different ammo types, but you don't need to remember that it's loaded hollow point, level three, ...". A Magazine (and a tube/en-bloc/belt load, chamber included) holds ONE ammo type + a count. Ammo types stay as items/loadout choices. Topping up a mag with a different type: replace the contents' type or refuse; choose the simpler and report it. Update Magazine, Gun.fire/reload, InvReload, item_defs, inventory UI text, save/load dicts (`to_dict`/`load_dict`; old saves with per-round lists: take the first round's type).
2. **F69: range reload ignores the inventory.** On maps in `RangeMaps.INFINITE_AMMO`, reload creates a brand-new full mag of the gun's chosen ammo type: no inventory take/return, no stale old mag kept in `Gun.spares`, no `staged`/`finish` round trip. Gregory: "it should ignore the inventory in the firing range, other than picking a loadout for the skirmish". Rewrite it as its own small path (e.g. `RangeReload`), not more branches in InvReload. Reload animations and sounds still play. Test: fire part of a mag, R, repeat 10x per action kind (detachable, enbloc, tube, belt, revolver) → full every time, inventory untouched. Skirmish reloads must keep working from the inventory.
Commit each as its own phase.

## C. Audio (n2-audio): F71, F72, F74
- F71 Garand: `garand_ping` (sox 0.9 s pure sine 2650+3980 Hz, `assets/audio/range/build_samples.py:81`) plays on the last shot (player_weapons.gd:210) AND as the reload `mag_out` (sound_defs.gd:52). Play it once, on the last shot only; give the reload a normal clip-in sound. Replace the sample with a short (~0.25 s), quieter metallic ping (decaying inharmonic partials, fast fade, no hard cut). Regenerate via build_samples.py.
- F74 Colt .44 Magnum (`revolver`): a Garand-like ping when it runs out. Not garand_ping (that is enbloc-only). Find which sample rings (pistol_mag_out / round_in / mode_click in sound_defs.gd:45, dry fire, shell ejection, repeated `round_in` per chamber) and fix it.
- F72 P90 (`smg57`: shot_p90 + tail_ppsh, sound_defs.gd:15) "still plays multiple times" (earlier F35 said "echoes"). Check the sample for baked repeats/echo, the tail, reverb, and double events per shot. Fix so one shot = one shot sound.
Do not change other guns' sounds. Report what each cause was.

## D. Gun animation (n2-anim): F70, F73
- F70 Garand: "the recoil feels fine but the animation causes it to flicker". Find the flicker (viewmodel hide/show, clip mesh swap, en-bloc eject, reload anim frames) and fix it. Recoil numbers unchanged.
- F73 Glock 18: "now the gun pushes back extremely far and ends up clipping with sustained fire". The drawn kick-back accumulates on full auto into the camera. Suspect RecoilEyeRoom / the M8 change (da0a47e, CHANGES.md on night). Cap the drawn push-back so sustained fire never clips; keep the 3 cm eye clearance (F58) and the climb curve (3046a89, data in TacRecoilDefs.GUN_ROWS) exactly.
Take before/after screenshots (Xvfb, `--weapon=garand|glock18 --fire=N --shot=/abs/path.png`, plus `--ads`), save in the worktree under `shots/n2-anim/`, list paths in the report. Don't judge them yourself beyond "rendered"; the orchestrator (Opus) judges.

## E. Sights + ragdolls (n2-sights): F76, F77
- F76 PKM ADS: "sights are still slightly too low on the end. Check the [front post] is placed on the middle dot. I think it's placed in between the two taller sights". The front post must sit on the rear sight's middle dot, centred, at the right height. Fix the PKM's sight data (`mounts.json` / per-gun sight offsets) only. Screenshot `--weapon=pkm --ads`, before/after, under `shots/n2-sights/`.
- F77: "Ensure that the enemy's ragdolls stay rigid, so they're not flopping all over the place." Stiffen Skirmish enemy ragdolls (tighter joint limits, more damping/stiffness); bodies still fall on death. Screenshot a few frames after a kill (`--bots --engage=... --fire=N`). Orchestrator judges the images.

## F. Ammo part 2 (later, after B merges): F75, F78
F75: deploying to Skirmish after the range, the AK was not refilled; guns start loaded, mags full. F78: R with no spare ammo does nothing (no animation).
