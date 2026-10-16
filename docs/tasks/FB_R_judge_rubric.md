# FB-R reload judge rubric (Opus judge agent; never the builder, never Haiku)
Gregory 2026-10-15: "animate all guns tonight, have a judge agent look at them and go up to 3 iterations shooting
for a 8/10". Target: every gun's empty and tactical reload scores >= 8.

## Inputs
- Frame sheets in `docs/art/reload/` (one per gun per reload kind, 6+ frames at named times through the reload).
  If a sheet is missing or stale, make it yourself with the `--strip` hook (see `FB_R_progress.md`).
- Reference: Escape from Tarkov's reload for the same weapon family (name the clip or still you compare against:
  e.g. EFT AKM empty reload, EFT M1911 reload, EFT M590 shell load). Timing marks: `FB_R_trp_reload_spec.md`.

## Score 0-10 = sum of (each 0-2)
1. **Hands do the work:** both hands on real points of the gun/mag every frame (no floating, no hand inside the gun,
   left hand reaches the mag well, pouch, charging handle / slide / bolt at the right moments).
2. **The magazine (shells, clip) is a real object:** visibly leaves, is pouched/dropped, the new one comes from the
   body and seats; never pops, never clips through the gun.
3. **Readable pose:** the gun turns/tilts so the action faces the camera, nothing crosses the eye or the near plane,
   the sight/stock never swings through the view, it reads at 1600x900 at a glance.
4. **Weight and timing:** phases match the logic's seconds and Tarkov's rhythm (mag out early, seat push, charge at
   the end only when empty); motion eases, no snaps or teleports between frames.
5. **Correct for the weapon:** the action matches the real gun (AK rock-in, pistol slide release, M4 bolt catch,
   tube shell by shell, Garand en-bloc thumb, Mosin stripper/single, revolver per def).

## Output (append to `docs/art/reload/SCORES.md`)
`| gun | reload | round | score | 1 | 2 | 3 | 4 | 5 | top 3 fixes (concrete: which phase, which number) |`
Be strict: 8 means Gregory would call it clean. Under 8 always lists fixes a builder can act on.
