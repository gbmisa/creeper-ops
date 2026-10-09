# Stage 21b progress log (Castles detail pass)

Branch `stage/21b-castles-detail`. Brief: [STAGE21b_castles_detail_long.md](STAGE21b_castles_detail_long.md).
Rules: [LONG_RUN_RULES.md](LONG_RUN_RULES.md), repo [AGENTS.md](../../AGENTS.md).
**No display on this machine: every "screenshot / look at it" step is recorded as
"not run (no display); Opus judges visuals". No placeholders, no claimed screenshots.**

## P0 audit (no code)

Baseline (tree at 0aa2823b, Godot 4.7.2-stable headless, 2026-10-09 ~03:13 UTC):
- Parse: `--headless --path . --import` — 0 script errors.
- Smoke: 734 PASS, 0 FAIL (`[smoke] OK: 0 failure(s)`).
- Sims:
  - `--demo --units --sim=900`: node_hp 500, over=false, time 900 — node survives.
  - `--autostart --sim=900`: node_hp 0, over=true, time 341 — node dies t=341.
  - `--level=2 --demo --sim=900`: node_hp 0, over=true, time 391 — node dies t=391.
  - `--level=2 --autostart --sim=900`: node_hp 0, over=true, time 229 — node dies t=229.
- Screenshots: not run (no display); Opus judges visuals.

### Rubric scores (code-based; no screenshots possible on this machine)
Judged against [JUDGE_art_rubric.md](JUDGE_art_rubric.md) criteria relevant to castles.
1. Fantasy coherence: 4/5 (stone/bronze/wood read; slabs are the flat note).
2. Weapon arms: n/a (no change this stage).
3. Weapon readability: n/a.
4. Scale: 4/5 (towers +6/+7 over yard dwarf the Operative; headroom respected).
5. Enemies: n/a.
6. Castles: 3/5 (reads as a castle, but bare: flat slabs, empty halls, no parapets on roofs).
7. Gameplay readability: 3/5 (roofs hide creeper in command view; no reach ring on trebuchets).
8. Polish: 3/5 (no floating parts found in code; plain surfaces everywhere).

### 10 weakest things, ranked
1. Roof slabs are flat untextured stone — the most visible castle surface in command view (P1).
2. Command view cannot see creeper under roofs (P4).
3. Halls lit by a single bare OmniLight; no braziers or torches (P2).
4. No parapets/merlons on keep roof or gatehouse roof edges (P1).
5. No stone arches over interior doors (P1).
6. Keep hall is empty: no dais, tables, weapon racks, rug (P3).
7. Gate hall is empty: no winch wheel/chains for the portcullis (P3).
8. No bailey standard or gate-stage banner showing capture progress (P2/P4).
9. Turret variety: Repeater/Lobber/Flak share one model (P5).
10. Hostile castles feel ungarrisoned: no wall patrols, no hall guard (P6).
Also queued: portcullis raise/lower tween, enemy builder skipping taken baileys,
`--castle2=0,gate`/`tower` spot aim (all P8).

### Phase order decision
Kept as briefed (P1→P8). The weakest list maps 1:1 onto the phase order and the
phases have a natural build dependency (stone → light → props → readability).
No reorder justified.

## P0 done
- Commit: a6ab9e32 (pushed via push_work.py; branch `stage/21b-castles-detail` created).
- No code changed. Log written; phase order kept as briefed.

## P1 stone that reads as a castle

Done (2026-10-09 ~04:40 UTC):
- `godot/shaders/castle_slab.gdshader` (new): roof-slab look reusing the terrain's
  castle-stone logic verbatim — `#include`s `noise.gdshaderinc` +
  `terrain_look.gdshaderinc`, calls `castle_stone(base, wp, wn, cliff, bump)` with the
  same slope→cliff rule as `ground_look` (flagstones on tops, ashlar courses on edges),
  derivative bump via `bumped()` like the terrain shader. Undersides get flagstones
  darkened ×0.55. No existing shader touched.
- `level/castle_interior_meshes.gd`: slabs now use the slab ShaderMaterial (one cached
  instance) for both surfaces instead of flat StandardMaterials; oak beams (thin boxes)
  under the slab on every `CastleDefs.SLAB_BEAM_EVERY`=2nd cell row.
- `level/castle_stairs.gd`: `CastleStairs.tower` returns `"doors": [cells]` (data only,
  no terrain change).
- `level/castle_stonework.gd` (new, `CastleStonework`): `parapets()` — merlons on every
  gatehouse/keep roof edge whose neighbour cell is 2+ levels below the roof (open air);
  tower slabs skipped (crowns already have merlons). `door_arches()` — a `ShapeKit.arch`
  over every tower door (span 2.6, spring `ARCH_SPRING`=1.7 m above the door floor,
  oriented along the wall) and one wide arch (span 6.6) over the keep's 3-wide door from
  `lay.keep.door` (spring `KEEP_ARCH_SPRING`=2.0 m). `wall_trim()` — per-segment trim
  parented under the segment node (hides with breached walls): merlons at the segment's
  real grid top (fixes inner-ring merlons sitting a level low), inner ring in darker
  `StrongholdMeshes.INNER_STONE` + dark string course + tapered buttresses every 4
  cells, outer ring gets a moss band just above the moat waterline (moat rows only).
- `level/stronghold_meshes.gd`: segment loop delegates to `CastleStonework.wall_trim`;
  `CastleStonework.build` called after interiors; added `INNER_STONE`.
- `level/castle_defs.gd`: `SLAB_BEAM_EVERY`, `ARCH_SPRING`, `KEEP_ARCH_SPRING`.
- `core/smoke_castles2b_stone.gd` (new, `SmokeCastles2bStone`, registered in
  `smoke_test.gd`): 7 checks per concentric castle (Level 1 + Level 2).
- Screenshots: not run (no display); Opus judges visuals.

Spec gaps filled:
- "Undersides darker": done in-shader (×0.55) rather than a second material.
- Parapet placement derived from open-air edges, not hand-listed — the keep slab only
  gets merlons above its door; the stair hatch is excluded (neighbour 1 below roof).
- Tower crowns (`CastleDecor._tower_crown`) fit the 5x5 towers: merlons sit 0.25 m
  inside the wall edge at roof-top level. No change needed.
- Inner-wall merlons were a level too low (used `lay.wall_top` for both rings); fixed
  to per-cell grid height as part of wall_trim.

Tests:
- Parse: `--headless --path godot --import` — 0 script errors.
- Full suite `-- --smoke --quit=0.1`: first run 770 PASS / 6 FAIL — all 6 my new
  "stone arches" check, one root cause: `Vector2i.dot` doesn't exist in Godot 4
  (script error in the keep-door branch). Fixed with manual arithmetic; final run:
  **[smoke] OK: 0 failure(s), 776 PASS** (734 baseline + 42 new), 0 script errors.
- Castle smokes (shape/walk/capture/engines/perks) all PASS in both runs.

Unfinished: none for P1. P2 next.
## P2 light and life

Done (2026-10-09 ~06:10 UTC):
- `level/castle_fires.gd` (new, `CastleFires`): `brazier()` — stone foot, iron stem and
  bowl (lathe), glowing ember ball, flickering OmniLight (energy 2.2, range 10 m);
  `torch()` — iron bracket, angled oak haft, flame ball, small warm light (0.9, 5 m);
  `flicker()` — two-sine energy flicker; `gate_inner_dir()` — a gatehouse's inner side
  (toward its rect's centre; the inner gatehouse uses the inner rect, so torches face
  the ward, never the bailey).
- `level/castle_interior_meshes.gd`: `_light` replaced by `_fires` — a brazier in every
  gate hall and the keep hall (inner gatehouses: one cell toward the ward so it stands
  in the gate hall, not on the gate cells), two torches flanking each gatehouse
  passage's inner opening; tower stairs stay unlit. Fire entries
  `{ light, base, seed, kind }` go to `v["fires"]` for the flicker pass.
- Light budget per castle: Crown Keep (biggest) = 4 braziers + 6 torches = 10;
  Ashmoat = 3 + 4 = 7. All ≤ 12 (checked in smoke).
- `level/castle_banners.gd` (new, `CastleBanners`): banners over every gate (outer and
  inner) on the gatehouse's outer face; a banner down each of the keep's four faces; the
  bailey standard — stone-footed iron pole + flag on the zone's centre cell — whose
  flag rises with `c.ring.progress` while the bailey stage runs and sits at full height
  once taken; a small war banner on a pole in the gate hall hoisted with the gate
  stage. Every cloth mesh is appended to the view's `banners` list, so
  `StrongholdMeshes.refresh` dyes them by owner. `animate_flags` reads only
  `c.stage`/`c.ring` — no rule changes.
- `level/stronghold_meshes.gd`: build passes `v.banners` + a fires array into
  `CastleInteriorMeshes.build`, stores `v["fires"]`, merges `CastleBanners.build`
  descriptors (`standard`, `gate_banner`) into `v`; `animate` flickers the fires and
  hoists the flags.
- `level/castle_defs.gd`: `BRAZIER_ENERGY/RANGE`, `TORCH_ENERGY/RANGE`, `STANDARD_H`.
- `core/smoke_castles2b_fires.gd` (new, `SmokeCastles2bFires`, registered): brazier and
  torch counts per castle, ≤ 12 lights, cloth count wired into the banners list, and the
  flag-rise behaviour (mid-progress, full when taken, gate banner on the gate stage,
  lowered again on retake).
- Screenshots: not run (no display); Opus judges visuals.

Spec gaps filled:
- Torch placement: flanking the passage's inner opening at the end row's side cells,
  2.2 m up — no axis stored on the interior dict, so the inner direction is derived
  from the rects at build time.
- The rising elements are flag *nodes* sliding up static poles (poles don't grow).
- Tower interiors lost their bare light (budget); the brief's "replacing the bare
  lights" covers halls — towers were the only cut.

Tests:
- Parse: `--headless --path godot --import` — 0 script errors (two caught during dev:
  `-1 << 20` illegal in GDScript, `:=` inference on a Variant product).
- Full suite `-- --smoke --quit=0.1`: **[smoke] OK: 0 failure(s), 818 PASS**
  (776 P1 + 42 new), 0 script errors. (One run was killed by a service restart at
  607 PASS/0 FAIL and re-run to completion on the final tree.)
- New fires checks: brazier/torch counts per castle (7 fires typical, 10 on Crown Keep
  — all ≤ 12), cloth counts exact (24, 27 on Crown Keep), flag-rise/retake all green.
- Castle smokes (shape/walk/capture/engines/perks) all PASS.

Unfinished: none for P2.
## P3 interior props

Done (2026-10-09 ~07:40 UTC). Commit: 22ad4c16 (pushed via push_work.py; 22 changed/new, 0 deleted).
- `level/castle_props.gd` (new, `CastleProps`, 249 lines): `build(root, g, lay)` returns a
  descriptor dict for the smoke test. Keep hall: a two-step stone dais (5.0 m / 3.6 m,
  `CastleDefs.DAIS_H`=0.5) under the crown nest; two long oak tables (top + 4 legs) on
  the longest runs of hall cells two cells either side of the aisle; two freestanding
  weapon racks (posts, crossbars, leaning blades) on the back cells of the table rows;
  a runner rug (flat 8 cm box — a prop, not a ground quad) on the aisle from the dais
  edge to the door. Gate halls (every gatehouse interior, outer + inner): a winch wheel
  (stone posts, oak drum, iron spoked wheel, chain up into the slab) in the hall's inner
  corner, and three chains over the gate cells for the portcullis. Tower stairs: a stone
  lip on each step's downhill edge (one trim per ring-cell edge, 8 per tower).
- `level/stronghold_meshes.gd`: calls `CastleProps.build`; the crown mesh rides up
  `DAIS_H` on concentric castles (capture logic reads zones/hp, `crown_push` tolerates
  3 m, the marker hangs off the node — all safe).
- `level/castle_defs.gd`: `DAIS_H`, `TABLE_H`, `WINCH_WHEEL_R`, `STAIR_TRIM_H`.
- `level/castle_interior_meshes.gd`: the no-column (9x9) keep-hall brazier moved from the
  hall centre to centre+(2,1) — the P3 dais owns the centre now (counts unchanged, fires
  smoke still green).
- `core/smoke_castles2b_props.gd` (new, `SmokeCastles2bProps`, registered in
  `smoke_test.gd`): per concentric castle — dais cell/height, two tables flanking the
  aisle (2-4 cells, in-zone, off stairs/doors/tower doors), two racks off the walking
  line, rug on hall/door floor, one winch per gatehouse interior off the walking line,
  exactly 8 trims per tower.
- Screenshots: not run (no display); Opus judges visuals.

Spec gaps filled:
- Table length adapts to the hall: door-end 4 cells on 11x11 keeps, 3 on the 9x9
  (Ashmoat), leaving the back row for the racks — racks are freestanding, not
  wall-mounted, so they fit both hall sizes.
- The winch corner is picked by max |perp| offset at the passage's inner end (never the
  middle walking column, never a tower door cell); chains hang over the gate cells'
  inner row, from the slab underside to the portcullis top.
- The rug is flat decor (walkers read the grid); it is the one prop allowed on the
  aisle, exempted from the walking-line check.
- Crown Keep (3 gates) gets 3 winches and 80 trims (10 towers); the smoke asserts per
  castle, not fixed totals.

Tests:
- Parse: `--headless --path godot --import` — 0 script errors (two caught during dev:
  `-1 << 20` illegal shift, `:=` inference on a Variant product; plus a stubborn
  phantom parse error in the first smoke draft that cleared on rewrite to bracket
  access — see Unfinished).
- Full suite `-- --smoke --quit=0.1`: **[smoke] OK: 0 failure(s)** — all 36 new props
  checks PASS on all 6 concentric castles (ashmoat/ashgate/thornwall/crown/northreach/
  stormcrown), castle smokes (shape/walk/capture/engines/perks) all PASS.
- Bug caught before push: the winch corner search initialised its best-score to -99,
  so no winch was ever placed — fixed to a proper max scan (the smoke now covers it).

Unfinished: none for P3. Open question for Opus: the first `smoke_castles2b_props.gd`
draft failed `--import` with "Expected closing )" at a line that parsed fine in
isolation; rewriting with bracket dict access and precomputed booleans cleared it.
Root cause not identified — worth knowing if it recurs (no behaviour impact).
## P4 command-view readability

Done (2026-10-09 ~08:30 UTC). Commit: 651ffeac (pushed via push_work.py; 27 changed/new, 0 deleted).
- `level/castle_readability.gd` (new, `CastleReadability`, 67 lines):
  `set_command_view(on)` sets `fade_alpha` on the shared slab ShaderMaterial;
  `build_markers(root, lay, v)` builds two horizontal progress bars (dark back bar +
  amber fill anchored left) over the gate hall (above the gate-banner pole) and the
  bailey standard (above the pole), paired with the P2 `gate_banner`/`standard`
  descriptors; `animate_markers(v, c)` shows a bar only while `c.state == "hostile"`
  and `c.stage` is that bar's stage, filled by `clampf(c.ring.progress)`. Read-only.
- `godot/shaders/castle_slab.gdshader`: new `fade_alpha` uniform (default 1.0),
  `render_mode blend_mix, depth_draw_opaque, cull_back`, `ALPHA = fade_alpha`. (P1
  created this shader; no other run owns it.)
- `core/game_flow.gd:139`: one-line `CastleReadability.set_command_view(cmd)` right
  after `WorldLook.set_command_view` — the hook the brief named.
- `level/stronghold_meshes.gd`: build merges the markers into `v`; animate calls
  `animate_markers` after `animate_flags`.
- `level/castle_defs.gd`: `ROOF_FADE_ALPHA`=0.35, `STAGE_BAR_W`=3.2.
- `core/smoke_castles2b_readability.gd` (new, `SmokeCastles2bReadability`, registered):
  the fade uniform toggles 0.35/1.0; per concentric castle both bars build; the bars
  track the running stage (gate 40% -> gate bar filled 40%, bailey hidden; bailey 70%
  -> bailey bar 70%; keep stage or held -> both hidden).
- Trebuchet reach ring on hover: NOT implemented — no free terrain-shader ring uniform
  (ring_a: placement ghost + selection/weapon range; ring_b: selection ring; shells[8]:
  enemy mortar + trebuchet telegraphs via `CastleEngines.rings`). Per the brief this
  goes under Suggestions, not into the tree.
- Screenshots: not run (no display); Opus judges visuals.

Spec gaps filled:
- Bars sit above their poles (gate-banner pole top + 1.4 m, standard pole top + 1.4 m)
  and lie flat — read top-down in command view; invisible in FPS except edge-on.
- One shared slab material: every castle's roofs fade together. Oak beams stay opaque
  (thin and structural; visually fine under a faded slab).
- At `fade_alpha` 1.0 the slab renders in the transparent pass but blends identically
  to opaque.

Tests:
- Parse: `--headless --path godot --import` — 0 script errors.
- Full suite `-- --smoke --quit=0.1`: **[smoke] OK: 0 failure(s)** (13 new readability
  checks PASS: 1 fade + 6 castles x 2 bar checks), castle smokes all PASS.

Unfinished: none for P4.
## P5 turret variety

Done (2026-10-09 ~10:30 UTC):
- `level/castle_turrets.gd`: two new DEFS rows + ORDER entries.
  - **Ballista**: costs 35/55/90, HP [80,120,180], range 26, interval 2.5 s, power [6,9,13],
    targets "raiders" (outranges Spitters at 20).
  - **Ward Lamp**: costs 30/45/70, HP [80,120,180], `"range": 0.0`, `"targets": "none"`,
    fires nothing; `CastleTurrets.ward_mult(c)` returns `CastleDefs.WARD_LAMP_MULT`
    (2.0) while one stands, else 1.0 (never stacks).
- `level/castle_perks.gd`: `ward` multiplies the drain by `CastleTurrets.ward_mult(c)` —
  the one P5 rule call allowed (nothing else in that file touched).
- `level/castle_defs.gd`: `WARD_LAMP_MULT := 2.0`.
- `level/castle_turret_fire.gd` (151 → ~230 lines, stays under 250, no split needed):
  `_model` now takes the turret type — Ballista gets a bigger bolt-thrower (long oak
  rail, heavy bronze arms, fat glowing bolt), the Ward Lamp a lamp post (iron post,
  caged crystal named "Glow" + a small OmniLight named "GlowLight"); the old
  ballista-looking head is the Repeater's. New `animate(v, c, t)` pulses the crystal
  scale and light energy (cheap: only ward-lamp sockets); tick matches
  `def.targets` with a no-op `"none"` arm. `_ballista` reuses a shared
  `_target_raider` helper (extracted from `_repeater`, behaviour unchanged): a slow
  heavy bolt (0.16-wide beam, 0.12 s) for 6/9/13.
- `level/stronghold_meshes.gd`: `animate` calls `CastleTurretFire.animate(v, c, t)`.
- `command/structure_defs.gd`: Castle menu gains `"@ballista"`, `"@ward_lamp"`;
  `_turret_actions` already iterates ORDER so both get label/cost_text/desc for free.
- `command/command_hover.gd`: the two hardcoded `"@repeater","@lobber","@flak"` match
  arms replaced by `CommandHover._turret_type(tool)` — any "@<turret>" tool in DEFS.
  The placement ghost ring reads `.get("range", 0.0)`, so the rangeless Ward Lamp
  draws no ring instead of crashing.
- `command/command_input.gd`: the turret click arm generalized the same way (handled
  before the match so `@repair`/`@terp` arms stay reachable).
- `core/smoke_castles2b_turrets.gd` (new, `SmokeCastles2bTurrets`, registered): 12
  checks — Castle tab shows both, rangeless/no-op keys, buy Ballista I + Ward Lamp I,
  Ballista hits a raider at 24 cells, stays silent at 27, lamp glow node builds,
  upgrade to Ballista II + second socket, ward_mult 2.0 while the lamp stands (1.0
  after it falls), `CastlePerks.ward` removes exactly 2x with the lamp, E on an empty
  socket still arms a Repeater. Leaves castle[0] hostile, sockets cleared, raiders
  cleared.
- Screenshots: not run (no display); Opus judges visuals.

Spec gaps filled:
- Ward Lamp stacking: one lamp doubles; extra lamps don't multiply further.
- The pulse is scale + light-energy on the lamp's own nodes, driven from
  `StrongholdMeshes.animate` — no new lights budget entry (the lamp's OmniLight is
  range 7, energy ~1.1–1.8, one per lamp).
- First-person E still defaults to Repeater on empty sockets (`use_label` untouched).

Tests:
- Parse: `--headless --path godot --import` — 0 script errors (two caught during dev:
  `:=` inference on Variant values in the new smoke).
- Full suite `-- --smoke --quit=0.1`: first green run 878 PASS / 2 FAIL — both mine:
  (1) the 27-cell silence check: socket 1's second Ballista (opposite corner) was
  closer than 26 cells to the test raider and shot it — restructured the smoke so the
  range test runs with only one Ballista armed; (2) the ward ratio: an earlier smoke's
  `_sim` left `c.ward_t` at 0.4, so the first measurement drained 0.054 not 0.03 —
  the smoke now zeroes `ward_t` before each measurement. Second run: 878 PASS / 1
  FAIL — only the pre-existing flaky "castle: garrison walks out of the gate to its
  prey" (smoke_castle_build, runs before my smoke; none of my changes touch raider
  pathing). Re-ran once per the brief: **[smoke] OK: 0 failure(s), 879 PASS**.
- Castle smokes (shape/walk/capture/engines/perks/turrets) all PASS.

Unfinished: none for P5.
## P6 castle guards — FILL
## P6 castle guards — FILL
## P7 castle-only production — FILL
## P8 Stage 21 leftovers — FILL

## Suggestions (unbriefed, not implemented)
- (P4) Trebuchet reach ring on hover: add a `ring_c` vec4 (+ `ring_c_color`) uniform to
  terrain.gdshader mirroring `ring_a`, plumb it through CommandOverlay (e.g.
  `show_engine_range(x, z, radius_m)` / clear on hover-out), and drive it from
  CommandHover.refresh when the hover cell falls inside a hostile concentric castle's
  rect while no tool is armed (radius `CastleDefs.ENGINE.range * Config.CELL`, 40
  cells, red-amber). Cheaper alternative: reuse a `shells[]` slot through
  `CastleEngines.rings` with a hover flag — riskier, live telegraphs could stomp it.
  Deliberately not implemented: the brief forbids adding a shader uniform here.
