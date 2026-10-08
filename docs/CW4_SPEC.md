# Creeper World 4 — observed simulation behavior

A behavioral model for designing an original game. It describes what the simulation does. It is not an implementation and it is not a port of CW3.

CW3's measured rules are in [CREEPER_SPEC.md](CREEPER_SPEC.md). Where CW4 uses the same number, that is called out. Where it does not, the CW3 rule does not carry over.

## How this was checked

| Source | What it supports |
|---|---|
| Installed game (`Creeper World 4`, IL2CPP) | Unit type names, and that creeper is updated as grid events (add, damage, set, clip, digitalis, walls vs anti-creeper). The flow fraction was **not** recovered from `GameAssembly.dll` in this pass. |
| Local story save, Farsite `story1` | The map is a heightfield: 180 by 110 cells. `tickcount` was 26553. |
| Knuckle Cracker wiki, `cw4:info:player_unit_data` and the unit pages | Weapon intervals, ammo, damage, costs, ERN effects. The wiki presents these as the game's numbers. |
| Kalil, *CW4 Useful Numbers* (Steam guide, playtest) | Cross-check of energy rates, anti-creeper cancellation, and mortar range vs height. His cannon timings match the wiki fire-rate buff. |

Per-second figures are at speed 1. Intervals in the tables are **frames**. The game runs at 30 frames per second, so a delay of 30 is one second and a delay of 8 is 0.267 seconds.

## Tick basis

| Quantity | Value | Basis |
|---|---|---|
| Simulation rate | 30 ticks per second | An emitter interval of 30 is 1 second. |
| Map | One height per cell | Farsite story 1 is 180 × 110. Creeper is a depth on that grid, drawn as a 3D volume. |
| Depth vs terrain | 1 terrain level = 1 depth | A custom mode can change this (CSM uses 100). Default is one-to-one. |
| Energy | Continuous, spent in packets | Build costs and ammo below are in energy, unless a unit uses Bluite, Arg, or Liftic. |
| Stored depth | About ±2147 | A damage monitor treats 2147 as a full cell. Same order of magnitude as CW3's cap. |

Anti-creeper is negative creeper in the same cell. Equal volumes cancel. A playtest of matched stacks found no leftover and no hidden advantage.

## 1. Creeper fluid

A cell holds a signed depth. Positive is creeper. Negative is anti-creeper. Flow seeks equal **heads**: terrain height plus depth. One level of climb takes one extra depth on the lower side, unless a map overrides the height scale.

The transfer fraction, the per-edge clamp, and whether a tick still exchanges only east and south, were measured for CW3 (μ = 0.04, at most 16% of a cell per tick). Those constants were **not** re-measured on the CW4 binary. Do not copy the CW3 μ into CW4 until that pass is done.

What is established for CW4:

- The presentation is 3D. Cannons and snipers aim in elevation and lose line of sight against steep ground. Mortars lob, so they mostly ignore walls.
- **Mesh** is a channel painted on the map. It has to be a continuous line back to an emitter, and a break withers. Active mesh carries creeper uphill and across void. Limited playtesting put the stable mesh depth about 4 above the surrounding creeper when an emitter is feeding it. Over a void, the mesh wants the same depth as the creeper at the ends.
- **Breeder** terrain multiplies whatever flows onto it. Blue multiplies creeper, white multiplies anti-creeper, yellow multiplies both. Rate, cycle, and cutoff are per paint, set in the editor. Creeper breeder, stashes, and emitters stop when the map's creeper cutoff is reached. Anti-creeper breeder does not.
- **Creeper++** is an optional clock. After a grace period, every `Creeper++ Time` the multiplier increases by 1, from 1 up to `Creeper++ Max`. It multiplies emitter payload, creeper-breeder rate and cap, and the cutoff. It divides void height. At 10×, nullifiers stop working.

## 2. Emitters

An emitter is a 3×3. Each pulse **adds** its emit amount. It does not raise the cell up to a level the way a CW3 emitter does. The amount is split across 8 of the 9 cells. One cell, chosen at random, is skipped. A negative amount adds anti-creeper instead.

Interval is in frames. 30 frames is one second. Emitters turn off at the creeper cutoff. A nullifier suppresses an emitter for as long as the nullifier stays powered. Mesh under an emitter activates only if the mesh touches the center cell.

Nominal rate, while the ground stays below the cutoff:

R = (emit amount) / (interval / 30) depths per second

That volume is spread over 8 cells, so each receiving cell gains R/8. Because this **adds**, a pooled emitter does not slow down the way a CW3 top-up emitter does. It slows only at the cutoff, or if something else is removing creeper.

## 3. Energy

The Rift Lab is the command node. It makes **1 energy per second** on its own. A new mission starts with **10** stored. The lab has 10 health. If it dies, no build or ammo packets move for the 20 second respawn, and it can be placed again after that. It can move without dropping the network. Packet dispatch can be limited to build only, ammo only, or priority to towers or miners.

Storage reads yellow under 50 and red under 25. Players describe the vanilla cap as 100. UltraCaps add storage and must be on the network. The exact bonus per UltraCap was not on the unit page read for this pass. The earlier project note of +100 per UltraCap is unverified.

### Towers and soylent

A tower is collector and relay together. It costs **5** energy. It lays a **square** field of at most **121** cells (11×11). A full, unobstructed, treeless field at 100% link efficiency makes

0.333334 energy per second

which is 1 energy per minute for every 6 soylent cells (0.333334 / 121 × 6 × 60 ≈ 0.99).

The field does not cross a rise or drop of more than **5** terrain levels. It only exists while the tower is connected to the Rift Lab, possibly through a Micro Rift. The field spreads after the tower finishes, so early income is below the steady rate. The wiki's 27 second payback for a 5-energy tower is longer than 5 / 0.333 ≈ 15 seconds because most of that wait is the field filling in.

**Eco** (trees) multiplies that cell by 5. A field that is half eco is 3× a bare field: 1.0 energy per second. A fully forested 121 is 1.667 per second. Creeper reduces eco to stumps. Stumps regrow on soylent once the cell is dry. A building on eco leaves a stump until the building is gone.

**Link loss** follows network hops, not straight-line distance. A playtest still had 86% after 12 links. The wiki also says packet travel, at its worst, cuts income by about 20%. Those are reported separately here. There is no closed formula yet. Pylons and Micro Rifts shorten the path. The unit menu shows the tower's efficiency.

The ERN portal's energy-collection upgrade is +50% once it has spun up, and the spin-up is part of the soylent formula (cell count and trees). A full bare tower goes from 0.333 to **0.500**. A miner goes from 1.0 to 1.5. Solar panels are excluded.

### Other producers

| Producer | Cost | Steady energy per second | With energy-collection ERN | With an ERN module on the unit |
|---|---|---|---|---|
| Rift Lab | — | 1 | 1.5 | — |
| Tower, 121 soylent, no eco | 5 | 0.333 | 0.500 | none |
| Tower, 121, half eco | 5 | 1.0 | 1.5 | none |
| Miner | 40 | 1 | 1.5 | 5 |
| Miner, both | 40 | — | — | 7.5 (1 × 1.5 × 5) |
| Solar 3×3 | — | 0.2 | none | none |
| Solar 5×5 | — | 0.5 | none | none |

Miner and portal bonuses multiply. Solar is unaffected, including by the portal.

### ERN portal

Six slots. Each takes one ERN crystal. The effect ramps **linearly over 120 seconds** and resets if the crystal is pulled. At full charge:

| Slot | Effect |
|---|---|
| Energy collection | +50% to lab, towers, and miners. Not solar. |
| Mine production | −50% production delay on factory resource units, including Bluite from miners. |
| Build speed | Build-packet interval shorter by 8 frames. |
| Move speed | +50% where the whole unit moves, and for aerial units. Not porter drones or terp drones. |
| Fire range | +25% weapon range. |
| Fire rate | −25% weapon fire delay. |

An ERN **on a unit** is a different, immediate bonus. It does not ramp. See the weapon table.

## 4. Weapons

Damage in the cannon and mortar columns is creeper depth removed per shot, at a deep target. A mortar cannot remove more depth from a cell than that cell holds, so it is weak against a thin front. A cannon shoots the **ground** inside line of sight, not the top of a wave. If the ground is hidden, a tall adjacent wave is safe. Cannon and sniper range do **not** grow with height. Mortar range does: higher ground relative to the target reaches farther than the base range below. Cannon and sniper also have a limited upward aim. A sniper's taller barrel covers more elevation than a cannon.

Snipers do not shoot creeper, spores, or air sacs. They shoot blobs, skimmers, forbs, glops, eggs, and scripted specials. The parenthetical on the sniper row is 0.6 hit points per shot.

Sprayer "damage" is anti-creeper created. Ammo is Bluite, not energy. Missiles use Arg. A missile that misses and hits terrain explodes like a bomber bomb.

Intervals are frames at 30 Hz. "Portal" means the matching portal upgrade at 100% charge. "ERN" means a crystal on that unit.

### Cannon (energy)

| Buff | Range | Interval | Ammo / shot | Damage / shot | Damage / s | Ammo / s | Damage / energy |
|---|---|---|---|---|---|---|---|
| None | 9 | 8 | 0.25 | 12 | 45 | 0.9375 | 48 |
| Portal fire rate, or range | 11 | 6 | 0.25 | 12 | 60 | 1.25 | 48 |
| ERN on the cannon | 18 | 4 | 0.20 | 12 | 90 | 1.5 | 60 |
| Both | 22 | 3 | 0.20 | 12 | 120 | 2 | 60 |

Unbuffed, this is the same 12 damage, 8-frame cycle, and 0.25 energy as the CW3 pulse cannon (3.75 shots per second, 45 depth per second). Whether CW4 still spreads that 12 across a disk of 1-depth hits was not re-checked. Packet requests go from every 15 frames to every 5 when the cannon holds an ERN.

A playtest on a 2×2 stack of depth 250 took 67 s unbuffed, 50 s with the fire-rate portal, 33 s with an ERN, and 25 s with both. 67/50 ≈ 1.34 and 67/33 ≈ 2.03, which matches −25% delay and a doubled rate. The absolute time is slower than 45 depth per second on 1000 depth, so the published 45 is a peak against a deep, well-aimed field, not that stack.

### Mortar (energy)

| Buff | Range | Interval | Ammo / shot | Damage / shot | Damage / s | Ammo / s | Damage / energy |
|---|---|---|---|---|---|---|---|
| None | 13 | 90 | 3 | 180 | 60 | 1 | 60 |
| Portal | 16 | 67 | 3 | 180 | 80.6 | 1.343 | 60 |
| ERN | 26 | 45 | 2 | 180 | 120 | 1.333 | 90 |
| Both | 32 | 33 | 2 | 180 | 163.6 | 1.818 | 90 |

It aims at the deepest creeper in range and lobs. Base cycle is 3 seconds, not 1. An older project note of range 9 and 3.4 packets per shot does not match this table.

### Sprayer (Bluite)

| Buff | Range | Interval | Ammo / shot | AC / shot | AC / s | Bluite / s | AC / Bluite |
|---|---|---|---|---|---|---|---|
| None | 9 | 10 | 0.2 | 1.8 | 5.4 | 0.6 | 9 |
| Portal | 11 | 7 | 0.2 | 1.8 | 7.71 | 0.857 | 9 |
| ERN | 18 | 5 | 0.2 | 1.8 | 10.8 | 1.2 | 9 |
| Both | 22 | 3 | 0.2 | 1.8 | 18 | 2 | 9 |

Always-on still prefers creeper in range. With nothing to shoot, it dumps anti-creeper under itself. Destroying a sprayer drops its loaded ammo as anti-creeper on its center cell. A collector field can pull nearby anti-creeper into a pile.

### Sniper (energy) and missile (Arg)

| Weapon | Buff | Range | Interval | Ammo / shot |
|---|---|---|---|---|
| Sniper | None | 30 | 30 | 6 |
| Sniper | Portal | 37 | 22 | 6 |
| Sniper | ERN | 45 | 15 | 3 |
| Sniper | Both | 56 | 11 | 3 |
| Missile | None | 40 | 16 | 4 |
| Missile | Portal | 50 | 12 | 4 |
| Missile | ERN | 60 | 8 | 2 |
| Missile | Both | 75 | 6 | 2 |

An ERN is ×1.5 range on these two, not ×2. Sniper hit points are 0.6 per shot.

### Bertha (energy)

Unlimited range. It can auto-aim at the deepest creeper on the map. The portal fire-rate upgrade does not change its interval.

| Buff | Interval | Ammo / shot | Damage / shot | Damage / s | Ammo / s | Damage / energy |
|---|---|---|---|---|---|---|
| None or portal | 180 | 40 | 1450 | 241.7 | 6.67 | 36.3 |
| ERN (three shells) | 180 | 40 | 4350 | 725 | 6.67 | 108.8 |

180 frames is 6 seconds. The ERN triples the salvo and does not add ammo cost. On energy efficiency it is worse than a cannon (48) or a mortar (60) until it holds an ERN.

### Nullifier (energy)

It can be built only in range of an emitter, spore tower, blob nest, skimmer factory, or air-sac cauldron. While it has energy it suppresses those targets: they sit there and do nothing. If the pool hits empty it must recharge fully before it suppresses again. A constant-fire playtest put the draw near **1 energy per second**, the same band as a mortar. The exact charge size was not in the weapon table.

Overload, on maps that allow it, spends a large charge and destroys the nullifier and the target. It is off for the campaign.

### Build costs

| Unit | Built with | Ammo |
|---|---|---|
| Tower | 5 energy | — |
| Pylon | 25 energy | — |
| Miner | 40 energy | — |
| Refinery | 80 energy | energy |
| Terp | 50 energy | energy |
| Porter | 40 energy | energy |
| Cannon | 25 energy | energy |
| Mortar | 40 energy | energy |
| Sprayer | 30 energy | anti-creeper |
| Sniper | 40 energy | energy |
| Missile | 40 energy | Arg |
| Nullifier | 50 energy | energy |
| Bomber / AC bomber | 100 energy | energy / anti-creeper |
| Bertha | 200 energy | energy |
| Shield | 20 Arg | Arg |
| Runway | 200 energy | — |

An ERN on a miner multiplies energy by 5 and Bluite rate by 5. On a refinery it doubles Liftic per Greenar, 12 to 24. On a terp it doubles range and dig speed. On a pylon it doubles link range. Towers do not take a unit ERN.

## 5. Ratios

Speed 1, no ERN, no eco, a tower at 100% link efficiency, weapons firing every cycle into a deep target.

**Collectors per cannon.** A cannon spends 0.9375 energy per second. A full tower makes 0.3333. Towers per cannon:

0.9375 / 0.333334 ≈ **2.81**

The Rift Lab alone (1 per second) covers **1.07** cannons. Three full towers cover one cannon with 0.063 energy per second left over.

**Collectors per mortar.** A mortar spends 1 per second. Towers per mortar:

1 / 0.333334 ≈ **3.00**

The lab alone covers one mortar. A miner (1 per second) covers one mortar or 1.07 cannons. An ERNed miner (5 per second) covers five mortars, or 5.33 cannons.

**Depth removed per energy**, peak, unbuffed: cannon 48, mortar 60, Bertha 36. The mortar is the efficient depth weapon when the pool is deep. Against a film it cannot collect that 180, because it cannot pull more than the cell holds. The cannon's 45 per second is the tool for a moving front. Anti-creeper from a sprayer cancels 9 depth per Bluite, and 5.4 depth per second, which is a poor trade against a mortar's 60 unless the goal is to stall mesh (anti-creeper slows mesh growth by about 90%).

**One emitter.** Time to add a volume of N depth-units, ignoring cutoff and removal:

T = N / R seconds, R = amount / (interval / 30)

A "50 every half second" emitter is R = 100. Matching it with sprayers takes 100 / 5.4 ≈ **18.5** unbuffed sprayers, and 100 / 9 ≈ **11.1** Bluite per second.

## What is still open

- The CW4 flow fraction and the per-edge volume clamp. CW3's μ = 0.04 must not be assumed.
- Whether cannon damage 12 is one cell or a spray of 1-depth hits.
- The exact hop-efficiency curve (one point: 86% at 12 links) and how it combines with the 20% packet-travel cap.
- UltraCap capacity, nullifier charge size, and the starting integrity of walls.
- Story-map emitter distributions. CW3's spec tabulated all 23 planets. CW4's campaign maps were not unpacked in this pass. One save, Farsite story 1, is 180 × 110.
