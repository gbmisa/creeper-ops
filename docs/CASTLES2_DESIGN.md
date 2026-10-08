# Castles 2.0 (MASTER_PLAN Stage 21)

Settled by the user (2026-10-08): bigger **concentric** castles captured **in stages**
(gatehouse → bailey → keep), **walkable interiors** for the key buildings, **hostile castles
are active fortresses**, and **held castles are a forward base, territory and an economy hub,
never a win condition**. CW3 rules for creeper and the network are unchanged
([CREEPER_SPEC.md](CREEPER_SPEC.md)). This doc extends [STRONGHOLDS_DESIGN.md](STRONGHOLDS_DESIGN.md) §3.1–3.4.

Level rows opt in with `"plan": "concentric"`. Rows without it build the Stage 7 castle
exactly as before (`CastleShape`), so old smoke tests and the cave keep working until both
levels are converted (Phase 6).

---

## 1. Layout grammar (`CastleShape2.build(g, row) -> lay`)

```
 k = depth from the outer rect edge (n = row.size, odd, 29..45; B = row.bailey, default 6)
 k -4..-3 apron  ·  k -2..-1 moat / cliff gap (outer only, Stage 7 code)
 k 0..1   OUTER WALL   yard + 3   (2 thick, wall walk on top, breachable segments)
 k 2..B+1 BAILEY       yard       (outer ring of open ground: garrison, engines' targets, your forward base)
 k B+2..B+3 INNER WALL yard + 4   (taller than the outer wall, breachable segments)
 k >= B+4 WARD         yard       (inner ground round the keep)
 centre   KEEP         11x11 (9x9 when the ward is narrow): hall, spire column, roof
```

| Piece | Cells | Height (over yard) | Notes |
|---|---|---|---|
| Corner tower (outer) | 5x5 at k 0..4 on both axes | roof +6 | Spiral stair inside (§2). Doors: bailey (+0) and both wall walks (+3). Engine/Sentinel post on the centre pillar |
| Outer gatehouse (per outer gate) | 13 wide (t = n/2 ± 6), k 0..4 | roof +6 | 3-wide **passage**: k 0..1 are the faction **gate** cells, k 2..4 the **gate hall** (capture point 1). Two 5x5 flanking towers with doors into the gate hall (+0) and onto the wall walk (+3) |
| Inner gatehouse | same, on the inner wall (`inner_gate`, default: outer gate side turned 90°) | roof +7 | Gate cells in the inner wall, gate hall on the ward side. Tower doors open **only** to the ward gate hall and the inner wall walk (never the bailey: raiders in the bailey must break the inner gate or a wall) |
| Keep | 11x11 centred | walls and roof +7 | Hall floor +1 (shallow ward creeper stays out), 3-wide door facing the inner gate, straight stair up the far side to a roof hatch. 11x11 keeps carry the 3x3 obsidian **spire column** (Spire material, `spire_h`) through the hall centre: the landmark stays |
| Climb routes | outer: pillars on k = -2 (Stage 7); inner: pillars on the bailey side of the inner wall (`inner_climbs`) | rising 1 a pillar | Gaps raiders can't step; the Operative's way in without a gate |
| Moat / drawbridge / raised plateau | outer ring only | as Stage 7 | `variant`, `moat`, `bridge` work as before (bridge on the first outer gate) |

**Courtyard** (`lay.courtyard`, what the old code calls the castle interior) = every natural bailey
and ward cell; `lay.bailey` and `lay.ward` split it. Consumers that only knew the Stage 7 keys
(`rect, yard, wall_top, segments, gates, bridge, winch, climbs, pump_cells, courtyard, towers,
home, pump_at, spire`) keep working; new keys: `plan, rings, bailey, ward, zones, interiors,
stages, crown_at, engine_posts, vaults, keep_box`.

- `lay.spire` on a concentric castle is `{ centre: keep centre, top, column, entry: keep door, pad: [] }`.
  `lay.zone` replaces `spire.column`/`spire.top` as the capture test for every castle
  (`{ cells, y }`, Stage 7 rows fill it from the spire top).
- Segments and gates carry `ring: "outer" | "inner"`. Walls stay 2 thick and breach to yard
  height through `TerrainEdit` as before. Towers, gatehouses and the keep are never segments:
  they are not breachable.
- Every level stays whole levels; nothing is decorative noise. Walls are `STONE`, the spire column `SPIRE`.

## 2. Interiors: a roof layer (`Grid.roof`, `GridRoofs`)

**Problem:** the world is one heightfield; a room needs a floor and a ceiling on the same cell.

**Chosen: a second, Operative-only walk layer.** `Grid.roof[i]` is a whole level (0 = none). The
cell's `height` stays the **floor**. Precedent: drawbridge decks are already a second walk layer
read by `stand_y`; a roof is the same idea for one faction (the Operative).

| Who | Sees |
|---|---|
| Creeper sim, terrain mesh, structures, raiders, units, raider/unit pathing | the floor only. Creeper flows in through doors and under roofs by the unchanged cell rule. Raiders and units walk interiors (passages, stairs) like any terrain |
| Operative (`PlayerController` via `GridRoofs`) | **upper layer** when the feet are within a step of the roof (`feet ≥ roof − CLIMB`): the roof is ground. **Lower layer** otherwise: the roof is a ceiling (`ROOF_THICK` slab; jumps stop under it, a cell whose ceiling is too low to stand under is a wall) |
| `Grid.raycast` (rifle, Sentinel/mortar line of sight, command picks, Operative build) | roof slabs are solid, so you can't shoot the heart through the keep roof and Sentinels can't see into halls |

- Roofs only go where the headroom is ≥ 2 levels (2.5 m; slab 0.5 m; the Operative's head is 1.85 m).
  The top steps of a stair stay open (the **hatch**), so the stair walks straight out onto the roof.
- Layers can't mix: under a roof the head clamp keeps the feet ≥ 1.75 levels below the roof, more than the
  1.15 level step threshold.
- Roof cells are `blocked` (no building). Roof slabs are meshes (`CastleInteriorMeshes`), lit inside by braziers.
- Rejected: physics collision meshes (the controller never uses physics; raiders, units and
  creeper would disagree with it), a full second `height` layer for everyone (raider fields, the creeper sim
  and pathing would all need two layers: weeks of work for the same play).
- Known limits: creeper deeper than a roof shows through the slab (only at depth ≥ 2 inside a hall, the
  castle is lost by then); creeper under roofs isn't visible from the command view (Grok: fade roofs in
  command view, §9).

**Stairs:** tower interiors are a 3x3 ring round a solid centre pillar. Ring cells rise one level each
(spiral, +0..+5) with two landing cells; doors are wall cells cut to the level of the ring cell beside
them. `CastleStairs.spiral` brute-forces the start cell and turn direction so every requested door lines up.

## 3. Staged capture (state machine)

`c.state` keeps its Stage 7 meaning for every other system (`hostile / capturing / held / siege`).
New plain-data fields: `c.stage` (index into `lay.stages`) and `c.ring = { progress, away, contest }`.
`lay.stages` is `["gate", "bailey", "keep"]` for concentric castles and `["keep"]` for Stage 7 rows.

| Stage (c.state = hostile) | Precondition | Hold | Effect |
|---|---|---|---|
| **gate** (outer gate hall, roofed, behind the hostile gate) | none | Operative in the gate hall `GATE_TIME` 10 s, no raider in it | Outer gates and drawbridge are **yours** (units walk in, raiders see a wall); outer Sentinels on the gatehouse die |
| **bailey** (3x3 bailey cells before the inner gate) | stage gate held, **every war engine destroyed** | `BAILEY_TIME` 12 s, no raider in it | The bailey is **buildable** for you (forward relays and weapons for the keep assault) |
| **keep** (keep hall) | stage bailey held | the crown nest in the hall is **shielded** until then; kill it → `capturing`, hold the hall `CAPTURE_TIME` | `held` (Stage 7 rules: Aether, Salvage, keep sender, turrets) + §5 perks |

- Progress decays at `CAPTURE_DECAY` while you're away; raiders in the zone **contest** it (no progress).
- **Ring retake while hostile:** raiders holding the last ring you took for `RING_RETAKE` 15 s
  (no Operative there) take it back; losing the bailey destroys what you built there.
- `capturing` abandoned (Stage 7 rule) regrows the crown and returns to stage **bailey**, not 0.
- **Held → siege → hostile:** siege starts when raiders enter the bailey or the ward; the retake
  timer only runs while raiders stand in the **ward** with no turret alive and the Operative not in the hall.
  A retake resets `c.stage` to 0 (both gates enemy again).
- Each ring is its own defensive line for both sides: hostile, the outer ring keeps your units out
  until the gate stage; held, raiders must break the outer gate/wall, then the inner gate/wall.

## 4. Hostile fortress: war engines (`CastleEngines`)

Stage 7 Sentinels stay (snipe 32 cells, bolt telegraph). New: **Trebuchets** on the outer corner
tower roofs (`engines` row key, default 2 on concentric castles). They make a hostile castle impossible to ignore:

| Key (`CastleDefs.ENGINE`) | Value | Why |
|---|---|---|
| range / min | 40 / 8 cells | Outranges Snipers (26) and Sentinels (32): your network can't creep up unanswered |
| interval | 11 s | Slow, heavy |
| telegraph | 3.0 s growing ground ring (terrain shader `shells`, the enemy mortar ring) + whistle | Fair: the Operative and units can walk out |
| blast | 2.5 cells; structure 45, unit 25, Operative 22 | One volley hurts a cannon (40 HP) badly, kills relays |
| hp / respawn | 140 / 150 s while the bailey is hostile | Kill them (Operative, Snipers, Lance, Bertha) to unlock the bailey stage |
| targets | weapons first, then other structures, units, Operative (needs line of sight to the Operative only) | Like enemy mortars |

Engines stop for good when the bailey is taken. The spire pump (moat → enemy build material)
and reprisal/siege raids (`CastleRaids`) carry over unchanged.

## 5. Held castle perks (anti-tedium; `CastlePerks`, numbers in `CastleDefs`)

Holding castles stays optional: none of this is needed to win, all of it shortens the walk.

| Perk | Rule | Number |
|---|---|---|
| **Reach** | Your weapons within `REACH_RADIUS` cells of a held castle's centre fire `REACH_BONUS` further (`WeaponLogic.range_cells` hook) | 28 cells, +25% |
| **Forward muster** | A held castle gets a free **Castle Barracks** in its ward beside the keep sender (`CastleKeeps`): units train and resupply at the front | 1 per castle, normal cap |
| **Ward** | Inside the outer wall of a held castle the creeper drains `WARD_DRAIN` depth/s per wet cell (`CreeperSim.remove`, no rule change); hives within `WARD_HIVE_RADIUS` spawn `WARD_HIVE_SLOW` slower | 0.03/s, 30 cells, −30% |
| **Economy hub** | `lay.vaults` (2 ward cells beside the keep) are the slots for rich Salvage Engines. `CastleVaults.ships(castles, cell)` → false while the castle around that cell isn't held | API only (engines are 9b) |
| Stage 7 | Aether + Salvage trickle, keep packet sender, turrets, wall repair | unchanged |

`castle_only` production (titans/units only buildable inside held castles) is designed but left
to Stage 21b content: `CastleVaults.inside_held(castles, cell)` is the placement test to use.

## 6. Raids and raiders against two rings

- `castle_goals()` = ward cells, plus **inner** breach cells (bailey side of inner gates/segments) when the
  inner ring is sealed, plus **outer** breach cells when the outer ring is sealed. One flow field, two breach lines.
- Wall/gate prey rows exist for both rings; a ring's pieces are prey while that ring is sealed and yours.
  Outer moat walls are still out of reach; inner walls are always reachable from the bailey.
- Garrison (hostile) lives in the bailey (`lay.home` = the bailey standard). Sentinels stand on the tower roofs.
- **Creeper:** unchanged. It ignores gates, decks and roofs; walls and the moat are the only barriers.
  The keep hall floor is +1, the inner wall +4, so creeper reaches the hall last.

## 7. Level data

```
{ "id", "name", "x", "z", "size": 41, "floor", "plan": "concentric", "variant", "moat", "bridge",
  "gates": ["s"], "inner_gate": "e", "bailey": 7, "climbs": ["w"], "inner_climbs": ["n"],
  "spire_h": 22, "engines": 2, "guards": 6, "yield": 1.5 }
```
Sizes: Level 2 castles 35–43. Level 1 (80x80) gets two compact concentric castles (29–31): a
35+ castle would fill half of that map. Revisit if the user wants Level 1 larger.

## 8. File plan (all new unless marked)

| File | Owns | Budget |
|---|---|---|
| `level/castle_defs.gd` | v2 tunables (def table, keeps `config.gd` free of conflicts) | 80 |
| `level/castle_shape2.gd` | ring grammar, walls, gates, moat (reuses `CastleShape` helpers) | 220 |
| `level/castle_stairs.gd` | spiral tower stairs, straight stairs, door cutting, roofs | 200 |
| `level/castle_keep_shape.gd` | keep hall, column, roof stair, zones | 160 |
| `world/grid_roofs.gd` | Operative layer, ceiling, roof slab test | 130 |
| `level/castle_interior_meshes.gd` | roof slabs, door lintels, braziers + lights | 180 |
| `level/castle_stages.gd` | staged capture, contest, ring retake, gate ownership per ring | 220 |
| `level/castle_engines.gd` + `castle_engine_fire.gd` | trebuchet state/targets/telegraph, models | 200 each |
| `level/castle_perks.gd`, `castle_vaults.gd` | reach, ward, hive slow; engine/placement API | 160, 60 |
| `level/castle_debug.gd` | `--castle2=I,spot`, `--stage=I,N` hooks | 120 |
| `core/smoke_castles2*.gd` | shape, interiors, capture, engines, perks | ≤ 250 each |
| shared (small, additive) | `grid.gd` (`roof` array, raycast), `player_controller.gd` (3 calls), `weapon_logic.gd` (range hook), `enemy_mortar_fire.gd` (extra telegraph rings), `debug.gd` + `smoke_test.gd` (1 line each), `game.gd` (engine prey) | |

## 9. Built here vs left for Stage 21b (Grok)

**Here (Opus):** shape v2, roofs and interiors, staged capture, engines, perks, vault API, L1/L2 conversion, smoke.
**21b:** banners/braziers/interior props, wall texture variety (castle_stone shader path), roof fade in command
view, turret variety, castle guards/garrison placement (hall guards, wall patrols), `castle_only` content,
gatehouse portcullis animation, anything listed unfinished in `tasks/STAGE21_progress.md`.
