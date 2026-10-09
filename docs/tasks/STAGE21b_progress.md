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
## P3 interior props — FILL
## P4 command-view readability — FILL
## P5 turret variety — FILL
## P6 castle guards — FILL
## P7 castle-only production — FILL
## P8 Stage 21 leftovers — FILL

## Suggestions (unbriefed, not implemented)
- (append as phases run)
