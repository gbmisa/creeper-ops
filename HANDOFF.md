# Handoff: 2026-10-07 (session 7: plan, GPU sim, terrain editing, orchestration)

## State
Godot 4.7 game in `godot/`. **The plan lives in [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md)**, the buildable spec in [docs/STRONGHOLDS_DESIGN.md](docs/STRONGHOLDS_DESIGN.md) (§0 answered by the user). The project is now a **git repo**; parallel work happens in worktrees under `../creeper fps td-worktrees/`.

**Roles:** Claude Opus orchestrates: it writes briefs in `docs/tasks/`, reviews every branch and is the only one that merges. Grok Build and other delegated agents follow [AGENTS.md](AGENTS.md): only their brief, commit on their own branch, never merge.

Merged to `main` this session (Phase A):
- **Stage 1** (Grok + Opus fix): built weapons lose HP in creeper (`WEAPON_CREEPER_*`); unbuilt or non-weapon structures die instantly; a charging Nullifier is immune. The Node keeps `STRUCT_*`.
- **Stage 2** (Grok): Beams air only; mortar splash does `MORTAR_RAIDER_DMG`; raiders step one terrace only (no cliff climbing or dropping); raid timing per level (`RAID_SCHEDULE`).
- **Stage 3** (Opus): the design doc.
- **Stage 4** (Opus): **GPU creeper sim** (`sim/creeper_gpu.gd`, `shaders/creeper_flow.glsl`); the CPU sim stays for headless. About 20× faster at 80×80 and about 200× at 512×512 on an RTX 5090.
- **Stage 5** (Opus): `TerrainEdit` (the only runtime terrain change), chunked terrain, `Grid.step_ok` with faction gates for every walker, `base_height`, materials.

## In progress (Grok, one fresh session each; brief in docs/tasks/)
| Worktree | Branch | Brief |
|---|---|---|
| `stage6` | `stage/6-packet-senders` | Outposts send packets (Opus reviews before merge) |
| `stage10b` | `stage/10b-deployment` | Totems, drop anywhere, recall cooldown, death and respawn, Stockpile |
| `grok-command-mode` | `grok/command-mode-split` | Split `command_mode.gd` (no behaviour change) |

Start line for Grok: *"Read AGENTS.md, CLAUDE.md, HANDOFF.md, docs/MASTER_PLAN.md and docs/tasks/<FILE>.md, then do that task and nothing else."*

## Run / test
`godot --path godot`. Tests: CLAUDE.md Testing. The GPU checks need the real display: `-- --gpu-parity` (must PASS) and `-- --perf-sim=512`. New hooks: `--cpu-sim`, `--raise=x,z,r,by`.

## Verified
- Smoke: **78/78 PASS** on `main`. `--demo --units --sim=900`: Node 500/500; wall time unchanged (≈31 s).
- GPU parity PASS, including a mid-run terrain wall, and it FAILS if the height upload is skipped (`--skip-upload`). GPU and CPU screenshots match.

## NOT verified (needs a human)
- How creeper soaking weapons and raiders that can't climb feel in play. GPU sim during a long real session.

## Known issues
- `RID ... Environment leaked at exit` and "resources still in use" at quit: pre-existing, also on the old build.
- Raiders with no route become guards permanently (Stage 2). Fine until enemy mortars arrive (8a); revisit then.
- Creeper ignores gates (Stage 7 decides).

## Next steps
1. **Stage 7, Strongholds (Opus):** castles (ground and raised, moat, drawbridge, wall platforming), tall indestructible spires with the moat pump feeding enemy production, capture and retake. Replaces `aether_towers.gd`. Best started in a **fresh Opus session** (cheaper than carrying this one's context).
2. Review and merge Grok's three branches as they report in. Stage 6 gets a close review.
3. Then write briefs for 8b (roster) and 9a (return packets, Ore, Salvage) for Grok.
