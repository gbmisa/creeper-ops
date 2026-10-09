# Brief PT3-F (Muse): show every objective at once; castle markers read as optional (playtest 3, item 29)

**Branch:** `pt3/objective-clarity` (from `integ/2026-10-09`). Touch `ui/objectives.gd` (panel layout and render only, **not** the `LIST` text: PT3-E edits that), `level/castle_stages.gd` (`marker` text only), `ui/markers.gd` (styling of `minor`/optional markers), `ui/ui_kit.gd` if a colour is needed, and a smoke file. PT3-E (`pt3/castle-economy`) runs at the same time and edits `stronghold_hooks.gd` labels and the `LIST` rows; stay out of those.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, those files.

## Gregory's report
> "It didn't show me all the objectives on screen at once. And it showed them sequentially, so I thought I had to destroy the castle."

## What Opus found
- The objectives panel lists every row, but collapsed it shows only one-line titles, and it is easy to miss when it's hidden in FPS (`_fps_open` starts false).
- **The real cause:** each hostile castle's on-screen marker shows its *next capture step* (`CastleStages.marker`: gatehouse, then bailey, then keep), one at a time, and looks just like an objective marker. So the castle read as a sequential mission.

## Tasks
1. **Panel:** always show all required objectives at once (titles), with a header like `OBJECTIVES 1/4 REQUIRED` and optional rows grouped under an `OPTIONAL` sub-header. The `[J]` toggle still expands hints. In FPS show the same compact list (not hidden by default); keep it small enough not to cover the crosshair area.
2. **Castle markers:** hostile castle markers get an `OPTIONAL` tag and a distinct colour/style (UiKit muted amber, smaller, `minor` style), and their text says what you gain, e.g. `Ashmoat Keep (optional): take the gatehouse. Holding it boosts your economy.` Keep the stage step itself (useful once you choose to attack).
3. Objective markers (spire, emitters, core) keep the strong style, so the two never look alike.
4. **Smoke rule:** on L1 and L2 at start, the panel text contains every non-optional `LIST` row; every hostile castle marker label contains "optional".

## Must not change
Victory rules, objective ids, `LIST` text, castle stage logic.

## Report
AGENTS.md format. Opus takes the screenshots.
