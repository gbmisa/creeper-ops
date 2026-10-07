# Research: Creeper World + FPS Hybrid

*Compiled 2026-10-06. Sources are listed at the bottom.*

## 1. What players love about Creeper World (CW3 Arc Eternal, CW4, IXE)

| Theme | Evidence from reviews | Keep / amplify in our game |
|---|---|---|
| **The fluid enemy** | Creeper "flows and splashes across terrain", and it is the series' identity (CW4 is 95% positive on Steam with ~4.5k reviews) | Heightfield cellular-automaton creeper that pools in valleys and spills over ridges |
| **Expand-and-hold loop** | "Rush to grab as much land as you can defend. Defend it." (wurb.com) | Energy network built from relays and collectors that grows outward from the ship |
| **Conclusive victories** | Destroying emitters "feels much more satisfactory and conclusive" than walling them in | Every objective is a *kill*: emitters, the Spore Spire, the Deep Core |
| **Leapfrogging (Guppy)** | Lets you "build in disconnected locations, enabling tactics otherwise impossible" | **The teleporter beacon is our Guppy, for the player's body**: drop anywhere in ship range |
| **Terrain matters** | High ground rewards range and visibility; terraforming adds depth | Stepped terrain levels. Cliffs block energy links and the operative's path |
| **Time-pressure levels** | Farbor (stop drones building a ship) "creates genuine urgency" | Spire volleys and Core output escalate over time |
| **Pause & plan** | "Play casually while pausing" | Pause works in command mode (Space) |
| **Map editor / community** | The #1 replayability driver for CW3/CW4 | Levels are plain data files (`src/level/*.js`), so an editor comes later |

## 2. What players dislike (and how we answer it)

| Complaint | Our answer |
|---|---|
| **Late-game "cleanup duty" is tedious**: "slowly chipping away", "no escalation" | Midgame FPS incursions break the routine. Underground targets *escalate* until killed |
| **Levels drag 30–90 min** | Target length is 15–25 min for the prototype level |
| **Poor explanations, no tooltips; "consult wikis"** | Every build button has a tooltip. Objectives panel. Event log explains *why* |
| **Clunky 3D placement (CW4)** | Top-down camera with a placement ghost that turns green or red with the reason shown |
| **Creeper AI is "uniform and bland"** | Different threat types: emitters, a shielded emitter, a spore-firing spire, and a cave that floods |
| **Story incomprehensible** | Minimal and diegetic: short operator radio lines only |

## 3. Has this been done before? (Prior art)

| Game | What it does | Lesson |
|---|---|---|
| **Creeper World 4 custom maps** | CW4 has a hidden first-person mode. *Almost all top-rated player maps use it.* Fans "decided it was more fun to use the engine to play a different game." | **Strongest validation of the idea**: CW fans already want to be on the ground |
| **Sanctum / Sanctum 2** | "First TD/FPS hybrid": build mazes, then shoot from first person | Praised: "best of both worlds". Criticised: hid info and tilted too far toward FPS. **Keep TD as the spine** |
| **Orcs Must Die / Dungeon Defenders** | Third-person hero plus traps and towers | The hero is in the arena *all the time*. We separate the two on purpose |
| **Natural Selection 1/2, Savage** | One commander in a top-down RTS view while teammates play FPS | Proves the two views can share one map. Ours is single-player: **you are both the commander and the grunt** |
| **Battlezone '98 Redux** | RTS commanded from a first-person tank cockpit | It works, but RTS input from first person is awkward. **Don't command from FPS; switch modes** |
| **Executive Assault 2** | RTS with possession of units in FPS | The FPS was "clunky", transitions "jarring and ineffective". **The FPS must feel good by itself, and transitions must be fast and readable** |
| **Sentry (upcoming)** | Place traps, then run around patching holes | Similar spirit, but it uses discrete enemies, not a fluid |

**Gap in the market:** no shipped game combines a *fluid-simulation* TD/RTS with *mandatory* FPS incursions against targets the turret network *cannot* reach. The closest are fan maps in CW4, which use first person *instead of* the RTS, not alongside it.

## 4. Design pillars for this project

1. **The creeper never stops.** When you teleport down, the surface sim keeps running. Every incursion is a gamble against your base.
2. **Two jobs, one battle.** Command mode handles what turrets *can* reach. The operative handles what they *can't*: underground hearts, armored spires, shielded nodes.
3. **Every incursion changes the macro game.** Killing the Deep Core drops a shield and stops vents. Killing the Spire stops artillery. Clear cause and effect.
4. **Fast, readable transitions.** One key to drop, one key (or the pad) to recall. Getting knocked out recalls you with a penalty instead of a game over.
5. **Explain everything in-game.** Tooltips, ghost-placement reasons, and an objective tracker.

## Sources

- Creeper World 3 on Steam: https://store.steampowered.com/app/280220
- wurb.com review of CW3: https://www.wurb.com/stack/archives/5626
- Vaporlens CW3 review summary: https://vaporlens.app/app/280220/creeper_world_3_arc_eternal
- Vaporlens CW4 review summary: https://vaporlens.app/app/848480/creeper_world_4.md
- Fanatical CW3 page: https://www.fanatical.com/en/game/creeper-word-3-arc-eternal
- Creeper World IXE (Vaporlens): https://vaporlens.app/app/2257010/creeper_world_ixe
- CW4 first-person fan maps (wurb.com): https://wurb.com/stack/
- Sanctum 2 reviews: https://destructoid.com/?p=150948, https://gameinformer.com/games/sanctum_2/b/pc/archive/2013/05/16/sanctum-2-review-.aspx
- Natural Selection: https://en.wikipedia.org/wiki/Natural_Selection_(video_game); NS2 review: https://www.pcgamer.com/uk/natural-selection-2-review
- Battlezone 98 Redux: https://destructoid.com/?p=185122
- Executive Assault 2: https://vaporlens.app/app/510500/executive_assault_2.md, https://primagames.com/featured/executive-assault-2-preview
- Sentry: https://www.gamesear.com/indie-games/sentry-hybrid-between-tower-defense-and-first-person-shooter
