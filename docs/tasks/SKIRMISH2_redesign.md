# Skirmish 2 (skirmish_large) redesign proposal, F138 — for Gregory's ruling
Opus, 2026-10-16 night, from shots of the spawns and two aerial views (scratchpad, not committed). No rebuild
until Gregory rules. The perf fix (F136) shows 24 + 40 bots run smoothly, so a bigger, denser map is affordable.

## What's wrong now
1. **Flat, empty desert.** One flat tan plane, no height anywhere except a few ramps. Outside the walled
   compound there is ~70% bare ground with nothing to use. Long sightlines everywhere, and no hills or dips.
2. **Shoebox buildings.** Every building is a plain box with the same wall texture and a few holes. No roofs you can read, no
   porches, no variety in shape or height, interiors are empty rooms. From the air it reads as a grid of sugar cubes.
3. **Cover is debris.** Hundreds of identical brown crates and blocks scattered evenly (F93/F100/F109 added more
   each time). Untextured flat-colour boxes; they don't look like anything (no cars, sandbags, walls, barrels).
4. **No landmarks.** You can't tell the districts apart, or where you are, without the HUD distances.
5. **Spawn starts in contact.** From the centre spawn a bot is already in view at ~20 m (shot spawn_c).
6. **Fake stairs.** Ramps drawn as stairs that can't be climbed (F137, being fixed tonight).
7. **Ugly perimeter.** A low white wall around a desert, with sparse orange cartoon trees.

## Proposed redesign (one map, three phases, each playable)
- **P1 Ground + layout:** terrain with height (a low ridge on the north, a riverbed/ravine on the west, a raised
  town centre), roads that connect spawns to extracts, the compound kept as the core. Fewer, bigger fights:
  4 named areas (Depot, Town, Ridge, River) each with its own look and one landmark (water tower, church
  steeple, radio mast, crashed truck). Spawns behind a rise with no line of sight to any patrol.
- **P2 Buildings:** a kit of 6-8 building types (house 1-2 storey with real stairs, shop, warehouse with catwalk,
  barracks, garage, church, office block) with roofs, door frames, window frames, and furnished interiors (tables,
  shelves, beds as cover). Real stairs everywhere (step boxes, not ramps).
- **P3 Cover + dressing:** replace the scattered crates with meaningful cover: wrecked cars, sandbag walls, low
  stone walls, fences, barrels, containers, hedges, using the low-poly scratch style he likes; grass/dirt patches,
  rocks, real trees; ground decals for roads.

## Questions for Gregory
1. What's worst to you: the look, the layout, or how fights play out? (Ranks P1-P3.)
2. Setting: keep desert town, or something else (forest village, industrial port, Eastern-European town)?
3. Keep the size (~220 m) or go bigger now that 60+ bots run fine?
