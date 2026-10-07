# Strongholds Design (MASTER_PLAN Stage 3)

The buildable spec for Phase A Stages 4–11. Readers: the user (approve the decisions in §0), then the models that build each stage. Numbers are first guesses; Stage 13 tunes them. All of them go in `config.gd`, a def table, or level data, never in logic.

---

## 0. Decisions to approve
These are the calls I made where the conversation left room. Everything else follows from the settled design in MASTER_PLAN §1.

1. **Castle walls, gates and spires are terrain, not meshes.** The game is a heightfield: first-person collision, raider pathing, unit pathing and creeper flow all read `grid.height`. Building walls out of raised cells means all four just work, and creeper flows *around* castles the way it does around cliffs. Decorative meshes (battlements, gate arches) sit on top. The catch: no overhangs, tunnels or interiors. A spire is a stepped tower with a ramp spiralling up its outside.
2. **Spires stay within `MAX_LEVEL` 10.** Castles sit on low ground (levels 1–4) so a spire rises 6–9 levels (7.5–11 m) above the courtyard.
3. **Gates belong to a faction.** A gate is a row of wall cells. The owner's side walks through it (the Operative and units for a player gate, raiders for an enemy gate). Everyone else treats it as a wall until it's breached.
4. **Wall materials:**
   - **Earth** (Terp, costs packets): raiders can't damage it; enemy mortars lower it one level per shell.
   - **Metal** (Terp, costs Ore): raiders can't damage it; it takes 8 mortar shells to lower one level.
   - **Stone** (castle walls only): has HP that raiders, Lancers and mortars all damage; at 0 HP the segment collapses (a breach); repaired with Salvage; can be plated with Ore, which doubles its HP and makes it as mortar-resistant as Metal.
5. **Enemy mortars can only lower *built-up* terrain** (cells higher than the level's original height). They can never dig into natural ground, so your mesa can't be carved out from under you.
6. **Hive Cores take damage only from the Operative and the Lance.** Snipers can kill hive defences and pits from outside, but the last step is always the Operative inside. That keeps the first-person half essential.
7. **One pressure value drives everything.** `pressure` goes from 0 to 1 over the level's schedule and sets spawn rates, caps, tier unlocks, hive growth and enemy mortar building. At 1.0 the level enters **Overrun**: hives send continuous waves at the Node. You're meant to win before that.
8. **Magazines hold one grade of ammo.** Switching a weapon to improved ammo empties its magazine, and only improved-ammo packets refill it after that.
9. **The Terp can't edit cells that have a structure on them** (as in CW3). If the Operative is standing on a cell that rises, they rise with it; on a cell that drops, they fall.
10. **Resources live in a new `Stockpile` instance** (Ore, Salvage), owned by `game.gd` and passed to the systems that need it. Static state like `Upgrades.aether` stays for now but isn't copied.

---

## 1. Shared foundations

### 1.1 Saveable state rule (applies to every new system)
- Each system keeps its state in **plain dictionaries and packed arrays** of ints, floats, strings, `Vector2i`/`Vector3` values, arrays and dictionaries. **No Node references inside state.**
- Nodes (meshes, bars, effects) live in a parallel `view` dictionary keyed by the same `id`. The view can be rebuilt from state.
- Every system that keeps state exposes `state() -> Dictionary` and `load_state(d)`. In Phase A they're only used by a smoke test that round-trips them, which keeps them honest until save/load arrives in Phase B.
- Timers are stored as "seconds remaining", never as absolute engine time.

### 1.2 Grid additions (`world/grid.gd`)
| Field | Type | Meaning |
|---|---|---|
| `base_height` | PackedFloat32 | Height after level build. Enemy mortars never lower a cell below it |
| `material` | PackedByte | `0` natural, `1` Earth, `2` Metal, `3` Stone, `4` Plated stone |
| `gate` | PackedByte | `0` none, `1` player gate, `2` enemy gate |
| `terp_target` | PackedFloat32 | `-1` = none, else the target level the Terp works toward |
| `terp_mat` | PackedByte | Material to lay at the target |

Wall HP is stored per **segment** in the stronghold, not per cell (see §3).

`Grid.passable_for(faction, ax, az, bx, bz) -> bool` replaces the separate climb checks.
- It applies a climb limit: `RAIDER_CLIMB` for raiders, `CLIMB` for the Operative, and the units' own value.
- A gate owned by `faction` counts as the ground beside it.
- `PlayerController.can_occupy`, `RaiderField.step_ok` and `Pathfind` all call it.

### 1.3 Terrain-editing tool (`world/terrain_edit.gd`, static)
`TerrainEdit.apply(world, edits: Array[Dictionary])`, where each edit is `{ x, z, height, material? }`. It's the **only** way gameplay changes terrain after the level is built. In one call it:
1. Writes `grid.height` and `grid.material`, skipping cells with a structure on them (`mgr.occupied`).
2. Updates the **height texture** in place (`Image.set_pixel` on the cell, then `ImageTexture.update`). The terrain and creeper shaders both read this texture, so they move together.
3. Marks the affected **terrain chunks** dirty. The terrain mesh is split into 16×16-cell chunks (a change to `terrain_mesh.gd`, which also keeps the decorative rim). Dirty chunks rebuild at most 2 per frame.
4. Calls `world.creeper.terrain_changed(cells)`: the CPU sim does nothing, the GPU sim uploads a height sub-rectangle.
5. Emits `Bus.terrain_changed(world, cells)`. The raider flow field and unit pathfinding listen and rebuild on their normal interval. Props on changed cells get removed.

Creeper already on a raised cell keeps its depth: its surface rises and it spills out naturally.

### 1.4 GPU creeper sim (Stage 4)
**Files:**
- *(As built: `creeper_sim.gd` stays the CPU sim **and** the shared interface; `creeper_gpu.gd` extends it. No separate `creeper_cpu.gd`.)*
- `sim/creeper_sim.gd` becomes the **shared interface**, with today's public API unchanged: `depth`, `add`, `remove`, `remove_radius`, `nearest_wet`, `deepest_wet`, `depth_at`, `depth_world`, `add_source`, `coverage`, `sources`, `ticks`, `update`.
- `sim/creeper_cpu.gd` holds today's code.
- `sim/creeper_gpu.gd` is the GPU version.
- `CreeperSim.create(grid)` returns the GPU version when `RenderingServer.get_rendering_device()` exists and `--cpu-sim` isn't passed; otherwise the CPU one. Headless always gets the CPU version.

**GPU layout:** use the main rendering device, so the creeper shader can sample the result through `Texture2DRD` with no copy. Commands go through `RenderingServer.call_on_render_thread`.

| Resource | Format | Purpose |
|---|---|---|
| `height` | r32f storage image | Uploaded at start and on terrain edits |
| `depth_a`, `depth_b` | r32f storage images | Ping-pong between ticks |
| `outflow` | rgba32f storage image | Four directional outflows per cell |
| `surf` | r32f storage image | Display level for `creeper_mesh` (replaces the CPU `_build_surface`) |
| `deltas` | storage buffer | `(cell index, amount)` pairs: emitters, weapon removals, `add`/`remove` calls |

**Each tick (15 Hz, unchanged), four compute passes over every cell.** They don't need atomics, so the result is deterministic on a given GPU:
1. **Apply deltas:** add the queued changes and clamp to `0..MAX_DEPTH`.
2. **Outflow:** the same maths as `_flow()` (four head differences × `FLOW_RATE`, scaled when the total exceeds depth), written to `outflow`.
3. **Apply flow:** new depth = depth − own outflow + the neighbours' outflow toward this cell. Dry threshold and clamp as today.
4. **Surface:** a port of `CreeperMesh._build_surface`.

**The CPU copy:**
- Every `GPU_READBACK_TICKS` (4, about 0.27 s), `texture_get_data_async` refreshes the CPU `depth` array. All gameplay reads that copy, at most about 0.3 s old.
- `add` and `remove` change the copy **immediately**, so a weapon that removes creeper sees the result in the same frame, and also queue a delta for the GPU.
- `remove()` returns the amount based on the CPU copy. It's an estimate, which is fine because it's only used for effects and stats.
- Emitters move into the delta buffer each tick, computed on the CPU from `sources` exactly as now.

**Tests:**
- Headless tests always use the CPU version. Direct writes to `creeper.depth[...]` in `smoke_test.gd` and `smoke_rules.gd` must become `set_depth(x, z, v)`, which the GPU version also queues.
- The parity test `--gpu-parity` (needs a display, so it runs on your machine) seeds the same grid in both versions, runs 300 ticks, and checks: total volume within 1%, maximum per-cell difference under 0.05, and the same set of wet cells within 2%.
- `--perf-sim=512` reports the time per tick for both versions on a 512×512 test grid.

### 1.5 Several packet senders (Stage 6)
- Defs gain `"sender": true`: the Node and the Outpost. Senders are also relays.
- In `Network.rebuild`, Dijkstra starts from **every** sender that is built, grounded and on the ground, all at distance 0. `_prev[sender] = null`. So `route(s)` automatically starts at the nearest sender along the relays, and nothing else in `packets.gd` changes for outbound packets.
- All senders share `economy.energy`. Each Outpost adds `OUTPOST_STORAGE` (50) to the bank's maximum, and no income.
- `node_ready` in `Packets.update` becomes "at least one sender ready". A flying Node no longer stops packets if an Outpost is up.

**Return packets** (Salvage and Ore) travel `route(s)` **in reverse**, from the extractor or miner to its sender, with `kind` set to `"salvage"` or `"ore"`. On arrival they credit the `Stockpile`. If the source dies mid-flight, the packet still arrives (it already left).

**Improved-ammo packets:** an `ammo` packet with `grade > 0`. At launch it costs 1 energy **plus** `AMMO_GRADES[grade].salvage` from the Stockpile. With no Salvage, the request counts as unmet demand, as energy does today.

---

## 2. Resources (`core/stockpile.gd`)
`var ore := 0.0`, `var salvage := 0.0`, `spend(kind, n) -> bool`, `add(kind, n)`, plus rolling rates per second for the HUD. The top bar shows Energy, Ore, Salvage and Aether.

| | Ore | Salvage |
|---|---|---|
| **Producer** | Miner (15 packets) on an ore deposit in network range | Extractor (10 packets, carried in by the Operative) on a Salvage deposit |
| **Rate** | 1 per 4 s per Miner | 1 per 10 s per Extractor |
| **Deposit size** | 300 (finite) | 150 (finite) |
| **Local storage while disconnected** | 10 | 15 |
| **Other sources** | None | Loot (§4.4), castle trickle of 1 per 20 s |

Miners and Extractors aren't weapons, so **creeper destroys them on contact** (Stage 1 rule).

---

## 3. Strongholds (`level/stronghold.gd` + helpers)
One class for both kinds, holding a list of state dictionaries:
```
{ id, kind: "castle" | "hive", owner: "enemy" | "player" | "none",
  state: <see below>, rect: Rect2i, floor: int,
  walls:   [{ id, cells: [Vector2i], top: int, hp, max_hp, plated: bool }],
  gates:   [{ id, cells: [Vector2i], hp, max_hp }],
  sockets: [{ id, cell: Vector2i, turret: "", level: 0, hp }],
  parts:   [{ id, type: "core" | "pit" | "spitter" | "spore" | "mortar" | "crown", cell, hp, max_hp }],
  deposits:[{ id, cell, kind: "salvage" | "ore", left }],
  capture: { progress: 0.0, retake: 0.0 }, stage: 0, timers: {} }
```
Files: `stronghold.gd` (state + update, under 250 lines), `stronghold_rules.gd` (state changes, static), `castle_shape.gd` and `hive_shape.gd` (level-data shaping helpers that write terrain via `grid.set_height` during the level build, so walls are part of `base_height`), `stronghold_meshes.gd` (decoration). `aether_towers.gd` is deleted.

### 3.1 Castle
**Shape** (`castle_shape.gd`, from a level row `{ x, z, w: 15, h: 15, gates: ["s"], floor }`):
- Stone walls 2 cells thick, 3 levels above the floor. A 1-cell walkway on the inner ring at +2, reached by ramps from the inside at 1 level per cell. That lets the Operative and turrets stand on the wall.
- A 5×5 **spire** in the middle, stepped up to `floor + 7`, with a 1-cell ramp spiralling up its outside at 1 level per cell (walkable at `CLIMB` 1.1). A 3×3 platform on top holds the **crown nest** and the **capture zone**.
- Each gate is 3 cells wide in the middle of a side.
- 4 turret sockets on the walkway corners, 1 above each gate, and 2 on the spire platform.

**States:**
| State | What happens | Leaves when |
|---|---|---|
| `hostile` | Enemy gates. Crown nest alive (HP 60, grows with pressure); it spawns a garrison of up to 4 raiders that stay inside. Enemy sockets have spitter turrets. | The crown nest dies → `capturing` |
| `capturing` | The Operative must stand in the capture zone. Progress +1/`CAPTURE_TIME` (20 s) per second while they're there; it drops 2% per second while they're away. A counterattack spawns from the nearest live hive: `2 + 2 × pressure` raiders at the current tier. | Progress reaches 1 → `held`. Progress reaches 0 with no Operative for 30 s → `hostile` (the nest regrows at 25% HP) |
| `held` | Player gates. Aether 5/min, Salvage 1 per 20 s. Sockets open for turrets, bought from command mode (select the castle) or with E in first-person. Walls repair for Salvage. | Raiders inside the walls → `siege` |
| `siege` | As `held`, plus the courtyard alarm. `retake` timer counts while at least one raider is in the courtyard, **no** turret is alive, and the Operative isn't in the capture zone. | Timer reaches `RETAKE_TIME` (15 s) → `hostile`: turrets destroyed, nest regrows at 25%. Courtyard cleared → `held` |

Raiders choose castles as targets once the castle is `held`. Their flow field treats castle wall segments as **breach targets**: when no route reaches the courtyard, they attack the nearest wall segment or gate (each wall segment is a prey entry with `hit(dmg)` on its HP pool). At 0 HP the segment's cells are set to the floor through `TerrainEdit` (a breach). Repairing costs `1 Salvage per 10 HP` and restores the height.

**Wall HP:** Stone segment 300, Plated 600 (costs 20 Ore). Gate 200.

### 3.2 Castle turrets (`level/castle_turrets.gd`, def table `TURRET_DEFS`)
They **don't use energy packets**; they're paid in Salvage. They target raiders and hive parts (and air, for Flak).
| Turret | Role | I / II / III cost | Range (cells) | Damage per shot |
|---|---|---|---|---|
| Repeater | Anti-raider, fast fire | 25 / 40 / 70 | 18 | 2 / 3 / 4.5 every 0.6 s |
| Flak | Air only | 25 / 40 / 70 | 20 | splash 3 / 4.5 / 6 |
| Lobber | Clears creeper inside and near the walls | 30 / 45 / 75 | 14 | Removes creeper like a mortar, 60% strength |

Turrets have HP 80 / 120 / 180, and creeper damages them like weapons (Stage 1 rule). Improved ammo applies to Repeaters (§5.3).

### 3.3 Hive (nest base)
**Shape** (`hive_shape.gd`, from `{ x, z, r: 6, floor }`): a ring of 1-level-high Earth berms with 2–3 gaps; a Blight zone inside (nothing buildable while active); the Core in the middle; parts at slots set by stage.

**Parts:**
| Part | HP | Behaviour | Who can damage it |
|---|---|---|---|
| Core | 150 + 100 × pressure | Razes the hive when it dies; drops 40 Salvage | **Operative and Lance only** |
| Spawner pit | 40 | Each pit adds a spawn channel; destroying pits slows spawning | Everyone |
| Spitter turret | 50 | Medium range (20 cells), lobs acid at structures, units and the Operative | Everyone |
| Spore launcher | 40 | Today's spore volleys (Beams counter them) | Everyone |
| Enemy mortar | 80 | §4.3 | Everyone; the Operative can sabotage it |

**Growth stages** (from `pressure`): 0 = Core + 1 pit; 1 (0.2) = +1 pit, +1 spitter; 2 (0.45) = +1 spore launcher, +1 spitter; 3 (0.7) = +1 pit, can build a mortar; 4 (0.9) = +1 mortar, every part gets +50% HP. New parts appear at their slots after a 20 s "growing" animation, so you can kill them early.

**States:** `active` → (Core dies) → `razed` → (an Outpost is built on the Core cell) → `outpost`.
- `razed`: the Blight clears, parts are gone, deposits are exposed. Ground is buildable.
- **Rebuilding:** at any non-active stage, 3 or more raiders standing within 4 cells of the Core cell for `REBUILD_TIME` (30 s) restore the hive at stage `max(1, stage − 1)`. Every player structure on site is destroyed, extractors included. Any **player structure** within 4 cells blocks rebuilding until the raiders destroy it. An Outpost is the natural blocker.
- Outposts cost **40 energy packets + 60 Ore** (paid when placed, like the Beacon's up-front cost but in Ore).

Today's `spore_nests.gd` becomes the hive's spawner part (rename to `hive_spawning.gd`). The `nests` rows in level data become `hives`.

---

## 4. Enemies

### 4.1 Pressure
Level data: `"pressure": { "grace": 300, "cap": 2400 }` (seconds). `pressure = clamp((t − grace) / (cap − grace), 0, 1)` after the grace period, 0 before it. Tier unlocks, hive stages, spawn interval (`lerp(20 s, 5 s)`), cap per pit (`lerp(3, 10)`) and enemy mortar building all read `pressure`. Each level can override the curve with a `"pressure_points"` array, so a level can add a spike.

**Overrun (pressure = 1):** every 45 s each active hive sends a wave of `6 + tier × 2` straight at the Node, ignoring guard rules. The HUD shows a pressure meter so the race can be seen.

### 4.2 Roster (`level/raider_defs.gd`, a table replacing `Config.RAIDER_TIERS`)
Sniper: range 26 cells, 4 damage per shot. Operative rifle and rockets as in config.
| Enemy | HP | Speed | Attack | Range (cells) | Unlock (pressure) | Loot (Salvage) |
|---|---|---|---|---|---|---|
| Skitter | 4 | 4.2 | Melee 3 dps | 0.5 | 0 | 10% chance of 1 |
| Spitter | 10 | 3.0 | Acid lob, 6 per 2 s, small splash | **20** | 0.10 | 1 |
| Brute | 16 | 3.4 | Melee 8 dps, ×3 against walls | 0.6 | 0.20 | 2 |
| Lancer | 14 | 2.6 | Beam: 1.5 s charge, then 25 damage. **Targets Snipers first**, then other weapons | **32** | 0.35 | 3 |
| Burrower | 20 | 3.0 underground | Tunnels under walls, cliffs and Metal (ignores terrain), surfaces next to the nearest **weapon** and bursts for 60 damage in a 1.5-cell radius. A dust trail shows it underground; it can only be hit while surfacing (1.5 s) | 0.5 | 0.40 | 2 |
| Spotter | 8 | 4.5 | None; lets mortars target the Operative | Sight 25 m | With the first mortar | 2 |
| Warden | 30 | 2.8 | Shield: allies within 5 cells take −50% damage | — | 0.50 | 3 |
| Ravager | 40 | 4.0 | Melee 16 dps | 0.7 | 0.60 | 4 |
| Behemoth | 120 | 2.6 | Melee 35 dps, ×3 against walls | 1.0 | 0.85 | 8 |

- Ranged enemies **stop when their target is in range and keep their distance.** Their shots are visible projectiles that take time to arrive, so they can be dodged.
- Lancers aim from beyond Sniper range, so Snipers can't answer them.
- **No fortress is automatic.** Lancers (outrange and hunt Snipers), Burrowers (ignore walls, hit weapons) and enemy mortars (outrange everything) mean a Sniper wall always needs maintenance: rebuilding, castle turrets, the Operative or the Lance. Every static defence has an enemy that beats it on its own.
- **Mixed groups** from pressure 0.35: each raid of N rolls roles as 50% front line (Brute/Ravager/Behemoth/Skitter), 35% ranged (Spitter/Lancer) and 15% support (Warden). The group moves together at the speed of its slowest member, with a 10 s gather at the hive first.

**Prey for ranged enemies:** structures, units, the Operative, castle turrets, wall segments.

### 4.3 Enemy mortars
- **Range** 36 cells, **minimum range 6**. Fires every 6 s. Blast radius 2.5 cells.
- **Damage:** structures 30, units 20, the Operative 70% of max HP at the centre (falling off with distance). Earth: −1 level at the 3×3 impact cells, never below `base_height`. Metal and plated stone: 1/8 of a level per shell, stored per cell. Stone wall segment: 40 HP.
- **Telegraph:** a launch thump sound at the mortar; a red ring grows on the target ground for `MORTAR_TELEGRAPH` 2.5 s, with a whistle for the last 1 s. The ring is a terrain-shader uniform, like range rings (never a quad). Sprinting covers 25 m in 2.5 s and the blast is 5 m across, so **it can always be dodged.**
- **Targeting:** structures in range, preferring weapons and Terps. It targets **the Operative only while a Spotter has line of sight to them** (`grid.raycast`, 25 m). The HUD shows "SPOTTED" in red.
- **Sabotage:** the Operative within 2 m holds E for 3 s, and the mortar is destroyed and drops 5 Salvage. A demolition charge (§5.2) works from 20 m.
- **When they're built:** a hive at stage ≥ 3 builds one. **Any** active hive builds one within 60 s once the Node has had no raider route for 60 s (the reaction to sealing yourself in). At most 1 per hive, 2 at stage 4. Each mortar spawns with 1 Spotter, which respawns 30 s after dying while the mortar lives.

### 4.4 Loot pickups
Loot drops as glowing pickups that last 90 s, collected only by the Operative (auto-pickup within 1.5 m). Pickups show on the markers layer as minor markers. Hive parts drop 5, crown nests 15, a Core 40.

---

## 5. The Operative

### 5.1 Extractors and supply points (Stage 9b)
- Supply points: the Command Node, any held castle, any Outpost, and the **Supply Depot** (new structure: 12 packets, relays, holds 4 extractors).
- **Ordering extractors:** select a supply point and press "Order Extractor". It becomes a packet build job (10 packets) at that supply point, with up to 4 in stock there.
- **Carrying:** standing within 3 m of a supply point and pressing E takes as many as fit (`carry` 2, raised by the upgrade). The first-person HUD shows `Extractors 1/2`.
- **Planting:** stand on a Salvage deposit (not inside an active hive) and hold E for 3 s. It becomes a player structure and links to the network as a leaf. A deposit inside an *active* hive can be planted too, and ships nothing until the hive is razed. That's high risk, but it's where Salvage is.
- Ships return packets while connected; otherwise stores up to 15.

### 5.2 Upgrades and advanced weapons (`fps/operative_upgrades.gd`, static, like `upgrades.gd`; reset each level)
| Upgrade | Per tier | Tiers | Cost |
|---|---|---|---|
| Firepower | Rifle damage +25%, rockets +1 in magazine | 3 | 20 / 45 / 80 |
| Armour | Max HP +25%, then a 30-point regenerating shield at tier 3 | 3 | 20 / 45 / 80 |
| Mobility | Sprint +10%; tier 2 double jump (needed for some ledges); tier 3 jump jet (+1 level) | 3 | 15 / 35 / 70 |
| Pack | Extractor carry 2 → 3 → 4 | 2 | 25 / 50 |

| Advanced weapon | Unlock | Salvage burned | Role |
|---|---|---|---|
| Railgun | 60 | 2 per shot | 30 damage, pierces a line of raiders, 1.5 s charge |
| Plasma thrower | 60 | 1 per second of firing | Removes creeper in a cone at 3× the rocket rate, 6 dps to raiders |
| Demolition charge | 40 | 8 each | Thrown 20 m, 120 damage to parts and mortars; can't hurt the Core (§0.6) |

Bought at the **Armoury** (the Command Node or any held castle's spire platform, via E in first-person or the castle panel in command mode). Multipliers are read through `OperativeUpgrades.mult(id)`; weapon code never reads raw config values.

### 5.3 Improved ammo
| Grade | Effect | Operative (per 30 rounds) | Network packet surcharge |
|---|---|---|---|
| Armour-piercing | +60% against Brute/Ravager/Behemoth/Warden, ignores the Warden shield | 12 | +0.5 Salvage |
| Incendiary | +2 dps for 3 s, removes creeper at the impact cell | 12 | +0.5 Salvage |
| Cluster (rockets only) | 4 sub-blasts | 15 per 3 rockets | — |

- **Unlock:** level data `"ammo_unlock": "<objective id>"` (Level 1: when the Deep Core objective becomes available). It's milestone-based, not time-based.
- Applies to the Operative, Snipers, Repeater turrets and units. For units, the barracks stock becomes the selected grade, and each resupply costs the surcharge.

---

## 6. The Terp (Stage 11)
- **Structure `terp`:** 25 packets to build, link 6, works on cells within 7 cells. A def flag `"unlock": "terp"`; level data `"unlocks": ["terp"]` (not in Level 1 by default).
- **Painting:** a command-mode tool. Drag a rectangle, choose Raise or Lower to a target level, and pick Earth or Metal. This writes `terp_target` and `terp_mat`. Painted cells show as a hatched tint in the terrain shader.
- **Working:** each Terp works on the nearest unfinished painted cell in range that has no structure on it, one level at a time.
  - Each level step requests `TERP_PACKETS` (4) packets, as a new request kind `"terp"` served after ammo and builds. Metal also costs **2 Ore per level**, paid when the step starts.
  - A step takes 3 s once paid.
- **Route rule:** sealing the Node off is allowed (§4.3 explains the enemy's answer). The placement ghost shows a warning tint when a paint would cut the last raider route ("Sealing triggers enemy siege mortars"), but doesn't block it.

---

## 7. File plan and line budgets
| File | Change |
|---|---|
| `world/grid.gd` | + `base_height`, `material`, `gate`, `terp_target`, `terp_mat`, `passable_for` (stays under 200 lines) |
| `world/terrain_edit.gd` | New (≈120) |
| `world/terrain_mesh.gd` | Chunked build (≈180) |
| `sim/creeper_sim.gd`, `creeper_cpu.gd`, `creeper_gpu.gd`, `shaders/creeper_flow.glsl` | Split and new |
| `sim/creeper_mesh.gd` | Texture2DRD path (≈130) |
| `command/network.gd` | Several senders (≈160) |
| `command/packets.gd` | Return kinds and ammo grades. **It's at 179 and will grow, so first split out `packet_requests.gd`** (`need`, `transit_headroom`, `rate`) |
| `core/stockpile.gd` | New |
| `level/stronghold.gd`, `stronghold_rules.gd`, `castle_shape.gd`, `hive_shape.gd`, `stronghold_meshes.gd`, `castle_turrets.gd`, `hive_spawning.gd` | New. `aether_towers.gd` and `spore_nests.gd` removed |
| `level/raider_defs.gd`, `raider_attacks.gd` (ranged projectiles), `enemy_mortars.gd`, `loot.gd` | New. `raiders.gd` keeps movement and thinking |
| `command/extractors.gd`, `supply_points.gd` | New |
| `fps/operative_upgrades.gd`, `fps/advanced_weapons.gd`, `ui/armoury_menu.gd`, `ui/castle_panel.gd` | New |
| `command/terp.gd`, `command/terp_paint.gd` | New |
| `ui/top_bar.gd` | Ore, Salvage and the pressure meter |

**New smoke tests go in new files** (`smoke_terrain.gd`, `smoke_strongholds.gd`, `smoke_economy2.gd`, `smoke_operative.gd`), each registered like the others, so separate branches don't conflict.

## 8. Build order notes
- Stage 5 (terrain editing) before 7 (castle breaches) and 11 (Terp).
- Stage 6 (several senders) before 8a (Outposts) and 9a (return packets).
- 8b (roster) can run alongside 7, since they touch different files.
- 9b needs 9a. 10 needs 9a. 11 needs 5 and 6.
- Stages 7, 8a and 8b each replace part of today's nest and tower code. Keep the game playable at the end of every stage, even if a feature is half-done behind a level-data switch.
