# Task B progress (fix/muse-b-bugs) — 2026-10-08

## B1: FPS camera inside orange mesh — FIXED (spawn moved)
- **Found via probe:** the "large orange curved mesh" is the great bronze gear
  (`TorusMesh`, 4.6 m diameter) on the east face of Salvage Engine **e5**
  (Ruined Forge at L1 cell 22,42), plus its gear teeth. The `--surface` debug
  spawn dropped the Totem at `rift.x + 12` = cell (26,42), putting the Operative
  at (26,41) — 2.6 m from the gear, facing directly into it (yaw PI/2 = west).
  Camera was not literally inside the AABB, but the gear filled the spawn view.
- **Fix:** `godot/scripts/core/debug.gd` — `--surface` now drops at
  `rift.x + 16` (was `+12`), giving ~10 m clearance from e5's gear while keeping
  the Rift in view. The gear mesh itself is correctly placed (art intent), so the
  spawn position was the wrong one.
- **Smoke:** new checks in `godot/scripts/core/smoke_deploy.gd` (`_spawn_cam`,
  `_spawn_cam_l2`, `_near_meshes`) — at Operative spawn on L1 (via `fps.enter`
  at the `--surface` spawn cell) and L2 (engine meshes vs the analogous spawn
  point), no visible `MeshInstance3D` AABB (excluding the viewmodel and terrain
  chunks, whose broad AABBs always contain the camera) contains the camera
  position. The spawn move itself was verified by Xvfb screenshot (clean view).

## B2: RecoilDefs.cam wired in — DONE
- `godot/scripts/fps/viewmodel_motion.gd`: new `cam_scale` (default 1.0);
  `cam_pitch()` now returns `k * VM_CAM_KICK * cam_scale`.
- `godot/scripts/fps/operative_weapons.gd` `kick()`: sets
  `motion.cam_scale = r.cam` per shot. Rifle (cam=1.0) keeps today's feel.
- `cam` also scales the new sustained climb (see below).

## Hold-to-fire (MUSE_NOTES.md 2026-10-08, Gregory via Opus) — DONE
- `godot/scripts/fps/recoil_defs.gd`: rifle `bloom_add` 0.28→0.8,
  `bloom_max` 1.4→5.5 (bloom_recover stays 6.0, so tap-fire stays accurate);
  new `climb`/`climb_max` keys per weapon
  (rifle 0.004/0.045, crossbow 0.006/0.02, rocket 0.008/0.03, railgun 0.006/0.025,
  plasma 0.001/0.02, demo 0.006/0.025, sprayer 0.0/0.0 — forgiving).
- `operative_weapons.gd`: `climb`/`climb_yaw` accumulators grow per shot while
  LMB held (scaled by `cam`, capped by `climb_max`, plus small random yaw drift);
  both ease back at `Config.CLIMB_RECOVER` (0.15 rad/s) after release.
- `fps_mode.gd`: `kick_pitch`/`kick_yaw` now add `weapons.climb`/`climb_yaw`.
- Plasma (hold-to-fire) gets a small climb; sprayer stays forgiving (no climb).
- Damage, fire interval, ammo untouched. Tap-fire TTK unchanged (climb and bloom
  only accumulate while held; bloom_recover is fast).
- **Hold-fire accuracy after 10 shots:** bloom = min(10×0.8, 5.5) = **5.5°**
  (reached at ~7 shots); climb ≈ 0.04 rad (~2.3°) sustained. At 5.5° spread the
  rifle is clearly inaccurate vs ~1–2 m targets past short range.
- **Smoke:** `smoke_fps_feel.gd` `_gunfeel` now checks cam wiring (rocket 1.4,
  rifle 1.0), 10-shot bloom ≈5.5°, climb accumulates capped, and climb eases back
  after 1 s of release.

## B3: "[1] Pulse Rifle" label — NO CHANGE (already correct)
- Stage 23 brief: slot 1 `rifle` = **Pulse Rifle**, label "Pulse Rifle" everywhere.
  Keybind `rifle` = KEY_1. `OperativeWeapons.label()` correctly shows
  "[1] Pulse Rifle" when the rifle is held and "[Y] Crossbow …" for the crossbow.
  The STAGE18c issue (rifle label while holding crossbow) is already fixed by the
  per-weapon `match` in `label()`. Nothing to change.

## B4: hud.gd split — DONE
- New `godot/scripts/ui/hud_alerts.gd` (`class_name HudAlerts`): owns the center
  banner alert and the placement-reason panel (build, `alert()`, per-frame `tick()`,
  reason show/set).
- `hud.gd`: 246 → 216 lines. Keeps a thin `alert()` delegate so the 5 existing
  `g.hud.alert(...)` callers are unchanged.

## Validation
- Parse (`--import`): clean, zero SCRIPT ERRORs.
- Smoke (`-- --smoke`): **744 PASS / 0 FAIL** (full suite). Includes the new
  B1 spawn-camera checks (L1+L2), the B2 cam-wiring check, hold-fire bloom/climb
  checks, and the updated tap-fire TTK check (4 shots, 4 hits). The one earlier
  FAIL was the pre-existing TTK check expecting max-bloom to hit 4/4; updated to
  tap-fire per Gregory's hold-fire design.
- Screenshots: Xvfb, `--demo --sim=60 --surface --shot=...` — before: camera
  2.6 m from Engine e5's bronze gear, view filled; after: clean spawn view.
- TEMPORARY `--camprobe`/`--spawncam`/`--feeltest` debug hooks in `debug.gd` —
  all REVERTED before push.

## Uncertainties / notes for Opus
- The brief said "inside"; the camera was 2.6 m away facing the gear, not inside
  its AABB. Fixed the spawn (moved), not the mesh. If the intent was literally
  "inside", the mesh was never the container.
- L2's `--surface` spawn was already clear (nearest engine 19 cells away); the
  L2 smoke check guards against future level edits.
- Ammo reserves not built (per note).
