# Handoff: 2026-10-08 (session 13: Grok work merged; three long runs out)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). Rules: [docs/CREEPER_SPEC.md](docs/CREEPER_SPEC.md); enemies: [docs/STRONGHOLDS_DESIGN.md](docs/STRONGHOLDS_DESIGN.md) (§3.3, §4 have "As built (Stage 8)" notes). `docs/CW4_SPEC.md` (user's, untracked) still unread.
**Roles:** Opus orchestrates and merges; Grok follows [AGENTS.md](AGENTS.md). The user is budget-limited: **give Grok everything a lesser model can do**; flag it when Opus isn't needed.
**Muse Code** (Meta) can now take the Grok role: setup and task queue in [Muse.md](Muse.md).

## Merged to main this session (all Grok, reviewed by Opus)
- **7c** stairs on L1 · **11a** Terp (Earth) · **10a** Armoury (upgrades, railgun/plasma/demo charge)
- **18b** viewmodels (`WeaponModels`), `dusk_sky.gdshader` with clouds, haze, SSAO · **18c** compact objectives (J), fading log, small banner, "Crossbow" · **18d** drag-build ghosts, field outlines, cost line, Operative drag-build
- **Stage 8** (overnight, 8 phases, log `docs/tasks/STAGE8_progress.md`): `Pressure` curve + overrun, `RaiderDefs` roster (Spitter, Lancer, Warden, Spotter, Burrower), ranged shots, mixed groups, **hives** replace nests (Core: Operative/Lance only, raze, Outpost, rebuild), **enemy mortars** with telegraph ring, Spotter, sabotage, sealed-Node rule.
- **Opus merge fixes:** raider separation clamped (packed groups outran their slowest member); Armoury weapons fall back to the crossbow model; Lancer smoke kills leftover raiders first; command view uses 1/4 fog (`WorldLook.set_command_view`; 18b's haze washed the whole top-down map beige/lavender); creeper roughness 0.32 / specular 0.25.

## Later the same session
- Merged **9a** economy, **8c** enemy construction, **loot + SPOTTED** (Grok did these from HANDOFF's next steps without briefs; all green alone and merged). Spitter restored to spec on main. Smoke OK x2 merged. L1 demo now loses the Node at 603 s (Snipers ignore Spitters): handed to the 9b run.
- **Long runs out** (rules: `docs/tasks/LONG_RUN_RULES.md`): `stage9b` (9b extractors, improved ammo, level placement, tuning), `stage19` (flyers), `stage20` (art pass 2). Each keeps `docs/tasks/<STAGE>_progress.md`.
- User asked about map size: current maps 80²/160² cells; ~256² fits today, 512²-1024² needs the Phase B "large-map performance" stage (creeper mesh is one whole-map mesh, full readback, whole-grid flow field). Waiting for the user's target size.

## Running when this was written (2026-10-08 evening)
Background Claude agents: Stage 21 castles (Opus, `stage21`), 9b Salvage Engines (Sonnet, `stage9b`), 19 flyers (Sonnet, `stage19`). Stage 23 FPS feel is merged. Queue for Muse: see [Muse.md](Muse.md). New token rules: CLAUDE.md "Token budget rules" (use `stage-runner`/`auditor`, not general-purpose).

## Verified
- Smoke **382/382 PASS**, three runs. Parse clean.
- Sims (merged): L1 demo 900 s Node 500/500; L1 undefended dies 336 s; L2 undefended 226 s; L2 demo dies 652 s. All four tiers + Spitter/Lancer/Warden seen in the L1 demo.
- Xvfb screenshots: command view, first person (new crossbow, clouds), gallery (new enemies), mortar ring.

## NOT verified / needs the user
- **Spitter:** the user chose the spec. HP 10, range 20 (`raider_defs.gd`). Skitter dps 6, `NEST_GUARDS` 1, and the later unlocks (Lancer 0.55, groups 0.60) stay as the balance pass left them. L1 `--demo --units --sim=900` now loses the Node at 622 s (was 500/500 at 900 s). Snipers still shoot nearer Skitters while Spitters shell from 20 cells.
- Nothing played by a human: Forward+ look (SSAO, sky), drag-build feel, Armoury, Terp, hives, mortars.

## Known gaps (from Stage 8 log)
No loot pickups (§4.4), no SPOTTED HUD widget (uses Bus.say), mortars not in the hive save, metal/stone-wall shell damage not built, Outpost Ore cost waits for 9a. Smoke files over 250 lines: smoke_terp 436, smoke_armoury 313, smoke_dragbuild 308; debug.gd ~280.

## Next
1. Playtest. 2. Grok briefs: 8c enemy construction, 9a economy, splitting the long smoke files/debug.gd, SPOTTED widget + loot pickups. 3. Opus: CW4_SPEC read if wanted.
