# Handoff: 2026-10-08 (session 13: overnight Grok work reviewed and merged)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). Run: [RUN.md](RUN.md). Rules: [docs/CREEPER_SPEC.md](docs/CREEPER_SPEC.md); enemies: [docs/STRONGHOLDS_DESIGN.md](docs/STRONGHOLDS_DESIGN.md) (§3.3, §4 have "As built (Stage 8)" notes). `docs/CW4_SPEC.md` (user's, untracked) still unread.
**Roles:** Opus orchestrates and merges; Grok follows [AGENTS.md](AGENTS.md). The user is budget-limited: **give Grok everything a lesser model can do**; flag it when Opus isn't needed.

## Merged to main this session (all Grok, reviewed by Opus)
- **7c** stairs on L1 · **11a** Terp (Earth) · **10a** Armoury (upgrades, railgun/plasma/demo charge)
- **18b** viewmodels (`WeaponModels`), `dusk_sky.gdshader` with clouds, haze, SSAO · **18c** compact objectives (J), fading log, small banner, "Crossbow" · **18d** drag-build ghosts, field outlines, cost line, Operative drag-build
- **Stage 8** (overnight, 8 phases, log `docs/tasks/STAGE8_progress.md`): `Pressure` curve + overrun, `RaiderDefs` roster (Spitter, Lancer, Warden, Spotter, Burrower), ranged shots, mixed groups, **hives** replace nests (Core: Operative/Lance only, raze, Outpost, rebuild), **enemy mortars** with telegraph ring, Spotter, sabotage, sealed-Node rule.
- **Opus merge fixes:** raider separation clamped (packed groups outran their slowest member); Armoury weapons fall back to the crossbow model; Lancer smoke kills leftover raiders first; command view uses 1/4 fog (`WorldLook.set_command_view`; 18b's haze washed the whole top-down map beige/lavender); creeper roughness 0.32 / specular 0.25.

## Verified
- Smoke **382/382 PASS**, three runs. Parse clean.
- Sims (merged): L1 demo 900 s Node 500/500; L1 undefended dies 336 s; L2 undefended 226 s; L2 demo dies 652 s. All four tiers + Spitter/Lancer/Warden seen in the L1 demo.
- Xvfb screenshots: command view, first person (new crossbow, clouds), gallery (new enemies), mortar ring.

## NOT verified / needs the user
- **Spitter decision:** in the balance pass Grok made the Spitter HP 4 with a 2-cell lob (spec: HP 10, range 20) so the *scripted* demo base survives. That removes the "medium-range acid lobber" role. Also Skitter dps 3→6, `NEST_GUARDS` 2→1, later unlocks (Lancer 0.55, groups 0.60). Ask the user; restoring spec is a Grok-sized task.
- Nothing played by a human: Forward+ look (SSAO, sky), drag-build feel, Armoury, Terp, hives, mortars.

## Known gaps (from Stage 8 log)
No loot pickups (§4.4), no SPOTTED HUD widget (uses Bus.say), mortars not in the hive save, metal/stone-wall shell damage not built, Outpost Ore cost waits for 9a. Smoke files over 250 lines: smoke_terp 436, smoke_armoury 313, smoke_dragbuild 308; debug.gd ~280.

## Next
1. Playtest; Spitter call. 2. Grok briefs: 8c enemy construction, 9a economy, splitting the long smoke files/debug.gd, SPOTTED widget + loot pickups. 3. Opus: CW4_SPEC read if wanted.
