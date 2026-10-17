# MAP-3 Town: progress log

## Phase 1 (done): plumbing + full layout
- `SkirmishLayout` / `SkirmishGame` / `SkirmishScene` read their tables from a `data: GDScript` var (default `SkirmishData`, so MAP-2 builds exactly as before). `TownScene` (town.tscn, map id `"town"`) sets `TownData`.
- `RangeMaps`: `"town"` scene + `is_skirmish()`; kit deploy, pause menu, Kestrel materials and environment treat the Town as a Skirmish map. Title menu has "Skirmish: Town".
- Data: `town_data.gd` (constants, styles), `town_buildings.gd` (45 buildings), `town_walls.gd` (49 free-standing walls + road strips), `town_cover.gd` (154 cover pieces). `town_layout.gd` builds walls + roads (visual strips) on top of SkirmishLayout. The Kestrel look (MAP-2 facades/props/foliage) is skipped for the Town.
- The layout was generated from a script (rows butt with 0.3 m seams) and then checked: no building overlaps, no cover through walls, every door (inside and outside), every 2F floor and the extract reachable by navmesh from the spawn.

## Phase 2 (done): enemies, loot, lights
- `town_data.gd`: 16 roster rows + 2 boss guards = 18 hostiles (checkpoint pair at the main-street barricades z ~29, market patrols W/E, shotgunner in w1_2, rifleman in e2_2, courtyard rifleman, marksman at the overwatch 2F window (54, 3.0, -23.4) with the municipal 2F window as 2nd spot, Runner via the west lanes, Runner through the orchard, 3 yard guards, annex + municipal ambushers, boss + 2 at the extract). Boss is the last row (followers append after the roster, as in MAP-2). No route enters the FOB.
- 14 loot crates (ammo/meds), 15 street lamps (post + warm omni, no shadows; `TownLayout._lamp`); ceiling lights come from SkirmishLayout as before.
- Checks (temporary scripts, not committed): 223 navmesh probes from the spawn (every door in/out, every 2F floor, loot, enemy starts/routes, spots, extract) all reachable; 40 s headless sim from (0, 40): bots patrol, engage, flank, killed a standing player.
- Range suite: 1114 PASS / 0 FAIL, 38 'lock' SCRIPT ERRORs (= baseline). (One earlier run was cut short at 217 while windowed shots ran in parallel; the clean rerun matched baseline.)
- Frame rate (windowed, 1280x720, uncapped, RTX): 130-175 fps at street level in the Town.

## Coordinates (x right, z toward spawn/south)
| Area | Where |
|---|---|
| Spawn / rack / FOB | (0, 74) / (-5, 77.2); walls x +-22, z 62..80, gate x -3.5..3.5 at z 62 |
| Farm / orchard / ditch | farm x -48..-14, z 40..60 (gate east z 49..53); orchard trees x 14..35, z 42..60; ditch z 37 |
| Main street / market street / square | x -4..4 / z 4..10 / x -12..12, z -2..16 |
| South barricades | z 34 (main street), (-33, 34), (30, 34); market: (-26, 5.6), truck (30, 7) |
| W1 / E1 (north rows) | W1 x -60..-18, E1 x 14..46, houses z -10/-6..4, courtyards to z -16, alley z -19..-16, back rows z -27..-19 |
| W2 / E2 (south rows) | houses z 10..20/24, courtyards to z 28, alley z 28..31 |
| Municipal / annex | x -16..-4.6, z -16..-2 (2F) / x -14..-6, z -26..-18 |
| West lanes | lane x -64..-61, gardens x -78..-64, outer lane x -80..-78 |
| Cemetery / overwatch | x 50..78, z -6..16 / x 50..60, z -36..-22 (2F) |
| Yard / extract | x -40..40, z -68..-30 (gates S, W z -52..-48, N); extract (0, -74) r 4 |

## Known issues / notes
- Only one overview angle; top-down roofs are flat slabs (interiors not visible).
- Bots are not blocked from the FOB by anything but their routes (chasing the player there is possible).
- The Town has no MAP-2 Kestrel dressing (facades, props, foliage, far ground) yet; walls use the Skirmish materials with per-building colours.
- 2-storey buildings are 14 m deep because the shared ramp code needs 6.5 m of run; widths/depths are uneven on purpose.
