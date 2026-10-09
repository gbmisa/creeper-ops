# Brief PT3-E (Muse): held castles are a huge resource boost, never a win condition (playtest 3, item 28)

**Branch:** `pt3/castle-economy` (from `integ/2026-10-09`). Touch `level/stronghold_tick.gd`, `level/stronghold_hooks.gd` (labels), `command/economy.gd` (one new income term), the game/command wiring that calls `Economy.tick`, `ui/top_bar.gd`, `core/config.gd` (CASTLE_* block), `ui/objectives.gd` (L1 Spore Spire row text only), `level/castle_vaults.gd` if the ore task needs it, and a smoke file.
**Read:** AGENTS.md, MUSE_NOTES.md, this brief, those files, `docs/CASTLES2_DESIGN.md` §5 only.

## Gregory's decision
> "Capturing all the castles is not a win condition. Castles are meant to be huge boosts to resource production and beneficial to own, not required to win."
> "Castle sounds good" (to the plan below).

He believes one of Hollow Ridge's win conditions is "capture all the castles". Code says no: victory = all non-optional rows in `Objectives.LIST` (objectives.gd:57), and none is a castle. Likely misreads: the **Spore Spire** objective (castles also have spires you climb) and the top bar **CASTLES 0** chip, which reads like a checklist.

## Today
A held castle pays `CASTLE_SALVAGE_RATE` 0.1/s and `CASTLE_AETHER_RATE` 5/min (× `yield`), plus Reach/Ward/Muster perks. A Reactor gives 0.4 energy/s for 50 energy.

## Tasks
1. **Energy:** add `CASTLE_ENERGY_RATE` (start 1.4/s, about 3.5 Reactors) × `yield` per held castle, as a new term in `Economy.tick`'s income (so the Forge `energy` multiplier applies and the top bar NET/S shows it). Paid only in state `held`, not during `siege` or `capturing`.
2. **Salvage:** raise `CASTLE_SALVAGE_RATE` to 0.4/s. Also paused during a siege.
3. **Ore:** vault cells (`CastleVaults`) on a held castle act as a rich ore vein for Miners (`CASTLE_VAULT_ORE_MULT`, start 3×), shipping only while held. If the ore system can't do this in a small change, skip it and say why.
4. **Readability:**
   - Top bar: rename the chip to "CASTLES HELD" and show its bonus, e.g. `1  +1.4⚡/s`; tooltip lists each held castle's energy/Salvage/Aether.
   - Capture message (stronghold_tick.gd:37) and the castle marker (stronghold_hooks.gd:91) state the energy and Salvage income too.
   - Briefing line about castles (game_flow.gd ~163): add "optional: holding castles boosts your economy; you never need them to win".
   - L1 objective "Destroy the Spore Spire": make clear it is the Blight spore tower, not a castle (e.g. "Destroy the Spore Spire (Blight tower, NE)").
5. **Smoke rules:** a held castle adds `CASTLE_ENERGY_RATE` to `Economy.income`; a besieged one adds 0; completing every non-optional L1 objective with zero castles held still emits `Bus.victory`.

## Must not change
Victory rules, castle states and capture flow, Reach/Ward/Muster perks, raid scaling.

## Report
AGENTS.md format. L1 `--demo --units --sim=900` before/after: energy income at 5/10/15 min with castles held (use `--debug` capture hooks if present).
