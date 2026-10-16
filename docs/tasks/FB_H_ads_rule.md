# Brief FB-H: one ADS rule for every gun (replaces FB-G per-gun numbers)
Branch off `fix/fb-guns` (6182f1d): `fix/fb-h-ads-rule`, worktree `../fb-h`. Progress log: `docs/tasks/FB_H_progress.md`.
Gregory's rulings (2026-10-15): one rule for all guns; viewmodel gets its own near plane (option A, CHANGES.md P6);
the M1911 follows the rule (drop the F50 restore); the P90 has the red dot fitted by default; Opus models real
iron sights where models lack them.

## The rule
ADS is correct when the **rear sight point and the front sight point both lie on the camera's forward axis**
(screen centre), the bore is straight below them (no cant), and the rear point is `relief` metres from the eye.
The barrel sitting a little under the view falls out of the gun's real sight height; nothing is tuned per gun.
With an optic fitted, its two lens-axis points replace the iron points.

## Must not change
Hip pose and hip yaw, ADS FOV/zoom/ADS speed, recoil (both modes), bob, sprint/draw/check poses, scoped-optic overlay
(model hidden while scoped), gun stats except as P90 red dot implies (report it), bots' `butt`, keybinds.
Never weaken a range/smoke check; report instead.

## Phase 1 (Opus, Blender MCP + Godot): sight points and missing sights
- Per gun in `art/gen/mounts.json`: `sight_rear` and `sight_front` (gun space, muzzle -Z). Rear = centre of notch or
  aperture; front = top of the post. Measure from `art/guns_src/gun_ortho.gd` rear/side renders, check in Blender.
- No rear sight: put `sight_rear` at the front point's height (`y`, `x`), where the rear sight would sit.
  No front sight: the same the other way round. The line is then parallel to the bore.
- Model low-poly iron sights (Gregory's scratch style) from reference ADS frames of other games: m4a1, mp5, vector
  (solid rear blocks → aperture), sr25 (flip-up rear above the rail), pkm (sight line clear of the carry handle).
  Opus judges each one in an ADS shot against its reference frame.
- P90: red dot as its default fit (find where default fits live; one data change).
- Optics: `AttachmentDefs.ROWS` gain `lens_rear` / `lens_front` (optic space), or derive from `axis_h` + `depth`.

## Phase 2 (Sonnet `feature-dev`): the solve, the near plane, the check
- `AttachmentMounts.ads_pose(def, sight_id) -> Transform3D`: rotation that sends `front - rear` to -Z with the bore
  below it (zero roll), translation that puts `rear` at `(0, 0, -relief)`. Replaces `ads_pos` y/x, `eye`, mounts `ads_y`
  and the mosin/sr25 x offsets for ADS (hip still reads `hip_pos`).
- `relief` per weapon class in `TacticalConfig` (pistol, notch, aperture, red dot, magnified), starting from FB-G's
  sheet; Opus sets the final values from the reference frames in Phase 3.
- `TacticalViewmodel.base_pos` becomes a pose lerp: hip transform → `ads_pose`, by `a`; recoil/bob/etc. stay added on
  top exactly as now.
- **Near plane (P6):** set `use_z_clip_scale` + `z_clip_scale` on every viewmodel material (gun, attachments, arms,
  hands; the materials are duplicated per viewmodel so world copies aren't affected). Do not enable `fov_override`.
  The camera near becomes one fixed value (0.05, as `fps_mode.gd`); delete `ads_near()` and its lerp. Check the gun
  never draws through walls and its self-shadowing still looks right; report anything off.
- Range check `--ads-check`: for every gun × {irons, each fitting sight}, put it at full ADS with sway, bob and recoil
  off, project `sight_rear`/`sight_front` (or lens points) and the muzzle with `cam.unproject_position`.
  PASS: both sight points within 0.5 px of centre at 1600x900, the muzzle at x within 0.5 px, below centre.
  Replace `range_test_attach.gd:306` (near-plane test) with "the sight is not clipped" via z-clip scale.
- Parse clean, smoke 0 fail, range all PASS. Stop and report.

## Phase 3 (Opus): sheet vs reference
ADS screenshot of every gun (`--weapon=ID --ads --wait=1.5 --shot=...`) beside a reference ADS frame of the same gun
from another game. Rubric: front post centred in the rear sight, post tip on the crosshair, no cant, barrel just visible
below the sights, rear sight apparent size and screen fill close to the reference (adjust class `relief` only), arms
not floating or blocking. Write verdicts into the progress log; model failures go back to Phase 1.
