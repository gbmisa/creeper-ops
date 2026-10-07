# Handoff: 2026-10-07 (session 6: keybinds, CW creeper rules, Aether Towers, nest raiders)

## State
The game is **Godot 4.7** in `godot/`. The JS build in `src/` is a frozen reference. This session:
- **Rebindable keys** (`core/keybinds.gd`, `ui/keybind_menu.gd`): 45 actions, two keys each. Open the Controls screen with F10, or the Controls button on the briefing and Operative pause screens. Binds save to `user://keybinds.cfg`, and only changed actions are stored, so later updates keep the player's keys and new actions get their defaults. Esc stays fixed. The help line, build menu and info panel show the current keys.
- **CW creeper rules** (`command/structure_upkeep.gd`, split out of structure_manager): creeper destroys any grounded structure on contact, built or not. The Command Node takes HP damage instead. Nothing can be placed on creeper, and the Nullifier lost its exemption, so you have to clear the creeper around an emitter before nullifying it.
- **Ammo fix:** full weapons never request packets. Transit headroom now applies only while a weapon is firing (`Structure.firing`).
- **Aether Towers** (`level/aether_towers.gd`) replace the crystals: 7 on the surface and 4 in the cave. The Operative presses E and holds the tower for 4 s while it stays dry. A held tower makes about 5 Aether/min. Creeper sitting on it for 3 s retakes it. The top bar shows Aether and towers held.
- **Nest raiders** (`level/spore_nests.gd`, `raiders.gd`, `raider_field.gd`) replace the floating mites: six-legged ground bugs that are immune to creeper. They follow one shared BFS flow field to your structures and climb cliffs when no route exists. Each nest keeps 2 guards. Raids start at 5:00. Over time the spawn rate, the cap, nest HP and the raider tier all rise: Skitter, Brute (8:00), Ravager (15:00), Behemoth (22:00). Snipers (power raised to 4), Beams, units, the Operative and the Lance kill them.

## Run
`godot --path godot`. Tests: CLAUDE.md Testing. New debug hooks: `--keys` (open Controls) and `--look=x,z,dist`.

## Verified
- No parse errors. `--smoke`: **49/49 PASS**. New checks: can't build on creeper, creeper kills unbuilt and built instantly, Node only loses HP, full weapon requests nothing, tower capture/pay/retake, raider marches on the base, nests escalate, rebind and key-stealing. Smoke never writes the player's keybind file (confirmed).
- `--demo --units --sim=1200`: base survives 20 min with Node 358/500. It's ground down to 8 structures, the nests reach Ravagers, Emitter NW gets nullified, and the bot never rebuilds. Undefended `--autostart`: raiders kill the Node at about 5:50 (it used to survive 15 min).
- Screenshots: Controls menu, towers with markers in FPS view, a raider walking through creeper.

## NOT verified (needs a human)
- Rebinding by hand (click, press a key, right-click to clear), and whether the binds survive a restart.
- Capture feel (press E, stay close), how raider pressure feels, whether 5:00 is a fair grace period, and whether the base can keep up with Ravagers and Behemoths.
- Raider animation is minimal (it slides with a bob when attacking).

## Known issues / ideas
- `command_mode.gd` (247) is at the size limit. Split it first.
- Cannons and mortars ignore raiders (CW-faithful). If early defence feels too thin, consider letting mortar splash hurt them.
- Spore volleys now one-shot whatever they land on, because creeper kills on contact. Beams matter more.
- The demo bot never builds a Forge or captures towers.
- Not ported: Shields, Terps, Guppies, Ore, Power Zones, Forge singularity, Totems.

## Next steps
**The full plan is now [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md).** Start with its Stages 1–2 (they fix several items below: weapons vs creeper, Beams, cliff climbing).
1. User playtest: keybinds, raids, towers, the instant-death creeper rule.
2. Tune `Config.NEST_*` and `RAIDER_TIERS` from the playtest. Split command_mode.
3. Phase 3 (saved, build only when asked): director, reinforcements, time gates. The nest clock is a first step toward it.
