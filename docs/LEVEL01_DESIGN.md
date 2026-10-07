# Level 01: "Hollow Ridge" (v2: CW loop + Blight + Barracks)

**Goal:** prove the core loop. Run a Creeper World packet network top-down, train units to push into Blight, and teleport the Operative down for the jobs only a person can do. Target length: 15–25 minutes.

## Map (80 × 80 cells, each 2 m; CW3 terraces, whole levels 0–10)
Landing mesa is level 6 with a stair ramp north; west ridge 8; NW emitter plateau 7 (creeper cascades off it); Spire Heights 10; knoll 5; east shelf 5. The ASCII sketch below is the layout, not the heights.

```
 N
 +--------------------------------------------------------------------------------+
 |  E1 (emitter, NW basin)                        ######## SPIRE HEIGHTS (lvl 9)  |
 |   ~~~~                                         #  N   S#  Blight, Spire + Nest  |
 |                                                ###  ####  ramp 0.5/cell south   |
 |                      ##N## central knoll (Blight, nest)    \                    |
 |  ~~~~~~~~~~~~ valley (creeper highway) ~~~~~~~~~~~~~~~~~~~~~~\~~~~~~~~~~~~~~    |
 |    ##N##                                                                        |
 |   # R  #  Rift (Blight) -- purple shield link -------------------> E2 (SHIELDED)|
 |    #####   vent                                                    east shelf   |
 |  ======== ridge ==== gap =====                                                  |
 |       vent            mesa (lvl 3.5) [ COMMAND SHIP ]                           |
 +--------------------------------------------------------------------------------+
 N = Spore Nest   # = Blight (no building)   R = Rift (cave mouth)   S = Spore Spire
```

## Who does what
| Threat / goal | Turrets | Units | Operative |
|---|---|---|---|
| Creeper | Blasters, Mortars (need ammo packets) | Soldiers chip, Crawlers spray | Null Sprayer |
| Emitters E1/E2 | **Nullifier** within 4 cells (E2 only after the Core dies) | no | no |
| Spore Nests (in Blight) | can't reach (Blight) | **yes** | yes (rifle) |
| Spore Spire | no (armored, Blight) | can clear its nest | **plant charge [E]** |
| Rift / Deep Core | no | **can't enter** | **yes**: 3 Shield Pylons, then the Core |

## Pressure curve (measured, headless)
- Undefended flow reaches the ship mesa at ~22 min (`node tools/balance.mjs`). Spore volleys kill an idle ship at ~19 min.
- A static, non-adapting base (`#demo`) is shredded by volleys by 15 min: the Spire is the timer that forces the first Operative drop.
- The cave floods to ~55% within 5 min, and pylons sit on the floor-1 shelves.

## Economy (Creeper World rules)
- Energy IS packets; no launch cap. The Node lands with **0 energy** and makes +0.8/s. Collectors claim a 7x7 square of dry, non-Blight land (+0.005/s per cell, shared: ~0.25/s per full field). Reactor +0.4/s for 50. Storage +30 cap.
- Pulse Cannon 25: 40 shots, a packet gives 4, fires every 0.27 s (~0.9 packets/s while firing). Mortar 40: 3 packets per shell.
- A dozen collectors feed ~3 firing cannons. Measured: `--demo` sits at ~2.4/s income vs ~12-20/s requested (STARVING), bank at 0.
- Creeper damages anything it touches: structures (6 + 14×depth HP/s), units, and the Operative's suit (9 + 14×depth/s).

## Aether and the Forge
8 surface crystals (Rift hollow, Spire Heights, the knoll, NW plateau, ridge, SE corner) plus 4 in the cave, each worth 15. Objectives pay 25-40, nests 10. The Rift sits on a level-3 rock in a level-2 hollow, so it's walkable (smoke-checked).

## Victory / defeat
- **Win:** Spire, E1, Core and E2 destroyed. Nests are optional.
- **Lose:** the Command Ship is destroyed.
- **Operative knocked out:** auto-recall, −50 energy, teleporter offline 20 s.
