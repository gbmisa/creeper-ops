# Handoff: 2026-10-07 (session 11: CW3 fidelity, fantasy art, Level 2, all merged)

## State
Godot 4.7 game in `godot/`. Plan: [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md). How to run: [RUN.md](RUN.md). Rules source: [docs/CREEPER_SPEC.md](docs/CREEPER_SPEC.md) (CW3, measured; gaps in [docs/CW3_FIDELITY_GAPS.md](docs/CW3_FIDELITY_GAPS.md)). The user also added `docs/CW4_SPEC.md` (untracked, not read yet).

**Roles:** Opus orchestrates (briefs in `docs/tasks/`, reviews, only one who merges). Grok and subagents follow [AGENTS.md](AGENTS.md).

Merged to `main` this session:
- **Stage 17 CW3 fidelity (Opus):** 30 Hz clamped edge flow (CPU + GPU, parity exact), top-up emitters with `start`, flat wet damage by `wet_time`, unbuilt sites lose progress, slow heal, `CreeperStrike` area weapons, CW3 ranges/costs (sniper 5 packets/shot: user keeps it), **Thor fires from its magazine anywhere**.
- **Stage 16 Level 2 "The Crown Marches" (subagent):** 160x160, 5 castles with terrain towers/gatehouses/keep, 29 Sentinel guards (range 32, charge-up, dodgeable bolts), level select (`--level=2`, briefing buttons).
- **Stage 15 fantasy art (subagent + judge, 4 rounds, final 4.125/5):** weapons on jointed arms, stone/bronze structures, Terp tower, 1.8 m soldiers, Blight raiders and Sentinel, castle decor, dusk light, `--gallery`.
- **Integration + user requests:** Level 2 emitters retuned; L2 towers crowned; held castles get a **Castle Keep** packet sender (`CastleKeeps`); a **flying Node keeps its network connected** (no launches until it lands); **raiders skip prey they can't walk to** (`RaiderField.reachable`).

## Parallel work still out (Grok, not merged, not reviewed)
| Stage | Worktree / branch |
|---|---|
| 7c traversable terrain (committed 112c128) | `stage7c` / `stage/7c-traversal` |
| 10a Armoury (uncommitted when last checked) | `stage10a` / `stage/10a-armoury` |
| 11a Terp Earth (uncommitted when last checked) | `stage11a` / `stage/11a-terp` |
Merge notes: all three branched before Stage 17, so expect conflicts in `config.gd`, `structure_defs.gd`, `debug.gd`, `smoke_test.gd`, `level01.gd` (17 retuned emitter intervals). 11a: replace its Terp case in old `structure_meshes.gd` with `TitanMeshes.terp` (already wired). 10a: wire the Armoury into held castles.

## Verified (headless + Xvfb + real GPU)
- Smoke **235/235 PASS** (the castle garrison check flakes ~1 in 10, also on old main).
- GPU parity PASS exact; 512² GPU 0.057 ms/tick.
- L1 demo 900 s: Node 500/500. L1 undefended: Node dies 354 s. L2 undefended: dies 236 s. L2 demo dies 691 s (all snipers dry; scripted base, not a player).
- Screenshots: merged L1 demo, L2 castle from above and first person (towers crowned, Sentinels visible).

## NOT verified (needs a human)
- How CW3 flow/emitters feel; Level 2 difficulty; whether castle keeps make castles too strong; flying-Node behaviour in play.
- Art in motion (judge saw stills only).

## Known issues
- Art leftovers: blocky first-person crossbow, HUD still says "Pulse Rifle", crown-nest ribs, flat barracks roof, castle walls are plain terrain texture.
- Terrain itself is untextured terraces; it's the biggest remaining visual weakness.
- Raiders now reach and kill lowland weapons they used to get stuck below (L1 demo ends with 4 of 8 weapons).

## Next steps
1. Ask the user how the merged build plays (art, CW3 feel, Level 2, keeps).
2. Review and merge Grok 7c, then 10a/11a when they report.
3. Read `docs/CW4_SPEC.md` if the user wants it applied.
4. Likely art follow-up: terrain/cliff texturing and creeper surface shader.
