# Playtest 3 feedback (Gregory, 2026-10-09)

Logged by Opus. Not briefed yet. Items marked (branch) may already be covered by Muse's unmerged branches; verify after they fold into integ.

1. **Enemy LOS:** enemies must not shoot through terrain. (fix/enemy-los)
2. **Submerged enemies:** enemies that can move in creeper must float on its surface. Right now they shoot from fully submerged and can't be seen.
3. **Spitters (rule from Gregory):** a Spitter must never outrange a Sniper. They level the base while the Operative is away. Today both have range 20 cells (raider_defs.gd:16, structure_defs.gd:69), and acid splash (1.5) lets a Spitter at the edge hit things a Sniper at the same edge can't reach. Fix: Spitter range clearly below Sniper range (e.g. 14), and add a smoke check that `spitter.range + splash < sniper.range`. Not covered by any open branch; fix/spitter-vs-structures only pauses healing on acid hits.
4. **Beam relevance:** beams go idle once the map's only mortar dies (~3 min into L1). Enemies building mortars as pressure rises should keep beams useful. (feat/enemy-castle-mortars, fix/beam-intercept-lobs)
5. **Operative survivability:** too tanky and HP regenerates. Fine for testing. Later: med kits and ammo bought with Salvage (not packets) in a shop UI. Down the road.
6. **Railgun UX:** pressing 4 shows "Unlock the Railgun (60 Salvage)" with no hint of where to buy it. The prompt stays on screen after switching guns. The Armoury is at the Command Node (walk up and press E, or select the Node in command mode). The prompt should say so and clear on weapon switch.
7. **Routing (clarified):** while a relay is unfinished, the Node routes packets through *finished* structures instead of directly to targets in its own range. Once the relay is built it switches to the direct route. The desired behaviour is a direct route from the start. fix/network-planned-relays may have misread this.
8. **Trebuchets (decided):** keep high HP, killable by guns. No charge required; there will be many of them and Salvage is sparse.
9. **Info:** Gregory wants a player-readable reference for enemies (stats live in raider_defs.gd, flyer_defs.gd, castle_defs.gd, and config.gd NEST_*).
10. **Mortars need a charge (decided):** enemy mortars can only be destroyed by a demolition charge; one plant kills one. Guns must not finish them (one died to gunfire in play). Charges infinite while testing; inventory space later.
11. **Totems look like Collectors:** make the Totem taller with a glowing red ball on top (art/blender/totem.py -> assets/models/totem.glb).
12. **Lancers guard castles (decided):** Lancers stay at their castle (beam range 32) and nothing can be built within a radius of a hostile castle. The Operative must clear the castle to use the land around it.
13. **Spitter towers (decided):** sabotaging one gives no Salvage. Some respawn instantly, which allows Salvage farming; that must stop. Spitter towers should be constructed by the enemy over time, not pre-placed and respawning.

Done on integ: 1, 3, 4, 7 (Muse branches + Spitter range 14), 10 + 13 (pt3/enemy-builds), 11 (art/totem-red), 12 + 14 (pt3/castle-guard, over-the-wall repro not confirmed), 2 + 6 + 15 (pt3/small-fixes). Open: 5, 9 (later); E-hold mortar sabotage still kills + pays 5 Salvage (ask Gregory). raiders.gd 304 lines, weapon_logic.gd 356: split.
14. **Ashmote Keep Lancers (L1):** Lancers in the keep shoot over the wall and hit the base. No collision rule is broken; Gregory moved the base. Item 12's build exclusion around hostile castles should cover this. Check the LOS fix (fix/enemy-los, merged) clips beams against wall height too.
15. **Flying Node launches packets (decided, overrides the CLAUDE.md "Flying Node" contract):** the Node must keep launching packets while it flies, as long as it is connected to the network. Update the contract in CLAUDE.md when built.
16. **Demolition charge is planted, not thrown (decided):** bought one at a time in the Armoury with Salvage, hold E to plant, fuse, then it destroys the target. Works on any non-living target with a large HP pool: Trebuchets, all enemy-built structures, mortars. Mortars die only to a charge; E-hold no longer kills or pays for them. (pt3/demo-plant)
17. **Unit patrols (decided):** Patrol order for soldiers/crawlers (select, patrol key, click points; loop, engage, resume) to guard the base against Skitters. Units from a barracks inside a held castle auto-patrol that castle. (pt3/unit-patrol)
18. **Null Sprayer is extremely overpowered** (anti-creeper, feat/anti-creeper). Nerf. (pt3/sprayer-cave)
19. **Deep Core projectiles go through cave terrain** (standing on a Salvage engine underground): they must be blocked by terrain and path around it sensibly, not clip through. (pt3/sprayer-cave)
20. **Pulse Rifle still very inaccurate:** bloom 5.5°→1.2°, yaw/climb cut (recoil_defs.gd, Opus).
