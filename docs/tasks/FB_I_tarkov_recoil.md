# FB-I recoil: Tarkov-only recoil + hip fire (F56, F63, F52, F54)
Branch `fix/fb-i-recoil` (worktree `../fb-i-recoil`), cut from `fix/fb-i` after items F59/F55/F62 are committed there.
Follow AGENTS.md. Progress log: `docs/tasks/FB_I_tarkov_recoil_progress.md`. ≤2 phases per agent.
Source of truth: `docs/tasks/FB_I_trp_recoil_spec.md` (TRP's read-out of Tarkov's `NewRecoilShotEffect`, measured
against the game, Apache-2.0; credit it in the code header). Port its formulas; don't invent a different model.

## Gregory's words
- F63 (2026-10-15): "make it like tarkov, don't even make a classic version, do research on projects that notate the
  effects and how it calculates vertical and horizontal recoil with a little bit of randomness with each shot, this is
  a massively important aspect of game design to get right." Earlier: hip fire's first shot should go to the dot.
- F52: Tarkov recoil has no camera kick, only the gun rises. F54: bullets ignore barrel/recoil direction.
- F56: Tarkov recoil, live tuning panel, he A/Bs.

## Behaviour changes this brief makes (all asked for)
1. The classic recoil path and the recoil toggle are removed; Tarkov is the only model (player side; bots unchanged).
2. Bullets leave along the barrel (the rotation process's current angle + hip offset), not the camera ray.
3. The camera gets its own kick (camera process) and follows the muzzle while aiming (spec "Onto the camera").
4. The weapon kicks back along the bore (position process) and rolls by the weapon curve.
5. Hip fire: the `HIP_CONE_DEG` random cone is removed. Hip inaccuracy = the spec's hip gain + muzzle wander. **At rest
   the barrel points exactly at the hip dot** (deviation from TRP: wander amplitude is `sqrt(gain)`, not
   `1 + sqrt(gain)`, so with no recent shots the first shot lands on the dot). MOA dispersion stays (all shots).

## Phase 1: the model (pure logic, `scripts/tactical/`)
- Replace `RecoilModel` internals with the spec: three springs (weapon rotation, weapon position, camera rotation),
  `Shoot(strength)` with the three random draws in order, shot groups, stable mode from `RecoilStableIndexShot`,
  progress multiplier, return path with settle point, hip gain + wander, weapon curve. Fixed 60 Hz step with an
  accumulator; blend between the last two steps for drawing. Split into files <250 lines (e.g. `recoil_springs.gd`,
  `recoil_model.gd`, `hip_wander.gd`).
- Per-gun params: new `recoil` sub-dict in a table `scripts/tactical/recoil_defs.gd` keyed by gun id with the spec's
  names (force_up, force_back, angle, dispersion, camera, convergence, damping, category_mult, stable_shot, hip_gain,
  hip_delay, hip_speed, return_offset...). The AK47 row = the spec's AKM values exactly. Other guns: scale force_up /
  force_back from the AK row by each def's existing `up` (and `side` → dispersion) relative to the AK47's, keep the
  rest; list the table in the report. Attachments keep scaling via `stat("up")` / `stat("side")` → the `parts` term.
- Range check `range_test_recoil.gd` (rewrite the classic checks; never delete a non-recoil check): AK47 standing,
  seeded, 40 runs: one hip shot muzzle peak 1.56-1.99 deg at ~0.14 s, back 15-25 mm, camera ~0.79 deg; aimed peak
  1.17-1.51; auto 600 rpm muzzle at shots 2-5 about 1.67/2.62/3.73/5.27 (hip) ±10%, held 5.3-9.5 from shot 7.
  Hip at rest: bullet direction within 0.01 deg of the hip dot ray. Same seed → same numbers.

## Phase 2: wiring + tuning panel (`scripts/range/`, `scripts/tactical/gun.gd`)
- `PlayerWeapons` / `TacticalViewmodel` / `Gun.shot_dirs`: bullets along the barrel (behaviour change 2), camera kick
  (3), kick back + curve on the viewmodel (4), hip as above (5). Remove `recoil_mode`, the toggle in the range menu and
  its save key (keep reading an old save without error). ADS must stay aligned: when not firing and at rest the sight
  line is exactly where FB-H puts it (its range checks stay green unchanged).
- Live tuning panel (range only, a new keybind action in `Keybinds.DEFAULTS`, e.g. F7): sliders for the current gun's
  recoil row + global stance factors, values applied live, "print row" writes it to the log in GDScript form.
- Re-run every range check, smoke, and an Xvfb shot pair: AK47 hip and ADS mid-burst (Opus judges, not you).

## Must not change
FB-H ADS pose and sights (frozen), viewmodel models/arms, damage, rpm, mags, reloads, sounds, ballistics/zero, bots'
aim and recoil, skirmish rules, keybind ids or the player's `user://keybinds.cfg`. Never weaken a check to pass.

## Verify
Parse clean, `--range-test` 0 FAIL, smoke 0 FAIL (pre-existing `ship` failures: report only). Report <250 words:
what changed, the recoil table, check numbers vs the spec's, every behaviour change incl. side effects.
