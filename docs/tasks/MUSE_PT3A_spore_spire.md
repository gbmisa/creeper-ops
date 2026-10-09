# Brief PT3-A (Muse): Spore Spire range, timing and punch (playtest 3, items 25 + 27)

**Branch:** `pt3/spore-spire` (from `integ/2026-10-09`). Touch only `level/surface_hazards.gd`, `core/config.gd` (SPIRE_*/SPORE_* block), the L1/L2 level files (`level01.gd`, `level02.gd` if it has a spire) and a new smoke file.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, `level/surface_hazards.gd` (`_update_spire`, `_fire_spore`), `core/config.gd` lines with `SPIRE_` / `SPORE_`, `level/pressure.gd`, and the `beam` row in `command/structure_defs.gd`.

## Gregory's report (L1)
> "The spore spire is the mortar that can shoot all the way across the map on level one. It's also completely negated by a single beam, so it doesn't feel powerful enough. But its range is too high." Also: it starts before it makes sense to have built a Beam.

## What Opus found
- `_fire_spore` targets `structures.nearest_to(spire)` with **no range limit**, so it reaches the Command Node from across L1.
- First volley at `SPIRE_INTERVAL` 60 s, long before a Beam is a sensible build.
- One lob per volley with `SPORE_HP` 3: a single Beam always shoots it down, so the spire is either unstoppable (no Beam) or harmless (one Beam).

## Tasks
1. **Range:** add `SPIRE_RANGE` (cells; start ~45, well under L1's width). Only structures within range are targets; none in range = no volley (the sac keeps charging, capped).
2. **Start time:** add `SPIRE_START` (s), overridable per level (`spire.start`). L1: first volley no earlier than when the briefing/tutorial flow makes a Beam affordable; pick a number from a `--demo=slow` run (Beam built time + margin) and report it.
3. **Punch:** volleys grow with mission pressure: `SPIRE_VOLLEY_MIN`..`SPIRE_VOLLEY_MAX` lobs (e.g. 1 -> 5), spread over nearby targets in range, staggered ~0.4 s, each `SPORE_HP` raised so one Beam can stop an early volley but **not** a full late one (two or three Beams can). Put the beam DPS maths in the report.
4. Keep the "Spore volley incoming" warning; say the lob count.
5. **Smoke rules** (new `smoke_spore_spire.gd`): no volley before `SPIRE_START`; no target beyond `SPIRE_RANGE`; at max pressure one Beam lets at least one lob land, three Beams stop all of them.

## Must not change
Spire destruction by demolition charge, the Sac visual, Beam stats, castle spires (different system).

## Report
AGENTS.md format. L1 `--demo --units --sim=900` before/after: volleys fired, lobs landed, lobs shot down.
