# Skirmish MAP-2: layout plan (2026-10-16)

Gregory: "a lot more cover with different routes ... CQC on the left side with a sniper in the tower to put on additional
pressure and the right side more open with a couple buildings." Data: `godot/scripts/range/skirmish_data.gd`.
Checks: `range_test_map2.gd` (in `--range-test`).

```
 z-60 ┌──────────────────────────── north wall ─────────────────────────────┐
      │ TOWER▲(marksman)       office      ┃ shack  EXTRACT        warehouse │
      │ ║ramp        crates / barrier       ┃ boss                (east)    │
      │ pump  ║  bunkhouse   ·  hotel(2F)   ┃ truck                 container│
 z  0 │ store ║  plaza       ·  row_a       ┃ truck      barracks (east)     │
      │ ·tree ║  clinic      ·  (yard)      ┃                     low walls  │
      │ garage║  cottage     ·  workshop    ┃ barriers   container  cars     │
      │ (car) ║  car                        ┃ checkpoint                     │
 z+60 └──────────────────────────── SPAWN ── south wall ────────────────────┘
       x-60  back alley runs along the west wall (x -60..-57)          x+60
             ║ = sniper street (x -50..-44)   · = inner alley   ┃ = centre lane
```

**West, old town (CQC).** Three columns of one-storey buildings plus the two-storey hotel. Every building has 2-4 doors,
and the clinic, storehouse, bunkhouse and office have inner walls (two rooms). Routes: the back alley along the west
wall, the sniper street, the inner alley, and three cross streets (market street z 18-26, the plaza, the lane north of
the hotel). Short sightlines: 5-20 m.

**Tower pressure.** The tower stands at the north end of the sniper street, so the marksman sees down the whole street
(`map2` check: 3 of 4 street points in sight) and over the open ground in front of the extract. The roofs hide the plaza
and the alleys from him (checked). The street is the fast, exposed route; the buildings are the slow, safe,
close-range one. Cover in the street (car, barriers, crate) lets you cross it in hops.

**Centre.** The checkpoint lane is kept, with three more pieces near the extract.

**East (open).** Only the barracks and warehouse. Containers, low walls, cars and barriers are spaced 8-15 m apart for
bounding; the run along the east wall stays sparse and exposed.

**Kept exactly:** the spawn, rack, extract, F93 spawn and lane cover, hotel, tower, barracks, warehouse, shack, enemy
roster and kinds, marksman spots. **Moved:** the cottage (to column 2), the west rifleman's and both Runners' starts
and routes (into the old town), the crate at (-40, -10) moved to (-40, -6), and the wall at (-26, 10) removed (now
inside row_a). The in-map tree at (-56, 4) moved to (-54, 16) (the old spot is inside the storehouse). Loot: the
cottage meds moved to the clinic; ammo was added in the garage and meds in the office (8 crates).

Next ideas (not built): rooftop access (ladders), a second storey on the clinic, container visuals (ribs/doors), and
fixing the barracks/warehouse navmesh gaps (HANDOFF known issues).
