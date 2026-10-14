# RANGE5 visual judge (Gregory, 2026-10-14)
"Create an agent to judge what the graphics end up looking like. Up to three iterations aiming for an 8 out of 10. Do this
for the different areas, level design, textures, items, and hand orientation interacting with items. Test that the
modular items function."

## Skirmish theme: "Outpost Kestrel"
A derelict Cold War radar/border station overrun by scavengers, late-autumn dusk: weathered concrete, rusted
corrugated metal, peeling green-grey paint, wet asphalt and gravel, dead grass and fallen leaves, low warm sun with cold
blue shadows, light ground mist. Landmarks: the radar dome/mast (by the watchtower), a checkpoint gate with a barrier
arm at the spawn, a motor pool (trucks), a barracks block, the hotel as the station's admin building. Signage in faded
stencils ("KESTREL", sector letters). The Firing Range hub contrasts it: clean, well-kept base, painted lanes, warm work
lights.

## Judge (`auditor`, Sonnet, read-only)
Takes its own Vulkan screenshots (commands in each track's progress log; `range_shot.gd` flags) at ≤800 px, and scores
each area 1–10 with the 3 most important concrete fixes (what, where, why). Areas:
1. **Level design**: readability, cover flow, sightlines, landmarks, theme coherence (Skirmish), hub feel (range).
2. **Textures/lighting**: material quality, tiling/stretching, lighting mood, fog, shadows, consistency.
3. **Items**: each gun / sight / attachment / utility model (contact sheet + in-hand view): shape, scale, readability.
4. **Hands**: grip on every gun at hip and ADS, support hand on handguard, reload pose, sights mounted straight,
   utility items held/thrown plausibly; no clipping or floating hands.
5. **Modular function**: fit each attachment in the inventory, verify the stat change (run the tests) and the visual
   (sight line through the fitted sight, zoom levels, suppressor removes flash). Report failures as bugs.
Score < 8 -> fixes go back to the producing track (max 3 rounds per area). Final scores go in this file.

## Scores
| Area | Round 1 | Round 2 | Round 3 |
|---|---|---|---|
