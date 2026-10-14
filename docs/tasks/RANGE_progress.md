# RANGE progress log

## Phase 1: Core module (done)
- Built `godot/scripts/tactical/*` (config, ammo/weapon/armor/material defs, ballistics, penetration, body_health,
  hitbox_rig, magazine, gun, recoil_model), `scripts/range/{firing_range,range_args,range_test,range_test_logic}.gd`,
  `scenes/firing_range.tscn`, `tools/range.sh`, 24 `t_*` ids + "Tactical" group appended in `core/keybinds.gd`.
- Verified: `--range-test` prints `[range] OK 42`; parse clean; main smoke 1264 PASS, 0 FAIL.
- Notes for next phase:
  - Class is `TacAmmoDefs` (file `ammo_defs.gd`): `AmmoDefs` already exists in `command/ammo_grades.gd`.
  - Bullets spawn at the camera/eye and fly along the aim ray rotated up by `Ballistics.zero_angle(ammo, dist)`;
    `Gun.shot_dirs(aim_basis, ammo, ads, rng)` returns pellet directions. Bullet is consumed on a body hit (no pass-through).
  - `Ballistics` is a Node3D (`auto_step` true = steps in _physics_process); signals `impact`, `body_hit`.
  - Armor lives in `BodyHealth.armor` (zone -> {id, dur}); `equip(id)`; bench loadouts in `ArmorDefs.LOADOUTS`.
  - `Gun.update(dt)` must be called every frame; `release()` on trigger release starts bolt/pump cycle; `inspect()` twice = fix.
  - Wall thickness factor uses `WALL_REF_THICK` 0.02 m (cap 5x); panels' box depth should equal meta `thick`.
  - Zones are named head/thorax/stomach/larm/rarm/lleg/rleg. `HitboxRig` boxes assume a 1.8 m tall figure, feet at y=0.
  - Keybinds: `t_use` F, `t_help` H, `t_crosshair` X (brief gave no key), slots 1-6, `t_sprint` doubles as hold-breath.

## Phase 2: Playable scene (done)
- Added `scripts/range/{range_layout,range_rack,tactical_player,player_weapons,tactical_viewmodel,range_hud,range_menu,
  range_impacts,range_sfx,range_shot,scope_overlay}.gd`; `firing_range.gd` now wires it all. `weapon_defs.gd` gained
  `ads_pos` / `hip_pos` per weapon (tuned by Xvfb screenshots: front sight tip within ~2 px of screen centre).
- Hooks: `-- --weapon=id --ads --look=x,y,z --pos=x,y,z --fire=N --wait=s --reload[=s] [--fast] --crouch --tune --shot=/abs.png`
  (`--tune` paints the gun flat magenta so tip offset can be measured). Prints `[range] fired N impacts M`.
- Verified: parse clean; `--range-test` OK 42; main smoke 0 FAIL; shots in `docs/art/range/<gun>_{ads,hip}.png`.
- Not verified: real mouse/keyboard play (only screenshots + scripted fire/reload), audio, double-tap R timing, hold breath,
  malfunction/inspect UI, lean collision (none), the Esc menu clicking.
- Notes: sniper ADS = 6x scope overlay (model hidden above ads 0.8). Impacts are puffs + hole quads only (targets: phase 3).
  Sfx reuses existing voices via `RangeSfx` (pop/blaster/rifle/boom + crack/tail, tick for clicks).
  Bench station (F) is just a table; the ammo/armor stations come in phase 3. Files outside tactical/range: none.

## Phase 2 review fixes + Phase 3: Targets + feedback (done)
- Fixes: glb colours kept (flat metal override only with `--tune`); hip pose parallel to the view, butt kept out of the lens
  (`HIP_BUTT`, `HIP_YAW` in tactical_viewmodel.gd, hip z derived from model length); booth roof shortened so the sky shows;
  berms 3.5 m; dusk sky (fog no longer flattens it); help panel small, top-left, semi-transparent, full binds.
- Added `scripts/range/{range_dummy,steel_plate,paper_target,range_targets,range_hit_log,range_feedback,range_bench,
  range_test_targets}.gd`. Class is `RangeDummy` (`Dummy` clashes with an existing class). `MaterialDefs` gained `paper`.
- Layout: plates alternate x=+-1.5 at 10..300 m; paper 25/50 m at x=15/17; dummies 15/30/60 m at x=5/9/13; penetration wall
  at 20 m, x=-16..-4 (plywood, plank, sheet metal, brick, concrete) with a dummy 0.9 m behind each; moving dummy rail at
  z=-48 (brief said 50 m; moved so it does not overlap the 50 m plate), x -9..9 at 2.5 m/s.
- Ammo bench (F at the bench, x=5): next ammo grade + refill. Armor station (F at x=1.5, back wall): cycles loadouts, resets all targets, clears the log.
- Hooks: `--armor=0..3`. Shots: docs/art/range/dummy_hitlog.png, penwall_front.png.
- Verified: parse clean; `--range-test` OK 56 (14 new); main smoke 0 FAIL (see commit). `RangeTest.run` now awaits `_wall_checks`
  (before, OK printed before they ran).
- Not verified: real mouse play, audio, moving target hit timing, bench/station prompts by hand, damage-number readability at 300 m.
