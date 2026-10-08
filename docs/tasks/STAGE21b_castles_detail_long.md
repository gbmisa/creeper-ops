# Stage 21b (long, overnight): Castles detail pass

**Agent:** Grok Build, one long unattended session. **Worktree:** `creeper fps td-worktrees/stage21b` · **Branch:** `stage/21b-castles-detail` · **Progress log:** `docs/tasks/STAGE21b_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md) first, then [CASTLES2_DESIGN.md](../CASTLES2_DESIGN.md) (the spec: rings, roofs, stages, engines, perks) and [STAGE21_progress.md](STAGE21_progress.md) (what Opus built, every decision, and the leftovers you inherit). For visuals, also [JUDGE_art_rubric.md](JUDGE_art_rubric.md).

Stage 21 (Opus) built concentric castles: outer wall + bailey + inner wall + keep, walkable interiors (tower stairs, gate passages, the keep hall) through an Operative-only **roof layer** (`Grid.roof`, `GridRoofs`), staged capture (gatehouse → bailey → keep), trebuchets on hostile castles, and held-castle perks. It works and is tested, but it looks bare: plain roof slabs, empty halls, no light or life. **Your job is the detail pass**, plus turret variety, castle guards, and the leftovers listed in P8.

## Rules for this run
- **Don't change the rules** in `world/grid.gd`, `world/grid_roofs.gd`, `level/castle_stages.gd`, `level/castle_engines.gd`, `level/castle_perks.gd` or the terrain written by `castle_shape2.gd` / `castle_stairs.gd` / `castle_keep_shape.gd`, except where a phase below says so. Numbers live in `level/castle_defs.gd` (CastleDefs); add new ones there.
- **Decoration has no collision.** Walkers (Operative, raiders, units) only ever read the grid. Keep props off the walking line of stairs, doors and passages: the scripted walks in `smoke_castles2_walk.gd` must stay green.
- **Ground visuals are shader tints, never quads** (CLAUDE.md). Meshes on walls, roofs and props are fine.
- If Stage 20 (art pass 2) is merged on `main` when you start, match its look (particles, flicker, materials). Don't edit shaders another run owns without checking `git log main -- <file>` first.
- Files you own: every `level/castle_*.gd`, `level/stronghold_meshes.gd`, `level/castle_decor.gd`, `level/castle_interior_meshes.gd`, `level/castle_engine_meshes.gd`, new files you add (split before 250 lines), castle rows in `level01.gd`/`level02.gd`, new smoke files `core/smoke_castles2b*.gd`.
- Screenshot hooks: `--castle2=I,spot` (spots: gate, gatehall, bailey, tower, wall, hall, roof), `--stage=I,N`, `--held=I`, `--engines=I` (all in `level/castle_debug.gd`; add spots there, document them in its header).

## Phases (each: build, screenshot, look at it, log, smoke all PASS, commit `Stage 21b Pn: ...`)

**P0 audit (no code).** Baseline smoke count and the four sims (`--demo --units --sim=900`, `--autostart --sim=900`, `--level=2 --demo --sim=900`, `--level=2 --autostart --sim=900`) into the log. Screenshots (Xvfb, CLAUDE.md Testing §5): `--level=2 --autostart --look=80,80,120,1.5`, `--level=2 --castle2=2,<spot>` for every spot, `--level=2 --autostart --engines=2 --look=58,58,70,1.1`, `--level=2 --autostart --held=2 --look=80,80,80,1.2`, `--castle2=0,hall` (Level 1). Score each with the rubric; list the 10 weakest things, ranked. P1-P4 may be reordered by that list (say so in the log).

**P1 stone that reads as a castle.**
- Roof slabs (`CastleInteriorMeshes._slab`) use the castle ashlar look instead of flat stone: a ShaderMaterial or StandardMaterial with the same texture/colour logic as castle stone in `shaders/terrain_look.gdshaderinc` (stone is the 0.33 surface kind). Undersides darker, with beams (thin box meshes every 2 cells).
- Parapets: merlons along every roof edge that borders open air (keep roof, gatehouse roofs, tower tops already have crowns in `CastleDecor._tower_crown`: check they fit the 5x5 towers).
- Door frames: a stone arch over every interior door. Door cells aren't recorded yet: add `"doors": [cells]` to the dict `CastleStairs.tower` returns (data only, no terrain change) and use `lay.keep.door` for the keep.
- Wall variety: inner wall a shade darker than the outer; moss/stain near the moat line. Prefer decor meshes (bands, buttresses) over shader edits.

**P2 light and life.**
- Braziers (mesh + flickering OmniLight) in every gate hall and the keep hall, replacing the bare lights `CastleInteriorMeshes._light` adds. Torches on the inner faces of gatehouses. Keep the light count per castle ≤ 12.
- Banners on gatehouse fronts, the keep's four faces and the bailey standard pole; add every cloth mesh to the view's `banners` list so `StrongholdMeshes.refresh` dyes them by owner.
- The **bailey standard**: a pole + flag on `lay.zones.bailey` (centre cell) that rises with `c.ring.progress` while the bailey stage runs and flies your colour once taken. Same for a small gate-hall banner on the gate stage. (Read state only; no rule changes.)

**P3 interior props.** Keep hall: a dais under the crown nest, two long tables, weapon racks, a rug; gate hall: a winch wheel and chains for the portcullis; tower stairs: a stone trim on each step edge. All outside the walking line (check with the walk smoke and a first-person screenshot from each `--castle2` spot).

**P4 command-view readability.**
- Roofs fade (alpha ~0.35) while the command view is active, so creeper under them shows. Hook it where `WorldLook.set_command_view` is called (one-line call into your file) or poll the camera mode in `StrongholdMeshes.animate`.
- Stage progress: the castle marker already shows text (`CastleStages.marker`); add a small progress ring/bar mesh over the gate hall and the bailey standard while that stage runs.
- Trebuchet reach: when the cursor hovers a hostile castle (command mode), show the engines' range as a ring. Use an existing terrain-shader ring uniform through `CommandOverlay` if one is free; if not, log it under Suggestions instead of adding a shader uniform.

**P5 turret variety.** Two new rows in `CastleTurrets.DEFS` with models and fire logic (split `castle_turret_fire.gd` if it passes 250 lines):
- **Ballista**: long range anti-raider (range 26, slow heavy bolt, power 6/9/13 every 2.5 s, costs 35/55/90, HP like a Repeater). Outranges Spitters (20).
- **Ward Lamp**: no shots; while it stands, the castle's ward drain (`CastleDefs.WARD_DRAIN`) doubles and it pulses a light (costs 30/45/70). Read it in `CastlePerks.ward` through a small helper (`CastleTurrets.ward_mult(c)`): that one call is the only rule change allowed in P5.
- Castle tab (F5) shows them; first-person E on an empty socket still arms a Repeater. Smoke in `core/smoke_castles2b_turrets.gd`: each new type buys/upgrades, a Ballista hits a raider at 24 cells, a Ward Lamp doubles the drain.

**P6 castle guards.** Hostile concentric castles should feel garrisoned per ring:
- **Wall patrols:** 2 raiders per hostile castle walk the outer wall walk between towers (they can: tower stairs are terrain). Give them a `patrol` list of cells (`lay.segments` of ring "outer" + tower doors) and step them along it in a small new file; they fight normally when prey comes close.
- **Hall guard:** one Warden (existing roster row, `RaiderDefs.named("Warden")`) stands in the keep hall beside the crown while the castle is hostile; respawns with the garrison timer.
- Garrison spawns stay at `CastleStages.home(c, lay)`.
- Smoke in `core/smoke_castles2b_guards.gd`: patrols stay on the wall walk for 60 s; the hall guard exists while hostile and is gone after capture; the Stage 7 "castle-garrison" checks still pass.

**P7 castle-only production (optional if time is short).** A `castle_only: true` def key: `Placement.can_place` refuses it outside a held castle (one guard calling a static callable that `CastlePerks.attach` sets to `CastleVaults.inside_held`). Content: a player **Trebuchet** (Weapons tab, cost 80, `castle_only`, range 40, needs network, packets as ammo, lobs at the nearest enemy structure / hive part / enemy mortar, never at creeper) with a model reusing `CastleEngineMeshes.trebuchet()` in your colours. Smoke: refused outside, placed inside a held bailey, fires at an enemy structure in range.

**P8 Stage 21 leftovers** (from STAGE21_progress.md; do the ones still open):
- The enemy builder (`enemy_build_plan.gd`) may pick sites in a bailey you took: skip `lay.bailey` cells when `CastleStages.bailey_open(c, lay)`.
- Portcullis: raise/lower the gate mesh (tween) when a gate changes hands instead of only recolouring.
- `--castle2=I,gate` faces a slope on Level 1: aim the spot at the gate from the open side; `tower` spot: pitch up so the stair is in view.
- Level 1 Ashmoat: playtest-style screenshots of the approach from the landing mesa; if the notch in the mesa's west edge looks wrong, smooth it with whole levels (no decorative noise).
- Anything else in the log's "Unfinished" lines.

**Wrap-up.** Final rubric scores vs P0 with before/after screenshot pairs; smoke count; the four sims vs P0. MASTER_PLAN: set the Stage 21b status cell and add one Changelog line. Report per LONG_RUN_RULES (phases done/partial/skipped, commits, test counts, sims, screenshots, spec gaps you filled, new files for the CLAUDE.md map).
