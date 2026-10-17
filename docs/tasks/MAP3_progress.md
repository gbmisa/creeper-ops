# MAP-3 Town: progress log

## Phase 1 (done): plumbing + full layout
- `SkirmishLayout` / `SkirmishGame` / `SkirmishScene` read their tables from a `data: GDScript` var (default `SkirmishData`, so MAP-2 builds exactly as before). `TownScene` (town.tscn, map id `"town"`) sets `TownData`.
- `RangeMaps`: `"town"` scene + `is_skirmish()`; kit deploy, pause menu, Kestrel materials and environment treat the Town as a Skirmish map. Title menu has "Skirmish: Town".
- Data: `town_data.gd` (constants, styles), `town_buildings.gd` (45 buildings), `town_walls.gd` (49 free-standing walls + road strips), `town_cover.gd` (154 cover pieces). `town_layout.gd` builds walls + roads (visual strips) on top of SkirmishLayout. The Kestrel look (MAP-2 facades/props/foliage) is skipped for the Town.
- The layout was generated from a script (rows butt with 0.3 m seams) and then checked: no building overlaps, no cover through walls, every door (inside and outside), every 2F floor and the extract reachable by navmesh from the spawn.
