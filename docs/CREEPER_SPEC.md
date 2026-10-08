# Creeper World 3 — observed simulation behavior

Measured from the installed game and from all 23 story-campaign planets. This is a behavioral model for designing an original game. It describes what the simulation does. It is not an implementation.

Per-second figures are at speed 1. At speed 2, 3, or 4 the game runs that many simulation ticks inside one displayed frame, so every rate below scales by the speed and every duration divides by it.

## Tick basis

| Quantity | Value | Basis |
|---|---|---|
| Simulation rate | 30 ticks per second | Speed 1. One tick is one full pass of flow, emitters, energy, and weapons. |
| Clock | 1 second = 30 ticks | Interface timers are tick count ÷ 30. |
| Depth | 1 depth = 1,000,000 counts | One depth is one terrain level. A cell's head is terrain height plus depth. |
| Energy | Continuous number | One packet costs 1 energy and delivers 1 ammo, or 1 build point. |
| Speed | 1, 2, 3, or 4 | The whole tick repeats that many times per displayed frame. |

Story-planet ranges below are the values actually placed on those 23 planets. A wider setting can exist outside that campaign.

## 1. Creeper fluid

Each cell holds one signed whole number of counts. Positive counts are creeper. Negative counts are anti-creeper. They share the cell. The stored range is about ±2,147 depths. The story planets do not set a depth cap, and an unset cap leaves depth uncapped.

A film thinner than 0.001 depth (1,000 counts) evaporates to empty at the end of the tick, whether the film is creeper or anti-creeper. Exactly 0.001 depth remains. A digitalis cell keeps a thinner film.

### Flow

Creeper flows once per tick. The tick reads a snapshot of the grid, then each cell exchanges only with the cell to its east and the cell to its south. Each shared edge is handled once. The same whole-number move is added to one cell and subtracted from the other, so rounding the move does not create or destroy volume. Evaporation, and a depth cap if one were set, are what remove volume.

On open ground the transfer fraction is

μ = 0.04

on both axes. A digitalis cell uses 0.20, five times the open-ground rate, on the two edges that cell initiates: east and south. Its western edge uses the western neighbor's fraction, and its northern edge uses the northern neighbor's fraction. Both fractions are per-map. On 22 of the 23 story planets they are 0.04 and 0.20. Arca sets the open-ground fraction to 0.10 on both axes and leaves digitalis at 0.20. Wind bias is 0 on every story planet. A nonzero wind is a count offset along an axis, applied before the clamp below, and it pushes creeper and anti-creeper in the same direction. The clamp still holds, so wind cannot move more than the μ fraction of a cell.

For an edge whose larger side is creeper, the proposed move in counts is

Δ = μ × ( (q_source − q_neighbor) + (h_source − h_neighbor) × 1,000,000 )

A positive Δ moves creeper from the west or north cell toward the east or south cell. The move is truncated to a whole number of counts. Equilibrium is equal heads: the same terrain-plus-depth on both sides. One terrain level of drop wants to move an extra μ depths downhill.

If the larger side is anti-creeper, the height term changes sign, so anti-creeper also runs downhill.

The move is then clamped. A cell cannot push more than μ times its own amount across that edge, and it cannot pull more than μ times the neighbor's amount. On flat ground a full cell therefore loses at most 4% of itself across one edge per tick. The height term can ask for more; the volume clamp still holds. Four edges can each take that fraction, so a cell with empty, lower neighbors can lose at most 16% of its volume in one tick.

On every edge that touches it, digitalis is treated as one terrain level lower when the height term is computed, unless the stored height is the void value 500, which is treated as a pit. That height change is separate from which cell supplies μ. Digitalis cells skip the thin-film evaporation.

Sprayer and shield fields, described with those weapons, are count offsets on the same edges. They are added before the clamp, so they also cannot move more than the μ fraction.

Walls do not flow. Once per tick, a wall loses 500 integrity for each of its four orthogonal neighbors that holds creeper whose head reaches the wall's terrain height. A diagonal neighbor does not count, and anti-creeper does not. Starting integrity is set per wall segment on the map and was not measured across the campaign.

Where creeper and anti-creeper meet, the signed exchange cancels them. A weapon's removal is separate: it subtracts from creeper and stops at empty. It does not continue into anti-creeper.

### Depth and damage

Depth decides whether a structure is wet. It does not scale the damage.

A landed unit is wet when any cell of its footprint has digitalis, or has creeper whose head sits above that cell's footing. The test is head > footing + 0.000001 depth. On flat ground the footing matches the stored height, so any positive depth wets the structure. On a shaped slope the footing can sit above the stored height, so a thin film in the low part of the cell can leave the structure dry. The slope footing formula was not recovered. A unit in the air, or otherwise not landed, stays dry.

A wet unit loses 1/240 hit points per tick. That is 0.125 hit points per second at speed 1, at every wetting depth. The same loss comes off build progress while a structure is still under construction, and a wet construction site does not request further packets. A finished unit with no health reserve is destroyed on the first wet tick.

Out of fluid, a finished unit heals 0.001 hit points per tick, which is 0.03 hit points per second, up to its maximum. Both the damage rate and the heal rate are global constants.

## 2. Emitters

Each placed emitter has its own burst depth, interval, and start delay. A stop time exists. On every story emitter it is unset in practice: the emitter runs for the rest of the mission.

If a map omits them, the built-in defaults are 1 depth, an interval of 36 ticks (1.2 seconds), and no start delay. No story emitter uses that 36-tick interval. An interval of 0 or below is forced to 1 tick.

The emitter must be finished and enabled, and its cell must be unfrozen. Bursts then fall on the ticks

tick index ≥ start, and (tick index − start) is a multiple of the interval

The tick index includes 0, so a start delay of 0 fires on the opening tick. The story campaign uses two delays: 0, and 900 ticks (30 seconds). The 30-second delay is used only twice, both on Seedet.

A burst does not add a pile on top of what is already there. It raises the emitter cell up to the burst depth. The volume added is the gap between the current depth and the burst depth. If the cell is already at or above the burst depth, the burst adds nothing. The story campaign has no anti-creeper emitters. An anti-creeper burst would lower the cell toward its (negative) burst amount by the same rule.

The panel shows burst depth and the interval in seconds, each rounded to two decimals. Interval in seconds is interval-in-ticks ÷ 30.

### Nominal rate

The nominal rate is the upper bound, reached only when every burst finds the cell empty:

R = burst depth / (interval in seconds) = burst depth × 30 / interval in ticks

R is in depths per second at speed 1. The actual long-run rate is lower whenever fluid is still standing in the emitter cell.

### Story campaign, 80 emitters on 23 planets

Intervals that occur, in ticks: 1, 5, 10, 15, 30. That is 1/30 second through 1 second.

Burst depths that occur: 1, 3, 3.5, 5, 6, 7, 10, 12, 15, 20, 25, 30, 40, 50.

Nominal rates that occur run from 2 to 300 depths per second. The slowest and fastest are real emitters, not a pairing of the biggest burst with the shortest interval. The pairs that actually exist:

| Interval | Burst | Start | Emitters | Nominal rate |
|---|---|---|---|---|
| 1 tick (0.0333 s) | 6 depth | 0 | 1 | 180 depth/s |
| 1 tick (0.0333 s) | 7 depth | 0 | 3 | 210 depth/s |
| 5 ticks (0.167 s) | 20 depth | 0 | 3 | 120 depth/s |
| 5 ticks (0.167 s) | 25 depth | 0 | 1 | 150 depth/s |
| 5 ticks (0.167 s) | 30 depth | 0 | 2 | 180 depth/s |
| 5 ticks (0.167 s) | 40 depth | 0 | 3 | 240 depth/s |
| 5 ticks (0.167 s) | 50 depth | 0 | 5 | 300 depth/s |
| 10 ticks (0.333 s) | 40 depth | 0 | 8 | 120 depth/s |
| 10 ticks (0.333 s) | 50 depth | 0 | 2 | 150 depth/s |
| 15 ticks (0.500 s) | 1 depth | 0 | 2 | 2 depth/s |
| 15 ticks (0.500 s) | 3 depth | 0 | 1 | 6 depth/s |
| 15 ticks (0.500 s) | 3.5 depth | 0 | 2 | 7 depth/s |
| 15 ticks (0.500 s) | 5 depth | 0 | 17 | 10 depth/s |
| 15 ticks (0.500 s) | 10 depth | 0 | 2 | 20 depth/s |
| 15 ticks (0.500 s) | 15 depth | 0 | 3 | 30 depth/s |
| 15 ticks (0.500 s) | 20 depth | 0 | 11 | 40 depth/s |
| 15 ticks (0.500 s) | 25 depth | 0 | 3 | 50 depth/s |
| 15 ticks (0.500 s) | 30 depth | 0 | 6 | 60 depth/s |
| 15 ticks (0.500 s) | 40 depth | 0 | 2 | 80 depth/s |
| 30 ticks (1.00 s) | 10 depth | 0 | 1 | 10 depth/s |
| 30 ticks (1.00 s) | 12 depth | 900 ticks (30 s) | 2 | 12 depth/s |

Per planet, counting nominal rates as if every burst found an empty cell:

| Planet | Emitters | Nominal output |
|---|---|---|
| Tempus | 1 | 6 depth/s |
| Carcere | 1 | 180 depth/s |
| Telos | 3 | 24 depth/s (7 to 10 each) |
| Starsync | 11 | 110 depth/s (10 each) |
| Far York | 3 | 90 depth/s (30 each) |
| Tiplex | 4 | 60 depth/s (10 to 20) |
| Flick | 1 | 40 depth/s |
| Seedet | 3 | 174 depth/s (12, 12, and 150; the two slow ones wait 30 s) |
| Ormos | 0 | — |
| Jojo | 3 | 120 depth/s (40 each) |
| Chanson | 3 | 150 depth/s (50 each) |
| Defi | 5 | 34 depth/s (2 to 10) |
| Ruine | 1 | 10 depth/s |
| Choix | 1 | 60 depth/s |
| Lemal | 3 | 630 depth/s (210 each) |
| Mistet | 3 | 360 depth/s (120 each) |
| Crosslaw | 5 | 280 depth/s (40 to 80) |
| Vapen | 3 | 720 depth/s (240 each) |
| Otrav | 8 | 960 depth/s (120 each) |
| Farbor | 10 | 760 depth/s (40 to 180) |
| Arca | 0 | — (this is the planet with 0.10 open-ground flow) |
| Meso | 5 | 1,500 depth/s (300 each) |
| Krig | 3 | 360 depth/s (60 to 150) |

## 3. Energy

Energy is a continuous number. Production and spending happen once per tick. The interface shows per-tick production and use multiplied by 30, to one decimal. One launched packet spends exactly 1 energy.

Order inside a tick: buildings produce and storage empties into the node pools; packets are then launched; overflow above the caps is parked back into storage.

### Collectors

A deployed collector yields

1/10900 energy per tick per exclusively covered cell

which is about 9.1743×10⁻⁵ energy per tick, or 30/10900 ≈ 0.002752 energy per second per cell. The ratio is stored as a 32-bit float. A full disk comes out 0.30 energy per second for every practical purpose.

Covered cells are those whose squared distance from the collector is strictly less than 36: an open disk of radius 6. That disk is 109 cells, and the scan includes all of them. A flat, unobstructed disk therefore produces

109 / 10900 = 0.01 energy per tick = 0.30 energy per second

If several collectors cover one cell, they split that cell's yield equally. The cell's total does not rise. Hills block coverage: a cell counts only with a strict line of sight in elevation, so the footing of a slope can shrink the field. The exact elevation test uses the unrecovered footing.

If a collector is standing on a power zone when it is created, or when a saved game is loaded, its radius becomes 18. Yield per cell stays the same. The radius is then fixed. Building a zone later, removing one, or moving the collector does not change it. Each rank of energy efficiency multiplies collector, reactor, and landed-node output by 1 + 0.2 × rank. The rank runs from 0 to 10, so the multiplier runs from 1 to 3.

A collector costs 5 packets to build. It is placed with no health reserve, produces only while deployed, and is destroyed on the first wet tick.

### Reactors and the command node

A reactor produces 1/75 energy per tick, which is 0.4 energy per second. If it is standing on a power zone when it is created, that rate is multiplied by 10, to 4 energy per second, and the multiplied rate stays even if the zone is later removed or the reactor is moved. A zone built afterwards does not raise it. Efficiency applies after the multiplication. It does not need land coverage. It costs 50 packets and has no health reserve.

A landed command node produces 0.05 energy per tick, which is 1.5 energy per second, times efficiency. An airborne node produces none.

### Storage

The node pool starts at 25 energy. Each energy-storage upgrade adds 50 to that pool. That upgrade has no rank cap. It does not enlarge storage buildings.

Each storage building holds 30 energy, or 300 on a power zone. Once per tick, before packets launch, a storage building pours its entire contents into the connected node pools, split by the number of pools, and then reads empty. After packets have been paid, energy above a node's cap is parked back into connected storage, filled in turn and capped per building. Landing pads that store energy are filled before storage buildings. Anything that fits neither pads, storage, nor a supply drone is discarded.

The usable bank is the node cap plus the sum of the storage caps.

### Rationing

Each unit has at most one packet request outstanding. Requests are served oldest first. A tie goes to the earlier unit.

A packet launches only when the connected nodes together hold at least 1 energy. The 1 is taken from those nodes in list order until it is paid. If the pool holds less than 1, nothing is sent, the request stays queued, and the node's missed-packet count increases. There is no partial packet.

Construction and ammo have no priority over each other beyond which request is older. The node can switch construction dispatch, or ammo dispatch, off entirely.

While a structure is building, and it is not sitting in creeper, it asks for one packet per request interval until the build cost is met. The interval starts at 15 ticks. Build-speed upgrades shorten it, down to a floor of 1 tick. The upgrade cap is 10 ranks.

Once it is built, with resupply on:

- A threshold of 0 asks whenever ammo plus packets already inbound is below the magazine.
- A nonzero threshold asks when the shortfall is at least that threshold. The built-in threshold is 1. The pulse cannon, mortar, sniper, beam, shield, and sprayer keep 1. The Bertha and the nullifier set it to 0.

The wait starts when the request is accepted, and it lasts one request interval. A pulse cannon's operating interval is 15 ticks minus 2 per fire-rate rank, so 2 requests per second at rank 0. That is faster than the cannon spends ammo. The spend rate is the limit, as long as energy is available.

## 4. Weapons

Baseline is fire-rate rank 0, fire-range rank 0, and no power zone. Fire range adds 2 cells per rank, up to 5 ranks, on the pulse cannon, mortar, sniper, and beam. A power zone typically doubles range and cuts shot cost and cooldown to one third. Weapons read the zone on every shot, unlike the collector radius and the reactor bonus, which are fixed when those buildings are created. The exceptions are in the notes. A map may replace a unit's build cost. The shot costs below are ammo, and they are global.

Cooldowns include the tick on which the weapon fires. The gap between shots equals the cooldown in ticks.

Splash removal walks outward from the impact, nearest ring first. Each hit subtracts its depth from one wet cell and stops at empty. A cell that held less than the full subtraction is cleared and still consumes the hit. The impact cell is tested twice: if it still holds creeper after the first subtraction, it takes a second subtraction and that uses a second hit.

### Firing

| Weapon | Energy per shot | Magazine | Resupply threshold | Range | Creeper damage | Rate of fire |
|---|---|---|---|---|---|---|
| Pulse cannon | 0.25 energy | 10 energy (40 shots) | 1 energy. Asks when ammo plus inbound ≤ 9. | Own cell, then a line of up to 9 cells along the barrel. A wall or a failed height check stops the line. | Up to 12 hits of 1 depth. Disk of squared distance strictly under 36 (109 cells). Only cells at or below the impact terrain. The impact cell can take 2 of the 12 hits. | Opportunity every 8 ticks (3.75 shots/s) while it holds ≥ 0.25 energy. Ammo is spent only when the line finds a target. The cycle is consumed either way. Fire-rate rank subtracts 1 tick from the 8. |
| Mortar | 3 energy | 15 energy | 1 energy | Euclidean distance of 13 cells or less, rim included. Aims at the deepest creeper in range. | 3.5 depth on each wet cell in the disk of squared distance strictly under 16 (45 cells). Terrain is ignored. The impact cell can take two hits, up to 7 depth. | Every 90 ticks (3 s, so 1 energy/s) while a target exists. Fire-rate rank subtracts 10 ticks. |
| Sniper | 5 energy | 60 energy | 1 energy | Euclidean distance of 20 cells or less, rim included, with line of sight. | None to creeper. 20 hit points to one runner or tower. | Every 45 ticks (1.5 s) while a target is tracked and the barrel has finished turning. That is 3.333 energy/s if it fires continuously. Fire-rate rank subtracts 4 ticks. |
| Beam | 1/6 energy per beam per tick | 25 energy | 1 energy | Euclidean distance of 23 cell-widths or less, in world space. Two beams. | None to the fluid. Each beam deals 1/70 hit points per tick to one spore that still carries a payload (about 0.429 HP/s). Nearest spores first. | Every tick, one hit per beam, when a spore is in range and ammo allows. Both beams firing is 10 energy/s. Fire-rate rank changes the divisor to 70 − 5 × rank. A power zone multiplies spore damage by 4 and does not cut the ammo cost. |
| Bertha | 150 energy | 150 energy (one shell) | 0. Asks as soon as any ammo is missing. | No maximum. It will not fire into the 11×11 square centered on itself (both axis distances of 5 cells or less). | 100 depth on each wet cell with squared distance strictly under 100 (305 cells). Terrain is ignored. The impact cell can take two hits, up to 200 depth. | The gun can cycle every 300 ticks (10 s). Fire-rate rank subtracts 15 ticks. Refill is one packet per 8 ticks, so a new shell takes 40 s and the sustained draw is 3.75 energy/s. |
| Shield | 0.05 energy per tick while up (1.5 energy/s) | 30 energy (20 s from full) | 1 energy | Open disk of radius 10, the shield's own cell excluded. | No hit subtraction. A radial push of 30,000 counts (0.03 depth) on every other cell in the disk, applied to creeper and anti-creeper before the flow clamp. | Stays up until the magazine cannot pay 0.05. After it drops, it waits 30 ticks (1 s) before it may rise again. |
| Nullifier | The whole magazine, spent across the charge | 50 energy | 0. Asks until full. | Open disk of radius 10 (squared distance strictly under 100, 305 cells). | No fluid damage. At the end of the charge it destroys emitters and the other creeper structures in range, or applies that structure's own nullifier injury if one is set. Then it destroys itself. | Requests every 7 ticks while arming (about 4.29 energy/s, about 11.7 s to fill). Then spends the 50 evenly over 60 ticks (2 s). |
| Sprayer | No energy shot. 5 depths of anti-creeper vacuumed from its own cell become 1 ammo. | Anti-creeper tank of 100. Exports ore once the tank exceeds 51. | Asks for anti-creeper when ammo plus inbound is below 50. | Vacuum is its own cell. The push field is an open disk of radius 14. | Pulls anti-creeper toward itself with a field of 100,000 counts (0.1 depth) on each other cell in the disk, before the flow clamp. | Ore leaves every 5 ticks while the tank is over 51. Anti-creeper requests are every 8 ticks, or every 3 on a power zone, minus the fire-rate rank, and not below 0. |

Digitalis is a separate layer with its own integrity. Fresh digitalis has 1.0. Weapon hits on it:

| Weapon | Digitalis injury | Where |
|---|---|---|
| Pulse cannon | 0.52 | Squared distance ≤ 1: the impact cell and its four orthogonal neighbors. Two shots clear a fresh cell. |
| Mortar | 0.52 | Squared distance ≤ 9 (29 cells). |
| Bertha | 0.70 | Squared distance ≤ 100 (317 cells). The rim at distance 10 is included; the creeper disk excludes it. |

Runners, separate from the fluid:

| Weapon | Runner injury | Where |
|---|---|---|
| Pulse cannon | 0.5 hit points | The 3×3 centered on the impact. |
| Mortar | 6 hit points | Squared distance ≤ 9. |
| Sniper | 20 hit points | The one target. |
| Bertha | 9 hit points | Squared distance ≤ 100. |

A power zone on the Bertha fires three shells in a 120-degree spread, each 50 world units (6.25 cells) out from the aim point. Only the first shell costs ammo, and that cost is halved to 75. The Bertha's cooldown is halved rather than cut to one third.

The sprayer's push and the shield's push are flow biases. They do not spend the μ budget twice; the clamp still limits each edge to the μ fraction of the cell.

### Survival under creeper

Contact damage is 0.125 hit points per second once wet. Heal, when dry, is 0.03 hit points per second.

| Unit | Health | Time in contact | Packets to build |
|---|---|---|---|
| Pulse cannon | 1.5 | 12 s | 25 |
| Mortar | 2 | 16 s | 40 |
| Sniper | 1.5 | 12 s | 75 |
| Beam | 0.2 | 1.6 s | 20 |
| Bertha | 20 | 160 s | 250 |
| Shield | 0.75 | 6 s | 75 |
| Nullifier | 1 | 8 s | 50 |
| Sprayer | 1.5 | 12 s | 50 |
| Collector | 0 | Destroyed on contact | 5 |
| Reactor | 0 | Destroyed on contact | 50 |
| Storage | 0 | Destroyed on contact | The standard packet cost is not used; the building's hold is 30 energy. |
| Relay | 0 | Destroyed on contact | 10 |

A dry pulse cannon heals its 1.5 health in 50 seconds.

## 5. Ratios

Baseline: speed 1, upgrade rank 0, no power zone, a collector seeing all 109 cells, a pulse cannon firing every opportunity.

### Collectors to sustain one pulse cannon

The cannon spends 0.25 energy every 8 ticks:

0.25 × (30 / 8) = 0.9375 energy per second

A full collector produces 0.30 energy per second. Collectors per continuously firing cannon:

0.9375 / 0.30 = 3.125

Three full collectors produce 0.90 and fall short by 0.0375 energy per second, so the magazine slowly empties. Four produce 1.20 and leave 0.2625 energy per second.

The landed command node produces 1.5 energy per second on its own. That covers one cannon and leaves 0.5625 energy per second, which is 1.875 collectors of surplus, or enough for 1.6 cannons:

1.5 / 0.9375 = 1.6

The cannon's request rate is 2 energy per second. It only spends 0.9375. Requests are not the limit while the pool can pay them.

A collector that sees fewer than 109 cells, or shares cells, produces in proportion to its share of each cell's 1/10900 per tick. Efficiency rank r multiplies every collector and the node by 1 + 0.2 r.

### Creeper one pulse cannon can remove

Each shot performs up to 12 subtractions of 1 depth. At 3.75 shots per second the ceiling is

12 × 3.75 = 45 depths per second

That ceiling is reached when every subtraction finds a cell holding at least 1 depth, inside the disk, at or below the impact terrain.

A single cell at the aim point is the impact cell, so it is eligible for two subtractions per shot. While it is deeper than 1, the cannon removes 2 depths per shot, which is 7.5 depths per second. The last depth, of 1 or less, takes one shot: 3.75 depths per second on a lone film.

This is a removal ceiling. It is the rate the gun can erase, given targets that are already there. Flow can move up to 16% of a neighboring cell back into a cleared cell each tick, and an emitter tops its own cell back up to its burst depth. Holding an emitter means removing whatever that top-up and the surrounding pool put back.

A full magazine is 10 energy, which is 40 shots, about 10.7 seconds of fire, and at most 480 depths removed, if no packets arrive.

### Time for one emitter to flood N cells

Take "flood N cells" to mean emitting a volume of N depth-units: enough to lay depth 1 on N cells if that volume stayed put. Spreading and terrain decide which cells actually get wet. They do not change the volume accounting.

The shortest time is the nominal rate, and it applies only while every burst finds the emitter cell empty:

T_min = N / R seconds

R is the nominal rate in depths per second. For the story campaign, R for one emitter runs from 2 to 300, on the pairs in the emitter table.

Worked bounds at speed 1:

| Source | R | Time to emit volume N |
|---|---|---|
| Slowest story emitter (1 depth every 15 ticks) | 2 depth/s | N / 2 seconds |
| Tempus, the one emitter there (3 depth every 15 ticks) | 6 depth/s | N / 6 seconds |
| Fastest story emitter (50 depth every 5 ticks; Meso has five of these) | 300 depth/s | N / 300 seconds |

If the cell still holds depth d when a burst of depth D arrives, that burst adds only D − d, or nothing if d ≥ D. The time is then longer than T_min. On open ground a cell can lose at most 16% of its volume per tick, so an isolated burst does drain quickly into empty neighbors, and early bursts on an empty map land close to the full amount. Once a pool has risen to the burst depth, further bursts add only the amount the cell has lost since the last one. Uphill flow needs a matching extra depth: equilibrium is equal heads, so each terrain level of climb takes one extra depth on the lower side.

Arca's open-ground fraction of 0.10 changes how fast a pool spreads. Arca has no emitters, so it does not change R.

## What is a constant, and what a map sets

| Quantity | Where it lives | Story campaign |
|---|---|---|
| Tick rate, depth scale, packet size | Global | 30 Hz, 1,000,000 counts per depth, 1 energy per packet |
| Open-ground and digitalis flow fractions | Per map | 0.04 and 0.20, except Arca at 0.10 and 0.20 |
| Wind | Per map | 0 everywhere |
| Depth cap | Available, unset on these maps | Uncapped |
| Thin-film evaporation, wall loss per contact, wet damage, heal | Global | 0.001 depth, 500 integrity, 0.125 HP/s, 0.03 HP/s |
| Emitter burst, interval, start | Per emitter | The pair table. 2 to 300 depth/s nominal. |
| Collector yield per cell, disk radius, reactor, node income, storage hold, node cap | Global, then upgrades and power zones | 1/10900 per cell per tick, radius 6, 0.4/s, 1.5/s, hold 30, node cap 25 |
| Shot cost, magazine, threshold, range, cooldown, splash | Global, then fire-rate, fire-range, and power zones | The weapon table |
| Build cost, placed-unit health, terrain, walls, initial fluid | Per map | Standard build costs are in the survival table. A map may replace a unit type's packet cost. |

Not recovered, and not invented here: the slope footing formula, and the starting integrity of campaign walls.
