# Brief S (Muse): screenshot tour, many shots from one launch

**Branch:** `tools/shot-tour` (from `main`). **Read:** AGENTS.md, this brief, `core/debug.gd` (the header lists every hook) and `core/debug_hooks.gd`. Change only `core/` debug files plus a new `core/shot_tour.gd`, and a smoke rule.

## Why
Opus judges the art from Xvfb screenshots. Today each shot is a fresh Godot launch (about 20–40 s of level build and sim each). A tour takes many framed shots in one run.

## Tasks
1. **`--tour=PATH`** reads a plain-text file, one shot per line, `#` comments and blank lines ignored:
   ```
   out=/abs/a.png look=40,74,22,0.9 wait=1.5
   out=/abs/b.png look=88,30,14 wait=0.5 select=cannon
   out=/abs/c.png fps=60,62,yaw=1.2,pitch=-0.2 wait=1.0
   out=/abs/d.png gallery=anim:wyvern clip=attack t=0.5
   ```
   - The level setup comes from the normal command line (`--demo`, `--creatures`, `--sim=N`, `--level=N` …) and runs **once**. Then each line runs in order: move the camera, wait `wait` seconds of game time (default 1.0), wait for `frame_post_draw`, save the PNG, print `[tour] saved PATH`. Quit after the last line.
   - `look=x,z[,d[,p]]` is the existing command-camera hook. `fps=x,z,yaw=..,pitch=..` puts the Operative camera there (surface mode), standing on the ground with `Grid.stand_y`. `select=T` selects the nearest structure of type T, like `--select`.
   - `gallery=anim:<id>` with `clip=` and `t=` (0–1) poses that model's clip at that time and frames its AABB. Pause the AnimationPlayer (`seek(t * length, true)` then pause) so the shot is exact.
2. **`--tour-orbit=id,N`** (shortcut): N shots orbiting the gallery model `id` at 360/N degree steps, named `<out dir>/<id>_<k>.png`, with `--shot` giving the directory. This is for checking models from every side.
3. Errors: an unknown key, or a gallery id with no model, prints `[tour] skip LINE: reason` and goes on.
4. **Smoke rule:** parse a 3-line tour string (no rendering) and check the parsed fields.
5. Keep files under ~250 lines. `debug.gd` is at 238, so the parser and runner go in `shot_tour.gd`, and `debug.gd` only dispatches to it. Add both flags to the `debug.gd` header.

## Must not change
Existing hooks and their behaviour, game rules, `user://keybinds.cfg`.

## Report
AGENTS.md format. Include an example tour file that covers the L1 Command Node, one L2 hive and the wyvern gallery attack clip, so Opus can run it straight away. You have no display: write "screenshots: Opus".
