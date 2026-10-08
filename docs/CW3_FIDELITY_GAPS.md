# CW3 fidelity gaps (spec vs. our code)

Compares [CREEPER_SPEC.md](CREEPER_SPEC.md) (measured CW3) with `main` on 2026-10-07. "Ours" values come from `config.gd`, `creeper_sim.gd` and `structure_defs.gd`. Scale note: our cell is 2 m and 1 level = 1 depth, the same as CW3's depth unit, so depth numbers can be compared directly. Times are in seconds.

## Creeper sim (affects how the fluid *feels*)
| Rule | CW3 | Ours | Effect of the gap |
|---|---|---|---|
| Tick | 30 Hz | 15 Hz (`CREEPER_TICK`) | none by itself |
| Flow | Pairwise exchange on each edge, μ = 0.04 × (Δdepth + Δheight), **clamped to μ × the cell's own volume per edge** (≤ 16 %/tick in total) | Outflow only, 0.22 × head difference per neighbour, may drain **100 %** of a cell per tick | Ours spreads ~3× faster and thinner. CW3 creeper *piles up* and creeps; ours races ahead as a film |
| Emitter | Burst **raises the cell up to** burst depth (adds only the gap) | **Adds** `amount` every interval (capped at 25) | CW3 emitters slow down when pooled and speed up when you clear around them. Ours ignore it |
| Emitter start delay | Per emitter (0 or 30 s on the story planets) | none | no mid-level surges |
| Evaporation | < 0.001 depth | < 0.0005 | negligible |
| Anti-creeper, digitalis, wind, shields | yes | no | out of scope for now |

## Damage under creeper
| Rule | CW3 | Ours |
|---|---|---|
| Wet test | any depth above footing | `MIN_DEPTH` 0.02 (dies), `DAMAGE_DEPTH` 0.06 (HP loss) |
| Damage | **flat 0.125 HP/s, depth doesn't matter** | depth-scaled: weapons 5.5 + 2.5 × depth HP/s |
| Time to die | cannon 12 s, mortar 16 s, sniper 12 s, beam 1.6 s, Bertha 160 s | cannon 40 HP ≈ 5 s at depth 1, ≈ 3 s at depth 3 |
| Unbuilt site | **loses build progress** at the same rate and stops requesting; dies only at 0 | dies instantly |
| Heal when dry | 0.03 HP/s (cannon full in 50 s) | `REPAIR_PER_SEC` 1.5 HP/s (cannon ≈ 27 s) |
| Collectors, relays, storage, reactors | die on the first wet tick | same ✔ |

## Energy
| Rule | CW3 | Ours |
|---|---|---|
| Node income | 1.5/s | 0.8/s |
| Starting bank | 25 (+50 per storage upgrade) | 0, bank 60 |
| Collector field | open **disk r 6** (109 cells), 0.30/s full | **7x7 square** (49 cells), ~0.25/s (deliberate, CW4 style) |
| Reactor | 0.4/s, 50 packets | same ✔ |
| Storage | 30, poured into the node pool | +30 bank ✔ |
| Requests | oldest first, one outstanding per structure, build request every 0.5 s | round robin, `REQ_BUILD` 2.5/s, `REQ_AMMO` 4/s |

## Weapons
| Weapon | CW3 | Ours |
|---|---|---|
| Cannon | range 9 (line along the barrel); **12 hits of 1 depth in an r 6 disk** every 0.27 s (≤ 45 depth/s); 0.25 energy per shot | range 8; 1.3 depth on the nearest wet cell every 0.27 s; ¼ packet per shot |
| Mortar | range 13; 3.5 depth on every wet cell in r 4 every 3 s; 3 energy/shot | range 16; power 8, splash 2.5, every 3 s; 3 packets/shot |
| Sniper | range 20; 20 HP every 1.5 s; 5 energy/shot | range 26; 4 power every 1.2 s |
| Beam | range 23, two beams, air only | range 14, air only ✔ role |
| Bertha | unlimited range (min 5); 100 depth on r 10 every 10 s; 150 energy/shell | range 40; power 14, splash 4.5, every 5 s; 5 packets/shell |
| Nullifier | r 10, 50 energy, 2 s charge | 4 cells to the emitter, 100 packets, 8 s charge |

## Takeaways
1. The two biggest differences in feel are **flow** (clamped pairwise vs. free outflow) and **top-up emitters**. Both are sim rules and need `creeper_sim.gd`, `creeper_flow.glsl` and `creeper_mesh.gd` changed together, plus a GPU parity re-run. That's Opus work.
2. CW3 weapons remove creeper in **area** (cannon 12 cells per shot); ours mostly single-cell. CW3 creeper is much deeper, so this keeps the balance.
3. Damage, heal and unbuilt-site rules are cheap to switch, but they go against earlier design decisions (Stage 1), so they need the user's call.
4. Changing the sim invalidates every tuned number (Level 1, Level 2 emitters, weapon power), so it should land **before** Stage 13 tuning.
