# Creeper World 3: Arc Eternal — mechanics reference (2026-10-06)

Research notes that drive the Godot port. Sources at the bottom. Several primary sources
(Knuckle Cracker wiki, NamuWiki, Steam guides) were behind Cloudflare/rate limits, so some
details below come from general knowledge of the game and are marked *(recalled)*.

## Economy: energy IS packets
- The **Command Node (CN)** turns energy into packets. HUD shows a **green** number
  (packets generated per second) and a **red** number (packets distributed per second).
- If distribution > generation, the CN draws from **stored** energy. When storage is empty
  the shortfall shows as **unfulfilled requests**: weapons starve and builds stall.
- There is **no separate launch-rate cap**. Throughput is limited by income + storage and by
  how fast each structure *requests*: ~2 packets/s while building, up to ~4/s for ammo.
- Sources: Collectors harvest land around them (overlapping fields share), Reactors give a
  flat amount and need no land. Storage raises the cap.
- Packets physically travel the network; relays have the longest link range. Destroying a
  relay strands everything behind it.
- Per-weapon toggles *(recalled)*: **supply on/off** (stop requesting ammo) and **hold fire**.

**What was wrong in our JS build:** `Packets.dispatch` capped launches at `PACKET_RATE*0.5`
(3.5 banked) per frame window, so at most ~3 packets went out per burst while income kept
piling into a full bank. That's the "energy always maxed, only three packets" bug. CW3 has no
such cap.

## Weapons and moving them
- Weapons are **movable**: select, click a destination; a green/red shadow shows validity.
  The unit lifts off, flies over terrain *and* creeper, lands, then reconnects. It doesn't
  fire while airborne. Ammo is kept *(recalled)*.
- Pulse Cannon: cost 25, ammo cap 10, 0.25 ammo/shot, fires every 8 frames, removes creeper
  from the 8 closest squares. Mortar: cost 40, lobs shells at deep creeper.
  Sprayer 39, Beam 78 (anti-spore), Sniper 160.
- **Titans:** Big Bertha (~250 packets, extreme range artillery, mission-gated) and
  **Thor** (~500, flying gunship from a crashed-ship artifact).
- The Command Node itself can lift off and relocate; it stops producing while moving *(recalled)*.

## Other systems (not all ported)
- Ore → anti-creeper (Sprayers, Bombers), Aether → **Forge** upgrades, Terps (terraforming),
  Shields, Guppies (air-drop packets to cut-off outposts), Strafers/Bombers, Totems,
  Power Zones (buff anything on them), Spore Towers (spore volleys; Beams shoot spores down).

## Build menu
The user asked for four screens: **Structures, Weapons, Titans, Orbital**. In our game,
Orbital holds drop-pod tech that fits the fiction: Beacon (Operative drop point), Orbital
Lance strike, and deploying the Operative.

## How the Godot port applies this
| CW3 rule | Our implementation |
|---|---|
| Energy = packets, no launch cap | `packets.gd` sends whenever energy ≥ 1 and a structure's request timer allows |
| Build/ammo request rates | `Config.REQ_BUILD` / `Config.REQ_AMMO` per structure |
| Green/red numbers + deficit | Top bar shows production, demand, and unmet demand |
| Movable weapons | `mover.gd`: lift, fly, land, reconnect (all weapons + titans + CN, not Nullifier) |
| Supply / hold-fire toggles | Info panel buttons (Z / V) |
| CN landing | `landing.gd`: choose the landing site at mission start |

## Session 4 research: numbers (Steam guides, KC forum, wiki fragments)
| Thing | CW3 | Ours now |
|---|---|---|
| Collector | cost 5, full field ~0.2 energy/s | cost 5, 29 cells x 0.008 = ~0.23/s |
| Relay | 2x collector cost, 2x link, 2x packet speed | cost 10, link 13 |
| Reactor | ~0.4/s, no land | cost 50, +0.4/s |
| Pulse Cannon | cost 25, ammo 10 packets, 0.25/shot every 8 frames (~0.94 packets/s firing) | cost 25, 40 shots (=10 packets), 4 shots/packet, 0.27 s (~0.93/s) |
| Mortar | cost 40, ammo 15, 3/shot, ~1 shot per 3-4 s, clears full depth | cost 40, 15 packets, 3/shot, 3 s, power 8 |
| Terrain | heights 1..10 whole levels, sheer walls; creeper has no max | levels 0..10, terraced (`Grid.terrace`) |
| Build tool | stays armed; chain-place collectors that build in order | same (right-click/Esc to stop) |

**Takeaway:** in CW3 one firing cannon eats the output of ~4 collectors. Weapons, not
construction, are the energy sink, so the economy must be lean for that to bite.

## Session 5: Forge (CW3) and Creeper World 4's 3D setup
**CW3 Forge** (Titan, 5x5, 100 packets): Aether (from powered Totems in CW3) buys upgrades.
Energy Efficiency 20/+20 per level, max 10, +20% output each. Build Speed, Packet Speed,
Energy Storage start at 10/+10. Fire Range, Fire Rate, Move Speed are weapon upgrades.
*Ours:* `upgrades.gd` uses the same costs. Aether comes from objectives, nests and
**crystals the Operative collects** (our stand-in for totems, and it ties FPS to command).

**CW4** (natively 3D):
- Towers are collector and relay in one, with a SQUARE 11x11 field (121 cells, ~0.33/s). They lose a little efficiency per link hop.
- The Rift Lab makes 1/s. Missions start with 10 stored energy (ours: 0, by request) and 100 storage (+100 per UltraCap).
- At a constant fire rate, cannons, mortars and nullifiers each cost about 1 energy/s.
- Mortar: range 9, 1 shot/s, 50 to build, 3.4 packets/shot.
- **Mortars reach further from high ground. Cannon, sniper and sprayer range ignore height.**
- Terps reshape terrain, and ERN modules buff units.

*Ours:*
- Square collector fields (7x7). `deepest_wet` gives mortars and Bertha +0.5 cells of reach per level of height advantage (`Config.LOB_RANGE_PER_LEVEL`).
- Weapons target anything the renderer draws as creeper. The old 2x threshold left thin, visible creeper that no weapon would shoot.
- Ammo packets are dispatched before construction.

## Sources
- [Steam: Basic Economy question (CW3)](https://steamcommunity.com/app/280220/discussions/0/540737414415305957/)
- [Knuckle Cracker forum: energy generation per second](https://knucklecracker.com/forums/index.php?msg=105826)
- [Steam: Unit movement controls](https://steamcommunity.com/app/280220/discussions/0/540737414785031156/)
- [Steam guide: Unit Descriptions](https://steamcommunity.com/sharedfiles/filedetails?id=243103280)
- [Steam guide: Basic Info](https://steamcommunity.com/sharedfiles/filedetails/?id=242973634)
- [Steam: Beginner tips (economy, relays 2x speed)](https://steamcommunity.com/app/280220/discussions/0/540738050921309200/)
- [Knuckle Cracker fandom: Structures (CW1/CW3 costs)](https://knucklecracker.fandom.com/wiki/Structures)
- [Steam: What rules does creeper follow (terrain 1-10, overflow)](https://steamcommunity.com/app/280220/discussions/0/594820656457406191/)
- [Steam guide: CW4 Useful Numbers](https://steamcommunity.com/sharedfiles/filedetails/?id=2312542241)
- [creeperworld.fandom: Forge](https://creeperworld.fandom.com/wiki/Forge)
- [creeperworld.fandom: Mortar (shoots over walls)](https://creeperworld.fandom.com/wiki/Mortar)
- [wurb.com review of CW3](https://www.wurb.com/stack/archives/5626)
- [Wikipedia: Creeper World](https://en.wikipedia.org/wiki/Creeper_World)
