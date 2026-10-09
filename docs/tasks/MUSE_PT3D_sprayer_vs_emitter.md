# Brief PT3-D (Muse): Null Sprayer must not erase an emitter (playtest 3, item 26)

**Branch:** `pt3/sprayer-emitter` (from `integ/2026-10-09`). Touch `core/config.gd` (`SPRAYER`, anti-creeper lines), `sim/creeper_sim.gd` (`_anti_tick`, `anti_add` only), `fps/advanced_weapons.gd` / `fps/operative_weapons.gd` (spray output only), `core/smoke_cave_spray.gd`.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, those files, and `docs/CREEPER_SPEC.md` (emitters section only).

## Gregory's report
> "The sprayer is still able to completely overtake an emitter." (After the item 18 nerf: `anti_per_sec` 1.7, 8 s tank.)

## Goal
One sprayer **holds a front or clears a path**; it can't permanently dry out an active emitter. Several sprayers, or the Operative plus Network weapons, can push an emitter back to its cell. The real answer to an emitter stays the Nullifier.

## Tasks
1. **Measure first:** headless sim, Operative-equivalent spray (call the spray function directly) aimed at the L1 emitter nearest the base from 6 cells away, continuous with tank refills, 300 s. Report emitter-cell depth and the wet area within 8 cells every 30 s. Repeat with no spray as the baseline.
2. Pick a rule and say why, e.g.: anti-creeper decays fast (short-lived), spray output falls off with distance, or the emitter's raise ignores anti on its own cell (CW3: the emitter keeps pumping). Numbers go in `config.gd`.
3. Target: with one sprayer for 300 s the emitter cell never stays dry for more than ~5 s and the wet area within 8 cells is at least 40% of baseline; with three sprayers it can be held to under 20%.
4. Smoke rule in `smoke_cave_spray.gd` for the one-sprayer case.

## Must not change
1:1 annihilation, the Nullifier, Network weapon removal.

## Report
AGENTS.md format with the before/after tables.
