# MAP-3 "Town": brief (orchestrator 2026-10-16)

Gregory: "design a new level taking the design of the first level (not skirmish 2) into account. It needs CQC
opportunities and to be more cohesive than having buildings scattered about, it needs to be closer to a real combat
scenario. It needs to be between 50 and 200% larger than the current skirmish and have a starting zone for the
loadout like skirmish 1 and 2 do."

Worktree: `../tactical ops-worktrees/map-town`, branch `feat/map-town`. Follow AGENTS.md. Agent: Sonnet.

## What "the first level" means
MAP-1 = `git show d882011^:godot/scripts/range/skirmish_data.gd` (the compound before MAP-2): spawn on the south edge
with the loadout rack, a lane up the middle to the extract on the north edge, a few big buildings (hotel 2F, barracks,
warehouse, shack), the marksman tower, cover pieces. Keep its *grammar*: south-to-north push, start zone with the rack,
extract at the far end, a marksman overwatch, the same enemy kinds, loot crates. Change its *weakness*: buildings
standing alone in a field. MAP-2 stays exactly as it is (it remains "Skirmish").

## Scenario
Clearing an enemy-held town district from a forward operating base. The route is FOB -> farm outskirts -> town (main
street + market street) -> walled industrial yard -> extract. Everything is aligned to roads, walls and property lines,
so it reads as one place: rows of houses sharing walls, walled courtyards behind them, back alleys, barricades where a
defender would put them (street mouths facing south), wrecked vehicles on the roads.

## Size and plan: 160 x 160 m (HALF 80; 1.78x MAP-2's 120 x 120 area)
x right, z toward the spawn (south = +z), same as SkirmishData.
```
 z-80 ┌─────────────────────────────── north wall ───────────────────────────────┐
      │        EXTRACT (north yard, boss + 2)                                     │
      │  ┌──────── industrial yard (2.5 m wall, gates S + W) ────────┐            │
      │  │ warehouse      workshop     containers   fuel/crates      │  overwatch │
 z-30 │  └────────────────────── gate ────────────────────────────────┘  2F (mks) │
      │ west   ║ row W1 ║ courtyards ║ MUNICIPAL 2F (on square) ║ row E1 ║ cemetery│
      │ lanes  ║ ───────── market street (E-W, z 4..10) ─── SQUARE ──────── fields  │
      │ walled ║ row W2 ║ courtyards ║  main street (N-S, x -4..4)  ║ row E2 ║ open   │
 z+34 │ gardens║ barricades at the street mouths (facing south)            sparse │
      │  FARM compound (walls, house, barn)    road    ORCHARD (tree rows, shed)  │
      │        ditch line = low walls with gaps (z ~48)                          │
 z+64 │                 ┌──── FOB: HESCO walls, gate N, rack, ammo/meds ────┐     │
 z+80 └─────────────────┴──────────────────── SPAWN ──────────────────────────┴───┘
```
- **FOB (start zone, z +62..+80, x -22..22):** walls 2.2 m high (cover kind `wall`/`barrier`), one gate north on
  the road. The loadout rack goes here, the same way MAP-1/MAP-2 place it (`SPAWN`, `RACK_POS`, F90 spare mags, the
  F93-style cover by the gate). Bots must not spawn or path into it.
- **Outskirts (z +36..+62):** the road north from the gate (x -4..4). West: farm compound (walled courtyard, gate on
  the road side, farmhouse with an inner wall + barn). East: orchard (trees in rows, 6-8 m apart) and a pump shed. An
  E-W ditch line of low walls (1.0-1.2 m) with gaps. A wrecked car on the road.
- **Town (z -28..+34, x -62..+46):** two streets crossing at a square. Main street N-S on the road line (6-8 m wide),
  market street E-W (6 m). Four blocks (W1, W2, E1, E2), each a row of 3-5 houses sharing side walls, fronting the
  street(s), with walled back courtyards (2.2 m) and a back alley (2.5-3 m) behind them. Every house: a street door, a
  courtyard/back door, inner wall(s) on the bigger ones; at least two 2-storey buildings per side with windows on the
  street (use `floors: 2`, `open2`). The square (about 24 x 18 m) has the MUNICIPAL building (2 storeys) on its north
  side. Barricades/sandbags at the south street mouths and across the market street; a burned truck in the market
  street. Sightlines in town 5-25 m; the main street is the long exposed one (up to ~60 m), as MAP-2's sniper street.
- **West lanes (x -80..-62):** walled gardens and narrow lanes (2.5-3.5 m) along the town's west edge: the close,
  slow flank. **East (x +46..+80):** cemetery (grid of low walls), open fields with sparse cover: the fast, exposed
  flank, watched by the OVERWATCH building (2F, x ~+52..+62, z ~-34..-24), the marksman's spot (reuse the tower /
  2F marksman pattern; one of tower or overwatch, not both, unless the tower fits the industrial yard better).
- **Industrial yard (z -70..-30, x -40..+40):** 2.5 m wall, gates south (main street) and west. Warehouse and workshop
  (interiors with inner walls), container stacks, crates, a truck. **Extract** in the north yard past it (z ~-72).

## Enemies, loot
Same kinds as MAP-2 (`BotDefs`/the skirmish roster tables), about 16-18 in all (MAP-2 has 12): checkpoint pair at the
town's south barricades, 2 patrolling the market street, 3 in houses (ambush at windows / courtyards), marksman
(overwatch or municipal 2F), 2 runners flanking via the west lanes and the orchard, 3 yard guards, boss + 2 at the
extract. Loot: ~10 crates (ammo/meds) spread along the routes, more in the risky spots.

## How (code)
- Keep `skirmish_data.gd` (MAP-2) and its behaviour **unchanged**. Add the town's tables as a parallel data source
  (e.g. `skirmish_town_data.gd`, same table shapes) and make the skirmish layout/game read the active map's tables
  instead of `SkirmishData` constants directly. MAP-2 must build exactly as before.
- New map id (e.g. `"town"`) in `RangeMaps`, its own scene if that is the existing pattern (`skirmish.tscn` +
  `SkirmishScene`), and a title-menu entry ("Skirmish: Town") next to Skirmish. Bigger map: check the outer walls,
  ground, navmesh bake bounds, bot spawn/route code and any `HALF`/`120` assumptions.
- Files under ~250 lines; split the data file by area if it grows (e.g. town buildings / cover / roster).
- Performance: the map has many more walls. Merge where the builder allows it; report the frame time you measure.

## Phases (commit each)
1. Plumbing (active-map data source, map id, scene, title entry) + the full layout (buildings, walls, cover, FOB, rack,
   extract, navmesh). MAP-2 still builds identically.
2. Enemies (positions, routes, marksman), loot, lights; play-through sanity: walk FOB -> extract, bots path and fight.

## Done means
Parse check clean; `skirmish.tscn` (MAP-2) and the town both boot; the range suite (`--range-test`, background, read
the summary) shows no new failures (baseline 1114 pass / 0 fail, 38 known `'lock'` SCRIPT ERRORs). Save a top-down
overview render and 3-4 street-level shots of the town (scratchpad or `docs/art/map3/`), list their paths in the report
for the orchestrator to judge. Write `docs/tasks/MAP3_progress.md` (what was built, coordinates table, known issues).
Report cap: 40 lines. Do not edit HANDOFF.md, CHANGES.md, MAP-2 data, guns, bots' AI code or anything outside the map.
