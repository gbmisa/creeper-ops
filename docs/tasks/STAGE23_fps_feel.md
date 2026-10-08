# Stage 23: First-person feel (recoil, spray, hit feedback)

**Agent:** Claude Sonnet. **Worktree:** `creeper fps td-worktrees/stage23` · **Branch:** `stage/23-fps-feel` · **Progress log:** `docs/tasks/STAGE23_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) first. Runs alongside 9b (Salvage Engines + improved ammo: it adds ammo switching in `operative_weapons.gd`, so keep your edits there small and additive), 19 (flyers), 21 (castles, Opus).
**Stay inside:** `fps/operative_weapons.gd`, `fps/weapon_models.gd`, `fps/player_controller.gd` (camera only), `fps/rocket_launcher.gd`, `fps/advanced_weapons.gd` (visual hooks only), `ui/fps_hud.gd`, `world/effects.gd`, `core/audio_synth.gd`, new files under `fps/` (e.g. `fps/viewmodel_motion.gd`, `fps/spray_fx.gd`), `config.gd` (new feel tunables only).

## Why (the user, after playing)
"Playing in first person is interesting and adds to the experience, but it still feels like shit. The gun has no recoil. The Null Sprayer has no visual anti-creeper that sprays out." An audit found recoil code in `operative_weapons.gd` that is too small to notice, and the sprayer has no spray effect at all. The user judges *felt* feedback; numbers in a sim don't count here.

## Do
1. **Viewmodel motion** (`fps/viewmodel_motion.gd`): per-shot kick (crossbow snaps back ~6 cm and pitches up ~6°, recovers over ~0.15 s with a slight overshoot), camera pitch kick (~0.8° that recovers, never permanent), idle breathing sway, walk bob tied to speed, sprint lowers and tilts the weapon, landing dip after a jump, mouse-look lag (weapon trails the view slightly). All amounts in `Config` (`VM_*`).
2. **Crossbow shot:** visible string snap (string mesh jumps forward), the bolt leaves the rail (a fast tracer from muzzle to hit point), a short bright muzzle glint on the crystal, a punchy shot sound (layered: twang + thump) via `Sfx`.
3. **Null Sprayer:** a visible cone of pale cyan-green mist **from the nozzle to where it reaches**, using `CPUParticles3D` (Xvfb uses GL compatibility), plus a faint translucent cone mesh while firing; droplets that **hit creeper fizz** (small white-steam bursts at the impact cells, the cells it actually evaporates); a hiss loop while held; the tank bar drains visibly. If the spray removes creeper through a specific call, put the fizz on that call (one line).
4. **Rockets / advanced weapons:** bigger kick for rockets, smoke trail, a launch flash. Railgun/plasma/demo get at least a kick and a flash.
5. **Hit feedback:** hit marker with a tick sound on enemy hits, a distinct kill confirm (marker turns red + a crunch), damage direction indicator when the Operative is hurt (red arc toward the source), and a short screen-edge red vignette on big hits (mortar, Lancer).

## Verify
- Parse clean, full smoke all PASS. Add `core/smoke_fps_feel.gd`: kick offsets return to rest within 0.4 s; camera pitch never drifts after 30 shots; spraying over creeper spawns fizz and lowers depth; nothing allocates unbounded particles (counts capped by config).
- Xvfb screenshots mid-action (add a debug hook like `--fire=rifle|sprayer|rocket` that fires on the screenshot frame): crossbow at peak kick with tracer, sprayer cone over creeper with fizz, rocket launch. **Look at them**; iterate until the spray is obvious and the kick is visible in a still.
- Report what still can't be judged from stills (feel in motion) so the user can playtest it.
