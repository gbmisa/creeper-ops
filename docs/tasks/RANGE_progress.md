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
