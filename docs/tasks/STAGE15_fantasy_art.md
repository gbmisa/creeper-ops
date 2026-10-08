# Stage 15: Fantasy art pass (structures, weapon arms, units, enemies, castles)

Worktree `creeper fps td-worktrees/stage15`, branch `stage/15-fantasy-art`. AGENTS.md applies: do only this brief, commit on your branch, never merge.
A separate **judge agent** scores your screenshots against [JUDGE_art_rubric.md](JUDGE_art_rubric.md). Read it: that is how your work is graded.

## Goal
The game looks like **high fantasy**, not sci-fi. Everything stays procedural (GDScript meshes, no imported assets), and **no gameplay changes**.

**Art direction ("Arcane Forge vs. the Blight")**
- **Player side:** weathered pale stone bases, bronze/brass fittings, dark oak, cloth banners, and **cyan rune crystals** as the energy colour (keep `ACCENT` cyan so faction reading doesn't change). Dwarven-arcane engineering: heavy, bolted, carved.
- **Enemy side (the Blight):** chitin, bone, fungal growths, sickly green/magenta glow. Organic and asymmetric, never boxy.
- **Castles:** grey stone, crenellations, round corner towers with conical slate roofs, a gatehouse arch, faction banners (red hostile, cyan held).
- Lighting/sky: a warm fantasy dusk in `world_look.gd`. You may retune terrain base colours in `terrain.gdshader` (grass/earth/rock by level), but **every overlay uniform must look and work the same** (collector tiles, ghost, range rings, network cover, selection rings).

## Scale (hard requirements)
- The Operative is ~1.85 m (eye `Config.EYE` 1.7). **Barracks soldiers must be the same height (~1.8 m)**. The tank stays vehicle-sized.
- **Every structure is taller than the Operative.** Weapons ~3.5–5 m tall, titans (bertha, thor, forge) 6–9 m, Command Node the tallest player structure. Collectors/relays at least ~2.2 m.
- **Footprints don't change:** stay inside the def's footprint cells. Check placement ghosts still match.
- Raider tiers must be clearly different in size and silhouette (Skitter small and fast-looking → Behemoth huge).

## Weapons get arms
Every weapon (cannon, mortar, beam, sniper, nullifier where it makes sense, bertha, thor) is: **tower base → yaw ring (`Turret`, already aimed by `weapon_logic.gd:56`) → articulated arm (shoulder joint, upper arm, elbow, forearm/cradle) → weapon head held at the end.** Ideas: cannon = bronze bombard; mortar = squat stone mortar cradle; beam = crystal focus lens on a staff arm; sniper = long arbalest/ballista; bertha = great bombard on a crane arm; thor = storm crystal on a twin arm. Each must be recognisable from the command camera.
- Keep every named animated part (`Spin`, `Turret`, `Core`, `Glow`) with the same meaning. You may add an `Arm` node that pitches toward the target; if you do, aim it in `weapon_logic.gd` next to the existing `Turret` code (visual only, no rule changes).

## Files
- `command/structure_meshes.gd` (184 lines) will grow: **split it** before it passes 250. Suggested: `structure_meshes.gd` (kit: `mat`, `cyl`, `box`, `ball`, material cache, dispatch), `weapon_meshes.gd` (all armed weapons), `support_meshes.gd` (node, collectors, relays, barracks, outposts, beacon, etc.). Add a shape helper (e.g. `world/shape_kit.gd`: lathe from a 2D profile, tapered prism, arch) if primitives aren't enough. **Cache materials** (one material per colour/style, not one per mesh).
- `units/unit_meshes.gd`, `level/hazard_meshes.gd` (raiders, nests, emitters, vents, spire, rift, core), `level/stronghold_meshes.gd` (castle decor on top of the terrain walls; walls stay terrain), `level/castle_turret_fire.gd` turret models, `world/world_look.gd`, `shaders/terrain.gdshader` (palette only), `shaders/creeper.gdshader` (colour only, optional).
- **Level 2 (Stage 16, running in parallel) adds a ranged castle guard tier named `"Sentinel"`** that is drawn with `HazardMeshes.raider(tier)`. Make `raider()` dispatch on `tier.name` and include a Sentinel design: a tall robed/armoured Blight archer with a glowing bow or spine-launcher. Unknown names fall back to a generic Blight creature.
- Add a `--gallery` hook in `core/debug.gd`: spawns one of every structure (built), one of each unit, one of each raider tier plus a Sentinel, on flat ground in a row, for screenshots. One line in `debug.gd`'s hook list, logic in a new small file if it's more than ~20 lines.
- Budget: ≤ ~40 MeshInstances per structure, ≤ ~15 per raider (there can be 60 raiders). Every file stays under ~250 lines.

## Don't
- Change any def number, footprint, range, HP, cost, ids, or rule. Don't touch `level01.gd`, `castle_shape.gd`, `config.gd` gameplay values, packets, sim.
- Add ground quads for visuals (CLAUDE.md: ground visuals are shader tints).
- Expect a clean merge with Stage 11a (adds a Terp case to `structure_meshes.gd`): that's the orchestrator's job, just note it.

## Screenshots (each round)
Save to `docs/art/round_<N>/` in your worktree (Xvfb command in CLAUDE.md Testing §5, 1600x900). Required set:
1. `gallery_cmd.png`: `--gallery` from the command camera.
2. `gallery_close.png`: `--gallery` close-up of the weapons (use `--look`).
3. `scale_fps.png`: first person standing next to a soldier and a weapon (scale check).
4. `castle.png`: a Level 1 castle (`--castle`/`--look`), and `castle_fps.png` from the ground in first person.
5. `raiders.png`: raider tiers and Sentinel close up.
6. `demo.png`: `--demo --units --sim=300` overview: overlays (collector tiles, range rings, creeper) must still read.
7. `before_*.png` for 1, 4 and 6 on round 1 only, taken **before** your changes, for comparison.

## Process
Work in rounds. After each round: parse check, smoke all PASS, screenshots, commit, then **report and stop** with the screenshot list. The orchestrator runs the judge and sends you its feedback; you then do the next round. Expect 2–3 rounds.

## Check
- Parse clean; smoke all PASS (count unchanged or higher); `--demo --units --sim=900` report numbers match `main` (art must not change the sim).
- MASTER_PLAN.md: add row 15 status ⚠ and one Changelog line.
