# Playtest 3 feedback (Gregory, 2026-10-09)

Logged by Opus. Not briefed yet. Items marked (branch) may already be covered by Muse's unmerged branches; verify after they fold into integ.

1. **Enemy LOS:** enemies must not shoot through terrain. (fix/enemy-los)
2. **Submerged enemies:** enemies that can move in creeper must float on its surface. Right now they shoot from fully submerged and can't be seen.
3. **Spitters (rule from Gregory):** a Spitter must never outrange a Sniper. They level the base while the Operative is away. Today both have range 20 cells (raider_defs.gd:16, structure_defs.gd:69), and acid splash (1.5) lets a Spitter at the edge hit things a Sniper at the same edge can't reach. Fix: Spitter range clearly below Sniper range (e.g. 14), and add a smoke check that `spitter.range + splash < sniper.range`. Not covered by any open branch; fix/spitter-vs-structures only pauses healing on acid hits.
4. **Beam relevance:** beams go idle once the map's only mortar dies (~3 min into L1). Enemies building mortars as pressure rises should keep beams useful. (feat/enemy-castle-mortars, fix/beam-intercept-lobs)
5. **Operative survivability:** too tanky and HP regenerates. Fine for testing. Later: med kits and ammo bought with Salvage (not packets) in a shop UI. Down the road.
6. **Railgun UX:** pressing 4 shows "Unlock the Railgun (60 Salvage)" with no hint of where to buy it. The prompt stays on screen after switching guns. The Armoury is at the Command Node (walk up and press E, or select the Node in command mode). The prompt should say so and clear on weapon switch.
7. **Routing (clarified):** while a relay is unfinished, the Node routes packets through *finished* structures instead of directly to targets in its own range. Once the relay is built it switches to the direct route. The desired behaviour is a direct route from the start. fix/network-planned-relays may have misread this.
8. **Trebuchets:** take too long to kill. Add a plantable explosive the Operative places to destroy one. Infinite for testing; it will take inventory space later.
9. **Info:** Gregory wants a player-readable reference for enemies (stats live in raider_defs.gd, flyer_defs.gd, castle_defs.gd, and config.gd NEST_*).
10. **Demolition charge vs siege engines:** a mortar died without a demo charge. Trebuchets and enemy mortars should keep high HP and be killable *only* by a demolition charge (Salvage-paid), which destroys one in a single plant. Gun damage should not finish them.
11. **Totems look like Collectors:** the Totem (beacon) model needs a clearly different silhouette and colour.
12. **Lancer range (open question):** Lancer beams reach 32 cells against Sniper 20 (raider_defs.gd:21). Same problem as item 3 unless Lancers are meant to be the Operative's job.

Done: item 3 (Spitter range 14, smoke rule in smoke_rules.gd `_balance`).
