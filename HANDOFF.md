# Handoff: 2026-10-07 (session 9: playtest fixes, 7b/7c planned)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md); spec: [docs/STRONGHOLDS_DESIGN.md](docs/STRONGHOLDS_DESIGN.md) (§3 has "As built (Stage 7)" notes). Git repo; parallel work in worktrees under `../creeper fps td-worktrees/`.

**Roles:** Opus orchestrates (briefs in `docs/tasks/`, reviews, only one who merges). Grok and other agents follow [AGENTS.md](AGENTS.md).

Merged to `main` this session:
- **Stage 7 (Opus): castles replace Aether Towers.** `CastleShape`/`SpireShape` carve ground and raised castles at level build: 2-wide stone walls with corner stairs, faction gates, moat, drawbridge (`Grid.deck`, owner-only, open to all once the winch dies), pillar climb routes, and a 7x7 obsidian spire (16-step ramp + jump pad, top 20 levels up). `Strongholds` (+ `_rules`, `_hooks`, `_meshes`, `spire_pump`) runs hostile → capturing → held → siege, with garrison, counterattack, Aether, breaches through `TerrainEdit`, and the moat pump (`pump.material`, for 8c). Level 1: **Ashmoat Keep** (ground, moat, SW, vent-fed) and **High Bastion** (raised, N). Cave towers removed.
- **Command-mode split** (Grok): `command_input/select/hover.gd`. Clean.
- **Stage 6** (Grok, reviewed): packets launch from the nearest sender; `outpost` structure; shared bank.
- **Stage 10b** (Grok, reviewed): Totems, `@drop` pods, recall cooldown, death and paid respawn, `Stockpile`. Fixed on merge: `@drop` ported into the split files, recall path uses `Grid.step_ok`, cave recall measures from the Rift.

**Session 9 (uncommitted on `main`):** playtest fixes. `PlayerController._push_out` (Operative stuck in the wall after the spire pad); `RaiderField.step_ok` blocks corner cutting; `Raiders._off_floor` keeps raiders off the sloped foot of tall walls; contact-death at `MIN_DEPTH`; darker claimed tint (`terrain.gdshader`); **F8 `test_recall`** (instant recall, no cooldown); `smoke_traps.gd`. Then castle fixes: point-blank rifle hits, solid crown (40 HP), **buildable courtyards in held castles** (`Grid.yard`; retake destroys them via `Strongholds.on_lost`), `smoke_castle_build.gd`. Smoke all PASS (0 failures), demo sim Node 500/500. Not yet checked by a human: the push-out in play, raiders at the Ashmoat moat wall.

**Batch 3 (also uncommitted):** round-robin packets, box-select weapons, solid structures for units, nearest-barracks restock + select-units buttons (U), first-person building (B, `--fpsbuild=T` hook), Nullifier range/soak, emitters 3.0, raider detour (Bastion gate). Smoke **159 PASS**, demo 900 s Node 500/500. **Not verified:** whether a Nullifier can now be finished next to an emitter in real play (the slow demo places it at t=0 into creeper, so it says nothing); feel of FPS building.

**Turrets (session 9, committed):** castle turrets with Salvage (Castle tab F5, or E at a socket). Remaining 7b work: reprisal raid, recurring sieges, aggression stacking, hostile-castle nest buff.

## Run / test
`godot --path godot`. Tests: CLAUDE.md Testing. New hook: `--castle=I[,climb|pad|top|gate]` drops the Operative at castle I (0 Ashmoat, 1 Bastion). From 10b: `--salvage=N`, `--tool=@drop`.

## Verified (headless + Xvfb)
- Smoke **144/144 PASS** on merged `main` (Stage 7 adds 40 checks: a scripted first-person pillar climb and jump-pad landing, raider-proof walls, bridge rules, capture, counterattack, siege/retake, gate break by real raiders, breach, pump + jam, state round-trip).
- `--demo --units --sim=900`: Node 500/500. Wall time 35 s vs 31 s before (castle flow field + garrisons).
- Screenshots: climb route, spire top, Bastion gate and drawbridge, command views, Drop tool.

## NOT verified (needs a human)
- How the climb, jump pad, capture and siege feel in play. Whether 20 s capture / 15 s retake / 4-raider garrisons are fair. GPU parity wasn't rerun (Stage 7 didn't touch the sim; spires only raise heights).
- Stages 1, 2, 4, 5, 6, 10b still lack a human playtest.

## Known issues / decisions to remember
- **Creeper ignores gates and decks** (decided in Stage 7). Ashmoat's moat fills from the SW vent and creeper can cross the gate causeway.
- Castle walls are raider prey only where raiders can stand next to them; a moat castle is attacked through its gate, a raised one through its winch, then its gate.
- Deferred to 9a: castle turrets, wall repair, Salvage trickle. Deferred to 8a: `pressure` (counterattack size uses nest tier for now).
- Pre-existing: `RID ... Environment leaked at exit` at quit. Raiders with no route become guards permanently.
- Merged worktrees (`stage5/6/7/10b`, `grok-command-mode`) are clean and can be removed.

## Next steps
1. Grok: start Stage 7c in worktree `../creeper fps td-worktrees/stage7c` (branch `stage/7c-traversal`), brief [docs/tasks/STAGE7c_traversal.md](docs/tasks/STAGE7c_traversal.md). Review + merge when it reports.
2. Opus finishes **7b** (spec in MASTER_PLAN): reprisal raid, sieges, aggression stacking, hostile-castle nest buff. Turrets are done.
3. Then briefs for 8a, 8b, 9a. Stage 12 places castles properly.
